// booking.controller.js — FLIGHTLY Booking Service
// Phase 6: Full booking creation, retrieval, and cancellation

const { v4: uuidv4 } = require('uuid');

class BookingController {
  constructor(db, redis) {
    this.db = db;
    this.redis = redis;
  }

  // ─── Helper: Generate unique booking reference FLY-YYYYMMDD-XXXXXX ────────────
  _generateReference() {
    const now = new Date();
    const date = now.toISOString().slice(0, 10).replace(/-/g, '');
    const suffix = Math.random().toString(36).toUpperCase().slice(2, 8);
    return `FLY-${date}-${suffix}`;
  }

  // ─── Helper: Ensure unique reference ─────────────────────────────────────────
  async _uniqueReference() {
    let ref;
    let exists = true;
    while (exists) {
      ref = this._generateReference();
      const row = await this.db.query('SELECT id FROM bookings WHERE reference = $1', [ref]);
      exists = row.rowCount > 0;
    }
    return ref;
  }

  // ─── POST /bookings/create ────────────────────────────────────────────────────
  // Creates a booking with passengers, returns reference number
  async createBooking(req, res) {
    const {
      user_id,
      flight_id,
      return_flight_id,
      trip_type = 'one_way',
      cabin_class,
      passenger_ids,   // Array of existing passenger UUIDs
      contact_email,
      contact_phone,
    } = req.body;

    // Basic validation
    if (!user_id || !flight_id || !cabin_class || !contact_email) {
      return res.status(400).json({ success: false, message: 'Missing required fields: user_id, flight_id, cabin_class, contact_email' });
    }
    if (!Array.isArray(passenger_ids) || passenger_ids.length === 0) {
      return res.status(400).json({ success: false, message: 'At least one passenger is required' });
    }

    const client = await this.db.connect();
    try {
      await client.query('BEGIN');

      // 1. Fetch flight price
      const flightRow = await client.query(
        'SELECT id, base_price, available_seats FROM flights WHERE id = $1 AND is_active = TRUE',
        [flight_id]
      );
      if (flightRow.rowCount === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ success: false, message: 'Flight not found or no longer available' });
      }
      const flight = flightRow.rows[0];

      if (flight.available_seats < passenger_ids.length) {
        await client.query('ROLLBACK');
        return res.status(409).json({ success: false, message: `Not enough seats. Only ${flight.available_seats} seats remaining.` });
      }

      // 2. Calculate total price (base price × number of passengers)
      let totalPrice = parseFloat(flight.base_price) * passenger_ids.length;

      // 3. If round-trip, add return flight price too
      let returnFlight = null;
      if (trip_type === 'round_trip' && return_flight_id) {
        const returnRow = await client.query(
          'SELECT id, base_price, available_seats FROM flights WHERE id = $1 AND is_active = TRUE',
          [return_flight_id]
        );
        if (returnRow.rowCount === 0) {
          await client.query('ROLLBACK');
          return res.status(404).json({ success: false, message: 'Return flight not found or no longer available' });
        }
        returnFlight = returnRow.rows[0];
        totalPrice += parseFloat(returnFlight.base_price) * passenger_ids.length;
      }

      // 4. Validate all passengers belong to this user
      const passengerCheck = await client.query(
        'SELECT id FROM passengers WHERE id = ANY($1::uuid[]) AND user_id = $2',
        [passenger_ids, user_id]
      );
      if (passengerCheck.rowCount !== passenger_ids.length) {
        await client.query('ROLLBACK');
        return res.status(400).json({ success: false, message: 'One or more passengers are invalid or do not belong to this user' });
      }

      // 5. Generate unique booking reference
      const reference = await this._uniqueReference();

      // 6. Insert booking record
      const bookingResult = await client.query(
        `INSERT INTO bookings (reference, user_id, flight_id, return_flight_id, trip_type, cabin_class, status, payment_status, total_price, contact_email, contact_phone)
         VALUES ($1, $2, $3, $4, $5, $6, 'pending', 'unpaid', $7, $8, $9)
         RETURNING *`,
        [reference, user_id, flight_id, return_flight_id || null, trip_type, cabin_class, totalPrice, contact_email, contact_phone || null]
      );
      const booking = bookingResult.rows[0];

      // 7. Link passengers to booking in booking_passengers junction table
      for (const passengerId of passenger_ids) {
        await client.query(
          `INSERT INTO booking_passengers (booking_id, passenger_id) VALUES ($1, $2)`,
          [booking.id, passengerId]
        );
      }

      // 8. Decrement available_seats on the flight(s)
      await client.query(
        'UPDATE flights SET available_seats = available_seats - $1 WHERE id = $2',
        [passenger_ids.length, flight_id]
      );
      if (returnFlight) {
        await client.query(
          'UPDATE flights SET available_seats = available_seats - $1 WHERE id = $2',
          [passenger_ids.length, return_flight_id]
        );
      }

      await client.query('COMMIT');

      // 9. Invalidate any cached booking list for this user
      if (this.redis) {
        await this.redis.del(`bookings:user:${user_id}`).catch(() => {});
      }

      res.status(201).json({
        success: true,
        message: 'Booking created successfully',
        data: {
          booking_id: booking.id,
          reference: booking.reference,
          status: booking.status,
          payment_status: booking.payment_status,
          total_price: parseFloat(booking.total_price),
          cabin_class: booking.cabin_class,
          trip_type: booking.trip_type,
          contact_email: booking.contact_email,
          contact_phone: booking.contact_phone,
          created_at: booking.created_at,
        },
      });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('createBooking error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to create booking' });
    } finally {
      client.release();
    }
  }

  // ─── GET /bookings/:id ────────────────────────────────────────────────────────
  // Full booking details: booking + flight + passengers
  async getBookingById(req, res) {
    const { id } = req.params;
    const { user_id } = req.query;

    // Try cache first
    if (this.redis) {
      const cached = await this.redis.get(`booking:${id}`).catch(() => null);
      if (cached) {
        return res.json({ success: true, data: JSON.parse(cached), cached: true });
      }
    }

    try {
      // Fetch core booking
      const bookingRow = await this.db.query(
        `SELECT b.*,
           f.flight_number, f.airline_name, f.airline_code, f.origin_iata, f.destination_iata,
           f.departure_time, f.arrival_time, f.duration_minutes, f.stops, f.cabin_class AS flight_cabin,
           f.baggage_cabin_kg, f.baggage_checked_kg, f.is_refundable,
           ao.city AS origin_city, ao.name AS origin_name,
           ad.city AS destination_city, ad.name AS destination_name
         FROM bookings b
         JOIN flights f ON b.flight_id = f.id
         JOIN airports ao ON f.origin_iata = ao.iata_code
         JOIN airports ad ON f.destination_iata = ad.iata_code
         WHERE b.id = $1`,
        [id]
      );

      if (bookingRow.rowCount === 0) {
        return res.status(404).json({ success: false, message: 'Booking not found' });
      }
      const booking = bookingRow.rows[0];

      // Security: user can only view their own bookings (soft check if user_id provided)
      if (user_id && booking.user_id !== user_id) {
        return res.status(403).json({ success: false, message: 'Access denied' });
      }

      // Fetch passengers on this booking
      const passengersRow = await this.db.query(
        `SELECT p.*, bp.seat_number, bp.ticket_number
         FROM booking_passengers bp
         JOIN passengers p ON bp.passenger_id = p.id
         WHERE bp.booking_id = $1`,
        [id]
      );

      // Fetch return flight if round-trip
      let returnFlightData = null;
      if (booking.return_flight_id) {
        const rfRow = await this.db.query(
          `SELECT f.*,
             ao.city AS origin_city, ao.name AS origin_name,
             ad.city AS destination_city, ad.name AS destination_name
           FROM flights f
           JOIN airports ao ON f.origin_iata = ao.iata_code
           JOIN airports ad ON f.destination_iata = ad.iata_code
           WHERE f.id = $1`,
          [booking.return_flight_id]
        );
        if (rfRow.rowCount > 0) returnFlightData = rfRow.rows[0];
      }

      const result = {
        id: booking.id,
        reference: booking.reference,
        status: booking.status,
        payment_status: booking.payment_status,
        trip_type: booking.trip_type,
        cabin_class: booking.cabin_class,
        total_price: parseFloat(booking.total_price),
        contact_email: booking.contact_email,
        contact_phone: booking.contact_phone,
        created_at: booking.created_at,
        updated_at: booking.updated_at,
        outbound_flight: {
          flight_number: booking.flight_number,
          airline_name: booking.airline_name,
          airline_code: booking.airline_code,
          origin_iata: booking.origin_iata,
          destination_iata: booking.destination_iata,
          origin_city: booking.origin_city,
          origin_name: booking.origin_name,
          destination_city: booking.destination_city,
          destination_name: booking.destination_name,
          departure_time: booking.departure_time,
          arrival_time: booking.arrival_time,
          duration_minutes: booking.duration_minutes,
          stops: booking.stops,
          baggage_cabin_kg: booking.baggage_cabin_kg,
          baggage_checked_kg: booking.baggage_checked_kg,
          is_refundable: booking.is_refundable,
        },
        return_flight: returnFlightData,
        passengers: passengersRow.rows.map(p => ({
          id: p.id,
          full_name: p.full_name,
          gender: p.gender,
          date_of_birth: p.date_of_birth,
          nationality: p.nationality,
          passport_number: p.passport_number,
          passport_expiry: p.passport_expiry,
          seat_number: p.seat_number,
          ticket_number: p.ticket_number,
        })),
      };

      // Cache for 5 minutes
      if (this.redis) {
        await this.redis.setEx(`booking:${id}`, 300, JSON.stringify(result)).catch(() => {});
      }

      res.json({ success: true, data: result });
    } catch (err) {
      console.error('getBookingById error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to fetch booking' });
    }
  }

  // ─── GET /bookings?user_id= ───────────────────────────────────────────────────
  // List all bookings for a user (upcoming + past)
  async getUserBookings(req, res) {
    const { user_id, status } = req.query;
    if (!user_id) {
      return res.status(400).json({ success: false, message: 'user_id is required' });
    }

    // Try cache
    const cacheKey = `bookings:user:${user_id}:${status || 'all'}`;
    if (this.redis) {
      const cached = await this.redis.get(cacheKey).catch(() => null);
      if (cached) return res.json({ success: true, data: JSON.parse(cached), cached: true });
    }

    try {
      let query = `
        SELECT b.id, b.reference, b.status, b.payment_status, b.trip_type, b.cabin_class,
               b.total_price, b.contact_email, b.created_at,
               f.flight_number, f.airline_name, f.airline_code,
               f.origin_iata, f.destination_iata,
               f.departure_time, f.arrival_time, f.duration_minutes,
               ao.city AS origin_city, ad.city AS destination_city,
               (SELECT COUNT(*) FROM booking_passengers bp WHERE bp.booking_id = b.id) AS passenger_count
        FROM bookings b
        JOIN flights f ON b.flight_id = f.id
        JOIN airports ao ON f.origin_iata = ao.iata_code
        JOIN airports ad ON f.destination_iata = ad.iata_code
        WHERE b.user_id = $1
      `;
      const params = [user_id];

      if (status) {
        query += ` AND b.status = $${params.length + 1}`;
        params.push(status);
      }

      query += ' ORDER BY b.created_at DESC';

      const result = await this.db.query(query, params);
      const bookings = result.rows.map(b => ({
        id: b.id,
        reference: b.reference,
        status: b.status,
        payment_status: b.payment_status,
        trip_type: b.trip_type,
        cabin_class: b.cabin_class,
        total_price: parseFloat(b.total_price),
        contact_email: b.contact_email,
        created_at: b.created_at,
        passenger_count: parseInt(b.passenger_count),
        flight: {
          flight_number: b.flight_number,
          airline_name: b.airline_name,
          airline_code: b.airline_code,
          origin_iata: b.origin_iata,
          destination_iata: b.destination_iata,
          origin_city: b.origin_city,
          destination_city: b.destination_city,
          departure_time: b.departure_time,
          arrival_time: b.arrival_time,
          duration_minutes: b.duration_minutes,
        },
      }));

      if (this.redis) {
        await this.redis.setEx(cacheKey, 120, JSON.stringify(bookings)).catch(() => {});
      }

      res.json({ success: true, data: bookings, total: bookings.length });
    } catch (err) {
      console.error('getUserBookings error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to fetch bookings' });
    }
  }

  // ─── POST /bookings/:id/confirm ───────────────────────────────────────────────
  // Phase 7 will call this after successful payment. For now it can be triggered
  // directly. Updates status → confirmed, payment_status → paid.
  async confirmBooking(req, res) {
    const { id } = req.params;
    const { user_id } = req.body;

    try {
      const result = await this.db.query(
        `UPDATE bookings
         SET status = 'confirmed', payment_status = 'paid', updated_at = NOW()
         WHERE id = $1 AND user_id = $2
         RETURNING *`,
        [id, user_id]
      );

      if (result.rowCount === 0) {
        return res.status(404).json({ success: false, message: 'Booking not found or access denied' });
      }

      // Invalidate caches
      if (this.redis) {
        await this.redis.del(`booking:${id}`).catch(() => {});
        await this.redis.del(`bookings:user:${user_id}:all`).catch(() => {});
        await this.redis.del(`bookings:user:${user_id}:pending`).catch(() => {});
      }

      const booking = result.rows[0];
      res.json({
        success: true,
        message: 'Booking confirmed',
        data: {
          id: booking.id,
          reference: booking.reference,
          status: booking.status,
          payment_status: booking.payment_status,
        },
      });
    } catch (err) {
      console.error('confirmBooking error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to confirm booking' });
    }
  }

  // ─── DELETE /bookings/:id ─────────────────────────────────────────────────────
  // Cancel a booking (only pending bookings can be cancelled)
  async cancelBooking(req, res) {
    const { id } = req.params;
    const { user_id } = req.body;

    const client = await this.db.connect();
    try {
      await client.query('BEGIN');

      const bookingRow = await client.query(
        'SELECT * FROM bookings WHERE id = $1 AND user_id = $2',
        [id, user_id]
      );

      if (bookingRow.rowCount === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ success: false, message: 'Booking not found or access denied' });
      }

      const booking = bookingRow.rows[0];

      if (booking.status === 'cancelled') {
        await client.query('ROLLBACK');
        return res.status(409).json({ success: false, message: 'Booking is already cancelled' });
      }

      // Restore seats on the flight
      const passengerCount = await client.query(
        'SELECT COUNT(*) FROM booking_passengers WHERE booking_id = $1',
        [id]
      );
      const count = parseInt(passengerCount.rows[0].count);

      await client.query(
        'UPDATE flights SET available_seats = available_seats + $1 WHERE id = $2',
        [count, booking.flight_id]
      );
      if (booking.return_flight_id) {
        await client.query(
          'UPDATE flights SET available_seats = available_seats + $1 WHERE id = $2',
          [count, booking.return_flight_id]
        );
      }

      // Mark as cancelled
      await client.query(
        `UPDATE bookings SET status = 'cancelled', updated_at = NOW() WHERE id = $1`,
        [id]
      );

      await client.query('COMMIT');

      // Invalidate caches
      if (this.redis) {
        await this.redis.del(`booking:${id}`).catch(() => {});
        await this.redis.del(`bookings:user:${user_id}:all`).catch(() => {});
      }

      res.json({ success: true, message: 'Booking cancelled successfully' });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('cancelBooking error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to cancel booking' });
    } finally {
      client.release();
    }
  }
}

module.exports = BookingController;
