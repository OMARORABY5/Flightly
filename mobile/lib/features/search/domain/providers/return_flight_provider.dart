// return_flight_provider.dart
// Stores the user's selected outbound flight during a round-trip booking flow.
// Cleared when a new search begins.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/features/search/domain/models/flight.dart';

/// The outbound flight selected by the user in a round-trip search.
/// Null when no round-trip is in progress.
final selectedOutboundFlightProvider = StateProvider<Flight?>((ref) => null);
