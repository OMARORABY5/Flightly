import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/features/search/domain/models/filter_options.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';

final filterOptionsProvider = StateProvider<FilterOptions>((ref) => const FilterOptions());

class FlightResultsState {
  final List<Flight> flights;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final bool hasMore;
  final int page;

  FlightResultsState({
    this.flights = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
  });

  FlightResultsState copyWith({
    List<Flight>? flights,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    bool? hasMore,
    int? page,
  }) {
    return FlightResultsState(
      flights: flights ?? this.flights,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class FlightResultsNotifier extends AutoDisposeNotifier<FlightResultsState> {
  @override
  FlightResultsState build() {
    return FlightResultsState();
  }

  Future<void> searchFlights() async {
    final query = ref.read(searchFormProvider);
    final filters = ref.read(filterOptionsProvider);
    
    if (!query.isValid) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ref.read(searchRepositoryProvider).searchFlights(
        query: query,
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
    final filters = ref.read(filterOptionsProvider);

    state = state.copyWith(isFetchingMore: true);

    try {
      final nextPage = state.page + 1;
      final response = await ref.read(searchRepositoryProvider).searchFlights(
        query: query,
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
      // We don't overwrite the main error so the list stays visible, maybe show a toast
    }
  }
}

final flightResultsProvider = AutoDisposeNotifierProvider<FlightResultsNotifier, FlightResultsState>(() {
  return FlightResultsNotifier();
});
