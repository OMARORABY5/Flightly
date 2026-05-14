import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/domain/models/saved_flight.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flightly/features/search/presentation/screens/flight_details_screen.dart' as flightly_details;

class SavedFlightCard extends ConsumerWidget {
  final SavedFlight savedFlight;

  const SavedFlightCard({super.key, required this.savedFlight});

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);

  Future<void> _handleRemove(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final repo = ref.read(searchRepositoryProvider);
    try {
      await repo.unsaveFlight(authState.user.id, savedFlight.flight.id);
      ref.invalidate(savedFlightsProvider);
      ref.invalidate(isFlightSavedProvider(savedFlight.flight.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from watchlist')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove flight')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flight = savedFlight.flight;
    final isCheaper = savedFlight.priceDifference < 0;
    final isMoreExpensive = savedFlight.priceDifference > 0;

    // Percentage drop relative to saved price
    final pctChange = savedFlight.savedPrice > 0
        ? ((savedFlight.priceDifference / savedFlight.savedPrice) * 100).abs()
        : 0.0;

    // Deal label tiers
    String? dealLabel;
    if (isCheaper) {
      if (pctChange >= 20) {
        dealLabel = 'Exceptional Deal';
      } else if (pctChange >= 10) {
        dealLabel = 'Great Deal Found';
      } else {
        dealLabel = 'Price Dropped';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCheaper
              ? AppColors.success.withValues(alpha: 0.35)
              : const Color(0xFFCDD5E0),
          width: isCheaper ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCheaper
                ? AppColors.success.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Deal banner (only when cheaper) ───────────────────────────────
          if (isCheaper)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.13),
                    AppColors.success.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.badgeCheck,
                        size: 14, color: AppColors.success),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dealLabel ?? 'Price Dropped',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '−${pctChange.toStringAsFixed(0)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Card body ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Airline and Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.plane,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(flight.airlineName,
                            style: AppTextStyles.labelSmall),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(LucideIcons.moreHorizontal,
                          color: AppColors.textSecondary),
                      color: AppColors.surfaceElevated,
                      onSelected: (value) {
                        if (value == 'view') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  flightly_details.FlightDetailsScreen(
                                flightId: flight.id,
                                seenPrice: savedFlight.currentPrice,
                              ),
                            ),
                          );
                        } else if (value == 'remove') {
                          _handleRemove(context, ref);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'view',
                          child: Row(
                            children: [
                              const Icon(LucideIcons.eye,
                                  size: 18, color: AppColors.textPrimary),
                              const SizedBox(width: 12),
                              Text('View Details',
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(LucideIcons.trash2,
                                  size: 18, color: AppColors.error),
                              const SizedBox(width: 12),
                              Text('Remove',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Times & Route
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatTime(flight.departureTime),
                            style: AppTextStyles.timeDisplay),
                        const SizedBox(height: 2),
                        Text(flight.originIata,
                            style: AppTextStyles.headingMedium
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(_formatDate(flight.departureTime),
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textHint)),
                      ],
                    ),
                    const Icon(LucideIcons.arrowRight,
                        color: AppColors.primary, size: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatTime(flight.arrivalTime),
                            style: AppTextStyles.timeDisplay),
                        const SizedBox(height: 2),
                        Text(flight.destinationIata,
                            style: AppTextStyles.headingMedium
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(_formatDate(flight.arrivalTime),
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.surfaceBorder, height: 1),
                const SizedBox(height: 16),

                // ── Pricing section ───────────────────────────────────────
                if (isCheaper) ...[
                  // Rich drop display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Was price (struck through)
                            Text(
                              'Was ${savedFlight.savedPrice.toStringAsFixed(0)} EGP',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textHint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Savings headline — the big number
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.trendingDown,
                                    size: 18, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'Save ${savedFlight.priceDifference.abs().toStringAsFixed(0)} EGP',
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Current price — dominant right side
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${savedFlight.currentPrice.toStringAsFixed(0)} EGP',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current price',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else if (isMoreExpensive) ...[
                  // Price went up — simple compact display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved at ${savedFlight.savedPrice.toStringAsFixed(0)} EGP',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.trendingUp,
                                  size: 14, color: AppColors.error),
                              const SizedBox(width: 4),
                              Text(
                                '+${savedFlight.priceDifference.abs().toStringAsFixed(0)} EGP',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.error),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${savedFlight.currentPrice.toStringAsFixed(0)} EGP',
                        style: AppTextStyles.headingMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ] else ...[
                  // No change
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'No price change',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${savedFlight.currentPrice.toStringAsFixed(0)} EGP',
                        style: AppTextStyles.headingMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
