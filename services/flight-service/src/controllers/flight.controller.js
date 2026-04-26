// flight.controller.js — FLIGHTLY Flight Service Controller
// Phase 3: Airport search & popular airports
// WHY: Separating business logic from routing keeps the codebase maintainable

class FlightController {
  constructor(db, redis) {
    this.db = db;
    this.redis = redis;
  }

  // ─── GET /flights/airports/popular ──────────────────────────────────────────
  // Returns a fixed list of the world's busiest hub airports.
  // WHY: Shown when user opens the airport picker before typing anything.
  async getPopularAirports(req, res) {
    try {
      const popularCodes = ['DXB', 'LHR', 'JFK', 'CDG', 'SIN', 'HND', 'FRA', 'AMS', 'IST', 'CAI'];
      const placeholders = popularCodes.map((_, i) => `$${i + 1}`).join(',');

      // Try Redis cache first (cache for 24h — popular airports rarely change)
      const cacheKey = 'airports:popular';
      if (this.redis?.isOpen) {
        const cached = await this.redis.get(cacheKey);
        if (cached) {
          return res.json({ success: true, data: JSON.parse(cached) });
        }
      }

      const result = await this.db.query(
        `SELECT iata_code, icao_code, name, city, country, country_code, latitude, longitude, timezone
         FROM airports
         WHERE iata_code IN (${placeholders}) AND is_active = true`,
        popularCodes
      );

      // Re-sort in JS to match our preferred popular order
      const orderMap = Object.fromEntries(popularCodes.map((c, i) => [c, i]));
      const airports = result.rows.sort((a, b) => (orderMap[a.iata_code] ?? 99) - (orderMap[b.iata_code] ?? 99));

      // Cache for 24 hours
      if (this.redis?.isOpen) {
        await this.redis.setEx(cacheKey, 86400, JSON.stringify(airports));
      }

      return res.json({ success: true, data: airports });
    } catch (err) {
      console.error('[Flight] getPopularAirports error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to fetch popular airports.' });
    }
  }

  // ─── GET /flights/airports/search?q= ────────────────────────────────────────
  // Full-text search across IATA code, name, city, and country.
  // WHY: User types in the airport picker and sees instant results.
  async searchAirports(req, res) {
    try {
      const { q } = req.query;

      if (!q || q.trim().length < 2) {
        return res.status(400).json({
          success: false,
          message: 'Query must be at least 2 characters.',
        });
      }

      const query = q.trim().toLowerCase();

      // Cache key per query (cache short — 5 min — data may refresh)
      const cacheKey = `airports:search:${query}`;
      if (this.redis?.isOpen) {
        const cached = await this.redis.get(cacheKey);
        if (cached) {
          return res.json({ success: true, data: JSON.parse(cached) });
        }
      }

      // Search by IATA code (exact priority), then city/name/country prefix match
      // WHY: IATA code match ranked first so typing "DXB" shows Dubai first
      const result = await this.db.query(
        `SELECT iata_code, icao_code, name, city, country, country_code, latitude, longitude, timezone,
                CASE
                  WHEN LOWER(iata_code) = $1 THEN 1
                  WHEN LOWER(city) LIKE $2 THEN 2
                  WHEN LOWER(name) LIKE $2 THEN 3
                  WHEN LOWER(country) LIKE $2 THEN 4
                  ELSE 5
                END AS relevance
         FROM airports
         WHERE is_active = true
           AND (
             LOWER(iata_code) LIKE $3
             OR LOWER(name)    LIKE $2
             OR LOWER(city)    LIKE $2
             OR LOWER(country) LIKE $2
           )
         ORDER BY relevance, city ASC
         LIMIT 10`,
        [query, `${query}%`, `${query}%`]
      );

      const airports = result.rows.map(({ relevance, ...rest }) => rest);

      // Cache for 5 minutes
      if (this.redis?.isOpen) {
        await this.redis.setEx(cacheKey, 300, JSON.stringify(airports));
      }

      return res.json({ success: true, data: airports });
    } catch (err) {
      console.error('[Flight] searchAirports error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to search airports.' });
    }
  }
}

module.exports = FlightController;
