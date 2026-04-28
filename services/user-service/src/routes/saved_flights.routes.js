// saved_flights.routes.js — FLIGHTLY User Service
// Phase 5: Saved Flights (Watchlist) endpoints
//
// Route ordering matters:
//   /saved-flights/check/:flightId  — must be BEFORE /saved-flights/:flightId
//   to prevent "check" being captured as a :flightId param

const express = require('express');
const router  = express.Router();
const SavedFlightsController = require('../controllers/saved_flights.controller');

function getController(req) {
  return new SavedFlightsController(req.db, req.redis);
}

// GET /users/saved-flights?user_id=<uuid>
// Returns all saved flights for a user with live price change indicators
router.get('/', async (req, res) => {
  await getController(req).getSavedFlights(req, res);
});

// GET /users/saved-flights/check/:flightId?user_id=<uuid>
// Check if a specific flight is in the user's watchlist (for heart-toggle state)
// WHY: MUST be before /:flightId route to avoid route collision
router.get('/check/:flightId', async (req, res) => {
  await getController(req).checkSaved(req, res);
});

// POST /users/saved-flights
// Body: { user_id, flight_id, search_criteria? }
// Saves a flight and snapshots the current price
router.post('/', async (req, res) => {
  await getController(req).saveFlight(req, res);
});

// DELETE /users/saved-flights/:flightId?user_id=<uuid>
// Removes a flight from the user's watchlist
router.delete('/:flightId', async (req, res) => {
  await getController(req).unsaveFlight(req, res);
});

module.exports = router;
