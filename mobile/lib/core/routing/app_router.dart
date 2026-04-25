import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/route_constants.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/auth_landing_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isOnboardingCompleted = ref.read(onboardingProvider);

  return GoRouter(
    initialLocation: isOnboardingCompleted 
        ? RouteConstants.authLanding 
        : RouteConstants.onboarding,
    routes: [
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.authLanding,
        builder: (context, state) => const AuthLandingScreen(),
      ),
    ],
  );
});
