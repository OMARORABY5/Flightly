// empty_widget.dart — FLIGHTLY Empty States
// Shown when a list/screen has no data (no trips, no saved flights, etc.)
// WHY: Empty states guide users to take action instead of seeing a blank screen,
//      reducing abandonment when there's no content to show.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppEmptyWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final IconData icon;
  final String? imagePath;

  const AppEmptyWidget({
    super.key,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCta,
    this.icon = LucideIcons.inbox,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildIcon(),
              )
            else
              _buildIcon(),
            const SizedBox(height: 24),
            Text(title, style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onCta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(ctaLabel!, style: AppTextStyles.button),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 48),
      ),
    );
  }
}
