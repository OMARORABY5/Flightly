import 'package:flightly/features/search/domain/models/airport.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/models/filter_options.dart';
import 'package:flightly/features/search/domain/models/price_check_result.dart';
import 'package:flightly/features/search/domain/models/saved_flight.dart';

abstract class SearchRepository {
  Future<List<Airport>> searchAirports(String query);
  Future<List<Airport>> getPopularAirports();
  Future<List<Map<String, dynamic>>> getAvailableAirlines();
  Future<PaginatedFlightResponse> searchFlights({
    required SearchQuery query,
    required FilterOptions filters,
    int page = 1,
  });

  // Phase 5
  Future<Flight?> getFlightDetails(String id);
  Future<PriceCheckResult> priceCheck(String flightId, double seenPrice);
  Future<List<SavedFlight>> getSavedFlights(String userId);
  Future<bool> saveFlight(String userId, String flightId);
  Future<bool> unsaveFlight(String userId, String flightId);
  Future<Map<String, dynamic>> checkSaved(String userId, String flightId);
}
