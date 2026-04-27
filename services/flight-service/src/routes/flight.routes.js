// flight.routes.js — FLIGHTLY Flight Service Routes
// Phase 3: Airport search & popular airports
// Phase 4: Flight search, filtering, sorting, detail, airlines list

const express = require('express');
const router  = express.Router();
const FlightController = require('../controllers/flight.controller');

// WHY: Instantiate controller per request using req.db/redis injected by server.js middleware
function getController(req) {
  return new FlightController(req.db, req.redis);
}

// ─── Airport Endpoints ────────────────────────────────────────────────────────

// GET /flights/airports/popular
// Returns hardcoded list of world's busiest hub airports (for empty search state)
router.get('/airports/popular', async (req, res) => {
  await getController(req).getPopularAirports(req, res);
});

// GET /flights/airports/search?q=<query>
// Search airports by IATA code, name, city, or country (min 2 chars)
router.get('/airports/search', async (req, res) => {
  await getController(req).searchAirports(req, res);
});

// ─── Flight Search Endpoints (Phase 4) ───────────────────────────────────────

// GET /flights/search?origin=&destination=&date=&cabin=&passengers=&sort=&page=
// Main flight search with full filter + sort + pagination support
// IMPORTANT: This route MUST be defined before /flights/:id to avoid "search"
//            being matched as an :id parameter.
router.get('/search', async (req, res) => {
  await getController(req).searchFlights(req, res);
});

// GET /flights/airlines
// Returns all distinct airlines currently in the flights table
// WHY: Filter screen populates the airline multi-select from this list
router.get('/airlines', async (req, res) => {
  await getController(req).getAvailableAirlines(req, res);
});

// GET /flights/:id
// Returns full detail for one flight (used by Flight Details screen)
router.get('/:id', async (req, res) => {
  await getController(req).getFlightById(req, res);
});

// ─── Dev Ping ────────────────────────────────────────────────────────────────
router.get('/ping', (req, res) => res.json({ success: true, message: 'flight-service is running' }));

module.exports = router;
