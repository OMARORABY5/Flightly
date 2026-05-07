// seed_flights.js — FLIGHTLY Flight Seeder (v3)
// All prices in EGP. Validates airports upfront. Robust error handling.
// Usage: docker exec flightly-flight node scripts/seed_flights.js

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { Pool } = require('pg');

const db = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     process.env.DB_PORT     || 5432,
  database: process.env.DB_NAME     || 'flightly',
  user:     process.env.DB_USER     || 'flightly_user',
  password: process.env.DB_PASSWORD || 'flightly_pass',
});

const AIRLINES = [
  { code: 'MS', name: 'EgyptAir',           logo: 'https://logos.skyscnr.com/images/airlines/favicon/MS.png' },
  { code: 'EK', name: 'Emirates',            logo: 'https://logos.skyscnr.com/images/airlines/favicon/EK.png' },
  { code: 'QR', name: 'Qatar Airways',       logo: 'https://logos.skyscnr.com/images/airlines/favicon/QR.png' },
  { code: 'TK', name: 'Turkish Airlines',    logo: 'https://logos.skyscnr.com/images/airlines/favicon/TK.png' },
  { code: 'AF', name: 'Air France',          logo: 'https://logos.skyscnr.com/images/airlines/favicon/AF.png' },
  { code: 'LH', name: 'Lufthansa',           logo: 'https://logos.skyscnr.com/images/airlines/favicon/LH.png' },
  { code: 'BA', name: 'British Airways',     logo: 'https://logos.skyscnr.com/images/airlines/favicon/BA.png' },
  { code: 'KL', name: 'KLM',                logo: 'https://logos.skyscnr.com/images/airlines/favicon/KL.png' },
  { code: 'SQ', name: 'Singapore Airlines',  logo: 'https://logos.skyscnr.com/images/airlines/favicon/SQ.png' },
  { code: 'FZ', name: 'flydubai',            logo: 'https://logos.skyscnr.com/images/airlines/favicon/FZ.png' },
  { code: 'XY', name: 'Flynas',              logo: 'https://logos.skyscnr.com/images/airlines/favicon/XY.png' },
  { code: 'J9', name: 'Jazeera Airways',     logo: 'https://logos.skyscnr.com/images/airlines/favicon/J9.png' },
];

// [origin, destination, durationMins, basePriceEGP, varianceEGP]
const ROUTES_RAW = [
  // Egypt Domestic
  ['CAI', 'LXR',  60,  1200,  400],
  ['LXR', 'CAI',  60,  1200,  400],
  ['CAI', 'ASW',  90,  1500,  500],
  ['ASW', 'CAI',  90,  1500,  500],
  ['CAI', 'HRG',  70,  1300,  450],
  ['HRG', 'CAI',  70,  1300,  450],
  ['CAI', 'SSH',  80,  1400,  450],
  ['SSH', 'CAI',  80,  1400,  450],
  ['CAI', 'HBE',  50,   950,  300],
  ['HBE', 'CAI',  50,   950,  300],
  ['CAI', 'RMF',  90,  1600,  500],
  ['RMF', 'CAI',  90,  1600,  500],
  ['CAI', 'SPX',  35,   800,  250],
  ['SPX', 'CAI',  35,   800,  250],
  ['CAI', 'TCP',  90,  1500,  400],
  ['TCP', 'CAI',  90,  1500,  400],
  ['LXR', 'HRG',  55,  1100,  350],
  ['HRG', 'LXR',  55,  1100,  350],
  ['ASW', 'LXR',  40,   900,  300],
  ['LXR', 'ASW',  40,   900,  300],
  ['SSH', 'HRG',  45,  1000,  350],
  ['HRG', 'SSH',  45,  1000,  350],
  ['CAI', 'ATZ',  75,  1350,  400],
  ['ATZ', 'CAI',  75,  1350,  400],
  ['CAI', 'HMB',  85,  1450,  450],
  ['HMB', 'CAI',  85,  1450,  450],
  // Egypt to Arab World
  ['CAI', 'DXB', 215,  9000,  3000],
  ['DXB', 'CAI', 215,  8750,  3000],
  ['CAI', 'AUH', 225,  8500,  3000],
  ['AUH', 'CAI', 225,  8250,  3000],
  ['CAI', 'DOH', 195,  7500,  2500],
  ['DOH', 'CAI', 195,  7250,  2500],
  ['CAI', 'AMM', 100,  5000,  1500],
  ['AMM', 'CAI', 100,  4800,  1500],
  ['CAI', 'BEY', 110,  5200,  1500],
  ['BEY', 'CAI', 110,  5000,  1500],
  ['CAI', 'JED', 180,  7000,  2000],
  ['JED', 'CAI', 180,  6800,  2000],
  ['CAI', 'RUH', 200,  8000,  2500],
  ['RUH', 'CAI', 200,  7800,  2500],
  ['CAI', 'MED', 175,  7000,  2000],
  ['MED', 'CAI', 175,  6800,  2000],
  ['CAI', 'KWI', 205,  8200,  2500],
  ['KWI', 'CAI', 205,  8000,  2500],
  ['CAI', 'BAH', 210,  8400,  2500],
  ['BAH', 'CAI', 210,  8200,  2500],
  ['CAI', 'MCT', 230,  9200,  3000],
  ['MCT', 'CAI', 230,  9000,  3000],
  ['CAI', 'KRT', 190,  7500,  2500],
  ['KRT', 'CAI', 190,  7300,  2500],
  ['CAI', 'ADD', 300, 11000,  3500],
  ['ADD', 'CAI', 300, 10800,  3500],
  ['HRG', 'JED', 120,  6000,  1800],
  ['JED', 'HRG', 120,  5800,  1800],
  ['SSH', 'AMM',  85,  4500,  1500],
  ['AMM', 'SSH',  85,  4300,  1500],
  // Egypt to Europe
  ['CAI', 'CDG', 290, 14000,  4000],
  ['CDG', 'CAI', 290, 13500,  4000],
  ['CAI', 'LHR', 310, 15000,  5000],
  ['LHR', 'CAI', 310, 14500,  5000],
  ['CAI', 'FRA', 295, 14200,  4500],
  ['FRA', 'CAI', 295, 13800,  4500],
  ['CAI', 'AMS', 305, 14500,  4500],
  ['AMS', 'CAI', 305, 14000,  4500],
  ['CAI', 'MAD', 340, 15500,  5000],
  ['MAD', 'CAI', 340, 15000,  5000],
  ['CAI', 'FCO', 225, 11000,  3500],
  ['FCO', 'CAI', 225, 10800,  3500],
  ['CAI', 'ATH', 120,  6500,  2000],
  ['ATH', 'CAI', 120,  6300,  2000],
  ['CAI', 'IST', 150,  8000,  2500],
  ['IST', 'CAI', 150,  7800,  2500],
  ['CAI', 'VIE', 270, 13000,  4000],
  ['VIE', 'CAI', 270, 12800,  4000],
  ['CAI', 'ZRH', 300, 14500,  5000],
  ['ZRH', 'CAI', 300, 14000,  5000],
  ['HRG', 'LHR', 360, 17000,  5500],
  ['LHR', 'HRG', 360, 16500,  5500],
  ['SSH', 'CDG', 340, 16500,  5000],
  ['CDG', 'SSH', 340, 16000,  5000],
  ['CAI', 'BCN', 330, 15200,  4800],
  ['BCN', 'CAI', 330, 14800,  4800],
  ['CAI', 'BRU', 300, 14300,  4500],
  ['BRU', 'CAI', 300, 13900,  4500],
  // Egypt to North Africa
  ['CAI', 'TUN', 160,  7500,  2500],
  ['TUN', 'CAI', 160,  7300,  2500],
  ['CAI', 'ALG', 210,  9500,  3000],
  ['ALG', 'CAI', 210,  9300,  3000],
  ['CAI', 'CMN', 310, 13500,  4000],
  ['CMN', 'CAI', 310, 13200,  4000],
  ['CAI', 'MJI', 200,  9000,  3000],
  ['MJI', 'CAI', 200,  8800,  3000],
  // Dubai Hub
  ['DXB', 'LHR', 425, 16000,  5000],
  ['LHR', 'DXB', 425, 15500,  5000],
  ['DXB', 'JFK', 830, 24000,  7000],
  ['JFK', 'DXB', 830, 23500,  7000],
  ['DXB', 'CDG', 400, 14500,  4500],
  ['CDG', 'DXB', 400, 14200,  4500],
  ['DXB', 'SIN', 435, 17500,  5500],
  ['SIN', 'DXB', 435, 17200,  5500],
  ['DXB', 'IST', 255,  9200,  3000],
  ['IST', 'DXB', 255,  9000,  3000],
  ['DXB', 'BKK', 380, 14000,  4500],
  ['BKK', 'DXB', 380, 13800,  4500],
  ['DXB', 'DEL', 220,  9500,  3000],
  ['DEL', 'DXB', 220,  9300,  3000],
  ['DXB', 'KUL', 420, 16000,  5000],
  ['KUL', 'DXB', 420, 15500,  5000],
  // European
  ['LHR', 'CDG',  75,  4750,  1500],
  ['CDG', 'LHR',  75,  4500,  1500],
  ['LHR', 'FRA',  95,  5500,  1800],
  ['FRA', 'LHR',  95,  5200,  1800],
  ['LHR', 'AMS',  70,  4400,  1400],
  ['AMS', 'LHR',  70,  4200,  1400],
  ['FRA', 'CDG',  85,  5000,  1600],
  ['CDG', 'FRA',  85,  4900,  1600],
  ['AMS', 'FRA',  65,  4600,  1500],
  ['FRA', 'AMS',  65,  4500,  1500],
  ['IST', 'LHR', 230,  8500,  2800],
  ['LHR', 'IST', 230,  8200,  2800],
  ['IST', 'CDG', 210,  8000,  2500],
  ['CDG', 'IST', 210,  7800,  2500],
  // Long Haul
  ['JFK', 'LHR', 420, 17500,  6000],
  ['LHR', 'JFK', 440, 18000,  6000],
  ['JFK', 'CDG', 450, 18500,  6500],
  ['CDG', 'JFK', 460, 18200,  6500],
  ['SIN', 'LHR', 780, 26000,  8000],
  ['LHR', 'SIN', 780, 25500,  8000],
  ['SIN', 'JFK', 1060, 32500, 10000],
  ['JFK', 'SIN', 1060, 32000, 10000],
  ['HND', 'SIN', 385, 15500,  5000],
  ['SIN', 'HND', 385, 15200,  5000],
  ['HND', 'LHR', 720, 29000,  9000],
  ['LHR', 'HND', 720, 28500,  9000],
  ['BKK', 'LHR', 680, 27000,  8500],
  ['LHR', 'BKK', 680, 26500,  8500],
  ['SYD', 'SIN', 510, 20000,  6500],
  ['SIN', 'SYD', 510, 19500,  6500],
];

const CABINS = [
  { name: 'economy',         multiplier: 1.00, baggage_cabin: 7,  baggage_checked: 23, refundable: false },
  { name: 'premium_economy', multiplier: 1.85, baggage_cabin: 10, baggage_checked: 32, refundable: false },
  { name: 'business',        multiplier: 4.20, baggage_cabin: 15, baggage_checked: 40, refundable: true  },
  { name: 'first',           multiplier: 8.50, baggage_cabin: 20, baggage_checked: 50, refundable: true  },
];

function randomBetween(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
function randomItem(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}
function randomDepartureHour() {
  const weights = [0,0,0,0,1,1,2,3,3,2,2,1,1,1,2,2,2,3,3,2,2,1,1,0];
  const total = weights.reduce((s, w) => s + w, 0);
  let rand = Math.random() * total;
  for (let h = 0; h < 24; h++) { rand -= weights[h]; if (rand <= 0) return h; }
  return 8;
}
function jitterPrice(base, variance) {
  const pct = 1 + (Math.random() * 2 - 1) * (variance / base);
  return Math.round(base * pct);
}
function pickAirline(origin, dest) {
  const egyptAirports = ['CAI','CCE','HBE','HRG','SSH','LXR','ASW','RMF','SPX','TCP','ATZ','HMB','PSD','MUH','AAC','DBB','ABS'];
  const isEgyptRoute = egyptAirports.includes(origin) || egyptAirports.includes(dest);
  if (isEgyptRoute && Math.random() < 0.45) return AIRLINES.find(a => a.code === 'MS');
  return randomItem(AIRLINES);
}

let flightCounter = 1000;

async function seed() {
  console.log('[Seeder] Starting v3 flight seed (EGP prices)...');
  await db.query('SELECT 1');

  await db.query('DELETE FROM flights');
  console.log('[Seeder] Cleared existing flights table.');

  // Validate airports upfront
  const allCodes = [...new Set(ROUTES_RAW.flatMap(([o, d]) => [o, d]))];
  const validRes = await db.query('SELECT iata_code FROM airports WHERE iata_code = ANY($1)', [allCodes]);
  const validSet = new Set(validRes.rows.map(r => r.iata_code));
  const invalid  = allCodes.filter(c => !validSet.has(c));
  if (invalid.length > 0) console.warn('[Seeder] Skipping unknown airports:', invalid);

  const ROUTES = ROUTES_RAW.filter(([o, d]) => validSet.has(o) && validSet.has(d));
  console.log(`[Seeder] Seeding ${ROUTES.length} valid routes out of ${ROUTES_RAW.length}...`);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let inserted = 0;
  let errors = 0;

  for (const [origin, dest, durationMins, priceBase, priceVariance] of ROUTES) {
    for (let dayOffset = 0; dayOffset < 30; dayOffset++) {
      const flightsPerDay = randomBetween(5, 8);
      const usedHours = new Set();

      for (let f = 0; f < flightsPerDay; f++) {
        const airline = pickAirline(origin, dest);
        flightCounter++;
        const flightNumber = `${airline.code} ${flightCounter}`;

        let depHour, attempts = 0;
        do { depHour = randomDepartureHour(); attempts++; }
        while (usedHours.has(depHour) && attempts < 30);
        usedHours.add(depHour);

        const depMinute = randomItem([0, 15, 30, 45]);
        const departureDate = new Date(today);
        departureDate.setDate(today.getDate() + dayOffset + 1);
        departureDate.setHours(depHour, depMinute, 0, 0);

        const stops = Math.random() < 0.20 ? 1 : 0;
        const totalMins = durationMins + (stops > 0 ? randomBetween(90, 180) : 0);
        const arrivalDate = new Date(departureDate.getTime() + totalMins * 60 * 1000);

        for (const cabin of CABINS) {
          const price = jitterPrice(priceBase * cabin.multiplier, priceVariance * cabin.multiplier);
          const seats = randomBetween(10, 150);

          try {
            await db.query(
              `INSERT INTO flights
                (flight_number, airline_code, airline_name, airline_logo_url,
                 origin_iata, destination_iata,
                 departure_time, arrival_time, duration_minutes, stops,
                 cabin_class, base_price, available_seats,
                 baggage_cabin_kg, baggage_checked_kg, is_refundable, is_active)
               VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,true)`,
              [flightNumber, airline.code, airline.name, airline.logo,
               origin, dest, departureDate.toISOString(), arrivalDate.toISOString(),
               totalMins, stops, cabin.name, price, seats,
               cabin.baggage_cabin, cabin.baggage_checked, cabin.refundable]
            );
            inserted++;
          } catch (err) {
            errors++;
            if (errors <= 5) console.error(`[Seeder] Insert error ${origin}->${dest}:`, err.message);
          }
        }
      }
    }
    if (ROUTES.indexOf(ROUTES.find(r => r[0] === origin && r[1] === dest)) % 10 === 0) {
      process.stdout.write('.');
    }
  }

  console.log(`\n[Seeder] Done! Inserted: ${inserted}, Errors: ${errors}`);
  await db.end();
}

seed().catch(err => { console.error('[Seeder] Fatal:', err.message); process.exit(1); });
