// my_cards_screen.dart — FLIGHTLY My Cards Screen
// Dummy screen for saved payment methods.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';

class MyCardsScreen extends StatelessWidget {
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('My Cards', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Icon(LucideIcons.creditCard, size: 60, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Text('No saved cards', style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Saving payment methods will be available in a future update.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.plus, size: 20),
                label: Text('Add Card', style: AppTextStyles.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceBorder,
                  foregroundColor: AppColors.textSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Coming Soon', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
