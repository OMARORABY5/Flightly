// flight_value_analyzer.dart — FLIGHTLY Smart Pricing Engine
// Pure Dart class — no Flutter dependencies, fully unit-testable.
//
// Scores every flight in a result set using weighted min-max normalization:
//   Price    40%  (lower = better)
//   Duration 30%  (shorter = better)
//   Stops    20%  (fewer = better)
//   Baggage  10%  (more checked kg = better)
//
// After scoring, assigns at most one SmartBadgeType per flight:
//   Cheapest     → lowest totalPrice
//   Fastest      → lowest durationMinutes
//   Best Value   → highest composite score
//   Recommended  → top-3 score, not yet labelled

import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/smart_pricing/flight_value_score.dart';

class FlightValueAnalyzer {
  // ─── Weights (must sum to 1.0) ───────────────────────────────────────────────
  static const double _weightPrice    = 0.40;
  static const double _weightDuration = 0.30;
  static const double _weightStops    = 0.20;
  static const double _weightBaggage  = 0.10;

  /// Scores all flights and assigns smart badges.
  /// Returns an empty list when given an empty input.
  List<FlightValueScore> scoreAll(List<Flight> flights) {
    if (flights.isEmpty) return [];
    if (flights.length == 1) {
      // Single result: perfect score, give Best Value badge automatically
      return [
        FlightValueScore(
          flight: flights.first,
          score: 100,
          badge: SmartBadgeType.bestValue,
        )
      ];
    }

    // ── Step 1: Extract raw values ─────────────────────────────────────────────
    final prices    = flights.map((f) => f.totalPrice).toList();
    final durations = flights.map((f) => f.durationMinutes.toDouble()).toList();
    final stops     = flights.map((f) => f.stops.toDouble()).toList();
    final baggage   = flights.map((f) => f.baggageCheckedKg.toDouble()).toList();

    // ── Step 2: Min-max bounds ─────────────────────────────────────────────────
    final minPrice    = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice    = prices.reduce((a, b) => a > b ? a : b);
    final minDuration = durations.reduce((a, b) => a < b ? a : b);
    final maxDuration = durations.reduce((a, b) => a > b ? a : b);
    final minStops    = stops.reduce((a, b) => a < b ? a : b);
    final maxStops    = stops.reduce((a, b) => a > b ? a : b);
    final minBaggage  = baggage.reduce((a, b) => a < b ? a : b);
    final maxBaggage  = baggage.reduce((a, b) => a > b ? a : b);

    // ── Step 3: Score each flight ──────────────────────────────────────────────
    final rawScores = <String, double>{};

    for (final f in flights) {
      // Normalise each factor to [0, 1].
      // For "lower is better" factors: score = 1 - normalised_value
      // For "higher is better" factors: score = normalised_value
      final priceScore    = _normaliseInverted(f.totalPrice,           minPrice,    maxPrice);
      final durationScore = _normaliseInverted(f.durationMinutes.toDouble(), minDuration, maxDuration);
      final stopsScore    = _normaliseInverted(f.stops.toDouble(),     minStops,    maxStops);
      final baggageScore  = _normalise(f.baggageCheckedKg.toDouble(),  minBaggage,  maxBaggage);

      final composite = (priceScore    * _weightPrice   +
                         durationScore * _weightDuration +
                         stopsScore    * _weightStops    +
                         baggageScore  * _weightBaggage) * 100;

      rawScores[f.id] = composite;
    }

    // ── Step 4: Identify badge winners ────────────────────────────────────────

    // Pre-calculate sets for quick lookup
    final cheapestId = flights
        .reduce((a, b) => a.totalPrice <= b.totalPrice ? a : b)
        .id;

    final fastestId = flights
        .reduce((a, b) => a.durationMinutes <= b.durationMinutes ? a : b)
        .id;

    final bestValueId = rawScores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final sortedByScore = rawScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // We only assign one badge per flight to avoid clutter. We keep track of assigned.
    final assignedBadges = <String, SmartBadgeType>{};

    // Priority 1: Limited Seats (Available Seats <= 5 and > 0)
    for (final f in flights) {
      if (f.availableSeats > 0 && f.availableSeats <= 5) {
        assignedBadges[f.id] = SmartBadgeType.limitedSeats;
      }
    }

    // Priority 2: Popular Choice
    for (final f in flights) {
      if (assignedBadges.containsKey(f.id)) continue;
      final isPopular = f.labels.any((l) => l.toLowerCase().contains('popular'));
      if (isPopular) {
        assignedBadges[f.id] = SmartBadgeType.popularChoice;
      }
    }

    // Priority 3: Best Value (strong price compared to flight quality)
    if (!assignedBadges.containsKey(bestValueId)) {
      assignedBadges[bestValueId] = SmartBadgeType.bestValue;
    }

    // Priority 4: Cheapest (lowest available price)
    if (!assignedBadges.containsKey(cheapestId)) {
      assignedBadges[cheapestId] = SmartBadgeType.cheapest;
    }

    // Priority 5: Fastest (shortest total duration)
    if (!assignedBadges.containsKey(fastestId)) {
      assignedBadges[fastestId] = SmartBadgeType.fastest;
    }

    // Priority 6: Recommended / Best / Smart Suggestion (balanced options)
    int recommendedCount = 0;
    for (final entry in sortedByScore) {
      if (recommendedCount >= 3) break; // Provide a few balanced options
      if (!assignedBadges.containsKey(entry.key)) {
        if (recommendedCount == 0) {
          assignedBadges[entry.key] = SmartBadgeType.recommended;
        } else if (recommendedCount == 1) {
          assignedBadges[entry.key] = SmartBadgeType.best;
        } else {
          assignedBadges[entry.key] = SmartBadgeType.smartSuggestion;
        }
        recommendedCount++;
      }
    }

    // ── Step 5: Build results ─────────────────────────────────────────────────
    return flights.map((f) {
      return FlightValueScore(
        flight: f,
        score: rawScores[f.id] ?? 0,
        badge: assignedBadges[f.id],
      );
    }).toList();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Normalise to [0,1] where higher raw value → higher score.
  double _normalise(double value, double min, double max) {
    if (max == min) return 1.0; // All same → perfect score for everyone
    return (value - min) / (max - min);
  }

  /// Normalise to [0,1] where LOWER raw value → higher score.
  double _normaliseInverted(double value, double min, double max) {
    if (max == min) return 1.0;
    return 1.0 - (value - min) / (max - min);
  }
}
