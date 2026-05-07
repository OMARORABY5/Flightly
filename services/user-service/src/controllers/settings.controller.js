class SettingsController {
  constructor(db, redisClient) {
    this.db = db;
    this.redis = redisClient;
  }

  async getSettings(req, res) {
    try {
      const result = await this.db.query(
        'SELECT language, country, currency FROM user_settings WHERE user_id = $1',
        [req.userId]
      );
      
      if (result.rows.length === 0) {
        return res.status(200).json({ 
          success: true, 
          data: { language: 'en', country: 'Egypt', currency: 'USD' } 
        });
      }
      
      return res.status(200).json({ success: true, data: result.rows[0] });
    } catch (err) {
      console.error('[Settings] getSettings error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to fetch settings' });
    }
  }

  async updateSettings(req, res) {
    try {
      const { language, country, currency } = req.body;
      
      const result = await this.db.query(
        `INSERT INTO user_settings (user_id, language, country, currency) 
         VALUES ($1, COALESCE($2, 'en'), COALESCE($3, 'Egypt'), COALESCE($4, 'USD'))
         ON CONFLICT (user_id) 
         DO UPDATE SET 
           language = COALESCE($2, user_settings.language), 
           country = COALESCE($3, user_settings.country), 
           currency = COALESCE($4, user_settings.currency), 
           updated_at = NOW()
         RETURNING language, country, currency`,
        [req.userId, language, country, currency]
      );
      
      return res.status(200).json({ 
        success: true, 
        data: result.rows[0], 
        message: 'Settings updated successfully' 
      });
    } catch (err) {
      console.error('[Settings] updateSettings error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to update settings' });
    }
  }
}

module.exports = SettingsController;
