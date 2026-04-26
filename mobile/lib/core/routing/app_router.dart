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
    ],
  );
});
