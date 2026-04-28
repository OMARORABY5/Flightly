// fcm.service.js — Firebase Cloud Messaging wrapper
// Uses GOOGLE_APPLICATION_CREDENTIALS env var (standard Firebase Admin approach)
// which points to the service account JSON file mounted into the container.
// Gracefully no-ops if the file is not present (dev without Firebase).

const admin = require('firebase-admin');

let firebaseApp = null;
let fcmInitialized = false;

function initFirebase() {
  if (fcmInitialized) return;

  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const projectId = process.env.FIREBASE_PROJECT_ID;

  if (!credPath || !projectId) {
    console.warn('[FCM] GOOGLE_APPLICATION_CREDENTIALS not set — push notifications disabled.');
    fcmInitialized = true;
    return;
  }

  try {
    // admin.credential.applicationDefault() auto-reads GOOGLE_APPLICATION_CREDENTIALS
    firebaseApp = admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId,
    });
    fcmInitialized = true;
    console.info('[FCM] Firebase Admin initialized — project:', projectId);
  } catch (err) {
    console.error('[FCM] Failed to initialize Firebase Admin:', err.message);
    fcmInitialized = true;
  }
}

/**
 * Send a push notification to a single FCM token.
 * @returns {Promise<string|null>} message ID or null if FCM not available
 */
async function sendPushNotification(token, title, body, data = {}) {
  if (!firebaseApp) return null;

  try {
    const message = {
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: {
        priority: 'high',
        notification: { sound: 'default', clickAction: 'FLUTTER_NOTIFICATION_CLICK' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    };

    const messageId = await admin.messaging().send(message);
    console.info('[FCM] Push sent, messageId:', messageId);
    return messageId;
  } catch (err) {
    console.error('[FCM] Send failed:', err.message);
    return null;
  }
}

/**
 * Send a notification to multiple tokens (multicast).
 */
async function sendMulticastNotification(tokens, title, body, data = {}) {
  if (!firebaseApp || !tokens || tokens.length === 0) return;

  try {
    const message = {
      tokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    };
    const result = await admin.messaging().sendEachForMulticast(message);
    console.info(`[FCM] Multicast: ${result.successCount} sent, ${result.failureCount} failed`);
  } catch (err) {
    console.error('[FCM] Multicast failed:', err.message);
  }
}

module.exports = { initFirebase, sendPushNotification, sendMulticastNotification };
