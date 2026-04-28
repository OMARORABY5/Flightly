// notification.routes.js — Phase 8 all notification endpoints
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  registerFcmToken,
  getPreferences,
  updatePreferences,
} = require('../controllers/notification.controller');

// Health ping (public)
router.get('/ping', (req, res) => res.json({ success: true, message: 'notification-service is running' }));

// All routes below require authentication
router.use(auth);

// Notification CRUD
router.get('/', getNotifications);               // GET  /notifications
router.put('/read-all', markAllAsRead);           // PUT  /notifications/read-all  (before /:id)
router.put('/:id/read', markAsRead);             // PUT  /notifications/:id/read
router.delete('/:id', deleteNotification);       // DELETE /notifications/:id

// FCM token registration
router.post('/fcm-token', registerFcmToken);     // POST /notifications/fcm-token

// Preferences
router.get('/preferences', getPreferences);      // GET  /notifications/preferences
router.put('/preferences', updatePreferences);   // PUT  /notifications/preferences

module.exports = router;
