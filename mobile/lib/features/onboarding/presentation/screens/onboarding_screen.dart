import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/features/onboarding/providers/onboarding_provider.dart';
import 'package:flightly/features/onboarding/presentation/widgets/notification_permission_button.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  void _onIntroEnd(BuildContext context, WidgetRef ref) async {
    // Mark onboarding as completed
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (context.mounted) {
      context.go(RouteConstants.authLanding);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageDecoration = PageDecoration(
      titleTextStyle: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
      bodyTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
      bodyPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
      pageColor: Colors.transparent, // Let AmbientBackground show through
      imagePadding: const EdgeInsets.only(bottom: 24),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: IntroductionScreen(
          globalBackgroundColor: Colors.transparent,
          allowImplicitScrolling: true,
          autoScrollDuration: 0,
          infiniteAutoScroll: false,
          pages: [
            PageViewModel(
              title: "Find Your Perfect Flight",
              body: "Explore the world's best destinations with our intelligent search engine. We make discovering your next journey effortless.",
              image: const _IllustrationPlaceholder(
                icon: LucideIcons.globe,
                color: AppColors.primary,
              ),
              decoration: pageDecoration,
            ),
            PageViewModel(
              title: "Compare & Save",
              body: "Seamless booking experience with smart pricing. We compare thousands of flights to get you the absolute best deal.",
              image: const _IllustrationPlaceholder(
                icon: LucideIcons.planeTakeoff,
                color: AppColors.accent,
              ),
              decoration: pageDecoration,
            ),
            PageViewModel(
              title: "Stay Updated",
              body: "Never miss a flight update. Enable notifications to receive instant alerts about gate changes, delays, and exclusive deals.",
              image: const _IllustrationPlaceholder(
                icon: LucideIcons.bellRing,
                color: AppColors.success,
              ),
              footer: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: const NotificationPermissionButton(),
              ),
              decoration: pageDecoration,
            ),
          ],
          onDone: () => _onIntroEnd(context, ref),
          onSkip: () => _onIntroEnd(context, ref),
          showSkipButton: true,
          skipOrBackFlex: 0,
          nextFlex: 0,
          showBackButton: false,
          back: const Icon(Icons.arrow_back, color: Colors.white),
          skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          next: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ),
          done: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          curve: Curves.fastLinearToSlowEaseIn,
          controlsMargin: const EdgeInsets.all(24),
          controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
          dotsDecorator: DotsDecorator(
            size: const Size(8.0, 8.0),
            color: AppColors.white.withValues(alpha: 0.2),
            activeSize: const Size(32.0, 8.0),
            activeColor: Colors.white,
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A highly stylized, multi-layered glowing icon container to serve as 
/// a premium placeholder illustration.
class _IllustrationPlaceholder extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IllustrationPlaceholder({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          // Inner translucent container
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          // Core Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 56,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
