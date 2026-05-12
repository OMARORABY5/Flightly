// flight_recommendation_engine.dart — FLIGHTLY Smart Pricing Engine
// Pure Dart class — no Flutter dependencies, fully unit-testable.
//
// Given the user's SELECTED flight and the full scored result set,
// produces ONE FlightRecommendation explaining whether there is a
// smarter alternative — or confirming it is already a great choice.
//
// Rules are evaluated in priority order:
//   1. bestChoice        → selected has highest score in set
//   2. cheaperSimilar    → same stops, duration diff ≤60 min, saves ≥15% price
//   3. fasterAlternative → saves ≥3 h travel, price diff ≤$30
//   4. betterValue       → alternative score 10+ pts higher, price diff ≤$50
//   5. noAction          → no useful recommendation to surface

import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/smart_pricing/flight_value_score.dart';

// ─── Enums & Data Classes ────────────────────────────────────────────────────

enum RecommendationType {
  bestChoice,
  cheaperSimilar,
  fasterAlternative,
  betterValue,
  noAction,
}

class FlightRecommendation {
  /// The category of recommendation.
  final RecommendationType type;

  /// Primary headline shown in the card, e.g. "Save $45 on a similar itinerary".
  final String headline;

  /// Optional supporting line shown below the headline.
  final String? subline;

  /// Up to 3 short bullet highlights, e.g. ['Direct flight', 'Better baggage'].
  final List<String> highlights;

  /// The alternative flight the card is pointing to.
  /// null for bestChoice / noAction.
  final Flight? alternativeFlight;

  const FlightRecommendation({
    required this.type,
    required this.headline,
    this.subline,
    this.highlights = const [],
    this.alternativeFlight,
  });

  bool get hasAlternative => alternativeFlight != null;
  bool get isActionable =>
      type != RecommendationType.noAction;
}

// ─── Engine ──────────────────────────────────────────────────────────────────

class FlightRecommendationEngine {
  // ── Thresholds ────────────────────────────────────────────────────────────
  static const double _cheaperSavingsPercent = 0.15;   // 15% cheaper
  static const int    _cheaperDurationMaxDiff = 60;     // ≤ 60 min difference
  static const int    _fasterDurationSaving  = 180;    // ≥ 3 hours faster
  static const double _fasterMaxPriceDiff    = 30.0;   // ≤ $30 more expensive
  static const double _betterValueMinScoreDiff = 10.0; // ≥ 10 score points better
  static const double _betterValueMaxPriceDiff = 50.0; // ≤ $50 more expensive

  /// Analyse [selected] against all [allScored] flights and return
  /// the single most relevant recommendation.
  FlightRecommendation recommend(
    FlightValueScore selected,
    List<FlightValueScore> allScored,
  ) {
    // Need at least 2 flights to compare
    if (allScored.length < 2) {
      return FlightRecommendation(
        type: RecommendationType.bestChoice,
        headline: 'Great choice — this is the only available option.',
        highlights: [],
      );
    }

    // All other flights (excluding the selected one)
    final others = allScored.where((s) => s.flight.id != selected.flight.id).toList();

    // ── Rule 1: bestChoice ───────────────────────────────────────────────────
    // If the selected flight has the highest score in the set, confirm it.
    final topScore = allScored.map((s) => s.score).reduce((a, b) => a > b ? a : b);
    if (selected.score >= topScore - 0.5) { // small epsilon for floating point
      return FlightRecommendation(
        type: RecommendationType.bestChoice,
        headline: 'Great choice — this is one of the best value options available.',
        subline: 'You\'ve picked an excellent combination of price, speed, and comfort.',
        highlights: _buildPositiveHighlights(selected.flight),
      );
    }

    // ── Rule 2: cheaperSimilar ───────────────────────────────────────────────
    // Same stops, duration within ±60 min, saves ≥15% on price.
    final cheaperSimilar = _findCheaperSimilar(selected.flight, others);
    if (cheaperSimilar != null) {
      final savings = selected.flight.totalPrice - cheaperSimilar.flight.totalPrice;
      final durationDiff = (selected.flight.durationMinutes - cheaperSimilar.flight.durationMinutes).abs();
      return FlightRecommendation(
        type: RecommendationType.cheaperSimilar,
        headline: 'Save \$${savings.toStringAsFixed(0)} with a very similar itinerary.',
        subline: durationDiff <= 10
            ? 'Nearly identical travel time at a lower price.'
            : 'Only ${_formatDuration(durationDiff)} difference in travel time.',
        highlights: _buildComparisonHighlights(selected.flight, cheaperSimilar.flight),
        alternativeFlight: cheaperSimilar.flight,
      );
    }

    // ── Rule 3: fasterAlternative ────────────────────────────────────────────
    // Saves ≥3 h, costs at most $30 more.
    final fasterAlt = _findFasterAlternative(selected.flight, others);
    if (fasterAlt != null) {
      final saving = selected.flight.durationMinutes - fasterAlt.flight.durationMinutes;
      final priceDiff = fasterAlt.flight.totalPrice - selected.flight.totalPrice;
      final priceStr = priceDiff > 0
          ? 'for only +\$${priceDiff.toStringAsFixed(0)}'
          : 'at the same price or less';
      return FlightRecommendation(
        type: RecommendationType.fasterAlternative,
        headline: 'Save ${_formatDuration(saving)} of travel time $priceStr.',
        subline: 'Get there faster with a quicker routing.',
        highlights: _buildComparisonHighlights(selected.flight, fasterAlt.flight),
        alternativeFlight: fasterAlt.flight,
      );
    }

    // ── Rule 4: betterValue ──────────────────────────────────────────────────
    // Alternative score 10+ pts higher, costs at most $50 more.
    final betterAlt = _findBetterValue(selected, others);
    if (betterAlt != null) {
      final priceDiff = betterAlt.flight.totalPrice - selected.flight.totalPrice;
      final priceStr = priceDiff > 0
          ? 'for only +\$${priceDiff.toStringAsFixed(0)}'
          : 'at a similar price';
      return FlightRecommendation(
        type: RecommendationType.betterValue,
        headline: 'Better overall value is available $priceStr.',
        subline: 'Improved comfort, speed, and convenience in one option.',
        highlights: _buildComparisonHighlights(selected.flight, betterAlt.flight),
        alternativeFlight: betterAlt.flight,
      );
    }

    // ── Rule 5: noAction ─────────────────────────────────────────────────────
    return const FlightRecommendation(
      type: RecommendationType.noAction,
      headline: '',
    );
  }

  // ─── Rule helpers ─────────────────────────────────────────────────────────

  FlightValueScore? _findCheaperSimilar(Flight selected, List<FlightValueScore> others) {
    final threshold = selected.totalPrice * (1 - _cheaperSavingsPercent);
    FlightValueScore? best;
    for (final s in others) {
      final f = s.flight;
      if (f.stops != selected.stops) continue;
      final durationDiff = (f.durationMinutes - selected.durationMinutes).abs();
      if (durationDiff > _cheaperDurationMaxDiff) continue;
      if (f.totalPrice >= threshold) continue;
      if (best == null || f.totalPrice < best.flight.totalPrice) best = s;
    }
    return best;
  }

  FlightValueScore? _findFasterAlternative(Flight selected, List<FlightValueScore> others) {
    FlightValueScore? best;
    for (final s in others) {
      final f = s.flight;
      final durationSaving = selected.durationMinutes - f.durationMinutes;
      if (durationSaving < _fasterDurationSaving) continue;
      final priceDiff = f.totalPrice - selected.totalPrice;
      if (priceDiff > _fasterMaxPriceDiff) continue;
      if (best == null || durationSaving > selected.durationMinutes - best.flight.durationMinutes) {
        best = s;
      }
    }
    return best;
  }

  FlightValueScore? _findBetterValue(FlightValueScore selected, List<FlightValueScore> others) {
    FlightValueScore? best;
    for (final s in others) {
      final scoreDiff = s.score - selected.score;
      if (scoreDiff < _betterValueMinScoreDiff) continue;
      final priceDiff = s.flight.totalPrice - selected.flight.totalPrice;
      if (priceDiff > _betterValueMaxPriceDiff) continue;
      if (best == null || s.score > best.score) best = s;
    }
    return best;
  }

  // ─── Highlight builders ───────────────────────────────────────────────────

  /// Positive highlights for the selected flight when it's already the best.
  List<String> _buildPositiveHighlights(Flight f) {
    final items = <String>[];
    if (f.stops == 0) items.add('Direct flight');
    if (f.baggageCheckedKg >= 23) items.add('Generous baggage allowance');
    if (f.isRefundable) items.add('Fully refundable');
    return items.take(3).toList();
  }

  /// Comparison highlights pointing out what makes the ALTERNATIVE better.
  List<String> _buildComparisonHighlights(Flight selected, Flight alt) {
    final items = <String>[];
    if (alt.stops < selected.stops) {
      items.add(alt.stops == 0 ? 'Direct flight' : 'Fewer stops');
    }
    if (alt.baggageCheckedKg > selected.baggageCheckedKg) {
      items.add('${alt.baggageCheckedKg - selected.baggageCheckedKg} kg more checked baggage');
    }
    if (alt.isRefundable && !selected.isRefundable) {
      items.add('Fully refundable');
    }
    if (alt.durationMinutes < selected.durationMinutes) {
      final diff = selected.durationMinutes - alt.durationMinutes;
      items.add('${_formatDuration(diff)} shorter flight');
    }
    if (alt.totalPrice < selected.totalPrice) {
      final diff = selected.totalPrice - alt.totalPrice;
      items.add('\$${diff.toStringAsFixed(0)} cheaper');
    }
    return items.take(3).toList();
  }

  // ─── Formatting ───────────────────────────────────────────────────────────

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
