import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/core/theme/app_colors.dart';

import 'package:flightly/features/onboarding/providers/onboarding_provider.dart';
import 'package:flightly/features/onboarding/presentation/widgets/notification_permission_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentPage = 0;

  void _onIntroEnd(BuildContext context, WidgetRef ref) async {
    // Mark onboarding as completed
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (context.mounted) {
      context.go(RouteConstants.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageDecoration = PageDecoration(
      titleTextStyle: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: const Color(0xFF1A2340),
          ),
      bodyTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: const Color(0xFF4A5568),
            height: 1.6,
          ),
      bodyPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
      pageColor: const Color(0xFFF0F4FF),
      imagePadding: const EdgeInsets.only(top: 40, bottom: 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Stack(
          children: [
            IntroductionScreen(
              globalBackgroundColor: const Color(0xFFF0F4FF),
              allowImplicitScrolling: true,
              initialPage: 0,
              onChange: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              pages: [
                PageViewModel(
                  title: "Find Your Perfect Flight",
                  body: "Explore the world's best destinations with our intelligent search engine. We make discovering your next journey effortless.",
                  image: const _OnboardingIllustration('assets/images/Welcome One.png'),
                  decoration: pageDecoration,
                ),
                PageViewModel(
                  title: "Compare & Save",
                  body: "Seamless booking experience with smart pricing. We compare thousands of flights to get you the absolute best deal.",
                  image: const _OnboardingIllustration('assets/images/Welcome Two.png'),
                  decoration: pageDecoration,
                ),
                PageViewModel(
                  title: "Stay Updated",
                  body: "Never miss a flight update. Enable notifications to receive instant alerts about gate changes, delays, and exclusive deals.",
                  image: const _OnboardingIllustration('assets/images/Welcome Three.png'),
                  decoration: pageDecoration,
                ),
              ],
              onDone: () => _onIntroEnd(context, ref),
              onSkip: () => _onIntroEnd(context, ref),
              showSkipButton: _currentPage != 2,
              isProgress: _currentPage != 2,
              showDoneButton: false,
              skipOrBackFlex: 0,
              nextFlex: 0,
              showBackButton: false,
              back: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF4A5568))),
              next: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 28),
              done: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
              curve: Curves.fastLinearToSlowEaseIn,
              controlsMargin: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
              controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
              dotsDecorator: const DotsDecorator(
                size: Size(8.0, 8.0),
                color: Color(0xFFBBCCEE),
                activeSize: Size(24.0, 8.0),
                activeColor: AppColors.primary,
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: _currentPage == 2 ? 40 : -100, // Slide up exactly when needed
              left: 24,
              right: 24,
              child: const NotificationPermissionButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  final String assetPath;

  const _OnboardingIllustration(this.assetPath);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
      ),
    );
  }
}
