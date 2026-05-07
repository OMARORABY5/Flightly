import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/core/constants/app_assets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/widgets/sky_background.dart';
import 'package:flightly/features/home/presentation/screens/home_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AuthLandingScreen extends ConsumerWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkyBackground(
      illustration: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.authLanding,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.flight_takeoff,
              size: 100,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Search, Book and Flight',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Search billions of flights, compare to book flights at right time and travel the world with Lywing.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
      child: Stack(
        children: [
          // Skip button in top right area of the sky (since SkyBackground covers whole screen)
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () {
                ref.read(homeTabProvider.notifier).state = 0;
                context.go(RouteConstants.home);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // White card content
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  // Mock Email Field (just for visual matching Figma)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(color: AppColors.subtitleGray.withOpacity(0.7)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push(RouteConstants.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(double.infinity, 56),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.push(RouteConstants.register),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'Register new account',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Social Buttons
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: Image.asset(AppAssets.icGoogle, width: 24, height: 24, errorBuilder: (c, e, s) => const Icon(LucideIcons.chrome, color: Colors.red)),
                    label: const Text(
                      'Sign up with Google',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
                    label: const Text(
                      'Login with Facebook',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () => context.push(RouteConstants.login),
                        child: const Text(
                          'Login',
                          style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
