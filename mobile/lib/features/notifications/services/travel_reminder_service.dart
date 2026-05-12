// travel_reminder_service.dart — FLIGHTLY Local Notification Engine
// Wraps flutter_local_notifications to schedule and cancel travel reminders.
// All notifications are on-device — no backend or push infrastructure needed.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:flightly/features/notifications/domain/models/travel_reminder.dart';

// Navigation callback — set by main.dart / app_router after GoRouter is ready
typedef NotificationTapCallback = void Function(String payload);

class TravelReminderService {
  static final TravelReminderService _instance = TravelReminderService._internal();
  factory TravelReminderService() => _instance;
  TravelReminderService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  NotificationTapCallback? _onTap;

  // ─── Channel constants ────────────────────────────────────────────────────────
  static const String _channelId = 'flightly_travel_reminders';
  static const String _channelName = 'Travel Reminders';
  static const String _channelDesc =
      'Flight countdown reminders, baggage tips, and airport arrival recommendations.';

  // ─── Initialize ──────────────────────────────────────────────────────────────
  Future<void> initialize({NotificationTapCallback? onTap}) async {
    if (_initialized) {
      _onTap = onTap ?? _onTap;
      return;
    }

    _onTap = onTap;

    // Initialize timezone database
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We request manually on first booking
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty && _onTap != null) {
          _onTap!(payload);
        }
      },
    );

    // Create Android notification channel
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

    _initialized = true;
    debugPrint('[TravelReminderService] Initialized.');
  }

  // ─── Request Permission (called once on first booking confirmation) ──────────
  Future<bool> requestPermission() async {
    // Android 13+
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true; // Other platforms
  }

  // ─── Schedule a single reminder ──────────────────────────────────────────────
  Future<void> scheduleReminder(TravelReminder reminder) async {
    if (kIsWeb) {
      debugPrint('[Web Simulation] Scheduled Notification: ${reminder.title} -> ${reminder.body} (at ${reminder.scheduledAt})');
      return; // Web doesn't support zonedSchedule native notifications
    }

    if (!_initialized) await initialize();

    // Don't schedule if time is in the past
    if (reminder.scheduledAt.isBefore(DateTime.now())) {
      debugPrint('[TravelReminderService] Skipping past reminder: ${reminder.type}');
      return;
    }

    final scheduledTz = tz.TZDateTime.from(reminder.scheduledAt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      reminder.notificationId,
      reminder.title,
      reminder.body,
      scheduledTz,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.payload,
    );

    debugPrint(
      '[TravelReminderService] Scheduled: ${reminder.type} at ${reminder.scheduledAt}',
    );
  }

  // ─── Cancel all reminders for a booking ──────────────────────────────────────
  Future<void> cancelRemindersForBooking(String bookingId) async {
    if (!_initialized) await initialize();

    for (final type in TravelReminderType.values) {
      final id = _notificationId(bookingId, type);
      await _plugin.cancel(id);
    }

    debugPrint('[TravelReminderService] Cancelled all reminders for booking: $bookingId');
  }

  // ─── Cancel all ──────────────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[TravelReminderService] Cancelled all scheduled reminders.');
  }

  // ─── Deterministic notification ID ──────────────────────────────────────────
  // Uses bookingId hash + type index so cancellation is reliable without a DB.
  static int _notificationId(String bookingId, TravelReminderType type) {
    return (bookingId.hashCode.abs() % 100000) * 100 + type.index;
  }

  static int notificationIdFor(String bookingId, TravelReminderType type) =>
      _notificationId(bookingId, type);
}

// ─── Riverpod Provider ────────────────────────────────────────────────────────
final travelReminderServiceProvider = Provider<TravelReminderService>((ref) {
  return TravelReminderService();
});
