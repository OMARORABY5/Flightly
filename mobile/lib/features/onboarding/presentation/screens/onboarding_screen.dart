import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/features/onboarding/providers/onboarding_provider.dart';
import 'package:flightly/features/onboarding/presentation/widgets/notification_permission_button.dart';

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
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
      bodyTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Theme.of(context).scaffoldBackgroundColor,
      imagePadding: EdgeInsets.zero,
    );

    return Scaffold(
      body: IntroductionScreen(
        globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
        allowImplicitScrolling: true,
        autoScrollDuration: 0,
        infiniteAutoScroll: false,
        pages: [
          PageViewModel(
            title: "Find Your Perfect Flight",
            body: "Explore the world's best destinations with our intelligent search engine. We make discovering your next journey effortless.",
            image: const _IllustrationPlaceholder(icon: LucideIcons.globe),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Compare & Save",
            body: "Seamless booking experience with smart pricing. We compare thousands of flights to get you the absolute best deal.",
            image: const _IllustrationPlaceholder(icon: LucideIcons.planeTakeoff),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Stay Updated",
            body: "Never miss a flight update. Enable notifications to receive instant alerts about gate changes, delays, and exclusive deals.",
            image: const _IllustrationPlaceholder(icon: LucideIcons.bellRing),
            footer: Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: const NotificationPermissionButton(),
            ),
            decoration: pageDecoration,
          ),
        ],
        onDone: () => _onIntroEnd(context, ref),
        onSkip: () => _onIntroEnd(context, ref), // You can override onSkip callback
        showSkipButton: true,
        skipOrBackFlex: 0,
        nextFlex: 0,
        showBackButton: false,
        back: const Icon(Icons.arrow_back),
        skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
        next: const Icon(Icons.arrow_forward),
        done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
        curve: Curves.fastLinearToSlowEaseIn,
        controlsMargin: const EdgeInsets.all(16),
        controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
        dotsDecorator: const DotsDecorator(
          size: Size(10.0, 10.0),
          color: AppColors.surface,
          activeSize: Size(22.0, 10.0),
          activeColor: AppColors.primary,
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
      ),
    );
  }
}

class _IllustrationPlaceholder extends StatelessWidget {
  final IconData icon;

  const _IllustrationPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 100,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
