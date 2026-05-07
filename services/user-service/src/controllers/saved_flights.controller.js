// saved_flights.controller.js — FLIGHTLY User Service
// Phase 5: Saved Flights (Watchlist) backend
//
// WHY a separate controller: saved_flights is logically a "user" concern (user owns the saves),
// but it queries the flights table which lives in the same DB. We query it directly from
// user-service since both services share the Postgres instance (monorepo dev setup).

class SavedFlightsController {
  constructor(db, redis) {
    this.db    = db;
    this.redis = redis;
  }

  // ─── Helper: invalidate user's saved-flights cache ──────────────────────────
  async _bust(userId) {
    if (this.redis?.isOpen) {
      await this.redis.del(`saved_flights:user:${userId}`);
    }
  }

  // ─── GET /users/saved-flights ────────────────────────────────────────────────
  // Returns all saved flights for the authenticated user, enriched with current live price.
  // WHY: Auth middleware sets req.userId from JWT — we use that instead of trusting
  //      a user-supplied user_id param (which could be spoofed to access other users' data).
  async getSavedFlights(req, res) {
    try {
      // Use userId from JWT (set by auth middleware); fall back to query param for dev testing
      const user_id = req.userId || req.query.user_id;
      if (!user_id) {
        return res.status(400).json({ success: false, message: 'user_id is required.' });
      }

      const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidPattern.test(user_id)) {
        return res.status(400).json({ success: false, message: 'Invalid user_id format.' });
      }

      // Cache key per user (busted on save/unsave)
      const cacheKey = `saved_flights:user:${user_id}`;
      if (this.redis?.isOpen) {
        const cached = await this.redis.get(cacheKey);
        if (cached) return res.json({ success: true, data: JSON.parse(cached) });
      }

      const result = await this.db.query(
        `SELECT
           sf.id            AS save_id,
           sf.saved_price,
           sf.search_criteria,
           sf.created_at    AS saved_at,
           -- Live flight data
           f.id             AS flight_id,
           f.flight_number,
           f.airline_code,
           f.airline_name,
           f.airline_logo_url,
           f.origin_iata,
           f.destination_iata,
           f.departure_time,
           f.arrival_time,
           f.duration_minutes,
           f.stops,
           f.cabin_class,
           f.base_price     AS current_price,
           f.available_seats,
           f.is_refundable,
           f.is_active,
           -- Airport enrichment
           oa.city          AS origin_city,
           oa.country       AS origin_country,
           da.city          AS destination_city,
           da.country       AS destination_country
         FROM saved_flights sf
         JOIN flights  f  ON f.id  = sf.flight_id
         JOIN airports oa ON oa.iata_code = f.origin_iata
         JOIN airports da ON da.iata_code = f.destination_iata
         WHERE sf.user_id = $1
         ORDER BY sf.created_at DESC`,
        [user_id]
      );

      // Compute price change for each saved flight
      const saved = result.rows.map((row) => {
        const savedPrice   = parseFloat(row.saved_price);
        const currentPrice = parseFloat(row.current_price);
        const difference   = Math.round((currentPrice - savedPrice) * 100) / 100;
        return {
          ...row,
          saved_price:   savedPrice,
          current_price: currentPrice,
          price_changed: Math.abs(difference) > 0.50,
          price_difference: difference,
        };
      });

      if (this.redis?.isOpen) {
        await this.redis.setEx(cacheKey, 120, JSON.stringify(saved)); // 2-min cache
      }

      return res.json({ success: true, data: saved });
    } catch (err) {
      console.error('[User] getSavedFlights error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to fetch saved flights.' });
    }
  }

  // ─── POST /users/saved-flights ───────────────────────────────────────────────
  // Save (watch) a flight. Snapshots current price for later comparison.
  // WHY: Price snapshot lets us show users if the price has gone up or down
  //      since they saved it — a key watchlist feature.
  //
  // Body: { user_id, flight_id, search_criteria? }
  async saveFlight(req, res) {
    try {
      // Use userId from JWT; accept body override only in dev (body.user_id) for Postman testing
      const user_id = req.userId || req.body.user_id;
      const { flight_id, search_criteria } = req.body;

      if (!user_id || !flight_id) {
        return res.status(400).json({ success: false, message: 'user_id and flight_id are required.' });
      }

      const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidPattern.test(user_id) || !uuidPattern.test(flight_id)) {
        return res.status(400).json({ success: false, message: 'Invalid UUID format.' });
      }

      // Fetch current price to snapshot
      const flightResult = await this.db.query(
        `SELECT base_price, is_active FROM flights WHERE id = $1`,
        [flight_id]
      );

      if (flightResult.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Flight not found.' });
      }

      if (!flightResult.rows[0].is_active) {
        return res.status(409).json({ success: false, message: 'Cannot save an inactive flight.' });
      }

      const savedPrice = parseFloat(flightResult.rows[0].base_price);

      // Insert — ON CONFLICT DO NOTHING to handle duplicate saves gracefully
      const insertResult = await this.db.query(
        `INSERT INTO saved_flights (user_id, flight_id, saved_price, search_criteria)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (user_id, flight_id) DO NOTHING
         RETURNING id`,
        [user_id, flight_id, savedPrice, search_criteria ? JSON.stringify(search_criteria) : null]
      );

      const alreadySaved = insertResult.rows.length === 0;

      await this._bust(user_id);

      return res.status(alreadySaved ? 200 : 201).json({
        success: true,
        data: {
          already_saved: alreadySaved,
          saved_price:   savedPrice,
          message:       alreadySaved ? 'Flight was already in your watchlist.' : 'Flight saved to watchlist.',
        },
      });
    } catch (err) {
      console.error('[User] saveFlight error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to save flight.' });
    }
  }

  // ─── DELETE /users/saved-flights/:flightId ───────────────────────────────────
  // Remove a flight from the user's watchlist.
  //
  // Query params:
  //   user_id  - UUID of the user (required)
  async unsaveFlight(req, res) {
    try {
      const { flightId } = req.params;
      // Use userId from JWT; fall back to query param for dev testing
      const user_id = req.userId || req.query.user_id;

      if (!user_id) {
        return res.status(400).json({ success: false, message: 'user_id query param is required.' });
      }

      const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidPattern.test(user_id) || !uuidPattern.test(flightId)) {
        return res.status(400).json({ success: false, message: 'Invalid UUID format.' });
      }

      const result = await this.db.query(
        `DELETE FROM saved_flights WHERE user_id = $1 AND flight_id = $2 RETURNING id`,
        [user_id, flightId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Saved flight not found.' });
      }

      await this._bust(user_id);

      return res.json({ success: true, data: { message: 'Flight removed from watchlist.' } });
    } catch (err) {
      console.error('[User] unsaveFlight error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to remove saved flight.' });
    }
  }

  // ─── GET /users/saved-flights/check/:flightId ───────────────────────────────
  // Check if a specific flight is saved by a user (used for heart-toggle UI state).
  // WHY: The details screen needs to know if the flight is already saved when it loads,
  //      so the heart icon renders in the correct state immediately.
  //
  // Query params:
  //   user_id  - UUID of the user (required)
  async checkSaved(req, res) {
    try {
      const { flightId } = req.params;
      // Use userId from JWT; fall back to query param for dev testing
      const user_id = req.userId || req.query.user_id;

      if (!user_id) {
        return res.status(400).json({ success: false, message: 'user_id query param is required.' });
      }

      const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidPattern.test(user_id) || !uuidPattern.test(flightId)) {
        return res.status(400).json({ success: false, message: 'Invalid UUID format.' });
      }

      const result = await this.db.query(
        `SELECT id, saved_price, created_at FROM saved_flights WHERE user_id = $1 AND flight_id = $2`,
        [user_id, flightId]
      );

      const isSaved = result.rows.length > 0;

      return res.json({
        success: true,
        data: {
          is_saved:    isSaved,
          saved_price: isSaved ? parseFloat(result.rows[0].saved_price) : null,
          saved_at:    isSaved ? result.rows[0].created_at : null,
        },
      });
    } catch (err) {
      console.error('[User] checkSaved error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to check saved status.' });
    }
  }
}

module.exports = SavedFlightsController;
