// price_drop_evaluator.dart — FLIGHTLY Smart Watchlist Price Engine
// Pure Dart class — no Flutter dependencies, fully unit-testable.
//
// Given a saved flight and nearby price data, evaluates three rules:
//
//   Rule 1 — priceDrop:
//     currentPrice < savedPrice AND drop ≥ minDropPercent (8%)
//
//   Rule 2 — flexibleDate:
//     A nearby date price < currentPrice AND saving ≥ minFlexibleSaving ($30)
//     Reports the single best (cheapest) nearby date found.
//
//   Rule 3 — goodPriceWindow:
//     currentPrice is the lowest in the nearby date spread
//     AND currentPrice < savedPrice (i.e. price is low right now)
//     Does NOT fire if Rule 1 already fired (priceDrop covers it).
//
// Returns a List<WatchlistAlert> — one entry per triggered rule (max 3).
// Each alert is self-contained with ready-to-use notification strings.

import 'package:flightly/features/saved_flights/domain/models/watchlist_alert.dart';

/// A nearby date price sample used by the evaluator.
class NearbyDatePrice {
  /// The nearby departure date.
  final DateTime date;

  /// Offset in days from the watched date. Negative = earlier, positive = later.
  final int dayOffset;

  /// The cheapest available price on this date for the same route.
  final double price;

  const NearbyDatePrice({
    required this.date,
    required this.dayOffset,
    required this.price,
  });
}

class PriceDropEvaluator {
  // ── Thresholds ──────────────────────────────────────────────────────────────
  /// Minimum percentage drop vs saved price to trigger a priceDrop alert.
  static const double minDropPercent = 0.08; // 8%

  /// Minimum absolute saving on a nearby date to trigger a flexibleDate alert.
  static const double minFlexibleSaving = 30.0; // $30

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Evaluates price conditions and returns all triggered alerts.
  ///
  /// [saveId]         — identifier from SavedFlight for dedup tracking.
  /// [flightId]       — flight UUID for deep-linking.
  /// [originIata]     — e.g. "CAI"
  /// [destinationIata]— e.g. "DXB"
  /// [originCity]     — e.g. "Cairo" (nullable)
  /// [destinationCity]— e.g. "Dubai" (nullable)
  /// [savedPrice]     — price when user added flight to watchlist.
  /// [currentPrice]   — latest observed price for the same flight.
  /// [nearbyPrices]   — list of NearbyDatePrice samples (±2 or ±5 days).
  List<WatchlistAlert> evaluate({
    required String saveId,
    required String flightId,
    required String originIata,
    required String destinationIata,
    String? originCity,
    String? destinationCity,
    required double savedPrice,
    required double currentPrice,
    List<NearbyDatePrice> nearbyPrices = const [],
  }) {
    final alerts = <WatchlistAlert>[];
    final now = DateTime.now();

    final from = originCity ?? originIata;
    final to = destinationCity ?? destinationIata;

    // ── Rule 1: Price Drop ─────────────────────────────────────────────────────
    final drop = savedPrice - currentPrice;
    final dropPct = savedPrice > 0 ? drop / savedPrice : 0.0;
    bool priceDropFired = false;

    if (currentPrice < savedPrice && dropPct >= minDropPercent) {
      priceDropFired = true;
      final dropStr = drop.toStringAsFixed(0);
      final pctStr = (dropPct * 100).toStringAsFixed(0);

      alerts.add(WatchlistAlert(
        saveId: saveId,
        flightId: flightId,
        originIata: originIata,
        destinationIata: destinationIata,
        originCity: originCity,
        destinationCity: destinationCity,
        type: WatchlistAlertType.priceDrop,
        savedPrice: savedPrice,
        currentPrice: currentPrice,
        priceDrop: drop,
        dropPercent: dropPct,
        notificationTitle: 'Good news ✈️ Prices dropped $pctStr%',
        notificationBody:
            'Your $from → $to trip is now \$$dropStr cheaper. Tap to book before prices change.',
        createdAt: now,
      ));
    }

    // ── Rule 2: Flexible Date ─────────────────────────────────────────────────
    if (nearbyPrices.isNotEmpty) {
      // Find the single best (cheapest) nearby date that saves ≥ $30 vs current
      NearbyDatePrice? bestNearby;
      double bestSaving = 0;

      for (final nearby in nearbyPrices) {
        final saving = currentPrice - nearby.price;
        if (saving >= minFlexibleSaving && saving > bestSaving) {
          bestSaving = saving;
          bestNearby = nearby;
        }
      }

      if (bestNearby != null) {
        final savingStr = bestSaving.toStringAsFixed(0);
        final offsetAbs = bestNearby.dayOffset.abs();
        final direction = bestNearby.dayOffset < 0 ? 'earlier' : 'later';
        final dayWord = offsetAbs == 1 ? 'day' : 'days';
        final dateStr = _formatDate(bestNearby.date);

        alerts.add(WatchlistAlert(
          saveId: saveId,
          flightId: flightId,
          originIata: originIata,
          destinationIata: destinationIata,
          originCity: originCity,
          destinationCity: destinationCity,
          type: WatchlistAlertType.flexibleDate,
          savedPrice: savedPrice,
          currentPrice: currentPrice,
          suggestedPrice: bestNearby.price,
          suggestedDate: bestNearby.date,
          suggestedDayOffset: bestNearby.dayOffset,
          flexibleSaving: bestSaving,
          notificationTitle: 'Flexible dates could save you \$$savingStr',
          notificationBody:
              'Flying $offsetAbs $dayWord $direction ($dateStr) on $from → $to is \$$savingStr cheaper.',
          createdAt: now,
        ));
      }
    }

    // ── Rule 3: Good Price Window ─────────────────────────────────────────────
    // Fires only when:
    //   - currentPrice is the lowest in the entire nearby spread (including itself)
    //   - currentPrice < savedPrice (confirming it's genuinely low)
    //   - Rule 1 did NOT already fire (avoid redundancy)
    if (!priceDropFired && nearbyPrices.isNotEmpty && currentPrice < savedPrice) {
      final allPrices = [currentPrice, ...nearbyPrices.map((n) => n.price)];
      final minPrice = allPrices.reduce((a, b) => a < b ? a : b);

      // Current price is the cheapest in the spread (within $5 rounding tolerance)
      if ((currentPrice - minPrice).abs() <= 5.0) {
        alerts.add(WatchlistAlert(
          saveId: saveId,
          flightId: flightId,
          originIata: originIata,
          destinationIata: destinationIata,
          originCity: originCity,
          destinationCity: destinationCity,
          type: WatchlistAlertType.goodPriceWindow,
          savedPrice: savedPrice,
          currentPrice: currentPrice,
          notificationTitle: 'Prices are low right now 📉',
          notificationBody:
              'Current $from → $to fares are lower than nearby dates. Good time to book.',
          createdAt: now,
        ));
      }
    }

    return alerts;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
