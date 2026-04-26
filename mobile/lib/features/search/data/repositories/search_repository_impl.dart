import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/search/domain/models/airport.dart';
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
}
