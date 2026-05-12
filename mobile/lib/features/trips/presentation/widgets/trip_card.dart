// trip_card.dart — FLIGHTLY Trip Card Widget
// Displays a single booking summary in the My Trips list.
// Shows: route, airline, dates/times, booking ref, status badge.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/trips/domain/models/trip.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const TripCard({super.key, required this.trip, required this.onTap});

  String _formatDate(DateTime dt) => DateFormat('d MMM yyyy').format(dt);
  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);
  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  // ─── Status badge config ──────────────────────────────────────────────────
  ({Color bg, Color text, IconData icon, String label}) get _statusConfig {
    if (trip.isCancelled) {
      return (bg: AppColors.error.withValues(alpha: 0.15), text: AppColors.error, icon: LucideIcons.xCircle, label: 'Cancelled');
    }
    if (trip.isCompleted) {
      return (bg: AppColors.success.withValues(alpha: 0.15), text: AppColors.success, icon: LucideIcons.checkCircle, label: 'Completed');
    }
    return (bg: AppColors.primary.withValues(alpha: 0.15), text: AppColors.primary, icon: LucideIcons.clock, label: 'Upcoming');
  }

  @override
  Widget build(BuildContext context) {
    final f = trip.flight;
    final cfg = _statusConfig;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            // ── Header: airline + status badge ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.plane, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(f.airlineName, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      Text('· ${f.flightNumber}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cfg.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cfg.icon, size: 12, color: cfg.text),
                        const SizedBox(width: 4),
                        Text(cfg.label, style: AppTextStyles.labelSmall.copyWith(color: cfg.text, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Route display ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Origin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.originIata, style: AppTextStyles.displayMedium),
                        const SizedBox(height: 2),
                        Text(_formatTime(f.departureTime), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        Text(_formatDate(f.departureTime), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                      ],
                    ),
                  ),

                  // Middle: duration + arrow
                  Column(
                    children: [
                      Text(_formatDuration(f.durationMinutes), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(width: 40, height: 1, color: AppColors.surfaceBorder),
                          const Icon(LucideIcons.plane, size: 16, color: AppColors.primary),
                          Container(width: 40, height: 1, color: AppColors.surfaceBorder),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f.stops == 0 ? 'Direct' : '${f.stops} stop${f.stops > 1 ? 's' : ''}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),

                  // Destination
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(f.destinationIata, style: AppTextStyles.displayMedium),
                        const SizedBox(height: 2),
                        Text(_formatTime(f.arrivalTime), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        Text(_formatDate(f.arrivalTime), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer: booking ref + passengers + price ─────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.reference, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '${trip.passengerCount} passenger${trip.passengerCount > 1 ? 's' : ''} · ${trip.cabinClass.replaceAll('_', ' ').toUpperCase()}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (trip.isCancelled && trip.refundAmount != null)
                        Text('Refunded: \$${trip.refundAmount!.toStringAsFixed(2)}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error))
                      else
                        Text('\$${trip.totalPrice.toStringAsFixed(2)}', style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('View details', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
