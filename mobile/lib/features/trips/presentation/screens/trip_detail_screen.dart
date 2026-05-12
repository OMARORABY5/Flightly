// trip_detail_screen.dart — FLIGHTLY Trip Detail Screen (Phase 10)
// View-only booking detail. Receives a Trip object via GoRouter extra.
// Shows: full itinerary, passenger count, contact info, booking ref, status.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/trips/domain/models/trip.dart';
import 'package:flightly/features/trips/domain/providers/trips_provider.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:go_router/go_router.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  // ─── Constants and state variables ──────────────────────────────────────────

  String _formatDate(DateTime dt) => DateFormat('EEEE, d MMMM yyyy').format(dt);
  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);
  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  void _copyReference(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.trip.reference));
    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.success(message: 'Booking reference copied!'),
    );
  }

  ({Color bg, Color text, String label}) get _statusConfig {
    if (widget.trip.isCancelled) return (bg: AppColors.error.withValues(alpha: 0.15), text: AppColors.error, label: 'CANCELLED');
    if (widget.trip.isCompleted) return (bg: AppColors.success.withValues(alpha: 0.15), text: AppColors.success, label: 'COMPLETED');
    return (bg: AppColors.primary.withValues(alpha: 0.15), text: AppColors.primary, label: 'UPCOMING');
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
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
      bottomNavigationBar: widget.trip.isUpcoming ? _buildBottomActions(context) : null,
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showCancelBottomSheet(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel Ticket', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.push('/trips/${widget.trip.id}/modify', extra: widget.trip);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Modify Booking', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateRefundAmount() {
    final now = DateTime.now();
    final hoursUntilDeparture = widget.trip.flight.departureTime.difference(now).inHours;
    
    double feePercent = 0.0;
    if (hoursUntilDeparture <= 0) {
      feePercent = 100;
    } else if (hoursUntilDeparture < 2) {
      feePercent = 70;
    } else if (hoursUntilDeparture < 4) {
      feePercent = 40;
    } else if (hoursUntilDeparture < 8) {
      feePercent = 30;
    } else if (hoursUntilDeparture < 16) {
      feePercent = 20;
    } else if (hoursUntilDeparture < 24) {
      feePercent = 10;
    }

    final feeAmount = (feePercent / 100) * widget.trip.totalPrice;
    return widget.trip.totalPrice - feeAmount;
  }

  void _showCancelBottomSheet(BuildContext context) {
    final refundAmount = _calculateRefundAmount();
    final feeAmount = widget.trip.totalPrice - refundAmount;
    final feePercent = (feeAmount / widget.trip.totalPrice) * 100;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cancel Ticket', style: AppTextStyles.headingMedium),
              const SizedBox(height: 16),
              if (feePercent > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A ${feePercent.toInt()}% cancellation fee applies as the flight departs in less than 24 hours.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Paid', style: AppTextStyles.bodyMedium),
                  Text('\$${widget.trip.totalPrice.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cancellation Fee', style: AppTextStyles.bodyMedium),
                  Text('-\$${feeAmount.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.surfaceBorder),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Refund to Wallet', style: AppTextStyles.labelMedium),
                  Text('\$${refundAmount.toStringAsFixed(2)}', style: AppTextStyles.headingSmall.copyWith(color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'This action cannot be undone.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keep Ticket'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close sheet
                        _performCancellation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performCancellation() async {
    // Show a loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      await ref.read(cancelBookingProvider(widget.trip.id).future);
      if (!mounted) return;
      
      Navigator.pop(context); // Dismiss loading overlay
      
      final refundAmount = _calculateRefundAmount();
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(message: 'Ticket cancelled. \$${refundAmount.toStringAsFixed(2)} refunded to your wallet.'),
      );

      // Invalidate the trips provider so it fetches the fresh lists
      ref.invalidate(upcomingTripsProvider);
      ref.invalidate(historyTripsProvider);

      // Pop back to trips list
      context.pop(); 
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading overlay
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: 'Failed to cancel booking: ${e.toString()}'),
      );
    }
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
              Text('Passengers: ${widget.trip.passengerCount}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
              if (widget.trip.passengers.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...widget.trip.passengers.map((name) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(name, style: AppTextStyles.bodyMedium),
                    )),
              ] else ...[
                const SizedBox(height: 2),
                Text('${widget.trip.passengerCount} passenger${widget.trip.passengerCount > 1 ? 's' : ''}', style: AppTextStyles.bodyMedium),
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
