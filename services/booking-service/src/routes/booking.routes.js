// booking.routes.js — FLIGHTLY Booking Service Routes
// Includes: Modify & Cancel (with wallet refund) endpoints

const express        = require('express');
const router         = express.Router();
const BookingController = require('../controllers/booking.controller');
const WalletController  = require('../controllers/wallet.controller');
const authMiddleware = require('../middleware/auth.middleware');

function getController(req) {
  return new BookingController(req.db, req.redis);
}
function getWalletController(req) {
  return new WalletController(req.db, req.redis);
}

// ─── GET /bookings?user_id= ────────────────────────────────────────────────────
// List all bookings for a user. Supports optional ?status= filter
router.get('/', async (req, res) => {
  await getController(req).getUserBookings(req, res);
});

// ─── GET /bookings/user/upcoming ───────────────────────────────────────────────
// Confirmed bookings with a future departure date (sorted soonest first)
// Auth required — userId extracted from JWT
router.get('/user/upcoming', authMiddleware, async (req, res) => {
  await getController(req).getUpcomingTrips(req, res);
});

// ─── GET /bookings/user/history ────────────────────────────────────────────────
// Past confirmed bookings + all cancelled bookings (sorted newest first)
// Auth required — userId extracted from JWT
router.get('/user/history', authMiddleware, async (req, res) => {
  await getController(req).getHistoryTrips(req, res);
});

// ─── GET /wallet ───────────────────────────────────────────────────────────────
// Returns the authenticated user's wallet balance + transaction history
// Auth required
router.get('/wallet', authMiddleware, async (req, res) => {
  await getWalletController(req).getWallet(req, res);
});

// Health ping — must be before /:id to avoid being swallowed
router.get('/ping', (req, res) => res.json({ success: true, message: 'booking-service is running' }));

// ─── POST /bookings/create ─────────────────────────────────────────────────────
// Create a new booking with passengers
router.post('/create', async (req, res) => {
  await getController(req).createBooking(req, res);
});

// ─── GET /bookings/:id ─────────────────────────────────────────────────────────
// Full booking detail: flight info + all passengers
router.get('/:id', async (req, res) => {
  await getController(req).getBookingById(req, res);
});

// ─── POST /bookings/:id/confirm ────────────────────────────────────────────────
// Called after successful payment to confirm + mark paid
router.post('/:id/confirm', async (req, res) => {
  await getController(req).confirmBooking(req, res);
});

// ─── POST /bookings/:id/cancel ─────────────────────────────────────────────────
// Cancel a confirmed booking. Applies tiered refund policy. Credits virtual wallet.
// Auth required — userId from JWT (no spoofing)
router.post('/:id/cancel', authMiddleware, async (req, res) => {
  await getController(req).cancelBooking(req, res);
});

// ─── PATCH /bookings/:id ───────────────────────────────────────────────────────
// Modify an upcoming confirmed booking (cabin class, contact info, passengers)
// Auth required
router.patch('/:id', authMiddleware, async (req, res) => {
  await getController(req).modifyBooking(req, res);
});

// ─── DELETE /bookings/:id ──────────────────────────────────────────────────────
// Legacy route — kept for backward compatibility. Now routes to cancelBooking.
// Note: cancelBooking now reads userId from JWT, not req.body.user_id.
//       This legacy route will only work if authMiddleware is present.
router.delete('/:id', authMiddleware, async (req, res) => {
  await getController(req).cancelBooking(req, res);
});

module.exports = router;
