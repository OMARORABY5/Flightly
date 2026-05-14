import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';
import 'package:flightly/features/booking/presentation/screens/booking_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class RoundTripSummaryScreen extends ConsumerStatefulWidget {
  final Flight outboundFlight;
  final Flight returnFlight;

  const RoundTripSummaryScreen({
    super.key,
    required this.outboundFlight,
    required this.returnFlight,
  });

  @override
  ConsumerState<RoundTripSummaryScreen> createState() => _RoundTripSummaryScreenState();
}

class _RoundTripSummaryScreenState extends ConsumerState<RoundTripSummaryScreen> {
  bool _isCheckingPrice = false;

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);
  String _formatDate(DateTime date) => DateFormat('EEE, d MMM').format(date);
  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  Future<void> _handleContinue() async {
    setState(() => _isCheckingPrice = true);

    try {
      final repo = ref.read(searchRepositoryProvider);
      // Check price for return flight (outbound was already checked earlier)
      final result = await repo.priceCheck(widget.returnFlight.id, widget.returnFlight.basePrice);

      setState(() => _isCheckingPrice = false);

      if (!mounted) return;

      if (result.unavailable) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.bottomSlide,
          title: 'Flight Unavailable',
          desc: 'The return flight you selected is no longer available. Please choose another one.',
          btnOkOnPress: () => Navigator.pop(context), // Go back to return flight results
          btnOkText: 'Go Back',
        ).show();
        return;
      }

      if (result.priceChanged) {
        final isIncrease = result.difference > 0;
        AwesomeDialog(
          context: context,
          dialogType: isIncrease ? DialogType.warning : DialogType.success,
          animType: AnimType.bottomSlide,
          title: 'Price Updated',
          desc: result.message,
          btnCancelOnPress: () {},
          btnCancelText: 'Cancel',
          btnOkOnPress: _proceedToBooking,
          btnOkText: 'Accept & Continue',
        ).show();
      } else {
        _proceedToBooking();
      }
    } catch (e) {
      setState(() => _isCheckingPrice = false);
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: 'Failed to verify price. Please try again.'),
      );
    }
  }

  void _proceedToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          flight: widget.outboundFlight,
          returnFlight: widget.returnFlight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.outboundFlight.basePrice + widget.returnFlight.basePrice;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Trip Summary', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.surfaceElevated,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AmbientBackground(child: SizedBox.shrink()),
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 56 + 16,
                  left: 20,
                  right: 20,
                  bottom: 120, // space for bottom bar
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Review Your Trip',
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Both flights selected. Ready to book!',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildFlightCard(
                      title: 'Step 1: Outbound Flight',
                      flight: widget.outboundFlight,
                      icon: LucideIcons.planeTakeoff,
                    ),
                    const SizedBox(height: 16),
                    _buildFlightCard(
                      title: 'Step 2: Return Flight',
                      flight: widget.returnFlight,
                      icon: LucideIcons.planeLanding,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).padding.bottom + 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total Trip Price',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                        Text('${totalPrice.toStringAsFixed(0)} EGP',
                            style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isCheckingPrice ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.surfaceElevated,
                      minimumSize: const Size(180, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    icon: _isCheckingPrice
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.arrowRight, size: 18, color: Colors.white),
                    label: _isCheckingPrice
                        ? Text('Checking…', style: AppTextStyles.button)
                        : Text('Continue to Booking', style: AppTextStyles.button),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightCard({required String title, required Flight flight, required IconData icon}) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(flight.airlineName, style: AppTextStyles.labelMedium),
              Text(flight.flightNumber, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatTime(flight.departureTime), style: AppTextStyles.displayLarge),
                    const SizedBox(height: 4),
                    Text(flight.originIata, style: AppTextStyles.headingLarge),
                    const SizedBox(height: 4),
                    Text(flight.originCity ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(_formatDuration(flight.durationMinutes), style: AppTextStyles.labelSmall),
                  const SizedBox(height: 8),
                  const Icon(LucideIcons.arrowRight, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    flight.stops == 0 ? 'Direct' : '${flight.stops} Stop${flight.stops > 1 ? 's' : ''}',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatTime(flight.arrivalTime), style: AppTextStyles.displayLarge),
                    const SizedBox(height: 4),
                    Text(flight.destinationIata, style: AppTextStyles.headingLarge),
                    const SizedBox(height: 4),
                    Text(flight.destinationCity ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
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
              Text('${_formatDate(flight.departureTime)} • ${flight.fareLabel ?? flight.cabinClass.toUpperCase()}',
                  style: AppTextStyles.bodyMedium),
              Text('${flight.basePrice.toStringAsFixed(0)} EGP', style: AppTextStyles.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}
