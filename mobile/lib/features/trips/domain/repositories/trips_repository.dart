// trips_repository.dart — Abstract contract for My Trips data access
import 'package:flightly/features/trips/domain/models/trip.dart';
import 'package:flightly/features/trips/domain/models/wallet.dart';

abstract class TripsRepository {
  Future<List<Trip>> getUpcomingTrips();
  Future<List<Trip>> getHistoryTrips();
  
  // Phase: Modify & Cancel Feature
  Future<void> cancelBooking(String bookingId);
  Future<void> modifyBooking(String bookingId, Map<String, dynamic> payload);
  Future<Wallet> getWallet();
}
