import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/domain/smart_pricing/flight_value_score.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SmartBadge extends StatelessWidget {
  final SmartBadgeType type;
  final bool showExplanation;

  const SmartBadge({Key? key, required this.type, this.showExplanation = false}) : super(key: key);

  factory SmartBadge.fromLabel(String label, {bool showExplanation = false}) {
    SmartBadgeType? parsedType;
    for (final t in SmartBadgeType.values) {
      if (t.label == label) {
        parsedType = t;
        break;
      }
    }
    // Fallback to recommended if not matched
    return SmartBadge(type: parsedType ?? SmartBadgeType.recommended, showExplanation: showExplanation);
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      // Value & Smart Suggestions
      case SmartBadgeType.bestValue:
      case SmartBadgeType.smartSuggestion:
        bgColor = Colors.amber.withValues(alpha: 0.15);
        iconColor = Colors.amber.shade700;
        icon = LucideIcons.star;
        break;

      // Price
      case SmartBadgeType.cheapest:
      case SmartBadgeType.lowestPrice:
        bgColor = AppColors.success.withValues(alpha: 0.15);
        iconColor = AppColors.success;
        icon = LucideIcons.badgeDollarSign;
        break;

      // Time
      case SmartBadgeType.fastest:
      case SmartBadgeType.shortestDuration:
        bgColor = Colors.blue.withValues(alpha: 0.15);
        iconColor = Colors.blue.shade600;
        icon = LucideIcons.zap;
        break;

      // General Recommendations
      case SmartBadgeType.best:
      case SmartBadgeType.recommended:
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        iconColor = AppColors.primary;
        icon = LucideIcons.award;
        break;

      // Popularity
      case SmartBadgeType.popularChoice:
        bgColor = Colors.purple.withValues(alpha: 0.15);
        iconColor = Colors.purple.shade600;
        icon = LucideIcons.trendingUp;
        break;

      // Urgency / Scarcity
      case SmartBadgeType.limitedSeats:
        bgColor = AppColors.error.withValues(alpha: 0.15);
        iconColor = AppColors.error;
        icon = LucideIcons.alertCircle;
        break;
    }

    final badgePill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (!showExplanation) {
      return badgePill;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        badgePill,
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            type.explanation,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
