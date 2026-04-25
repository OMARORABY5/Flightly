// Flight Routes — Stub (Phase 3+ will add real endpoints)
const express = require('express');
const router = express.Router();

// Placeholder: will be filled in Phase 3 (Airport Search) and Phase 4 (Flight Search)
router.get('/ping', (req, res) => res.json({ success: true, message: 'flight-service is running' }));

module.exports = router;
