// notification.controller.js — All notification endpoint handlers
// FLIGHTLY Phase 8: Notifications & Alerts
// Schema-accurate: matches the actual DB tables created in init.sql

const { sendPushNotification } = require('../services/fcm.service');

// ─── GET /notifications ─────────────────────────────────────────────────────
// Returns all notifications for the authenticated user, newest first.
async function getNotifications(req, res) {
  const userId = req.userId;
  const { limit = 50, offset = 0, unread_only = 'false' } = req.query;

  try {
    let query = `
      SELECT id, type, title, body, data, is_read, created_at
      FROM notifications
      WHERE user_id = $1
    `;
    const params = [userId];

    if (unread_only === 'true') {
      query += ` AND is_read = false`;
    }

    query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await req.db.query(query, params);

    // Count unread
    const unreadResult = await req.db.query(
      'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    return res.json({
      success: true,
      data: {
        notifications: result.rows,
        unread_count: parseInt(unreadResult.rows[0].count),
        total: result.rows.length,
      },
    });
  } catch (err) {
    console.error('getNotifications error:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
  }
}

// ─── PUT /notifications/:id/read ─────────────────────────────────────────────
// Mark a single notification as read.
async function markAsRead(req, res) {
  const userId = req.userId;
  const { id } = req.params;

  try {
    const result = await req.db.query(
      `UPDATE notifications SET is_read = true
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [id, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    return res.json({ success: true, message: 'Notification marked as read' });
  } catch (err) {
    console.error('markAsRead error:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to mark notification as read' });
  }
}

// ─── PUT /notifications/read-all ─────────────────────────────────────────────
// Mark ALL notifications for the user as read.
async function markAllAsRead(req, res) {
  const userId = req.userId;

  try {
    const result = await req.db.query(
      `UPDATE notifications SET is_read = true
       WHERE user_id = $1 AND is_read = false`,
      [userId]
    );

    return res.json({
      success: true,
      message: `Marked ${result.rowCount} notification(s) as read`,
      data: { updated: result.rowCount },
    });
  } catch (err) {
    console.error('markAllAsRead error:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to mark all as read' });
  }
}

// ─── DELETE /notifications/:id ───────────────────────────────────────────────
// Delete a single notification.
async function deleteNotification(req, res) {
  const userId = req.userId;
  const { id } = req.params;

  try {
    const result = await req.db.query(
      'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    return res.json({ success: true, message: 'Notification deleted' });
  } catch (err) {
    console.error('deleteNotification error:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to delete notification' });
  }
}

// ─── POST /notifications/fcm-token ───────────────────────────────────────────
// Register/update the FCM device token for the user.
// NOTE: Schema stores the FCM token in notification_preferences.fcm_token
//       (no separate fcm_tokens table). Upsert to ensure row exists.
async function registerFcmToken(req, res) {
  const userId = req.userId;
  const { token } = req.body;

  if (!token) {
    return res.status(400).json({ success: false, message: 'FCM token is required' });
  }

  try {
    await req.db.query(
      `INSERT INTO notification_preferences (user_id, fcm_token, updated_at)
       VALUES ($1, $2, NOW())
       ON CONFLICT (user_id)
       DO UPDATE SET fcm_token = $2, updated_at = NOW()`,
      [userId, token]
    );

    return res.json({ success: true, message: 'FCM token registered' });
  } catch (err) {
    console.error('registerFcmToken error:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to register FCM token' });
  }
}

// ─── GET /notifications/preferences ─────────────────────────────────────────
// Get user notification preferences.
async function getPreferences(req, res) {
  const userId = req.userId;

  try {
    const result = await req.db.query(
      `SELECT booking_updates, price_alerts, schedule_updates, promotional, fcm_token, updated_at
       FROM notification_preferences WHERE user_id = $1`,
      [userId]
    );

    if (result.rowCount === 0) {
      // Return defaults if no prefs row yet
      return res.json({
        success: true,
        data: {
          booking_updates: true,
          price_alerts: true,
          schedule_updates: true,
          promotional: false,
          fcm_token: null,
        },
      });
    }

    return res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('getPreferences error:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to fetch preferences' });
  }
}

// ─── PUT /notifications/preferences ─────────────────────────────────────────
// Update user notification preferences (partial update supported).
async function updatePreferences(req, res) {
  const userId = req.userId;
  const { booking_updates, price_alerts, schedule_updates, promotional } = req.body;

  try {
    await req.db.query(
      `INSERT INTO notification_preferences (user_id, booking_updates, price_alerts, schedule_updates, promotional, updated_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       ON CONFLICT (user_id)
       DO UPDATE SET
         booking_updates  = COALESCE($2, notification_preferences.booking_updates),
         price_alerts     = COALESCE($3, notification_preferences.price_alerts),
         schedule_updates = COALESCE($4, notification_preferences.schedule_updates),
         promotional      = COALESCE($5, notification_preferences.promotional),
         updated_at       = NOW()`,
      [userId, booking_updates ?? null, price_alerts ?? null, schedule_updates ?? null, promotional ?? null]
    );

    return res.json({ success: true, message: 'Preferences updated' });
  } catch (err) {
    console.error('updatePreferences error:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to update preferences' });
  }
}

// ─── Internal: Create a notification + push it ────────────────────────────────
// Called by other services (e.g. booking-service on confirm).
async function createAndSendNotification(db, userId, type, title, body, data = {}) {
  try {
    const { v4: uuidv4 } = require('uuid');
    const id = uuidv4();

    await db.query(
      `INSERT INTO notifications (id, user_id, type, title, body, data, is_read, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, false, NOW())`,
      [id, userId, type, title, body, JSON.stringify(data)]
    );

    // Get FCM token from preferences row
    const prefResult = await db.query(
      'SELECT fcm_token FROM notification_preferences WHERE user_id = $1',
      [userId]
    );

    const fcmToken = prefResult.rows[0]?.fcm_token;
    if (fcmToken) {
      await sendPushNotification(fcmToken, title, body, data);
    }

    return id;
  } catch (err) {
    console.error('createAndSendNotification error:', err.message);
    return null;
  }
}

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  registerFcmToken,
  getPreferences,
  updatePreferences,
  createAndSendNotification,
};
