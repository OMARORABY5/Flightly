// trip_card.dart — FLIGHTLY Trip Card Widget
// Displays a single booking summary in the My Trips list.
// Supports both one-way (single leg) and round-trip (two legs) cards.

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
    final cfg = _statusConfig;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCDD5E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header: trip type + status badge ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        trip.isRoundTrip ? LucideIcons.arrowLeftRight : LucideIcons.arrowRight,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trip.isRoundTrip ? 'Round Trip' : 'One Way',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text('· ${trip.flight.airlineName}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
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

            // ── Outbound leg ─────────────────────────────────────────────────
            if (trip.isRoundTrip)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.planeTakeoff, size: 11, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Outbound', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            _buildFlightLegRow(trip.flight),

            // ── Return leg (round-trip only) ─────────────────────────────────
            if (trip.isRoundTrip && trip.returnFlight != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: AppColors.surfaceBorder.withValues(alpha: 0.6), height: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.planeLanding, size: 11, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text('Return', style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildFlightLegRow(trip.returnFlight!),
            ],

            // ── Footer: booking ref + passengers + price ─────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Color(0xFFCDD5E0), width: 1)),
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
                        Text('Refunded: ${trip.refundAmount!.toStringAsFixed(2)} EGP', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error))
                      else
                        Text('${trip.totalPrice.toStringAsFixed(2)} EGP', style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary)),
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

  Widget _buildFlightLegRow(TripFlight f) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Origin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatTime(f.departureTime), style: AppTextStyles.timeDisplay),
                const SizedBox(height: 2),
                Text(f.originIata, style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
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
                  Container(width: 36, height: 1, color: AppColors.surfaceBorder),
                  const Icon(LucideIcons.plane, size: 16, color: AppColors.primary),
                  Container(width: 36, height: 1, color: AppColors.surfaceBorder),
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
                Text(_formatTime(f.arrivalTime), style: AppTextStyles.timeDisplay),
                const SizedBox(height: 2),
                Text(f.destinationIata, style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(_formatDate(f.arrivalTime), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
