import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flightly/features/notifications/data/repositories/notification_repository_impl.dart';

// Top-level function for background FCM handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to initialize Firebase here, do so, but generally it's already done
  // await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  final Ref ref;
  bool _isInitialized = false;

  PushNotificationService(this.ref);

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Graceful initialization: if it throws (e.g. no GoogleService-Info), catch it
      await Firebase.initializeApp();
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      await _requestPermission();
      await _setupLocalNotifications();
      await _getToken();
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle when app is opened via notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('[FCM] Firebase could not be initialized (Missing config?): $e');
    }
  }

  Future<void> _requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _setupLocalNotifications() async {
    if (kIsWeb) return; // flutter_local_notifications doesn't fully support web the same way
    
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _getToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('[FCM] Token retrieved: $token');
        final repo = ref.read(notificationRepositoryProvider);
        await repo.registerFcmToken(token);
      }
      
      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.registerFcmToken(newToken);
      });
    } catch (e) {
      debugPrint('[FCM] Failed to get/register token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message received: ${message.notification?.title}');
    
    // Refresh the notifications provider so the unread count goes up
    // Assuming you have access to the notifier:
    // ref.read(notificationNotifierProvider.notifier).refresh();
    
    // On Android, FCM doesn't automatically show a heads-up notification when in foreground.
    // You would use flutter_local_notifications to display it manually here.
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Message opened app: ${message.notification?.title}');
    // Navigation logic here based on message.data
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});
