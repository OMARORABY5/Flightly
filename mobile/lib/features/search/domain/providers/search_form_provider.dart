import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';

class SearchFormNotifier extends StateNotifier<SearchQuery> {
  SearchFormNotifier() : super(SearchQuery());

  void updateQuery(SearchQuery query) {
    state = query;
  }

  void swapOriginDestination() {
    state = state.copyWith(
      origin: state.destination,
      destination: state.origin,
    );
  }

  /// Clears all fields so the next search starts fresh.
  void reset() {
    state = SearchQuery();
  }
}

final searchFormProvider = StateNotifierProvider<SearchFormNotifier, SearchQuery>((ref) {
  return SearchFormNotifier();
});
