import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/smart_pricing/flight_recommendation_engine.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SmartSuggestionCard extends StatefulWidget {
  final FlightRecommendation recommendation;
  final bool compact;
  final void Function(Flight alternativeFlight)? onViewAlternative;

  const SmartSuggestionCard({
    Key? key,
    required this.recommendation,
    this.compact = false,
    this.onViewAlternative,
  }) : super(key: key);

  @override
  State<SmartSuggestionCard> createState() => _SmartSuggestionCardState();
}

class _SmartSuggestionCardState extends State<SmartSuggestionCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !widget.recommendation.isActionable) {
      return const SizedBox.shrink();
    }

    final isAffirmation = widget.recommendation.type == RecommendationType.bestChoice;

    if (isAffirmation) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recommendation.headline,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.recommendation.subline != null && !widget.compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.recommendation.subline!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.lightbulb, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recommendation.headline,
                        style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary),
                      ),
                      if (widget.recommendation.subline != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.recommendation.subline!,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ]
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _dismissed = true),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (!widget.compact && widget.recommendation.highlights.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...widget.recommendation.highlights.map((highlight) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.check, size: 14, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            highlight,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (widget.recommendation.hasAlternative && widget.onViewAlternative != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onViewAlternative!(widget.recommendation.alternativeFlight!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('View Alternative', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
