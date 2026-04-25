// Notification Routes — Stub (Phase 8 will add real endpoints)
const express = require('express');
const router = express.Router();

router.get('/ping', (req, res) => res.json({ success: true, message: 'notification-service is running' }));

module.exports = router;
