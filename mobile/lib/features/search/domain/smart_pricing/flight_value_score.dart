// flight_value_score.dart — FLIGHTLY Smart Pricing Engine
// Data class holding the computed value score and smart badge for one flight.
// Produced by FlightValueAnalyzer.scoreAll().

import 'package:flightly/features/search/domain/models/flight.dart';

/// The smart badge types that can be surfaced on a flight card.
enum SmartBadgeType {
  bestValue,    // Highest overall weighted score
  cheapest,     // Lowest total price
  fastest,      // Shortest duration
  recommended,  // Top-3 score but not already labelled
}

extension SmartBadgeTypeLabel on SmartBadgeType {
  String get label {
    switch (this) {
      case SmartBadgeType.bestValue:   return 'Best Value';
      case SmartBadgeType.cheapest:    return 'Cheapest';
      case SmartBadgeType.fastest:     return 'Fastest';
      case SmartBadgeType.recommended: return 'Recommended';
    }
  }
}

/// Holds the scoring result for a single flight.
class FlightValueScore {
  /// The original flight object.
  final Flight flight;

  /// Normalised composite value score in the range [0, 100].
  /// Higher = better overall deal.
  final double score;

  /// Optional smart badge assigned to this flight, or null if none.
  final SmartBadgeType? badge;

  const FlightValueScore({
    required this.flight,
    required this.score,
    this.badge,
  });

  /// Convenience getter — returns the display label of the badge, or null.
  String? get badgeLabel => badge?.label;

  @override
  String toString() =>
      'FlightValueScore(id: ${flight.id}, score: ${score.toStringAsFixed(1)}, badge: $badgeLabel)';
}
