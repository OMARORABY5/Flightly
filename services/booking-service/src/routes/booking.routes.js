// booking.routes.js — FLIGHTLY Booking Service Routes
// Phase 6: Full booking CRUD endpoints

const express = require('express');
const router  = express.Router();
const BookingController = require('../controllers/booking.controller');

function getController(req) {
  return new BookingController(req.db, req.redis);
}

// ─── GET /bookings?user_id= ────────────────────────────────────────────────────
// List all bookings for a user. Supports optional ?status= filter
router.get('/', async (req, res) => {
  await getController(req).getUserBookings(req, res);
});

// ─── POST /bookings/create ─────────────────────────────────────────────────────
// Create a new booking with passengers
// Body: { user_id, flight_id, cabin_class, passenger_ids[], contact_email, ... }
router.post('/create', async (req, res) => {
  await getController(req).createBooking(req, res);
});

// ─── GET /bookings/:id ─────────────────────────────────────────────────────────
// Full booking detail: flight info + all passengers
router.get('/:id', async (req, res) => {
  await getController(req).getBookingById(req, res);
});

// ─── POST /bookings/:id/confirm ────────────────────────────────────────────────
// Phase 7: Called after successful payment to confirm + mark paid
router.post('/:id/confirm', async (req, res) => {
  await getController(req).confirmBooking(req, res);
});

// ─── DELETE /bookings/:id ──────────────────────────────────────────────────────
// Cancel a booking (restores seats)
router.delete('/:id', async (req, res) => {
  await getController(req).cancelBooking(req, res);
});

// Health ping
router.get('/ping', (req, res) => res.json({ success: true, message: 'booking-service is running' }));

module.exports = router;
