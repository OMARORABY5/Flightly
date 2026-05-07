// return_flight_results_provider.dart
// A dedicated search provider for the return leg of a round-trip.
// Mirrors FlightResultsNotifier but uses:
//   - origin = query.destination  (swapped)
//   - destination = query.origin  (swapped)
//   - date = query.returnDate

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/features/search/domain/models/filter_options.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';

/// Separate filter state for the return leg so it doesn't share with outbound.
final returnFilterOptionsProvider =
    StateProvider<FilterOptions>((ref) => const FilterOptions());

class ReturnFlightResultsState {
  final List<Flight> flights;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final bool hasMore;
  final int page;

  ReturnFlightResultsState({
    this.flights = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
  });

  ReturnFlightResultsState copyWith({
    List<Flight>? flights,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    bool? hasMore,
    int? page,
  }) {
    return ReturnFlightResultsState(
      flights: flights ?? this.flights,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class ReturnFlightResultsNotifier
    extends AutoDisposeNotifier<ReturnFlightResultsState> {
  @override
  ReturnFlightResultsState build() => ReturnFlightResultsState();

  Future<void> searchFlights() async {
    final query = ref.read(searchFormProvider);
    final filters = ref.read(returnFilterOptionsProvider);

    if (query.origin == null ||
        query.destination == null ||
        query.returnDate == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Build a swapped query: dest→origin on the return date
      final returnQuery = SearchQuery(
        tripType: TripType.oneWay,
        origin: query.destination,       // swapped
        destination: query.origin,       // swapped
        departureDate: query.returnDate, // use return date
        adults: query.adults,
        children: query.children,
        infants: query.infants,
        cabinClass: query.cabinClass,
      );

      final repo = ref.read(searchRepositoryProvider);
      final response = await repo.searchFlights(
        query: returnQuery,
        filters: filters,
        page: 1,
      );

      state = state.copyWith(
        isLoading: false,
        flights: response.flights,
        hasMore: response.hasNext,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isFetchingMore || !state.hasMore) return;

    final query = ref.read(searchFormProvider);
    final filters = ref.read(returnFilterOptionsProvider);

    if (query.origin == null ||
        query.destination == null ||
        query.returnDate == null) return;

    state = state.copyWith(isFetchingMore: true);

    try {
      final returnQuery = SearchQuery(
        tripType: TripType.oneWay,
        origin: query.destination,
        destination: query.origin,
        departureDate: query.returnDate,
        adults: query.adults,
        children: query.children,
        infants: query.infants,
        cabinClass: query.cabinClass,
      );

      final nextPage = state.page + 1;
      final repo = ref.read(searchRepositoryProvider);
      final response = await repo.searchFlights(
        query: returnQuery,
        filters: filters,
        page: nextPage,
      );

      state = state.copyWith(
        isFetchingMore: false,
        flights: [...state.flights, ...response.flights],
        hasMore: response.hasNext,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false);
    }
  }
}

final returnFlightResultsProvider = AutoDisposeNotifierProvider<
    ReturnFlightResultsNotifier, ReturnFlightResultsState>(() {
  return ReturnFlightResultsNotifier();
});
