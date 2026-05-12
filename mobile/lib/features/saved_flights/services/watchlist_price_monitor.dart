// watchlist_price_monitor.dart — FLIGHTLY Smart Watchlist Price Tracking
// Orchestrator service that runs the monitoring pass:
//   1. Load saved flights
//   2. Check dedup store (skip flights alerted within 23h)
//   3. Fetch nearby date prices via SearchRepository
//   4. Evaluate rules via PriceDropEvaluator
//   5. Fire immediate local notifications for triggered alerts
//   6. Persist dedup records
//
// Daily auto-pass  → checks ±2 nearby days (4 API calls per flight)
// Manual "Check Now" pass → checks ±5 nearby days (10 API calls per flight)
// Web (kIsWeb) → skips scheduled pass; only runs on manual trigger.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:flightly/features/search/domain/models/airport.dart';
import 'package:flightly/features/search/domain/models/filter_options.dart';
import 'package:flightly/features/search/domain/models/saved_flight.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';
import 'package:flightly/features/search/domain/repositories/search_repository.dart';
import 'package:flightly/features/saved_flights/domain/logic/price_drop_evaluator.dart';
import 'package:flightly/features/saved_flights/domain/logic/watchlist_notification_store.dart';
import 'package:flightly/features/saved_flights/domain/models/watchlist_alert.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const int _nearbyDaysAuto   = 2; // ±2 days on daily pass
const int _nearbyDaysManual = 5; // ±5 days on manual "Check Now"

// SharedPreferences key for the daily scheduled notification ID
const String _kDailyPassNotifId = 'watchlist_daily_pass_notif_id';

// Notification channel for watchlist price alerts
const String _channelId   = 'flightly_watchlist_alerts';
const String _channelName = 'Price Alerts';
const String _channelDesc = 'Watchlist price drop and flexible date notifications.';

// ─── WatchlistPriceMonitor ────────────────────────────────────────────────────

class WatchlistPriceMonitor {
  final SearchRepository _repo;
  final WatchlistNotificationStore _store;
  final PriceDropEvaluator _evaluator;
  final FlutterLocalNotificationsPlugin _plugin;

  WatchlistPriceMonitor({
    required SearchRepository repo,
  })  : _repo = repo,
        _store = WatchlistNotificationStore(),
        _evaluator = PriceDropEvaluator(),
        _plugin = FlutterLocalNotificationsPlugin();

  // ── Public: run monitoring pass ─────────────────────────────────────────────

  /// Runs a full monitoring pass over all saved flights.
  ///
  /// [isManual] — true when triggered by "Check Now" button.
  ///   Manual pass: checks ±5 nearby days.
  ///   Auto pass:   checks ±2 nearby days.
  ///
  /// Returns the list of alerts that were fired.
  Future<List<WatchlistAlert>> runMonitoringPass({
    required String userId,
    bool isManual = false,
  }) async {
    final allFired = <WatchlistAlert>[];
    final nearbyRange = isManual ? _nearbyDaysManual : _nearbyDaysAuto;

    debugPrint('[WatchlistPriceMonitor] Starting ${isManual ? "manual" : "auto"} pass (±$nearbyRange days)');

    List<SavedFlight> savedFlights;
    try {
      savedFlights = await _repo.getSavedFlights(userId);
    } catch (e) {
      debugPrint('[WatchlistPriceMonitor] Failed to load saved flights: $e');
      return [];
    }

    if (savedFlights.isEmpty) {
      debugPrint('[WatchlistPriceMonitor] No saved flights to monitor.');
      return [];
    }

    for (final saved in savedFlights) {
      // ── Dedup guard ─────────────────────────────────────────────────────────
      // On auto passes, skip if we already alerted within 23h.
      // On manual passes, always run (user explicitly asked for it).
      if (!isManual && await _store.wasAlertedRecently(saved.saveId)) {
        debugPrint('[WatchlistPriceMonitor] Skipping ${saved.saveId} — alerted recently.');
        continue;
      }

      // ── Fetch nearby prices ─────────────────────────────────────────────────
      final nearbyPrices = await _fetchNearbyPrices(saved, nearbyRange);

      // ── Evaluate rules ──────────────────────────────────────────────────────
      final alerts = _evaluator.evaluate(
        saveId: saved.saveId,
        flightId: saved.flight.id,
        originIata: saved.flight.originIata,
        destinationIata: saved.flight.destinationIata,
        originCity: saved.flight.originCity,
        destinationCity: saved.flight.destinationCity,
        savedPrice: saved.savedPrice,
        currentPrice: saved.currentPrice,
        nearbyPrices: nearbyPrices,
      );

      if (alerts.isEmpty) {
        debugPrint('[WatchlistPriceMonitor] No alerts for ${saved.saveId}');
        continue;
      }

      // ── Fire notifications ──────────────────────────────────────────────────
      for (final alert in alerts) {
        await _fireNotification(alert);
        allFired.add(alert);
      }

      // ── Record dedup (use current price as the last notified price) ─────────
      await _store.recordAlert(saved.saveId, saved.currentPrice);
    }

    // ── Record global check ──────────────────────────────────────────────────
    await _store.recordGlobalCheck();

    debugPrint('[WatchlistPriceMonitor] Pass complete — ${allFired.length} alert(s) fired.');
    return allFired;
  }

  // ── Public: schedule daily pass ─────────────────────────────────────────────

  /// Schedules a daily monitoring pass at 9:00 AM local time.
  /// Skipped on Flutter Web (kIsWeb) — web is manual-only.
  Future<void> scheduleDaily() async {
    if (kIsWeb) {
      debugPrint('[WatchlistPriceMonitor] Web detected — skipping daily schedule (manual-only on web).');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Check user preference (default true if not set)
    final isEnabled = prefs.getBool('pref_watchlist_alerts') ?? true;
    if (!isEnabled) {
      debugPrint('[WatchlistPriceMonitor] Watchlist alerts disabled by user — skipping schedule.');
      // Ensure we cancel any existing schedules
      final oldId = prefs.getInt(_kDailyPassNotifId);
      if (oldId != null) {
        await _plugin.cancel(oldId);
      }
      return;
    }

    await _ensureChannel();
    // Cancel previous daily pass notification if any
    final oldId = prefs.getInt(_kDailyPassNotifId);
    if (oldId != null) {
      await _plugin.cancel(oldId);
    }

    // Schedule at 9:00 AM tomorrow, then repeats daily
    final now = DateTime.now();
    var next9am = DateTime(now.year, now.month, now.day, 9, 0, 0);
    if (now.isAfter(next9am)) {
      next9am = next9am.add(const Duration(days: 1));
    }

    const int notifId = 900001; // Fixed ID for the daily watchlist pass
    await prefs.setInt(_kDailyPassNotifId, notifId);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      enableVibration: false,
      // Silent "background tick" — user never sees this notification
      ongoing: false,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      notifId,
      'Checking your watchlist…',
      'Flightly is checking prices for your saved routes.',
      tz.TZDateTime.from(next9am, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );

    debugPrint('[WatchlistPriceMonitor] Daily pass scheduled at ${next9am.toIso8601String()}');
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Fetches the cheapest price for the same route on each nearby date.
  Future<List<NearbyDatePrice>> _fetchNearbyPrices(
    SavedFlight saved,
    int range,
  ) async {
    final flight = saved.flight;
    final baseDate = flight.departureTime;
    final results = <NearbyDatePrice>[];

    // Build minimal Airport objects from IATA codes on the Flight
    final origin = Airport(
      iataCode: flight.originIata,
      name: flight.originName ?? flight.originIata,
      city: flight.originCity ?? '',
      country: '',
      countryCode: '',
    );
    final destination = Airport(
      iataCode: flight.destinationIata,
      name: flight.destinationName ?? flight.destinationIata,
      city: flight.destinationCity ?? '',
      country: '',
      countryCode: '',
    );

    for (int offset = -range; offset <= range; offset++) {
      if (offset == 0) continue; // skip the watched date itself
      final nearbyDate = baseDate.add(Duration(days: offset));
      // Don't search past dates
      if (nearbyDate.isBefore(DateTime.now())) continue;

      try {
        final query = SearchQuery(
          tripType: TripType.oneWay,
          origin: origin,
          destination: destination,
          departureDate: nearbyDate,
          adults: 1,
        );
        const filters = FilterOptions(sortOption: SortOption.priceAsc);
        final response = await _repo.searchFlights(query: query, filters: filters, page: 1);

        if (response.flights.isNotEmpty) {
          // Take the cheapest result (already sorted by price_asc)
          final cheapest = response.flights.reduce(
            (a, b) => a.totalPrice < b.totalPrice ? a : b,
          );
          results.add(NearbyDatePrice(
            date: nearbyDate,
            dayOffset: offset,
            price: cheapest.totalPrice,
          ));
        }
      } catch (e) {
        // Silently skip failed nearby searches — non-critical
        debugPrint('[WatchlistPriceMonitor] Nearby search error (offset $offset): $e');
      }
    }

    return results;
  }

  /// Fires an immediate local notification for a given alert.
  Future<void> _fireNotification(WatchlistAlert alert) async {
    await _ensureChannel();

    final int notifId = _alertNotifId(alert);

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

    await _plugin.show(
      notifId,
      alert.notificationTitle,
      alert.notificationBody,
      details,
      payload: '/watchlist', // Tap → open watchlist tab
    );

    debugPrint('[WatchlistPriceMonitor] Fired: ${alert.type} for ${alert.saveId}');
  }

  /// Ensures the Android notification channel exists.
  Future<void> _ensureChannel() async {
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
  }

  /// Deterministic notification ID: saveId hash + alert type index.
  static int _alertNotifId(WatchlistAlert alert) {
    return (alert.saveId.hashCode.abs() % 100000) * 10 + alert.type.index;
  }
}

// ─── Riverpod Provider ────────────────────────────────────────────────────────

final watchlistPriceMonitorProvider = Provider<WatchlistPriceMonitor>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return WatchlistPriceMonitor(repo: repo);
});

final watchlistLastCheckedProvider = FutureProvider.autoDispose<DateTime?>((ref) async {
  return WatchlistNotificationStore().getGlobalLastChecked();
});
