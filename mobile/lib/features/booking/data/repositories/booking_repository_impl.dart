// booking_repository_impl.dart
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/booking/domain/models/booking.dart';
import 'package:flightly/features/booking/domain/models/booking_request.dart';
import 'package:flightly/features/booking/domain/models/passenger.dart';
import 'package:flightly/features/booking/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final DioClient _dioClient;

  BookingRepositoryImpl(this._dioClient);

  // ─── Passengers ──────────────────────────────────────────────────────────────
  @override
  Future<List<Passenger>> getSavedPassengers(String userId) async {
    final response = await _dioClient.get('/users/passengers', queryParams: {'user_id': userId});
    if (response.data['success'] == true) {
      final data = response.data['data'] as List;
      return data.map((e) => Passenger.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<Passenger> addPassenger(Passenger passenger) async {
    final response = await _dioClient.post('/users/passengers', data: passenger.toJson());
    if (response.data['success'] == true) {
      return Passenger.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to add passenger');
  }

  @override
  Future<Passenger> updatePassenger(Passenger passenger) async {
    final response = await _dioClient.put('/users/passengers/${passenger.id}', data: passenger.toJson());
    if (response.data['success'] == true) {
      return Passenger.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to update passenger');
  }

  @override
  Future<void> deletePassenger(String passengerId, String userId) async {
    final response = await _dioClient.delete('/users/passengers/$passengerId', queryParams: {'user_id': userId});
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete passenger');
    }
  }

  // ─── Bookings ───────────────────────────────────────────────────────────────
  @override
  Future<Booking> createBooking(BookingRequest request) async {
    final response = await _dioClient.post('/bookings/create', data: request.toJson());
    if (response.data['success'] == true) {
      // The create endpoint returns only a summary. Fetch the full booking to get
      // outbound_flight + passengers so we can display them on the confirmation screen.
      final bookingId = response.data['data']['booking_id'];
      return getBookingById(bookingId, request.userId);
    }
    throw Exception(response.data['message'] ?? 'Failed to create booking');
  }

  @override
  Future<Booking> getBookingById(String bookingId, String userId) async {
    final response = await _dioClient.get('/bookings/$bookingId', queryParams: {'user_id': userId});
    if (response.data['success'] == true) {
      return Booking.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to get booking details');
  }

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    final response = await _dioClient.get('/bookings/', queryParams: {'user_id': userId});
    if (response.data['success'] == true) {
      final data = response.data['data'] as List;
      return data.map((e) => Booking.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> confirmBooking(String bookingId, String userId, {bool useWallet = true}) async {
    final response = await _dioClient.post(
      '/bookings/$bookingId/confirm',
      data: {'user_id': userId, 'use_wallet': useWallet},
    );
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to confirm booking');
    }
  }
}
