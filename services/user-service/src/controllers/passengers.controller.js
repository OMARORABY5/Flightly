// passengers.controller.js — FLIGHTLY User Service
// Phase 6: Passenger profile CRUD — saved per user for quick re-use at booking

class PassengersController {
  constructor(db, redis) {
    this.db = db;
    this.redis = redis;
  }

  _cacheKey(userId) {
    return `passengers:user:${userId}`;
  }

  async _invalidate(userId) {
    if (this.redis) await this.redis.del(this._cacheKey(userId)).catch(() => {});
  }

  // ─── GET /users/passengers?user_id= ────────────────────────────────────────────
  // List all saved passenger profiles for a user
  async listPassengers(req, res) {
    const { user_id } = req.query;
    if (!user_id) {
      return res.status(400).json({ success: false, message: 'user_id is required' });
    }

    // Try cache
    if (this.redis) {
      const cached = await this.redis.get(this._cacheKey(user_id)).catch(() => null);
      if (cached) return res.json({ success: true, data: JSON.parse(cached), cached: true });
    }

    try {
      const result = await this.db.query(
        `SELECT id, full_name, gender, date_of_birth, nationality, passport_number,
                passport_expiry, is_primary, created_at, updated_at
         FROM passengers
         WHERE user_id = $1
         ORDER BY is_primary DESC, created_at ASC`,
        [user_id]
      );

      const passengers = result.rows;

      if (this.redis) {
        await this.redis.setEx(this._cacheKey(user_id), 300, JSON.stringify(passengers)).catch(() => {});
      }

      res.json({ success: true, data: passengers, total: passengers.length });
    } catch (err) {
      console.error('listPassengers error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to fetch passengers' });
    }
  }

  // ─── POST /users/passengers ─────────────────────────────────────────────────────
  // Add a new passenger profile
  async addPassenger(req, res) {
    const {
      user_id,
      full_name,
      gender,
      date_of_birth,
      nationality,
      passport_number,
      passport_expiry,
      is_primary = false,
    } = req.body;

    if (!user_id || !full_name || !gender || !date_of_birth || !nationality || !passport_number) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    // Gender validation
    if (!['male', 'female'].includes(gender.toLowerCase())) {
      return res.status(400).json({ success: false, message: 'Gender must be male or female' });
    }

    // DOB: must be in the past
    const dob = new Date(date_of_birth);
    if (isNaN(dob.getTime()) || dob >= new Date()) {
      return res.status(400).json({ success: false, message: 'Invalid date of birth' });
    }

    // Passport expiry: must be in the future if provided
    if (passport_expiry) {
      const expiry = new Date(passport_expiry);
      if (expiry <= new Date()) {
        return res.status(400).json({ success: false, message: 'Passport has already expired' });
      }
    }

    // Duplicate passport check for same user
    const dup = await this.db.query(
      'SELECT id FROM passengers WHERE user_id = $1 AND passport_number = $2',
      [user_id, passport_number.toUpperCase()]
    );
    if (dup.rowCount > 0) {
      return res.status(409).json({ success: false, message: 'A passenger with this passport number already exists' });
    }

    try {
      // If is_primary is being set, clear existing primary
      if (is_primary) {
        await this.db.query(
          'UPDATE passengers SET is_primary = FALSE WHERE user_id = $1',
          [user_id]
        );
      }

      const result = await this.db.query(
        `INSERT INTO passengers (user_id, full_name, gender, date_of_birth, nationality, passport_number, passport_expiry, is_primary)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [user_id, full_name.trim(), gender.toLowerCase(), date_of_birth, nationality, passport_number.toUpperCase(), passport_expiry || null, is_primary]
      );

      await this._invalidate(user_id);

      res.status(201).json({ success: true, message: 'Passenger added', data: result.rows[0] });
    } catch (err) {
      console.error('addPassenger error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to add passenger' });
    }
  }

  // ─── PUT /users/passengers/:id ─────────────────────────────────────────────────
  // Update an existing passenger profile
  async updatePassenger(req, res) {
    const { id } = req.params;
    const {
      user_id,
      full_name,
      gender,
      date_of_birth,
      nationality,
      passport_number,
      passport_expiry,
      is_primary,
    } = req.body;

    if (!user_id) {
      return res.status(400).json({ success: false, message: 'user_id is required' });
    }

    // Verify ownership
    const existing = await this.db.query(
      'SELECT id FROM passengers WHERE id = $1 AND user_id = $2',
      [id, user_id]
    );
    if (existing.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Passenger not found or access denied' });
    }

    try {
      // If setting as primary, clear others first
      if (is_primary === true) {
        await this.db.query(
          'UPDATE passengers SET is_primary = FALSE WHERE user_id = $1',
          [user_id]
        );
      }

      const result = await this.db.query(
        `UPDATE passengers
         SET full_name      = COALESCE($1, full_name),
             gender         = COALESCE($2, gender),
             date_of_birth  = COALESCE($3, date_of_birth),
             nationality    = COALESCE($4, nationality),
             passport_number= COALESCE($5, passport_number),
             passport_expiry= COALESCE($6, passport_expiry),
             is_primary     = COALESCE($7, is_primary),
             updated_at     = NOW()
         WHERE id = $8 AND user_id = $9
         RETURNING *`,
        [
          full_name?.trim() || null,
          gender?.toLowerCase() || null,
          date_of_birth || null,
          nationality || null,
          passport_number?.toUpperCase() || null,
          passport_expiry || null,
          is_primary !== undefined ? is_primary : null,
          id,
          user_id,
        ]
      );

      await this._invalidate(user_id);

      res.json({ success: true, message: 'Passenger updated', data: result.rows[0] });
    } catch (err) {
      console.error('updatePassenger error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to update passenger' });
    }
  }

  // ─── DELETE /users/passengers/:id ──────────────────────────────────────────────
  // Delete a passenger profile (cannot delete if they're on an active booking)
  async deletePassenger(req, res) {
    const { id } = req.params;
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({ success: false, message: 'user_id is required' });
    }

    // Check they own it
    const existing = await this.db.query(
      'SELECT id FROM passengers WHERE id = $1 AND user_id = $2',
      [id, user_id]
    );
    if (existing.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Passenger not found or access denied' });
    }

    // Block delete if passenger is on a confirmed/pending booking
    const activeBooking = await this.db.query(
      `SELECT bp.id FROM booking_passengers bp
       JOIN bookings b ON bp.booking_id = b.id
       WHERE bp.passenger_id = $1 AND b.status IN ('pending', 'confirmed')`,
      [id]
    );
    if (activeBooking.rowCount > 0) {
      return res.status(409).json({ success: false, message: 'Cannot delete a passenger who is on an active booking' });
    }

    try {
      await this.db.query('DELETE FROM passengers WHERE id = $1', [id]);
      await this._invalidate(user_id);
      res.json({ success: true, message: 'Passenger deleted' });
    } catch (err) {
      console.error('deletePassenger error:', err.message);
      res.status(500).json({ success: false, message: 'Failed to delete passenger' });
    }
  }
}

module.exports = PassengersController;
