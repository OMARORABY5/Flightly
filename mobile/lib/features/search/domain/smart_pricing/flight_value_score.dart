// flight_value_score.dart — FLIGHTLY Smart Pricing Engine
// Data class holding the computed value score and smart badge for one flight.
// Produced by FlightValueAnalyzer.scoreAll().

import 'package:flightly/features/search/domain/models/flight.dart';

/// The smart badge types that can be surfaced on a flight card.
enum SmartBadgeType {
  best,
  cheapest,
  fastest,
  recommended,
  lowestPrice,
  shortestDuration,
  bestValue,
  popularChoice,
  limitedSeats,
  smartSuggestion,
}

extension SmartBadgeTypeLabel on SmartBadgeType {
  String get label {
    switch (this) {
      case SmartBadgeType.best:             return 'Best';
      case SmartBadgeType.cheapest:         return 'Cheapest';
      case SmartBadgeType.fastest:          return 'Fastest';
      case SmartBadgeType.recommended:      return 'Recommended';
      case SmartBadgeType.lowestPrice:      return 'Lowest Price';
      case SmartBadgeType.shortestDuration: return 'Shortest Duration';
      case SmartBadgeType.bestValue:        return 'Best Value';
      case SmartBadgeType.popularChoice:    return 'Popular Choice';
      case SmartBadgeType.limitedSeats:     return 'Limited Seats';
      case SmartBadgeType.smartSuggestion:  return 'Smart Suggestion';
    }
  }

  String get explanation {
    switch (this) {
      case SmartBadgeType.best:
      case SmartBadgeType.smartSuggestion:
      case SmartBadgeType.recommended:
        return 'Best balance between price, duration, and comfort.';
      case SmartBadgeType.cheapest:
      case SmartBadgeType.lowestPrice:
        return 'Lowest available price for this route.';
      case SmartBadgeType.fastest:
      case SmartBadgeType.shortestDuration:
        return 'Shortest total travel duration.';
      case SmartBadgeType.popularChoice:
        return 'Popular choice with strong overall value.';
      case SmartBadgeType.bestValue:
        return 'Good price compared to flight quality and timing.';
      case SmartBadgeType.limitedSeats:
        return 'Few seats remaining at this price.';
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
