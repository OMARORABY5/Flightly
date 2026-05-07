import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/search/domain/models/airport.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/models/saved_flight.dart';
import 'package:flightly/features/search/domain/repositories/search_repository.dart';
import 'package:flightly/features/search/data/repositories/search_repository_impl.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(dioClient: DioClient.instance());
});

final popularAirportsProvider = FutureProvider<List<Airport>>((ref) async {
  final repo = ref.watch(searchRepositoryProvider);
  return repo.getPopularAirports();
});

final availableAirlinesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(searchRepositoryProvider);
  return repo.getAvailableAirlines();
});

final airportSearchQueryProvider = StateProvider<String>((ref) => '');

final airportSearchProvider = FutureProvider<List<Airport>>((ref) async {
  final query = ref.watch(airportSearchQueryProvider);
  final repo = ref.watch(searchRepositoryProvider);
  
  if (query.isEmpty) {
    return ref.watch(popularAirportsProvider.future);
  }
  
  if (query.length < 2) {
    return [];
  }
  
  return repo.searchAirports(query);
});

// ─── Phase 5: Flight Details & Smart Pricing ─────────────────────────────────

final flightDetailsProvider = FutureProvider.family<Flight?, String>((ref, id) async {
  final repo = ref.watch(searchRepositoryProvider);
  return repo.getFlightDetails(id);
});

// ─── Phase 5: Saved Flights (Watchlist) ──────────────────────────────────────

final savedFlightsProvider = FutureProvider<List<SavedFlight>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final repo = ref.watch(searchRepositoryProvider);
  return repo.getSavedFlights(authState.user.id);
});

final isFlightSavedProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, flightId) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return {'is_saved': false};

  final repo = ref.watch(searchRepositoryProvider);
  return repo.checkSaved(authState.user.id, flightId);
});
