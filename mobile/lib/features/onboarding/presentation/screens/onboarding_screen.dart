import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/constants/app_assets.dart';
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
            color: AppColors.textPrimary,
          ),
      bodyTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
      bodyPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
      pageColor: AppColors.background,
      imagePadding: const EdgeInsets.only(top: 60, bottom: 24),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IntroductionScreen(
          globalBackgroundColor: AppColors.background,
          allowImplicitScrolling: true,
          initialPage: 0,
          pages: [
            PageViewModel(
              title: "Find Your Perfect Flight",
              body: "Explore the world's best destinations with our intelligent search engine. We make discovering your next journey effortless.",
              image: Image.asset(
                AppAssets.welcomeOne,
                errorBuilder: (context, error, stackTrace) => const _IllustrationPlaceholder(
                  icon: LucideIcons.globe,
                  color: AppColors.primary,
                ),
              ),
              decoration: pageDecoration,
            ),
            PageViewModel(
              title: "Compare & Save",
              body: "Seamless booking experience with smart pricing. We compare thousands of flights to get you the absolute best deal.",
              image: Image.asset(
                AppAssets.welcomeTwo,
                errorBuilder: (context, error, stackTrace) => const _IllustrationPlaceholder(
                  icon: LucideIcons.planeTakeoff,
                  color: AppColors.accent,
                ),
              ),
              decoration: pageDecoration,
            ),
            PageViewModel(
              title: "Stay Updated",
              body: "Never miss a flight update. Enable notifications to receive instant alerts about gate changes, delays, and exclusive deals.",
              image: Image.asset(
                AppAssets.welcomeThree,
                errorBuilder: (context, error, stackTrace) => const _IllustrationPlaceholder(
                  icon: LucideIcons.bellRing,
                  color: AppColors.success,
                ),
              ),
              footer: const Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: NotificationPermissionButton(),
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
          back: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textSecondary)),
          next: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 28),
          done: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
          curve: Curves.fastLinearToSlowEaseIn,
          controlsMargin: const EdgeInsets.all(24),
          controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
          dotsDecorator: DotsDecorator(
            size: const Size(10.0, 10.0),
            color: AppColors.lightGray,
            activeSize: const Size(24.0, 10.0),
            activeColor: AppColors.primary,
            activeShape: const RoundedRectangleBorder(
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
