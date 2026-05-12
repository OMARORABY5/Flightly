import 'package:shared_preferences/shared_preferences.dart';
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/search/domain/models/airport.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/models/filter_options.dart';
import 'package:flightly/features/search/domain/models/price_check_result.dart';
import 'package:flightly/features/search/domain/models/saved_flight.dart';
import 'package:flightly/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final DioClient _dioClient;

  SearchRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<List<Airport>> getPopularAirports() async {
    final response = await _dioClient.get('/flights/airports/popular');
    if (response.data['success'] == true) {
      final data = response.data['data'] as List;
      return data.map((e) => Airport.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<Airport>> searchAirports(String query) async {
    final response = await _dioClient.get('/flights/airports/search', queryParams: {'q': query});
    if (response.data['success'] == true) {
      final data = response.data['data'] as List;
      return data.map((e) => Airport.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableAirlines() async {
    final response = await _dioClient.get('/flights/airlines');
    if (response.data['success'] == true) {
      return List<Map<String, dynamic>>.from(response.data['data']);
    }
    return [];
  }

  @override
  Future<PaginatedFlightResponse> searchFlights({
    required SearchQuery query,
    required FilterOptions filters,
    int page = 1,
  }) async {
    final queryParams = {
      'origin': query.origin!.iataCode,
      'destination': query.destination!.iataCode,
      'date': query.departureDate!.toIso8601String().split('T')[0],
      'cabin': query.cabinClass.name,
      'passengers': query.totalPassengers.toString(),
      'page': page.toString(),
      ...filters.toQueryParams(),
    };

    final response = await _dioClient.get('/flights/search', queryParams: queryParams);
    
    if (response.data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      final simDiscount = prefs.getBool('sim_discount') ?? false;

      if (simDiscount) {
         final data = response.data['data'];
         if (data['flights'] != null) {
            data['flights'] = (data['flights'] as List).map((e) => _applyDiscount(e)).toList();
         }
         return PaginatedFlightResponse.fromJson(data);
      }
      
      return PaginatedFlightResponse.fromJson(response.data['data']);
    }
    return PaginatedFlightResponse(flights: [], page: 1, limit: 20, total: 0, totalPages: 1, hasNext: false, hasPrev: false);
  }

  Map<String, dynamic> _applyDiscount(Map<String, dynamic> json) {
    final modified = Map<String, dynamic>.from(json);
    if (modified['base_price'] != null) {
      modified['base_price'] = (modified['base_price'] as num) * 0.85;
    }
    if (modified['total_price'] != null) {
      modified['total_price'] = (modified['total_price'] as num) * 0.85;
    }
    if (modified['current_price'] != null) {
      modified['current_price'] = (modified['current_price'] as num) * 0.85;
      if (modified['saved_price'] != null) {
         modified['price_difference'] = (modified['current_price'] as num) - (modified['saved_price'] as num);
      }
    }
    return modified;
  }

  // ─── Phase 5: Flight Details & Smart Pricing ───────────────────────────────

  @override
  Future<Flight?> getFlightDetails(String id) async {
    final response = await _dioClient.get('/flights/$id');
    if (response.data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      final simDiscount = prefs.getBool('sim_discount') ?? false;
      var data = response.data['data'];
      if (simDiscount) {
         data = _applyDiscount(data);
      }
      return Flight.fromJson(data);
    }
    return null;
  }

  @override
  Future<PriceCheckResult> priceCheck(String flightId, double seenPrice) async {
    final response = await _dioClient.get(
      '/flights/$flightId/price-check',
      queryParams: {'seen_price': seenPrice.toString()},
    );
    if (response.data['success'] == true) {
      return PriceCheckResult.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Price check failed');
  }

  // ─── Phase 5: Saved Flights (Watchlist) ────────────────────────────────────
  // Note: user_id is hardcoded here for testing. Phase 6 will use the auth token.

  @override
  Future<List<SavedFlight>> getSavedFlights(String userId) async {
    final response = await _dioClient.get('/users/saved-flights', queryParams: {'user_id': userId});
    if (response.data['success'] == true) {
      final data = response.data['data'] as List;
      final prefs = await SharedPreferences.getInstance();
      final simDiscount = prefs.getBool('sim_discount') ?? false;
      
      return data.map((e) {
        if (simDiscount) {
           return SavedFlight.fromJson(_applyDiscount(e));
        }
        return SavedFlight.fromJson(e);
      }).toList();
    }
    return [];
  }

  @override
  Future<bool> saveFlight(String userId, String flightId) async {
    final response = await _dioClient.post(
      '/users/saved-flights',
      data: {'user_id': userId, 'flight_id': flightId},
    );
    return response.data['success'] == true;
  }

  @override
  Future<bool> unsaveFlight(String userId, String flightId) async {
    final response = await _dioClient.delete(
      '/users/saved-flights/$flightId',
      queryParams: {'user_id': userId},
    );
    return response.data['success'] == true;
  }

  @override
  Future<Map<String, dynamic>> checkSaved(String userId, String flightId) async {
    final response = await _dioClient.get(
      '/users/saved-flights/check/$flightId',
      queryParams: {'user_id': userId},
    );
    if (response.data['success'] == true) {
      return response.data['data'];
    }
    return {'is_saved': false};
  }
}
