// watchlist_notification_store.dart — FLIGHTLY Watchlist Dedup Store
// Lightweight SharedPreferences wrapper that prevents notification spam.
// Tracks the last alert time and last notified price per saved flight.
//
// Keys stored in SharedPreferences:
//   wl_alerted_at_{saveId}    → ISO-8601 string of last alert timestamp
//   wl_alerted_price_{saveId} → last price that triggered an alert (double as string)

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistNotificationStore {
  static const int _minHoursBetweenAlerts = 23;

  static String _keyAlertedAt(String saveId) => 'wl_alerted_at_$saveId';
  static String _keyAlertedPrice(String saveId) => 'wl_alerted_price_$saveId';
  static const String _keyGlobalLastChecked = 'wl_global_last_checked';

  /// Returns true if an alert was already sent for [saveId] within the last 23 hours.
  Future<bool> wasAlertedRecently(String saveId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyAlertedAt(saveId));
      if (raw == null) return false;
      final last = DateTime.tryParse(raw);
      if (last == null) return false;
      final elapsed = DateTime.now().difference(last);
      return elapsed.inHours < _minHoursBetweenAlerts;
    } catch (e) {
      debugPrint('[WatchlistNotificationStore] wasAlertedRecently error: $e');
      return false;
    }
  }

  /// Records that an alert was sent for [saveId] at [price].
  /// Call this immediately after firing the notification.
  Future<void> recordAlert(String saveId, double price) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAlertedAt(saveId), DateTime.now().toIso8601String());
      await prefs.setString(_keyAlertedPrice(saveId), price.toString());
      debugPrint('[WatchlistNotificationStore] Recorded alert for $saveId at \$$price');
    } catch (e) {
      debugPrint('[WatchlistNotificationStore] recordAlert error: $e');
    }
  }

  /// Returns the price that last triggered an alert for [saveId], or null if never alerted.
  Future<double?> getLastNotifiedPrice(String saveId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyAlertedPrice(saveId));
      if (raw == null) return null;
      return double.tryParse(raw);
    } catch (e) {
      debugPrint('[WatchlistNotificationStore] getLastNotifiedPrice error: $e');
      return null;
    }
  }

  /// Returns the timestamp of the last alert for [saveId], or null if never alerted.
  Future<DateTime?> getLastAlertTime(String saveId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyAlertedAt(saveId));
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (e) {
      debugPrint('[WatchlistNotificationStore] getLastAlertTime error: $e');
      return null;
    }
  }

  /// Clears all alert records for [saveId]. Call when user removes a flight from watchlist.
  Future<void> clearRecord(String saveId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAlertedAt(saveId));
      await prefs.remove(_keyAlertedPrice(saveId));
      debugPrint('[WatchlistNotificationStore] Cleared record for $saveId');
    } catch (e) {
      debugPrint('[WatchlistNotificationStore] clearRecord error: $e');
    }
  }

  /// Records the global timestamp of the last completed monitoring pass.
  Future<void> recordGlobalCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyGlobalLastChecked, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('[WatchlistNotificationStore] recordGlobalCheck error: $e');
    }
  }

  /// Returns the global timestamp of the last completed monitoring pass.
  Future<DateTime?> getGlobalLastChecked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyGlobalLastChecked);
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (e) {
      debugPrint('[WatchlistNotificationStore] getGlobalLastChecked error: $e');
      return null;
    }
  }
}
