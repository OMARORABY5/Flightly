// app_constants.dart — FLIGHTLY Global Constants
// API URLs, timeouts, pagination sizes, and other magic numbers
// WHY: Avoiding magic numbers makes code maintainable and easy to update
import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // ─── API Configuration ────────────────────────────────────────────────────
  // Dynamically points to the correct local address depending on the platform:
  // Web (Chrome) uses localhost. Android Emulator uses 10.0.2.2.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:80/api'; // Chrome / Web
    }
    // TODO: For iOS simulator, use 'http://localhost:80/api'
    // TODO: For physical devices, use your local network IP (e.g., http://192.168.1.X:80/api)
    return 'http://10.0.2.2:80/api'; // Android Emulator
  }

  // ─── Request Timeouts ────────────────────────────────────────────────────
  static const int connectTimeoutSeconds = 10;   // Connection timeout
  static const int receiveTimeoutSeconds = 30;   // Receive timeout (spec: 30s max)
  static const int sendTimeoutSeconds = 30;      // Upload timeout

  // ─── Authentication ───────────────────────────────────────────────────────
  static const String jwtStorageKey = 'flightly_jwt_token';
  static const String userIdStorageKey = 'flightly_user_id';
  static const int loginDebounceSeconds = 2;     // Prevent double-tap login
  static const int registerDebounceSeconds = 3;  // Prevent double-tap register

  // ─── Search ───────────────────────────────────────────────────────────────
  static const int airportSearchDebounceMs = 300; // Debounce for airport autocomplete
  static const int maxSearchHistory = 10;          // Max recent searches to save
  static const int maxPassengers = 8;              // Max total passengers
  static const int minAdults = 1;                  // Always at least 1 adult

  // ─── Pagination ───────────────────────────────────────────────────────────
  static const int flightResultsPageSize = 20;    // Flights per page in results

  // ─── SharedPreferences Keys ───────────────────────────────────────────────
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyFirstLaunchCompleted = 'first_launch_completed';
  static const String keyNotificationPermissionStatus = 'notification_permission_status';
  static const String keySearchHistory = 'search_history';
  static const String keyLanguage = 'app_language';
  static const String keyCountry = 'app_country';
  static const String keyGuestMode = 'is_guest_mode';

  // ─── Animation Durations ─────────────────────────────────────────────────
  static const int animationFastMs = 200;
  static const int animationNormalMs = 350;
  static const int animationSlowMs = 500;
  static const int confettiDurationMs = 3500;    // Booking confirmation confetti
  static const int paymentSimulationMs = 2000;   // Dummy payment processing delay

  // ─── Validation ───────────────────────────────────────────────────────────
  static const int passwordMinLength = 8;
  static const int passportMinLength = 6;
  static const int passportMaxLength = 12;
}
