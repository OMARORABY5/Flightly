// smart_pricing_provider.dart — FLIGHTLY Smart Pricing Suggestion
// Riverpod providers that derive scoring and recommendations from the
// already-loaded flight result sets. Zero extra API calls.
//
// Outbound providers:
//   scoredFlightsProvider              → List<FlightValueScore>
//   flightRecommendationProvider       → FlightRecommendation? (family by flightId)
//
// Return-leg providers (independent scoring):
//   scoredReturnFlightsProvider        → List<FlightValueScore>
//   returnFlightRecommendationProvider → FlightRecommendation? (family by flightId)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/features/search/domain/providers/flight_results_provider.dart';
import 'package:flightly/features/search/domain/providers/return_flight_results_provider.dart';
import 'package:flightly/features/search/domain/smart_pricing/flight_value_score.dart';
import 'package:flightly/features/search/domain/smart_pricing/flight_value_analyzer.dart';
import 'package:flightly/features/search/domain/smart_pricing/flight_recommendation_engine.dart';

// ─── Shared analyzer & engine instances ──────────────────────────────────────
// Both are stateless so a single instance is fine.
final _analyzer = FlightValueAnalyzer();
final _engine   = FlightRecommendationEngine();

// ─────────────────────────────────────────────────────────────────────────────
// OUTBOUND FLIGHTS
// ─────────────────────────────────────────────────────────────────────────────

/// Scored outbound flights derived from [flightResultsProvider].
/// Re-computes automatically whenever the flight list changes.
final scoredFlightsProvider = Provider.autoDispose<List<FlightValueScore>>((ref) {
  final flights = ref.watch(flightResultsProvider).flights;
  return _analyzer.scoreAll(flights);
});

/// Badge label lookup map for outbound flights: flightId → badge label string.
/// Convenience provider so screens don't have to iterate the list themselves.
final flightBadgeMapProvider = Provider.autoDispose<Map<String, String?>>((ref) {
  final scored = ref.watch(scoredFlightsProvider);
  return {for (final s in scored) s.flight.id: s.badgeLabel};
});

/// Smart recommendation for a specific outbound flight, keyed by [flightId].
/// Returns null if the flight is not found in the current results.
final flightRecommendationProvider =
    Provider.autoDispose.family<FlightRecommendation?, String>((ref, flightId) {
  final scored = ref.watch(scoredFlightsProvider);
  if (scored.isEmpty) return null;

  FlightValueScore? selected;
  for (final s in scored) {
    if (s.flight.id == flightId) {
      selected = s;
      break;
    }
  }
  if (selected == null) return null;

  return _engine.recommend(selected, scored);
});

// ─────────────────────────────────────────────────────────────────────────────
// RETURN FLIGHTS (independent scoring — outbound and return never mix)
// ─────────────────────────────────────────────────────────────────────────────

/// Scored return flights derived from [returnFlightResultsProvider].
final scoredReturnFlightsProvider = Provider.autoDispose<List<FlightValueScore>>((ref) {
  final flights = ref.watch(returnFlightResultsProvider).flights;
  return _analyzer.scoreAll(flights);
});

/// Badge label lookup map for return flights: flightId → badge label string.
final returnFlightBadgeMapProvider = Provider.autoDispose<Map<String, String?>>((ref) {
  final scored = ref.watch(scoredReturnFlightsProvider);
  return {for (final s in scored) s.flight.id: s.badgeLabel};
});

/// Smart recommendation for a specific return flight, keyed by [flightId].
final returnFlightRecommendationProvider =
    Provider.autoDispose.family<FlightRecommendation?, String>((ref, flightId) {
  final scored = ref.watch(scoredReturnFlightsProvider);
  if (scored.isEmpty) return null;

  FlightValueScore? selected;
  for (final s in scored) {
    if (s.flight.id == flightId) {
      selected = s;
      break;
    }
  }
  if (selected == null) return null;

  return _engine.recommend(selected, scored);
});
