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
    
    Color differenceColor = AppColors.textSecondary;
    IconData? differenceIcon;
    
    if (isCheaper) {
      differenceColor = AppColors.success;
      differenceIcon = LucideIcons.trendingDown;
    } else if (isMoreExpensive) {
      differenceColor = AppColors.error;
      differenceIcon = LucideIcons.trendingUp;
    }

    return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Airline and Menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.plane, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(flight.airlineName, style: AppTextStyles.labelSmall),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.moreHorizontal, color: AppColors.textSecondary),
                    color: AppColors.surfaceElevated,
                    onSelected: (value) {
                      if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => flightly_details.FlightDetailsScreen(
                              flightId: flight.id,
                              seenPrice: savedFlight.currentPrice,
                            ),
                          ),
                        );
                      } else if (value == 'remove') {
                        _handleRemove(context, ref);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.eye, size: 18, color: AppColors.textPrimary),
                            const SizedBox(width: 12),
                            Text('View Details', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'remove',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                            const SizedBox(width: 12),
                            Text('Remove', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Route
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(flight.originIata, style: AppTextStyles.headingLarge),
                  const Icon(LucideIcons.arrowRight, color: AppColors.primary, size: 20),
                  Text(flight.destinationIata, style: AppTextStyles.headingLarge),
                ],
              ),
              const SizedBox(height: 8),
              
              // Date & Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatTime(flight.departureTime), style: AppTextStyles.bodyMedium),
                      Text(_formatDate(flight.departureTime), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatTime(flight.arrivalTime), style: AppTextStyles.bodyMedium),
                      Text(_formatDate(flight.arrivalTime), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              const SizedBox(height: 16),
              
              // Pricing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved at ${savedFlight.savedPrice.toStringAsFixed(2)} EGP', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (differenceIcon != null) ...[
                            Icon(differenceIcon, size: 14, color: differenceColor),
                            const SizedBox(width: 4),
                            Text(
                              '${savedFlight.priceDifference.abs().toStringAsFixed(2)} EGP',
                              style: AppTextStyles.labelSmall.copyWith(color: differenceColor),
                            ),
                          ] else ...[
                            Text('No price change', style: AppTextStyles.labelSmall.copyWith(color: differenceColor)),
                          ]
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${savedFlight.currentPrice.toStringAsFixed(2)} EGP',
                    style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}
