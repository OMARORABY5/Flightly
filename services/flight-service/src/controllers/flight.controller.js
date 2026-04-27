// flight.controller.js — FLIGHTLY Flight Service Controller
// Phase 3: Airport search & popular airports
// Phase 4: Flight search with filtering, sorting, pagination + flight detail
// WHY: Separating business logic from routing keeps the codebase maintainable

class FlightController {
  constructor(db, redis) {
    this.db    = db;
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
        if (cached) return res.json({ success: true, data: JSON.parse(cached) });
      }

      const result = await this.db.query(
        `SELECT iata_code, icao_code, name, city, country, country_code, latitude, longitude, timezone
         FROM airports
         WHERE iata_code IN (${placeholders}) AND is_active = true`,
        popularCodes
      );

      // Re-sort in JS to match our preferred popular order
      const orderMap = Object.fromEntries(popularCodes.map((c, i) => [c, i]));
      const airports  = result.rows.sort((a, b) => (orderMap[a.iata_code] ?? 99) - (orderMap[b.iata_code] ?? 99));

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
  async searchAirports(req, res) {
    try {
      const { q } = req.query;

      if (!q || q.trim().length < 2) {
        return res.status(400).json({ success: false, message: 'Query must be at least 2 characters.' });
      }

      const query    = q.trim().toLowerCase();
      const cacheKey = `airports:search:${query}`;

      if (this.redis?.isOpen) {
        const cached = await this.redis.get(cacheKey);
        if (cached) return res.json({ success: true, data: JSON.parse(cached) });
      }

      const result = await this.db.query(
        `SELECT iata_code, icao_code, name, city, country, country_code, latitude, longitude, timezone,
                CASE
                  WHEN LOWER(iata_code) = $1 THEN 1
                  WHEN LOWER(city)      LIKE $2 THEN 2
                  WHEN LOWER(name)      LIKE $2 THEN 3
                  WHEN LOWER(country)   LIKE $2 THEN 4
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

      if (this.redis?.isOpen) {
        await this.redis.setEx(cacheKey, 300, JSON.stringify(airports));
      }

      return res.json({ success: true, data: airports });
    } catch (err) {
      console.error('[Flight] searchAirports error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to search airports.' });
    }
  }

  // ─── GET /flights/search ─────────────────────────────────────────────────────
  // Search available flights with optional filtering and sorting.
  //
  // Required query params:
  //   origin       - IATA code (e.g., "CAI")
  //   destination  - IATA code (e.g., "DXB")
  //   date         - Departure date ISO string (e.g., "2025-05-10")
  //   cabin        - Cabin class (economy|premium_economy|business|first)
  //   passengers   - Total passenger count (default 1)
  //
  // Optional filter params:
  //   maxPrice     - Max price per person (number)
  //   maxStops     - Max stops (0=direct only, 1=up to 1 stop, omit=any)
  //   airlines     - Comma-separated IATA airline codes (e.g., "EK,QR")
  //   minDuration  - Min flight duration in minutes
  //   maxDuration  - Max flight duration in minutes
  //
  // Optional sort params:
  //   sort         - best | price_asc | price_desc | duration_asc | departure_asc | arrival_asc
  //
  // Pagination:
  //   page         - Page number (default 1)
  //   limit        - Results per page (default 20, max 50)
  async searchFlights(req, res) {
    try {
      const {
        origin, destination, date,
        cabin      = 'economy',
        passengers = '1',
        maxPrice,
        maxStops,
        airlines,
        minDuration,
        maxDuration,
        sort  = 'best',
        page  = '1',
        limit = '20',
      } = req.query;

      // ── Validate required params ─────────────────────────────────────────────
      if (!origin || !destination || !date) {
        return res.status(400).json({
          success: false,
          message: 'origin, destination, and date are required.',
        });
      }

      if (origin.toUpperCase() === destination.toUpperCase()) {
        return res.status(400).json({
          success: false,
          message: 'Origin and destination cannot be the same airport.',
        });
      }

      const validCabins = ['economy', 'premium_economy', 'business', 'first'];
      if (!validCabins.includes(cabin)) {
        return res.status(400).json({
          success: false,
          message: `Invalid cabin class. Must be one of: ${validCabins.join(', ')}`,
        });
      }

      const pax   = Math.max(1, Math.min(parseInt(passengers, 10) || 1, 9));
      const pageN  = Math.max(1, parseInt(page, 10)  || 1);
      const limitN = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
      const offset = (pageN - 1) * limitN;

      // ── Build dynamic WHERE clauses ──────────────────────────────────────────
      const params = [
        origin.toUpperCase(),       // $1
        destination.toUpperCase(),  // $2
        cabin,                      // $3
        pax,                        // $4
      ];
      let paramIdx = 5;

      // Date window: the full calendar day of the requested date (in UTC)
      const depDay     = new Date(date);
      depDay.setHours(0, 0, 0, 0);
      const depDayEnd  = new Date(date);
      depDayEnd.setHours(23, 59, 59, 999);

      params.push(depDay.toISOString());    // $5
      params.push(depDayEnd.toISOString()); // $6
      paramIdx = 7;

      let filters = '';

      // Filter: maxPrice
      if (maxPrice) {
        filters += ` AND f.base_price <= $${paramIdx}`;
        params.push(parseFloat(maxPrice));
        paramIdx++;
      }

      // Filter: maxStops
      if (maxStops !== undefined && maxStops !== '') {
        filters += ` AND f.stops <= $${paramIdx}`;
        params.push(parseInt(maxStops, 10));
        paramIdx++;
      }

      // Filter: airlines (comma-separated codes)
      if (airlines) {
        const codes = airlines.split(',').map((c) => c.trim().toUpperCase()).filter(Boolean);
        if (codes.length > 0) {
          const placeholders = codes.map((_, i) => `$${paramIdx + i}`).join(',');
          filters += ` AND f.airline_code IN (${placeholders})`;
          codes.forEach((c) => params.push(c));
          paramIdx += codes.length;
        }
      }

      // Filter: duration range
      if (minDuration) {
        filters += ` AND f.duration_minutes >= $${paramIdx}`;
        params.push(parseInt(minDuration, 10));
        paramIdx++;
      }
      if (maxDuration) {
        filters += ` AND f.duration_minutes <= $${paramIdx}`;
        params.push(parseInt(maxDuration, 10));
        paramIdx++;
      }

      // ── Sorting ──────────────────────────────────────────────────────────────
      // "best" = composite score: cheapest + fastest weighted equally
      const ORDER_MAP = {
        best:          'f.base_price / 100.0 + f.duration_minutes / 60.0 ASC',
        price_asc:     'f.base_price ASC',
        price_desc:    'f.base_price DESC',
        duration_asc:  'f.duration_minutes ASC',
        departure_asc: 'f.departure_time ASC',
        arrival_asc:   'f.arrival_time ASC',
      };
      const orderClause = ORDER_MAP[sort] || ORDER_MAP.best;

      // ── Main query ───────────────────────────────────────────────────────────
      const flightQuery = `
        SELECT
          f.id,
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
          f.base_price,
          f.available_seats,
          f.baggage_cabin_kg,
          f.baggage_checked_kg,
          f.is_refundable,
          -- Enrich with airport data
          oa.city   AS origin_city,
          oa.name   AS origin_name,
          oa.country AS origin_country,
          da.city   AS destination_city,
          da.name   AS destination_name,
          da.country AS destination_country,
          -- Total price for all passengers
          ROUND((f.base_price * $4)::numeric, 2) AS total_price,
          -- Count query for pagination
          COUNT(*) OVER () AS total_count
        FROM flights f
        JOIN airports oa ON oa.iata_code = f.origin_iata
        JOIN airports da ON da.iata_code = f.destination_iata
        WHERE
          f.origin_iata      = $1
          AND f.destination_iata = $2
          AND f.cabin_class      = $3
          AND f.available_seats  >= $4
          AND f.departure_time   >= $5
          AND f.departure_time   <= $6
          AND f.is_active        = true
          ${filters}
        ORDER BY ${orderClause}
        LIMIT ${limitN} OFFSET ${offset}
      `;

      const result = await this.db.query(flightQuery, params);

      const totalCount = result.rows.length > 0 ? parseInt(result.rows[0].total_count, 10) : 0;
      const totalPages = Math.ceil(totalCount / limitN);

      // Strip the total_count meta field from individual flight objects
      const flights = result.rows.map(({ total_count, ...f }) => ({
        ...f,
        base_price:  parseFloat(f.base_price),
        total_price: parseFloat(f.total_price),
      }));

      // ── Attach value labels (Best / Cheapest / Fastest) ──────────────────────
      // WHY: Frontend uses these badges on flight cards without needing to sort again
      if (flights.length > 0) {
        const minPrice    = Math.min(...flights.map((f) => f.base_price));
        const minDur      = Math.min(...flights.map((f) => f.duration_minutes));
        const bestScore   = (f) => f.base_price / 100.0 + f.duration_minutes / 60.0;
        const minBest     = Math.min(...flights.map(bestScore));

        flights.forEach((f) => {
          f.labels = [];
          if (f.base_price       === minPrice) f.labels.push('cheapest');
          if (f.duration_minutes === minDur)   f.labels.push('fastest');
          if (Math.abs(bestScore(f) - minBest) < 0.01) f.labels.push('best');
        });
      }

      return res.json({
        success: true,
        data: {
          flights,
          pagination: {
            page:        pageN,
            limit:       limitN,
            total:       totalCount,
            total_pages: totalPages,
            has_next:    pageN < totalPages,
            has_prev:    pageN > 1,
          },
          meta: {
            origin:      origin.toUpperCase(),
            destination: destination.toUpperCase(),
            date,
            cabin,
            passengers:  pax,
            sort,
          },
        },
      });
    } catch (err) {
      console.error('[Flight] searchFlights error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to search flights.' });
    }
  }

  // ─── GET /flights/:id ────────────────────────────────────────────────────────
  // Returns full details for a single flight (used on the Flight Details screen).
  // WHY: Card list shows summary; details screen needs all fields.
  async getFlightById(req, res) {
    try {
      const { id } = req.params;

      // Validate UUID format
      const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidPattern.test(id)) {
        return res.status(400).json({ success: false, message: 'Invalid flight ID format.' });
      }

      // Try cache first — flight details rarely change
      const cacheKey = `flight:detail:${id}`;
      if (this.redis?.isOpen) {
        const cached = await this.redis.get(cacheKey);
        if (cached) return res.json({ success: true, data: JSON.parse(cached) });
      }

      const result = await this.db.query(
        `SELECT
           f.*,
           oa.name     AS origin_name,
           oa.city     AS origin_city,
           oa.country  AS origin_country,
           oa.timezone AS origin_timezone,
           da.name     AS destination_name,
           da.city     AS destination_city,
           da.country  AS destination_country,
           da.timezone AS destination_timezone
         FROM flights f
         JOIN airports oa ON oa.iata_code = f.origin_iata
         JOIN airports da ON da.iata_code = f.destination_iata
         WHERE f.id = $1 AND f.is_active = true`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Flight not found.' });
      }

      const flight = {
        ...result.rows[0],
        base_price: parseFloat(result.rows[0].base_price),
      };

      // Cache for 10 minutes
      if (this.redis?.isOpen) {
        await this.redis.setEx(cacheKey, 600, JSON.stringify(flight));
      }

      return res.json({ success: true, data: flight });
    } catch (err) {
      console.error('[Flight] getFlightById error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to fetch flight details.' });
    }
  }

  // ─── GET /flights/airlines ────────────────────────────────────────────────────
  // Returns the list of airlines that have flights in the database.
  // WHY: Filter screen needs this to populate the "Airlines" multi-select list.
  async getAvailableAirlines(req, res) {
    try {
      const cacheKey = 'flights:airlines';
      if (this.redis?.isOpen) {
        const cached = await this.redis.get(cacheKey);
        if (cached) return res.json({ success: true, data: JSON.parse(cached) });
      }

      const result = await this.db.query(
        `SELECT DISTINCT airline_code, airline_name, airline_logo_url
         FROM flights
         WHERE is_active = true
         ORDER BY airline_name ASC`
      );

      if (this.redis?.isOpen) {
        await this.redis.setEx(cacheKey, 3600, JSON.stringify(result.rows));
      }

      return res.json({ success: true, data: result.rows });
    } catch (err) {
      console.error('[Flight] getAvailableAirlines error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to fetch airlines.' });
    }
  }
}

module.exports = FlightController;
