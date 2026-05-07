// app_assets.dart — FLIGHTLY Asset Paths
// Centralized constants for all static assets (images, icons, animations)
// WHY: Avoids hardcoding strings like 'assets/images/logo.png' everywhere.

class AppAssets {
  AppAssets._();

  // ─── Folders ──────────────────────────────────────────────────────────────
  static const String _imagesPath = 'assets/images';
  static const String _animationsPath = 'assets/animations';
  static const String _iconsPath = 'assets/icons';

  // ─── Images (Updated to match user-added files) ──────────────────────────
  
  // Illustrations for onboarding / landing
  static const String authLanding = '$_imagesPath/Auth Landing.png';
  static const String welcomeOne = '$_imagesPath/Welcome One.png';
  static const String welcomeTwo = '$_imagesPath/Welcome Two.png';
  static const String welcomeThree = '$_imagesPath/Welcome Three.png';

  // Empty state illustrations
  static const String emptySearch = '$_imagesPath/No flights were found.png';
  static const String emptyTrips = '$_imagesPath/No history trip.png';
  static const String emptySaved = '$_imagesPath/No saved flight.png';

  // Placeholders / Other
  static const String backgroundHero = '$_imagesPath/bg_hero.png';
  static const String profilePlaceholder = '$_imagesPath/profile_placeholder.png';
  
  // ─── Animations (Lottie) ──────────────────────────────────────────────────
  static const String animSuccess = '$_animationsPath/success.json';
  static const String animLoading = '$_animationsPath/loading.json';
  static const String animEmpty = '$_animationsPath/empty.json';
  static const String animError = '$_animationsPath/error.json';

  // ─── Icons ────────────────────────────────────────────────────────────────
  static const String icGoogle = '$_iconsPath/google.png';
  static const String icApple = '$_iconsPath/apple.png';
  static const String icFacebook = '$_iconsPath/facebook.png';
}
