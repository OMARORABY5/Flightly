// seed_flights.js — FLIGHTLY Flight Seeder
// Phase 4: Generates realistic simulated flights for the next 30 days
// WHY: A static SQL file would quickly have past-dated flights. This script
//      runs via Docker exec and always seeds FUTURE flights from today.
//
// Usage (from host): docker exec flightly-flight node scripts/seed_flights.js
// Usage (local dev):  node scripts/seed_flights.js

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { Pool } = require('pg');

const db = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     process.env.DB_PORT     || 5432,
  database: process.env.DB_NAME     || 'flightly',
  user:     process.env.DB_USER     || 'flightly_user',
  password: process.env.DB_PASSWORD || 'flightly_pass',
});

// ─── Airline Catalog ──────────────────────────────────────────────────────────
const AIRLINES = [
  { code: 'EK', name: 'Emirates',             logo: 'https://logos.skyscnr.com/images/airlines/favicon/EK.png' },
  { code: 'QR', name: 'Qatar Airways',         logo: 'https://logos.skyscnr.com/images/airlines/favicon/QR.png' },
  { code: 'BA', name: 'British Airways',       logo: 'https://logos.skyscnr.com/images/airlines/favicon/BA.png' },
  { code: 'LH', name: 'Lufthansa',            logo: 'https://logos.skyscnr.com/images/airlines/favicon/LH.png' },
  { code: 'AF', name: 'Air France',           logo: 'https://logos.skyscnr.com/images/airlines/favicon/AF.png' },
  { code: 'KL', name: 'KLM',                  logo: 'https://logos.skyscnr.com/images/airlines/favicon/KL.png' },
  { code: 'TK', name: 'Turkish Airlines',     logo: 'https://logos.skyscnr.com/images/airlines/favicon/TK.png' },
  { code: 'SQ', name: 'Singapore Airlines',   logo: 'https://logos.skyscnr.com/images/airlines/favicon/SQ.png' },
  { code: 'MS', name: 'EgyptAir',             logo: 'https://logos.skyscnr.com/images/airlines/favicon/MS.png' },
  { code: '9W', name: 'Jet Airways',          logo: 'https://logos.skyscnr.com/images/airlines/favicon/9W.png' },
];

// ─── Route Definitions (origin → destination) ─────────────────────────────────
// Each route defines [origin, destination, flightMins, priceBase, priceVariance]
// WHY: Pre-defined realistic routes ensure durations & pricing make geographic sense
const ROUTES = [
  // Middle East Hub Routes
  ['DXB', 'LHR', 425, 320,  150], // Dubai → London
  ['LHR', 'DXB', 425, 310,  150],
  ['DXB', 'JFK', 830, 480,  200], // Dubai → New York
  ['JFK', 'DXB', 830, 470,  200],
  ['DXB', 'CDG', 400, 290,  120], // Dubai → Paris
  ['CDG', 'DXB', 400, 285,  120],
  ['DXB', 'SIN', 435, 350,  140], // Dubai → Singapore
  ['SIN', 'DXB', 435, 345,  140],
  ['CAI', 'DXB', 215, 180,   80], // Cairo → Dubai
  ['DXB', 'CAI', 215, 175,   80],
  // European Routes
  ['LHR', 'CDG', 75,  95,   40],  // London → Paris
  ['CDG', 'LHR', 75,  90,   40],
  ['LHR', 'FRA', 95,  110,  50],  // London → Frankfurt
  ['FRA', 'LHR', 95,  105,  50],
  ['LHR', 'AMS', 70,  88,   35],  // London → Amsterdam
  ['AMS', 'LHR', 70,  85,   35],
  ['FRA', 'CDG', 85,  100,  40],  // Frankfurt → Paris
  ['CDG', 'FRA', 85,  98,   40],
  ['AMS', 'FRA', 65,  92,   35],
  ['FRA', 'AMS', 65,  90,   35],
  // Long Haul
  ['JFK', 'LHR', 420, 350,  180], // New York → London
  ['LHR', 'JFK', 440, 360,  180],
  ['JFK', 'CDG', 450, 370,  190],
  ['CDG', 'JFK', 460, 365,  190],
  ['SIN', 'LHR', 780, 520,  220], // Singapore → London
  ['LHR', 'SIN', 780, 510,  220],
  ['SIN', 'JFK', 1060, 650, 250], // Singapore → New York
  ['JFK', 'SIN', 1060, 640, 250],
  // Istanbul hub
  ['IST', 'LHR', 230, 170,   80],
  ['LHR', 'IST', 230, 165,   80],
  ['IST', 'DXB', 255, 185,   90],
  ['DXB', 'IST', 255, 180,   90],
  ['IST', 'CDG', 210, 160,   75],
  ['CDG', 'IST', 210, 155,   75],
  // Cairo routes
  ['CAI', 'LHR', 310, 210,  100],
  ['LHR', 'CAI', 310, 205,  100],
  ['CAI', 'CDG', 290, 195,   90],
  ['CDG', 'CAI', 290, 190,   90],
  ['CAI', 'IST', 150, 130,   60],
  ['IST', 'CAI', 150, 125,   60],
  // Tokyo
  ['HND', 'SIN', 385, 310,  130],
  ['SIN', 'HND', 385, 305,  130],
  ['HND', 'LHR', 720, 580,  230],
  ['LHR', 'HND', 720, 575,  230],
];

// ─── Cabin classes and their price multipliers ───────────────────────────────
const CABINS = [
  { name: 'economy',         multiplier: 1.00, baggage_cabin: 7,  baggage_checked: 23, refundable: false },
  { name: 'premium_economy', multiplier: 1.85, baggage_cabin: 10, baggage_checked: 32, refundable: false },
  { name: 'business',        multiplier: 4.20, baggage_cabin: 15, baggage_checked: 40, refundable: true  },
  { name: 'first',           multiplier: 8.50, baggage_cabin: 20, baggage_checked: 50, refundable: true  },
];

// ─── Helpers ─────────────────────────────────────────────────────────────────
function randomBetween(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomItem(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

/** Return a random departure hour weighted toward realistic flight windows */
function randomDepartureHour() {
  const weights = [
    // 0=midnight, prob = early morning band
    0, 0, 0, 0, 1, 1, 2, 3, 3, 2, 2, 1,
    1, 1, 2, 2, 2, 3, 3, 2, 2, 1, 1, 0,
  ];
  const total = weights.reduce((s, w) => s + w, 0);
  let rand = Math.random() * total;
  for (let h = 0; h < 24; h++) {
    rand -= weights[h];
    if (rand <= 0) return h;
  }
  return 8;
}

/** Add a small price jitter to simulate dynamic demand */
function jitterPrice(base, variance) {
  const pct = 1 + (Math.random() * 2 - 1) * (variance / base);
  return Math.round(base * pct * 100) / 100;
}

let flightCounter = 100; // sequential suffix for flight numbers

async function seed() {
  console.log('[Seeder] Starting Phase 4 flight seed…');
  await db.query('SELECT 1'); // sanity check

  // Wipe old simulated flights so re-running is idempotent
  await db.query(`DELETE FROM flights`);
  console.log('[Seeder] Cleared existing flights table.');

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let inserted = 0;

  for (const [origin, dest, durationMins, priceBase, priceVariance] of ROUTES) {
    // 2-4 flights per route per day for 30 days
    for (let dayOffset = 0; dayOffset < 30; dayOffset++) {
      const flightsPerDay = randomBetween(2, 4);
      for (let f = 0; f < flightsPerDay; f++) {
        const airline = randomItem(AIRLINES);
        flightCounter++;
        const flightNumber = `${airline.code} ${flightCounter}`;

        const depHour   = randomDepartureHour();
        const depMinute = randomItem([0, 15, 30, 45]);

        const departureDate = new Date(today);
        departureDate.setDate(today.getDate() + dayOffset + 1); // +1 so today is never included
        departureDate.setHours(depHour, depMinute, 0, 0);

        // Add stops: mostly direct, occasionally 1 stop
        const stops = Math.random() < 0.25 ? 1 : 0;
        // With stops, add 1.5–3 h layover to duration
        const totalMins = durationMins + (stops > 0 ? randomBetween(90, 180) : 0);

        const arrivalDate = new Date(departureDate.getTime() + totalMins * 60 * 1000);

        // Seed all 4 cabin classes for each flight slot
        for (const cabin of CABINS) {
          const price = jitterPrice(priceBase * cabin.multiplier, priceVariance * cabin.multiplier);
          const seats = randomBetween(10, 100);

          await db.query(
            `INSERT INTO flights
              (flight_number, airline_code, airline_name, airline_logo_url,
               origin_iata, destination_iata,
               departure_time, arrival_time, duration_minutes, stops,
               cabin_class, base_price, available_seats,
               baggage_cabin_kg, baggage_checked_kg, is_refundable, is_active)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,true)`,
            [
              flightNumber,
              airline.code,
              airline.name,
              airline.logo,
              origin, dest,
              departureDate.toISOString(),
              arrivalDate.toISOString(),
              totalMins,
              stops,
              cabin.name,
              price,
              seats,
              cabin.baggage_cabin,
              cabin.baggage_checked,
              cabin.refundable,
            ]
          );
          inserted++;
        }
      }
    }
  }

  console.log(`[Seeder] ✅  Inserted ${inserted} flight records across 30 days.`);
  await db.end();
}

seed().catch((err) => {
  console.error('[Seeder] Fatal error:', err.message);
  process.exit(1);
});
