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
               (SELECT COUNT(*) FROM booking_passengers bp WHERE bp.booking_id = b.id) AS passenger_count,
               (SELECT json_agg(json_build_object('id', p.id, 'full_name', p.full_name)) FROM booking_passengers bp JOIN passengers p ON bp.passenger_id = p.id WHERE bp.booking_id = b.id) AS passengers
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
        passengers: b.passengers || [],
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
    const { user_id, use_wallet } = req.body;

    const client = await this.db.connect();
    try {
      await client.query('BEGIN');

      const bookingRes = await client.query(
        'SELECT * FROM bookings WHERE id = $1 AND user_id = $2 FOR UPDATE',
        [id, user_id]
      );

      if (bookingRes.rowCount === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ success: false, message: 'Booking not found or access denied' });
      }

      const booking = bookingRes.rows[0];
      if (booking.status === 'confirmed') {
        await client.query('ROLLBACK');
        return res.status(400).json({ success: false, message: 'Booking is already confirmed' });
      }

      let walletDeducted = 0;

      if (use_wallet) {
        const walletRes = await client.query(
          'SELECT * FROM wallets WHERE user_id = $1 FOR UPDATE',
          [user_id]
        );

        if (walletRes.rowCount > 0) {
          const wallet = walletRes.rows[0];
          const balance = parseFloat(wallet.balance);
          const price = parseFloat(booking.total_price);

          if (balance > 0) {
            walletDeducted = Math.min(balance, price);
            
            await client.query(
              'UPDATE wallets SET balance = balance - $1, updated_at = NOW() WHERE user_id = $2',
              [walletDeducted, user_id]
            );

            await client.query(
              `INSERT INTO wallet_transactions (wallet_id, transaction_type, amount, reference, created_at)
               VALUES ($1, 'payment', $2, $3, NOW())`,
              [wallet.id, -walletDeducted, `Payment for booking ${booking.reference}`]
            );
          }
        }
      }

      const updateRes = await client.query(
        `UPDATE bookings
         SET status = 'confirmed', payment_status = 'paid', updated_at = NOW()
         WHERE id = $1
         RETURNING *`,
        [id]
      );

      await client.query('COMMIT');

      if (this.redis) {
        await this.redis.del(`booking:${id}`).catch(() => {});
        await this.redis.del(`bookings:user:${user_id}:all`).catch(() => {});
        await this.redis.del(`bookings:user:${user_id}:pending`).catch(() => {});
        await this.redis.del(`wallet:${user_id}`).catch(() => {});
      }

      const updatedBooking = updateRes.rows[0];
      res.json({
        success: true,
        message: 'Booking confirmed',
        data: {
          id: updatedBooking.id,
          reference: updatedBooking.reference,
          status: updatedBooking.status,
          payment_status: updatedBooking.payment_status,
          wallet_deducted: walletDeducted
        },
      });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('confirmBooking error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to confirm booking' });
    } finally {
      client.release();
    }
  }

  // ─── Helper: Tiered cancellation fee ────────────────────────────────────────
  // Returns the fee percentage based on hours remaining before departure.
  // Policy:
  //   > 24h  → 0%  (full refund)
  //   16-24h → 10%
  //   8-16h  → 20%
  //   4-8h   → 30%
  //   2-4h   → 40%
  //   < 2h   → 70%
  //   After departure → non-refundable (100% fee, caller should block this case)
  _getCancellationFeePercent(departureTime) {
    const now = new Date();
    const hoursUntilDeparture = (new Date(departureTime) - now) / (1000 * 60 * 60);
    if (hoursUntilDeparture <= 0)  return 100; // already departed
    if (hoursUntilDeparture < 2)   return 70;
    if (hoursUntilDeparture < 4)   return 40;
    if (hoursUntilDeparture < 8)   return 30;
    if (hoursUntilDeparture < 16)  return 20;
    if (hoursUntilDeparture < 24)  return 10;
    return 0;
  }

  // ─── POST /bookings/:id/cancel ───────────────────────────────────────────────
  // Cancel a confirmed booking. Applies tiered refund policy based on time
  // remaining before departure. Refund is credited to the user's virtual wallet.
  // Body: { reason? }   — userId comes from JWT via authMiddleware (req.userId)
  async cancelBooking(req, res) {
    const { id } = req.params;
    const userId = req.userId;                        // set by authMiddleware
    const { reason } = req.body;

    const client = await this.db.connect();
    try {
      await client.query('BEGIN');

      // 1. Fetch booking + outbound flight departure time in one query
      const bookingRow = await client.query(
        `SELECT b.*, f.departure_time
         FROM bookings b
         JOIN flights f ON b.flight_id = f.id
         WHERE b.id = $1 AND b.user_id = $2`,
        [id, userId]
      );

      if (bookingRow.rowCount === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ success: false, message: 'Booking not found or access denied' });
      }

      const booking = bookingRow.rows[0];

      // 2. Guard: already cancelled
      if (booking.status === 'cancelled') {
        await client.query('ROLLBACK');
        return res.status(409).json({ success: false, message: 'Booking is already cancelled' });
      }

      // 3. Guard: flight has already departed — non-refundable
      const now = new Date();
      if (new Date(booking.departure_time) <= now) {
        await client.query('ROLLBACK');
        return res.status(422).json({
          success: false,
          message: 'This flight has already departed. Cancellations are not allowed after departure.',
        });
      }

      // 4. Calculate refund using tiered fee policy
      const feePercent  = this._getCancellationFeePercent(booking.departure_time);
      const totalPrice  = parseFloat(booking.total_price);
      const feeAmount   = parseFloat(((feePercent / 100) * totalPrice).toFixed(2));
      const refundAmount = parseFloat((totalPrice - feeAmount).toFixed(2));

      // 5. Restore available seats for outbound (and return) flight
      const passengerRow = await client.query(
        'SELECT COUNT(*) FROM booking_passengers WHERE booking_id = $1',
        [id]
      );
      const passengerCount = parseInt(passengerRow.rows[0].count);

      await client.query(
        'UPDATE flights SET available_seats = available_seats + $1 WHERE id = $2',
        [passengerCount, booking.flight_id]
      );
      if (booking.return_flight_id) {
        await client.query(
          'UPDATE flights SET available_seats = available_seats + $1 WHERE id = $2',
          [passengerCount, booking.return_flight_id]
        );
      }

      // 6. Mark booking as cancelled + store refund metadata
      await client.query(
        `UPDATE bookings
         SET status               = 'cancelled',
             payment_status       = 'refunded',
             refund_amount        = $1,
             cancellation_fee_pct = $2,
             cancellation_reason  = $3,
             cancelled_at         = NOW(),
             updated_at           = NOW()
         WHERE id = $4`,
        [refundAmount, feePercent, reason || null, id]
      );

      // 7. Credit wallet (UPSERT — auto-creates wallet if first refund)
      const walletRow = await client.query(
        `INSERT INTO wallets (user_id, balance)
         VALUES ($1, $2)
         ON CONFLICT (user_id) DO UPDATE
           SET balance     = wallets.balance + EXCLUDED.balance,
               updated_at  = NOW()
         RETURNING id`,
        [userId, refundAmount]
      );
      const walletId = walletRow.rows[0].id;

      // 8. Record wallet transaction (immutable audit entry)
      await client.query(
        `INSERT INTO wallet_transactions
           (wallet_id, booking_id, type, amount, fee_percent, description)
         VALUES ($1, $2, 'refund', $3, $4, $5)`,
        [
          walletId,
          id,
          refundAmount,
          feePercent,
          `Refund for booking ${booking.reference}${feePercent > 0 ? ` (${feePercent}% cancellation fee applied)` : ''}`,
        ]
      );

      await client.query('COMMIT');

      // 9. Invalidate all related Redis cache keys
      if (this.redis) {
        await Promise.all([
          this.redis.del(`booking:${id}`),
          this.redis.del(`bookings:user:${userId}:all`),
          this.redis.del(`bookings:upcoming:${userId}`),
          this.redis.del(`bookings:history:${userId}`),
          this.redis.del(`wallet:${userId}`),
        ].map(p => p.catch(() => {})));
      }

      return res.json({
        success: true,
        message: 'Booking cancelled successfully',
        data: {
          booking_id:      id,
          reference:       booking.reference,
          refund_amount:   refundAmount,
          fee_percent:     feePercent,
          fee_amount:      feeAmount,
          wallet_balance:  refundAmount, // caller can refresh wallet for exact balance
        },
      });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('cancelBooking error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to cancel booking' });
    } finally {
      client.release();
    }
  }

  // ─── GET /bookings/user/upcoming ─────────────────────────────────────────────
  // Phase 10: Returns confirmed bookings where the outbound flight hasn't departed yet.
  // WHY query-time: no cron needed — departure_time > NOW() handles auto-transition
  //                  naturally without any background jobs.
  async getUpcomingTrips(req, res) {
    // userId is injected by auth middleware from JWT — no spoofing possible
    const userId = req.userId;

    const cacheKey = `bookings:upcoming:${userId}`;
    if (this.redis) {
      const cached = await this.redis.get(cacheKey).catch(() => null);
      if (cached) return res.json({ success: true, data: JSON.parse(cached), cached: true });
    }

    try {
      const result = await this.db.query(
        `SELECT b.id, b.reference, b.status, b.payment_status, b.trip_type, b.cabin_class,
                b.total_price, b.contact_email, b.contact_phone, b.created_at,
                f.flight_number, f.airline_name, f.airline_code, f.airline_logo_url,
                f.origin_iata, f.destination_iata,
                f.departure_time, f.arrival_time, f.duration_minutes, f.stops,
                ao.city AS origin_city, ao.name AS origin_name,
                ad.city AS destination_city, ad.name AS destination_name,
                (SELECT COUNT(*) FROM booking_passengers bp WHERE bp.booking_id = b.id) AS passenger_count,
                (SELECT json_agg(json_build_object('id', p.id, 'full_name', p.full_name)) FROM booking_passengers bp JOIN passengers p ON bp.passenger_id = p.id WHERE bp.booking_id = b.id) AS passengers
         FROM bookings b
         JOIN flights f ON b.flight_id = f.id
         JOIN airports ao ON f.origin_iata = ao.iata_code
         JOIN airports ad ON f.destination_iata = ad.iata_code
         WHERE b.user_id = $1
           AND b.status = 'confirmed'
           AND b.payment_status = 'paid'
           AND f.departure_time > NOW()
         ORDER BY f.departure_time ASC`,
        [userId]
      );

      const bookings = result.rows.map(b => ({
        id: b.id,
        reference: b.reference,
        status: b.status,
        payment_status: b.payment_status,
        trip_type: b.trip_type,
        cabin_class: b.cabin_class,
        total_price: parseFloat(b.total_price),
        contact_email: b.contact_email,
        contact_phone: b.contact_phone,
        created_at: b.created_at,
        passenger_count: parseInt(b.passenger_count),
        passengers: b.passengers || [],
        flight: {
          flight_number: b.flight_number,
          airline_name: b.airline_name,
          airline_code: b.airline_code,
          airline_logo_url: b.airline_logo_url,
          origin_iata: b.origin_iata,
          destination_iata: b.destination_iata,
          origin_city: b.origin_city,
          origin_name: b.origin_name,
          destination_city: b.destination_city,
          destination_name: b.destination_name,
          departure_time: b.departure_time,
          arrival_time: b.arrival_time,
          duration_minutes: b.duration_minutes,
          stops: b.stops,
        },
      }));

      // Cache 2 minutes — upcoming trips don't change frequently
      if (this.redis) {
        await this.redis.setEx(cacheKey, 120, JSON.stringify(bookings)).catch(() => {});
      }

      res.json({ success: true, data: bookings, total: bookings.length });
    } catch (err) {
      console.error('getUpcomingTrips error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to fetch upcoming trips' });
    }
  }

  // ─── GET /bookings/user/history ───────────────────────────────────────────────
  // Phase 10: Returns bookings where the outbound flight has already departed,
  // plus any cancelled bookings regardless of date.
  // WHY include cancelled: users want to see their full booking history.
  async getHistoryTrips(req, res) {
    const userId = req.userId;

    const cacheKey = `bookings:history:${userId}`;
    if (this.redis) {
      const cached = await this.redis.get(cacheKey).catch(() => null);
      if (cached) return res.json({ success: true, data: JSON.parse(cached), cached: true });
    }

    try {
      const result = await this.db.query(
        `SELECT b.id, b.reference, b.status, b.payment_status, b.trip_type, b.cabin_class,
                b.total_price, b.contact_email, b.contact_phone, b.created_at,
                f.flight_number, f.airline_name, f.airline_code, f.airline_logo_url,
                f.origin_iata, f.destination_iata,
                f.departure_time, f.arrival_time, f.duration_minutes, f.stops,
                ao.city AS origin_city, ao.name AS origin_name,
                ad.city AS destination_city, ad.name AS destination_name,
                (SELECT COUNT(*) FROM booking_passengers bp WHERE bp.booking_id = b.id) AS passenger_count,
                (SELECT json_agg(json_build_object('id', p.id, 'full_name', p.full_name)) FROM booking_passengers bp JOIN passengers p ON bp.passenger_id = p.id WHERE bp.booking_id = b.id) AS passengers
         FROM bookings b
         JOIN flights f ON b.flight_id = f.id
         JOIN airports ao ON f.origin_iata = ao.iata_code
         JOIN airports ad ON f.destination_iata = ad.iata_code
         WHERE b.user_id = $1
           AND (
             -- Completed trips: confirmed + paid + already departed
             (b.status = 'confirmed' AND b.payment_status = 'paid' AND f.departure_time <= NOW())
             OR
             -- All cancelled bookings regardless of departure date
             (b.status = 'cancelled')
           )
         ORDER BY f.departure_time DESC`,
        [userId]
      );

      const bookings = result.rows.map(b => ({
        id: b.id,
        reference: b.reference,
        status: b.status,
        payment_status: b.payment_status,
        trip_type: b.trip_type,
        cabin_class: b.cabin_class,
        total_price: parseFloat(b.total_price),
        contact_email: b.contact_email,
        contact_phone: b.contact_phone,
        created_at: b.created_at,
        passenger_count: parseInt(b.passenger_count),
        passengers: b.passengers || [],
        flight: {
          flight_number: b.flight_number,
          airline_name: b.airline_name,
          airline_code: b.airline_code,
          airline_logo_url: b.airline_logo_url,
          origin_iata: b.origin_iata,
          destination_iata: b.destination_iata,
          origin_city: b.origin_city,
          origin_name: b.origin_name,
          destination_city: b.destination_city,
          destination_name: b.destination_name,
          departure_time: b.departure_time,
          arrival_time: b.arrival_time,
          duration_minutes: b.duration_minutes,
          stops: b.stops,
        },
      }));

      // Cache 5 minutes — history is stable
      if (this.redis) {
        await this.redis.setEx(cacheKey, 300, JSON.stringify(bookings)).catch(() => {});
      }

      res.json({ success: true, data: bookings, total: bookings.length });
    } catch (err) {
      console.error('getHistoryTrips error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to fetch trip history' });
    }
  }

  // ─── PATCH /bookings/:id ─────────────────────────────────────────────────────
  // Modify an upcoming confirmed booking.
  // Allowed changes: cabin_class, contact_email, contact_phone,
  //                  add_passenger_ids[], remove_passenger_ids[]
  // userId comes from JWT via authMiddleware (req.userId).
  async modifyBooking(req, res) {
    const { id } = req.params;
    const userId = req.userId;
    const {
      cabin_class,
      contact_email,
      contact_phone,
      add_passenger_ids    = [],
      remove_passenger_ids = [],
    } = req.body;

    const client = await this.db.connect();
    try {
      await client.query('BEGIN');

      // 1. Fetch booking + flight departure time
      const bookingRow = await client.query(
        `SELECT b.*, f.departure_time, f.base_price
         FROM bookings b
         JOIN flights f ON b.flight_id = f.id
         WHERE b.id = $1 AND b.user_id = $2`,
        [id, userId]
      );

      if (bookingRow.rowCount === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ success: false, message: 'Booking not found or access denied' });
      }

      const booking = bookingRow.rows[0];

      // 2. Guard: only confirmed bookings can be modified
      if (booking.status !== 'confirmed') {
        await client.query('ROLLBACK');
        return res.status(422).json({ success: false, message: 'Only confirmed bookings can be modified' });
      }

      // 3. Guard: flight must not have departed yet
      if (new Date(booking.departure_time) <= new Date()) {
        await client.query('ROLLBACK');
        return res.status(422).json({ success: false, message: 'Cannot modify a booking after the flight has departed' });
      }

      // 4. Validate added passengers belong to this user
      if (add_passenger_ids.length > 0) {
        const check = await client.query(
          'SELECT id FROM passengers WHERE id = ANY($1::uuid[]) AND user_id = $2',
          [add_passenger_ids, userId]
        );
        if (check.rowCount !== add_passenger_ids.length) {
          await client.query('ROLLBACK');
          return res.status(400).json({ success: false, message: 'One or more passengers to add are invalid or do not belong to this user' });
        }
      }

      // 5. Remove passengers (delete from junction table)
      if (remove_passenger_ids.length > 0) {
        await client.query(
          'DELETE FROM booking_passengers WHERE booking_id = $1 AND passenger_id = ANY($2::uuid[])',
          [id, remove_passenger_ids]
        );
        // Restore seats for removed passengers
        await client.query(
          'UPDATE flights SET available_seats = available_seats + $1 WHERE id = $2',
          [remove_passenger_ids.length, booking.flight_id]
        );
        if (booking.return_flight_id) {
          await client.query(
            'UPDATE flights SET available_seats = available_seats + $1 WHERE id = $2',
            [remove_passenger_ids.length, booking.return_flight_id]
          );
        }
      }

      // 6. Add new passengers (insert into junction table, ignore duplicates)
      if (add_passenger_ids.length > 0) {
        for (const passengerId of add_passenger_ids) {
          await client.query(
            `INSERT INTO booking_passengers (booking_id, passenger_id)
             VALUES ($1, $2)
             ON CONFLICT (booking_id, passenger_id) DO NOTHING`,
            [id, passengerId]
          );
        }
        // Decrement available seats for added passengers
        await client.query(
          'UPDATE flights SET available_seats = available_seats - $1 WHERE id = $2',
          [add_passenger_ids.length, booking.flight_id]
        );
        if (booking.return_flight_id) {
          await client.query(
            'UPDATE flights SET available_seats = available_seats - $1 WHERE id = $2',
            [add_passenger_ids.length, booking.return_flight_id]
          );
        }
      }

      // 7. Recalculate total price based on new passenger count
      const newPassengerRow = await client.query(
        'SELECT COUNT(*) FROM booking_passengers WHERE booking_id = $1',
        [id]
      );
      const newPassengerCount = parseInt(newPassengerRow.rows[0].count);
      const basePrice = parseFloat(booking.base_price);

      // Price = outbound price × passengers (+ return flight price × passengers if round-trip)
      let newTotalPrice = basePrice * newPassengerCount;
      if (booking.return_flight_id) {
        const returnRow = await client.query(
          'SELECT base_price FROM flights WHERE id = $1',
          [booking.return_flight_id]
        );
        if (returnRow.rowCount > 0) {
          newTotalPrice += parseFloat(returnRow.rows[0].base_price) * newPassengerCount;
        }
      }

      // 8. Build dynamic UPDATE for scalar fields
      const updates  = [];
      const values   = [];
      let   paramIdx = 1;

      if (cabin_class) {
        updates.push(`cabin_class = $${paramIdx++}`);
        values.push(cabin_class);
      }
      if (contact_email) {
        updates.push(`contact_email = $${paramIdx++}`);
        values.push(contact_email);
      }
      if (contact_phone !== undefined) {
        updates.push(`contact_phone = $${paramIdx++}`);
        values.push(contact_phone);
      }

      // Always update price and timestamp
      updates.push(`total_price = $${paramIdx++}`);
      values.push(newTotalPrice.toFixed(2));
      updates.push(`updated_at = NOW()`);

      values.push(id); // for WHERE clause
      await client.query(
        `UPDATE bookings SET ${updates.join(', ')} WHERE id = $${paramIdx}`,
        values
      );

      await client.query('COMMIT');

      // 9. Invalidate cache
      if (this.redis) {
        await Promise.all([
          this.redis.del(`booking:${id}`),
          this.redis.del(`bookings:user:${userId}:all`),
          this.redis.del(`bookings:upcoming:${userId}`),
        ].map(p => p.catch(() => {})));
      }

      return res.json({
        success: true,
        message: 'Booking updated successfully',
        data: {
          booking_id:      id,
          new_total_price: parseFloat(newTotalPrice.toFixed(2)),
          passenger_count: newPassengerCount,
        },
      });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('modifyBooking error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to modify booking' });
    } finally {
      client.release();
    }
  }
}

module.exports = BookingController;
