// empty_widget.dart — FLIGHTLY Empty States
// Shown when a list/screen has no data (no trips, no saved flights, etc.)
// WHY: Empty states guide users to take action instead of seeing a blank screen

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppEmptyWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final IconData icon;

  const AppEmptyWidget({
    super.key,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCta,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onCta,
                style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
                child: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
