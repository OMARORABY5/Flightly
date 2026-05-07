// connectivity_provider.dart — FLIGHTLY Connectivity Detection
// Detects online/offline status using connectivity_plus and streams changes.
// WHY: The app needs to react immediately when the user goes offline so we can
//      show a banner and disable network-dependent actions.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Stream provider that emits connectivity changes.
/// Returns true when online, false when offline.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
});

/// Provider for the current connectivity status (snapshot).
/// Defaults to true (online) while we don't yet know.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.when(
    data: (isOnline) => isOnline,
    loading: () => true, // Assume online while detecting
    error: (_, __) => true, // Fail open — allow user to try
  );
});
