// route_constants.dart — FLIGHTLY Named Routes
// All app route names in one place
// WHY: Using constants prevents typos in route names and makes refactoring easy

class RouteConstants {
  RouteConstants._();

  // ─── Onboarding ───────────────────────────────────────────────────────────
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';

  // ─── Auth ────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';

  // ─── Main App (Bottom Nav) ────────────────────────────────────────────────
  static const String home = '/home';
  static const String myTrips = '/my-trips';
  static const String watchlist = '/watchlist';
  static const String account = '/account';

  // ─── Search Flow ──────────────────────────────────────────────────────────
  static const String flightResults = '/results';
  static const String flightDetails = '/flight-details';

  // ─── Booking Flow ────────────────────────────────────────────────────────
  static const String booking = '/booking';
  static const String passengers = '/booking/passengers';
  static const String addEditPassenger = '/booking/passengers/edit';
  static const String bookingOverview = '/booking/overview';
  static const String payment = '/payment';
  static const String confirmation = '/confirmation';

  // ─── Notifications ────────────────────────────────────────────────────────
  static const String notifications = '/notifications';

  // ─── Account Screens ──────────────────────────────────────────────────────
  static const String profile = '/account/profile';
  static const String changePassword = '/account/change-password';
  static const String savedFlights = '/account/saved-flights';
  static const String myCards = '/account/my-cards';
  static const String settings = '/account/settings';
  static const String passengersManagement = '/account/passengers';
}
