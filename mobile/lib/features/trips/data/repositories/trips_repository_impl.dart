// trips_repository_impl.dart — Concrete implementation of TripsRepository
// Calls the booking-service authenticated endpoints added in Phase 10 backend.
// WHY: Separated from the domain layer so we can swap the data source without
//      touching the UI or provider layers.

import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/trips/domain/models/trip.dart';
import 'package:flightly/features/trips/domain/models/wallet.dart';
import 'package:flightly/features/trips/domain/repositories/trips_repository.dart';

class TripsRepositoryImpl implements TripsRepository {
  final DioClient _dioClient;

  TripsRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<List<Trip>> getUpcomingTrips() async {
    // JWT is automatically attached by DioClient's _AuthInterceptor
    final response = await _dioClient.get('/bookings/user/upcoming');
    if (response.data['success'] == true) {
      final data = response.data['data'] as List;
      return data.map((e) => Trip.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<Trip>> getHistoryTrips() async {
    final response = await _dioClient.get('/bookings/user/history');
    if (response.data['success'] == true) {
      final data = response.data['data'] as List;
      return data.map((e) => Trip.fromJson(e)).toList();
    }
    return [];
  }

  // ─── Phase: Modify & Cancel Feature ─────────────────────────────────────────

  @override
  Future<void> cancelBooking(String bookingId) async {
    final response = await _dioClient.post('/bookings/$bookingId/cancel');
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to cancel booking');
    }
  }

  @override
  Future<void> modifyBooking(String bookingId, Map<String, dynamic> payload) async {
    final response = await _dioClient.patch('/bookings/$bookingId', data: payload);
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to modify booking');
    }
  }

  @override
  Future<Wallet> getWallet() async {
    final response = await _dioClient.get('/bookings/wallet');
    if (response.data['success'] == true) {
      return Wallet.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch wallet');
  }
}
