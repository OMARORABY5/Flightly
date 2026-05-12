// trips_provider.dart — Riverpod providers for My Trips feature
// WHY: FutureProvider handles loading/error/data states automatically.
//      Both providers watch authProvider so they invalidate on login/logout.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/features/trips/domain/models/trip.dart';
import 'package:flightly/features/trips/domain/models/wallet.dart';
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

// ─── Phase: Modify & Cancel Feature ─────────────────────────────────────────

final cancelBookingProvider = FutureProvider.family.autoDispose<void, String>((ref, bookingId) async {
  return ref.read(tripsRepositoryProvider).cancelBooking(bookingId);
});

final modifyBookingProvider = FutureProvider.family.autoDispose<void, Map<String, dynamic>>((ref, args) async {
  final bookingId = args['bookingId'] as String;
  final payload = args['payload'] as Map<String, dynamic>;
  return ref.read(tripsRepositoryProvider).modifyBooking(bookingId, payload);
});

final walletProvider = FutureProvider.autoDispose<Wallet>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) throw Exception('Not authenticated');
  return ref.read(tripsRepositoryProvider).getWallet();
});
