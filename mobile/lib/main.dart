// main.dart — FLIGHTLY App Entry Point
// Sets up Riverpod, GoRouter, theme, and app startup routing
// WHY: Thin main.dart keeps the entry point clean — all logic is in providers

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';

// ─── Feature screen imports (will be filled in per phase) ────────────────────
// Phase 1: Onboarding
// import 'features/onboarding/presentation/screens/onboarding_screen.dart';
// Phase 2: Auth
// import 'features/auth/presentation/screens/auth_landing_screen.dart';
// etc.


void main() async {
  // Ensure Flutter engine is initialized before we access platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation (flight booking app is portrait-only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar with dark icons on the app's dark background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Light icons on dark bg
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Check first-launch state to determine initial route
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;

  runApp(
    // ProviderScope wraps the entire app — required for Riverpod
    ProviderScope(
      child: FlightlyApp(showOnboarding: !onboardingCompleted),
    ),
  );
}

class FlightlyApp extends StatelessWidget {
  final bool showOnboarding;

  const FlightlyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLIGHTLY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,

      // Initial route based on onboarding state
      // Phase 1 will replace this with GoRouter
      home: showOnboarding ? const _PlaceholderScreen(label: 'Onboarding') : const _PlaceholderScreen(label: 'Auth Landing'),
    );
  }
}

// ─── Temporary placeholder screen ────────────────────────────────────────────
// This will be replaced by real screens starting Phase 1
class _PlaceholderScreen extends StatelessWidget {
  final String label;

  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FLIGHTLY logo placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'FLIGHTLY',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phase 0 — $label (coming in next phase)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
