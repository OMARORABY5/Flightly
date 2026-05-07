// trip_detail_screen.dart — FLIGHTLY Trip Detail Screen (Phase 10)
// View-only booking detail. Receives a Trip object via GoRouter extra.
// Shows: full itinerary, passenger count, contact info, booking ref, status.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/trips/domain/models/trip.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

class TripDetailScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  String _formatDate(DateTime dt) => DateFormat('EEEE, d MMMM yyyy').format(dt);
  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);
  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  void _copyReference(BuildContext context) {
    Clipboard.setData(ClipboardData(text: trip.reference));
    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.success(message: 'Booking reference copied!'),
    );
  }

  ({Color bg, Color text, String label}) get _statusConfig {
    if (trip.isCancelled) return (bg: AppColors.error.withValues(alpha: 0.15), text: AppColors.error, label: 'CANCELLED');
    if (trip.isCompleted) return (bg: AppColors.success.withValues(alpha: 0.15), text: AppColors.success, label: 'COMPLETED');
    return (bg: AppColors.primary.withValues(alpha: 0.15), text: AppColors.primary, label: 'UPCOMING');
  }

  @override
  Widget build(BuildContext context) {
    final f = trip.flight;
    final cfg = _statusConfig;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Booking Details', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Reference + Status ─────────────────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Booking Reference', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                trip.reference,
                                style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary, letterSpacing: 1.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _copyReference(context),
                              child: const Icon(LucideIcons.copy, size: 18, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: cfg.bg, borderRadius: BorderRadius.circular(20)),
                    child: Text(cfg.label, style: AppTextStyles.labelSmall.copyWith(color: cfg.text, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Flight Itinerary ───────────────────────────────────────────────
            Text('Outbound Flight', style: AppTextStyles.headingSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Airline row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          f.airlineName,
                          style: AppTextStyles.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(f.flightNumber, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Route
                  Row(
                    children: [
                      // Origin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatTime(f.departureTime), style: AppTextStyles.displayMedium),
                            const SizedBox(height: 2),
                            Text(f.originIata, style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
                            const SizedBox(height: 2),
                            Text(f.originCity ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),

                      // Arrow + duration
                      Column(
                        children: [
                          Text(_formatDuration(f.durationMinutes), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          const Icon(LucideIcons.arrowRight, color: AppColors.primary, size: 22),
                          const SizedBox(height: 4),
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
                            Text(_formatTime(f.arrivalTime), style: AppTextStyles.displayMedium),
                            const SizedBox(height: 2),
                            Text(f.destinationIata, style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
                            const SizedBox(height: 2),
                            Text(f.destinationCity ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceBorder),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _formatDate(f.departureTime),
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _formatDate(f.arrivalTime),
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Booking Summary ────────────────────────────────────────────────
            Text('Booking Summary', style: AppTextStyles.headingSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPassengersSection(),
                  const SizedBox(height: 12),
                  _summaryRow(LucideIcons.armchair, 'Cabin Class', trip.cabinClass.replaceAll('_', ' ').toUpperCase()),
                  const SizedBox(height: 12),
                  _summaryRow(LucideIcons.arrowLeftRight, 'Trip Type', trip.tripType == 'round_trip' ? 'Round Trip' : 'One Way'),
                  const SizedBox(height: 12),
                  _summaryRow(LucideIcons.mail, 'Contact Email', trip.contactEmail),
                  if (trip.contactPhone != null) ...[
                    const SizedBox(height: 12),
                    _summaryRow(LucideIcons.phone, 'Contact Phone', trip.contactPhone!),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.surfaceBorder),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Paid', style: AppTextStyles.labelMedium),
                      Text('\$${trip.totalPrice.toStringAsFixed(2)}', style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.users, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Passengers: ${trip.passengerCount}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
              if (trip.passengers.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...trip.passengers.map((name) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(name, style: AppTextStyles.bodyMedium),
                    )),
              ] else ...[
                const SizedBox(height: 2),
                Text('${trip.passengerCount} passenger${trip.passengerCount > 1 ? 's' : ''}', style: AppTextStyles.bodyMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
