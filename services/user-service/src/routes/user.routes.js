// User Routes — Stub (Phase 6+ will add real endpoints)
const express = require('express');
const router = express.Router();

router.get('/ping', (req, res) => res.json({ success: true, message: 'user-service is running' }));

module.exports = router;
