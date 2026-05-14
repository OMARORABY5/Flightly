// main.dart — FLIGHTLY App Entry Point
// Sets up Riverpod, GoRouter, theme, and app startup routing
// WHY: Thin main.dart keeps the entry point clean — all logic is in providers

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flightly/core/theme/app_theme.dart';
import 'package:flightly/core/theme/app_colors.dart';

import 'package:flightly/core/routing/app_router.dart';
import 'package:flightly/core/providers/storage_provider.dart';
import 'package:flightly/features/notifications/services/push_notification_service.dart';
import 'package:flightly/features/notifications/services/travel_reminder_service.dart';
import 'package:flightly/features/saved_flights/services/watchlist_price_monitor.dart';


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
      statusBarIconBrightness: Brightness.dark, // Dark icons on light bg
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize SharedPreferences synchronously before app startup
  final prefs = await SharedPreferences.getInstance();

  runApp(
    // ProviderScope wraps the entire app — required for Riverpod
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FlightlyApp(),
    ),
  );
}

class FlightlyApp extends ConsumerStatefulWidget {
  const FlightlyApp({super.key});

  @override
  ConsumerState<FlightlyApp> createState() => _FlightlyAppState();
}

class _FlightlyAppState extends ConsumerState<FlightlyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize push notifications gracefully
    Future.microtask(() {
      ref.read(pushNotificationServiceProvider).initialize();
      // Initialize travel reminder service with tap-to-navigate callback
      final router = ref.read(appRouterProvider);
      ref.read(travelReminderServiceProvider).initialize(
        onTap: (payload) {
          if (payload == '/watchlist') {
             router.go('/', extra: {'tabIndex': 2});
          } else {
             router.push(payload);
          }
        },
      );
      // Initialize Smart Watchlist daily background task
      ref.read(watchlistPriceMonitorProvider).scheduleDaily();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FLIGHTLY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}


