// booking_repository.dart
import 'package:flightly/features/booking/domain/models/booking.dart';
import 'package:flightly/features/booking/domain/models/booking_request.dart';
import 'package:flightly/features/booking/domain/models/passenger.dart';

abstract class BookingRepository {
  Future<List<Passenger>> getSavedPassengers(String userId);
  Future<Passenger> addPassenger(Passenger passenger);
  Future<Passenger> updatePassenger(Passenger passenger);
  Future<void> deletePassenger(String passengerId, String userId);
  
  Future<Booking> createBooking(BookingRequest request);
  Future<Booking> getBookingById(String bookingId, String userId);
  Future<List<Booking>> getUserBookings(String userId);
  Future<void> confirmBooking(String bookingId, String userId);
}
