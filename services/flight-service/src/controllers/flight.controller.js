// flight.controller.js — FLIGHTLY Flight Service Controller
// Phase 3: Airport search & popular airports
// Phase 4: Flight search with filtering, sorting, pagination + flight detail
// Phase 5: Enhanced flight details, smart pricing, price-check endpoint
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
      // Egyptian airports first, then world hubs
      const popularCodes = ['CAI', 'HBE', 'SSH', 'HRG', 'LXR', 'DXB', 'LHR', 'JFK', 'CDG', 'IST', 'SIN', 'FRA'];
      const placeholders = popularCodes.map((_, i) => `$${i + 1}`).join(',');

      // Try Redis cache first (cache for 24h — popular airports rarely change)
      const cacheKey = 'airports:popular:v2';
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
      const orderClause = ORDER_MAP[sort] ?? ORDER_MAP.best;

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
  // Phase 5: Enhanced with smart pricing data, seat availability indicator,
  //          fare class display label, and refund/change policy fields.
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
           oa.name       AS origin_name,
           oa.city       AS origin_city,
           oa.country    AS origin_country,
           oa.timezone   AS origin_timezone,
           da.name       AS destination_name,
           da.city       AS destination_city,
           da.country    AS destination_country,
           da.timezone   AS destination_timezone
         FROM flights f
         JOIN airports oa ON oa.iata_code = f.origin_iata
         JOIN airports da ON da.iata_code = f.destination_iata
         WHERE f.id = $1 AND f.is_active = true`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Flight not found.' });
      }

      const raw    = result.rows[0];
      const price  = parseFloat(raw.base_price);
      const seats  = parseInt(raw.available_seats, 10);

      // ── Smart Pricing: Seat availability indicator ───────────────────────────
      // WHY: "Only 3 seats left!" creates urgency, drives conversions.
      // We bucket availability into levels without revealing exact seat count (airline best practice).
      let seatAvailability;
      if (seats <= 3)       seatAvailability = 'critical';   // "Only 3 left!"
      else if (seats <= 9)  seatAvailability = 'low';        // "Almost full"
      else if (seats <= 20) seatAvailability = 'limited';    // "Limited seats"
      else                  seatAvailability = 'available';  // Normal state

      // ── Smart Pricing: Price trend simulation ────────────────────────────────
      // WHY: Shows users if prices are rising or falling to nudge booking decisions.
      // In production this would compare against a historical price table.
      // For this MVP we derive it deterministically from the flight ID + price
      // so it's stable across page refreshes but varies by flight.
      const idSum  = id.replace(/-/g, '').split('').reduce((s, c) => s + c.charCodeAt(0), 0);
      const trends = ['rising', 'stable', 'stable', 'falling', 'stable'];
      const priceTrend = trends[idSum % trends.length];

      // ── Smart Pricing: Price change percentage (vs "yesterday") ──────────────
      // Deterministic simulation: stable ± 0%, rising +5-15%, falling -3-12%
      let priceChangePercent = 0;
      if (priceTrend === 'rising')  priceChangePercent = +((idSum % 11) + 5);   // +5..+15%
      if (priceTrend === 'falling') priceChangePercent = -((idSum % 10) + 3);   // -3..-12%

      // ── Fare class label mapping ──────────────────────────────────────────────
      // WHY: DB stores machine-readable cabin class; UI needs a display label
      const FARE_LABELS = {
        economy:         'Economy',
        premium_economy: 'Premium Economy',
        business:        'Business Class',
        first:           'First Class',
      };

      // ── Refund & Change Policy ────────────────────────────────────────────────
      // WHY: Required info for details screen; derived from is_refundable + cabin_class.
      // Business/First are always changeable for a fee; economy varies by refundability.
      const isHighCabin = ['business', 'first'].includes(raw.cabin_class);
      const policy = {
        is_refundable:       raw.is_refundable,
        cancellation_policy: raw.is_refundable
          ? 'Free cancellation up to 24 hours before departure.'
          : 'Non-refundable. Credit valid for 12 months.',
        change_policy: isHighCabin
          ? 'Date/time changes permitted for a fee.'
          : (raw.is_refundable ? 'Changes allowed with fare difference.' : 'No changes permitted.'),
        change_fee: isHighCabin ? 75 : (raw.is_refundable ? 50 : null), // USD
      };

      const flight = {
        ...raw,
        base_price:           price,
        // Smart pricing enrichments
        seat_availability:    seatAvailability,
        seats_remaining:      seats,
        price_trend:          priceTrend,
        price_change_percent: priceChangePercent,
        // Display helpers
        fare_label:           FARE_LABELS[raw.cabin_class] ?? raw.cabin_class,
        // Policy
        policy,
      };

      // Cache for 5 minutes (shorter than Phase 4 to keep seat count fresh)
      if (this.redis?.isOpen) {
        await this.redis.setEx(cacheKey, 300, JSON.stringify(flight));
      }

      return res.json({ success: true, data: flight });
    } catch (err) {
      console.error('[Flight] getFlightById error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to fetch flight details.' });
    }
  }

  // ─── GET /flights/:id/price-check ────────────────────────────────────────────
  // Phase 5: Real-time price change check (called just before "Book Now" taps).
  // WHY: Airlines dynamically adjust prices; FLIGHTLY must warn users if the
  //      price changed between viewing details and tapping Book Now.
  //
  // Query params:
  //   seen_price  - The price the user saw on the details screen (number)
  //
  // Returns:
  //   price_changed  - boolean
  //   current_price  - actual current price
  //   seen_price     - what the user saw
  //   difference     - current - seen (positive = more expensive, negative = cheaper)
  async priceCheck(req, res) {
    try {
      const { id } = req.params;
      const { seen_price } = req.query;

      const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidPattern.test(id)) {
        return res.status(400).json({ success: false, message: 'Invalid flight ID format.' });
      }

      if (!seen_price || isNaN(parseFloat(seen_price))) {
        return res.status(400).json({ success: false, message: 'seen_price query parameter is required.' });
      }

      const result = await this.db.query(
        `SELECT base_price, available_seats, is_active FROM flights WHERE id = $1`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Flight not found.' });
      }

      const { base_price, available_seats, is_active } = result.rows[0];

      if (!is_active) {
        return res.json({
          success: true,
          data: {
            flight_id:     id,
            price_changed: true,
            unavailable:   true,
            message:       'This flight is no longer available.',
            current_price: null,
            seen_price:    parseFloat(seen_price),
          },
        });
      }

      const currentPrice = parseFloat(base_price);
      const userSeenPrice = parseFloat(seen_price);
      const difference = Math.round((currentPrice - userSeenPrice) * 100) / 100;
      // Price changed if it differs by more than $0.50 (avoids floating-point noise)
      const priceChanged = Math.abs(difference) > 0.50;

      return res.json({
        success: true,
        data: {
          flight_id:        id,
          price_changed:    priceChanged,
          unavailable:      false,
          current_price:    currentPrice,
          seen_price:       userSeenPrice,
          difference,
          seats_remaining:  parseInt(available_seats, 10),
          message: priceChanged
            ? (difference > 0
                ? `Price increased by $${Math.abs(difference).toFixed(2)}.`
                : `Good news! Price dropped by $${Math.abs(difference).toFixed(2)}.`)
            : 'Price is unchanged. Proceed to booking.',
        },
      });
    } catch (err) {
      console.error('[Flight] priceCheck error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to check flight price.' });
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
