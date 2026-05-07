// User Routes
// Phase 5: Saved Flights endpoints wired in
// Phase 6: Passengers CRUD endpoints wired in
const express = require('express');
const router  = express.Router();

// ── Health ping ──────────────────────────────────────────────────────────────
router.get('/ping', (req, res) => res.json({ success: true, message: 'user-service is running' }));

// ── Saved Flights (Watchlist) ─────────────────────────────────────────────────
// All routes: /users/saved-flights/...
const savedFlightsRoutes = require('./saved_flights.routes');
router.use('/saved-flights', savedFlightsRoutes);

// ── Profile ───────────────────────────────────────────────────────────────────
// All routes: /users/profile/...
const profileRoutes = require('./profile.routes');
router.use('/profile', profileRoutes);

// ── Settings ──────────────────────────────────────────────────────────────────
// All routes: /users/settings/...
const settingsRoutes = require('./settings.routes');
router.use('/settings', settingsRoutes);

// ── Passengers CRUD ───────────────────────────────────────────────────────────
// All routes: /users/passengers/...
const passengersRoutes = require('./passengers.routes');
router.use('/passengers', passengersRoutes);

module.exports = router;
