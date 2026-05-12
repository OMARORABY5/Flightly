import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/domain/smart_pricing/flight_value_score.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SmartBadge extends StatelessWidget {
  final SmartBadgeType type;

  const SmartBadge({Key? key, required this.type}) : super(key: key);

  factory SmartBadge.fromLabel(String label) {
    SmartBadgeType? parsedType;
    for (final t in SmartBadgeType.values) {
      if (t.label == label) {
        parsedType = t;
        break;
      }
    }
    // Fallback to recommended if not matched
    return SmartBadge(type: parsedType ?? SmartBadgeType.recommended);
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case SmartBadgeType.bestValue:
        bgColor = Colors.amber.withOpacity(0.15);
        iconColor = Colors.amber.shade700;
        icon = LucideIcons.star;
        break;
      case SmartBadgeType.cheapest:
        bgColor = AppColors.success.withOpacity(0.15);
        iconColor = AppColors.success;
        icon = LucideIcons.badgeDollarSign;
        break;
      case SmartBadgeType.fastest:
        bgColor = Colors.blue.withOpacity(0.15);
        iconColor = Colors.blue.shade600;
        icon = LucideIcons.zap;
        break;
      case SmartBadgeType.recommended:
        bgColor = AppColors.primary.withOpacity(0.15);
        iconColor = AppColors.primary;
        icon = LucideIcons.award;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
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
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
