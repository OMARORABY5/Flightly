import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Basic placeholder for Phase 1. 
    // This will be fully implemented in Phase 2.
    return Scaffold(
      appBar: AppBar(
        title: const Text('FLIGHTLY Auth'),
        automaticallyImplyLeading: false, // Prevent going back to onboarding
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.flight_takeoff,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to FLIGHTLY',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Auth Flow will be built in Phase 2.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                // Placeholder action
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
