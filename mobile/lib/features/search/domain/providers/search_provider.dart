import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/search/domain/models/airport.dart';
import 'package:flightly/features/search/domain/repositories/search_repository.dart';
import 'package:flightly/features/search/data/repositories/search_repository_impl.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(dioClient: DioClient.instance());
});

final popularAirportsProvider = FutureProvider<List<Airport>>((ref) async {
  final repo = ref.watch(searchRepositoryProvider);
  return repo.getPopularAirports();
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
