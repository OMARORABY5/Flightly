// trips_provider.dart — Riverpod providers for My Trips feature
// WHY: FutureProvider handles loading/error/data states automatically.
//      Both providers watch authProvider so they invalidate on login/logout.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/features/trips/domain/models/trip.dart';
import 'package:flightly/features/trips/domain/repositories/trips_repository.dart';
import 'package:flightly/features/trips/data/repositories/trips_repository_impl.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────
final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepositoryImpl(dioClient: DioClient.instance());
});

// ─── Upcoming Trips ───────────────────────────────────────────────────────────
// Returns [] if user is not authenticated to avoid pointless API calls
// autoDispose: refreshes automatically every time the screen is revisited
final upcomingTripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  return ref.read(tripsRepositoryProvider).getUpcomingTrips();
});

// ─── History Trips ────────────────────────────────────────────────────────────
final historyTripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];
  return ref.read(tripsRepositoryProvider).getHistoryTrips();
});
