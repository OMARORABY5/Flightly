import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/features/onboarding/presentation/screens/onboarding_screen.dart';
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
import 'package:flightly/features/trips/presentation/screens/trip_detail_screen.dart';
import 'package:flightly/features/trips/domain/models/trip.dart';
import 'package:flightly/features/account/presentation/screens/profile_screen.dart';
import 'package:flightly/features/account/presentation/screens/change_password_screen.dart';
import 'package:flightly/features/account/presentation/screens/settings_screen.dart';
import 'package:flightly/features/account/presentation/screens/my_cards_screen.dart';
import 'package:flightly/features/account/presentation/screens/wallet_screen.dart';
import 'package:flightly/features/trips/presentation/screens/modify_booking_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isOnboardingCompleted = ref.read(onboardingProvider);

  // Use read instead of watch to prevent the router from fully resetting
  // and destroying the navigation stack every time auth state changes (e.g. to Loading)
  final authState = ref.read(authProvider);

  String initial = RouteConstants.onboarding;
  if (isOnboardingCompleted) {
    initial = authState is AuthAuthenticated 
        ? RouteConstants.home 
        : RouteConstants.login;
  }

  return GoRouter(
    initialLocation: initial,
    errorBuilder: (context, state) {
      // silently redirects to login by returning the LoginScreen
      return const LoginScreen();
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteConstants.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteConstants.home,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final tabIndex = extra?['tabIndex'] as int? ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: HomeScreen(initialIndex: tabIndex),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final flight = extra['flight'] as dynamic;
          final returnFlight = extra['returnFlight'] as dynamic;
          return BookingScreen(flight: flight, returnFlight: returnFlight);
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
                  final passenger = state.extra as dynamic;
                  return AddEditPassengerScreen(passenger: passenger);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'overview',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              final flight = extra['flight'] as dynamic;
              final returnFlight = extra['returnFlight'] as dynamic;
              return BookingOverviewScreen(flight: flight, returnFlight: returnFlight);
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
      // Phase 10: Trip detail — receives Trip object via extra
      GoRoute(
        path: '/trips/:id',
        builder: (context, state) {
          final trip = state.extra as Trip;
          return TripDetailScreen(trip: trip);
        },
        routes: [
          GoRoute(
            path: 'modify',
            builder: (context, state) {
              final trip = state.extra as Trip;
              return ModifyBookingScreen(trip: trip);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notification-preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      // Phase 11: Account & Profile Management
      GoRoute(
        path: '/account/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/account/password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/account/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/account/cards',
        builder: (context, state) => const MyCardsScreen(),
      ),
      GoRoute(
        path: '/account/passengers',
        builder: (context, state) => const PassengersScreen(isBookingFlow: false),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
    ],
  );
});
