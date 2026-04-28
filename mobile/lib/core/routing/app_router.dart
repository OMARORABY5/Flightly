import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flightly/features/auth/presentation/screens/auth_landing_screen.dart';
import 'package:flightly/features/auth/presentation/screens/login_screen.dart';
import 'package:flightly/features/auth/presentation/screens/register_screen.dart';
import 'package:flightly/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flightly/features/home/presentation/screens/home_screen.dart';
import 'package:flightly/features/onboarding/providers/onboarding_provider.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/features/booking/presentation/screens/booking_screen.dart';
import 'package:flightly/features/booking/presentation/screens/passengers_screen.dart';
import 'package:flightly/features/booking/presentation/screens/add_edit_passenger_screen.dart';
import 'package:flightly/features/booking/presentation/screens/booking_overview_screen.dart';
import 'package:flightly/features/payment/presentation/screens/payment_screen.dart';
import 'package:flightly/features/payment/presentation/screens/booking_confirmation_screen.dart';
import 'package:flightly/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flightly/features/notifications/presentation/screens/notification_preferences_screen.dart';
import 'package:flutter/material.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isOnboardingCompleted = ref.read(onboardingProvider);

  final authState = ref.watch(authProvider);

  String initial = RouteConstants.onboarding;
  if (isOnboardingCompleted) {
    initial = authState is AuthAuthenticated 
        ? RouteConstants.home 
        : RouteConstants.authLanding;
  }

  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.authLanding,
        builder: (context, state) => const AuthLandingScreen(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteConstants.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) {
          final flight = state.extra as dynamic; // Flight model
          return BookingScreen(flight: flight);
        },
        routes: [
          GoRoute(
            path: 'passengers',
            builder: (context, state) => const PassengersScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddEditPassengerScreen(),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final passenger = state.extra as dynamic; // Passenger model
                  return AddEditPassengerScreen(passenger: passenger);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'overview',
            builder: (context, state) {
              final flight = state.extra as dynamic; // Flight model
              return BookingOverviewScreen(flight: flight);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final booking = state.extra as dynamic; // Booking model
          return PaymentScreen(booking: booking);
        },
        routes: [
          GoRoute(
            path: 'confirmation',
            builder: (context, state) {
              final booking = state.extra as dynamic; // Booking model
              return BookingConfirmationScreen(booking: booking);
            },
          ),
        ],
      ),
      // Placeholder for my-trips
      GoRoute(
        path: '/my-trips',
        builder: (context, state) => const Scaffold(body: Center(child: Text('My Trips Screen (Phase 10)'))),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notification-preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
    ],
  );
});
