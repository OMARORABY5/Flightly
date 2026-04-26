import 'package:flightly/features/search/domain/models/airport.dart';

abstract class SearchRepository {
  Future<List<Airport>> searchAirports(String query);
  Future<List<Airport>> getPopularAirports();
}
