class ProfileController {
  constructor(db, redisClient) {
    this.db = db;
    this.redis = redisClient;
  }

  async getProfile(req, res) {
    try {
      const result = await this.db.query(
        'SELECT id, email, display_name, phone, nationality, photo_url, created_at FROM users WHERE id = $1',
        [req.userId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
      return res.status(200).json({ success: true, data: result.rows[0] });
    } catch (err) {
      console.error('[Profile] getProfile error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to fetch profile' });
    }
  }

  async updateProfile(req, res) {
    try {
      const { display_name, phone, nationality } = req.body;
      const result = await this.db.query(
        'UPDATE users SET display_name = COALESCE($1, display_name), phone = COALESCE($2, phone), nationality = COALESCE($3, nationality), updated_at = NOW() WHERE id = $4 RETURNING id, email, display_name, phone, nationality, photo_url',
        [display_name, phone, nationality, req.userId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
      return res.status(200).json({ success: true, data: result.rows[0], message: 'Profile updated successfully' });
    } catch (err) {
      console.error('[Profile] updateProfile error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to update profile' });
    }
  }

  async updatePhoto(req, res) {
    try {
      const { photo_url } = req.body;
      if (!photo_url) {
        return res.status(400).json({ success: false, message: 'photo_url is required' });
      }
      const result = await this.db.query(
        'UPDATE users SET photo_url = $1, updated_at = NOW() WHERE id = $2 RETURNING photo_url',
        [photo_url, req.userId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
      return res.status(200).json({ success: true, data: result.rows[0], message: 'Photo updated successfully' });
    } catch (err) {
      console.error('[Profile] updatePhoto error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to update photo' });
    }
  }
}

module.exports = ProfileController;
