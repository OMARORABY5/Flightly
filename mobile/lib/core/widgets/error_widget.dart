// error_widget.dart — FLIGHTLY Error States
// Consistent error display with icon, message, and retry button.
// WHY: Users need clear feedback when something goes wrong, and a retry path
//      so they don't feel stuck and abandon the app.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  /// Optional: override the icon shown
  final IconData icon;

  const AppErrorWidget({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = LucideIcons.cloudOff,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated error icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.error, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops!',
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(retryLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact inline error for when only part of the screen fails.
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text('Retry', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
            ),
        ],
      ),
    );
  }
}
