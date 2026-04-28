import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/network/dio_client.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:flightly/features/booking/domain/models/passenger.dart';
import 'package:flightly/features/booking/domain/repositories/booking_repository.dart';

// Provides the repository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(DioClient.instance());
});

// A helper to get the current user ID, falling back to test user ID for development
final currentUserIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user.id;
  }
  return '11111111-1111-1111-1111-111111111111'; // Fallback test ID
});

// Provides the list of saved passengers
final savedPassengersProvider = FutureProvider.autoDispose<List<Passenger>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repo.getSavedPassengers(userId);
});

// StateNotifier for selecting passengers for a booking
class SelectedPassengersNotifier extends StateNotifier<List<Passenger>> {
  SelectedPassengersNotifier() : super([]);

  void togglePassenger(Passenger passenger) {
    if (state.any((p) => p.id == passenger.id)) {
      state = state.where((p) => p.id != passenger.id).toList();
    } else {
      state = [...state, passenger];
    }
  }

  void clear() {
    state = [];
  }
}

final selectedPassengersProvider = StateNotifierProvider<SelectedPassengersNotifier, List<Passenger>>((ref) {
  return SelectedPassengersNotifier();
});

// StateProvider for Contact Info
final contactEmailProvider = StateProvider<String>((ref) => '');
final contactPhoneProvider = StateProvider<String>((ref) => '');
