// trips_repository.dart — Abstract contract for My Trips data access
import 'package:flightly/features/trips/domain/models/trip.dart';

abstract class TripsRepository {
  Future<List<Trip>> getUpcomingTrips();
  Future<List<Trip>> getHistoryTrips();
}
