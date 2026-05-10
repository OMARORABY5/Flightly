// booking_confirmation_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/booking/domain/models/booking.dart';
import 'package:flightly/features/trips/domain/providers/trips_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final Booking booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Invalidate trips providers so My Trips auto-refreshes on next visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(upcomingTripsProvider);
      ref.invalidate(historyTripsProvider);
    });
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    // Start confetti when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _copyReference() {
    Clipboard.setData(ClipboardData(text: widget.booking.reference));
    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.info(message: 'Booking reference copied to clipboard'),
    );
  }

  void _downloadTicket() {
    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.info(message: 'Download Ticket coming soon!'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false, // User shouldn't be able to go back to payment
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: AmbientBackground(child: SizedBox.shrink())),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSuccessIcon(),
                    const SizedBox(height: 24),
                    Text('Payment Successful!', style: AppTextStyles.headingLarge),
                    const SizedBox(height: 8),
                    Text('Your flight is confirmed.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    // Trip-type badge
                    _buildTripTypeBadge(),
                    const SizedBox(height: 32),
                    _buildReferenceCard(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                    const SizedBox(height: 32),
                    
                    // Buttons
                    ElevatedButton(
                      onPressed: _downloadTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Download Ticket', style: AppTextStyles.button),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/home', extra: {'tabIndex': 1}),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text('Go to My Trips', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/home'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              side: const BorderSide(color: AppColors.textSecondary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text('Go Home', style: AppTextStyles.button.copyWith(color: AppColors.textPrimary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // blast downwards
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(LucideIcons.checkCircle, size: 40, color: AppColors.success),
      ),
    );
  }

  Widget _buildTripTypeBadge() {
    final isRoundTrip = widget.booking.tripType == 'round_trip';
    final color = isRoundTrip ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRoundTrip ? LucideIcons.arrowLeftRight : LucideIcons.arrowRight,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isRoundTrip ? 'Round-trip' : 'One-way',
            style: AppTextStyles.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard() {
    return GestureDetector(
      onTap: _copyReference,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            Text('BOOKING REFERENCE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(widget.booking.reference, style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.copy, size: 18, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final flight = widget.booking.outboundFlight;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${flight.originIata} → ${flight.destinationIata}', style: AppTextStyles.headingSmall),
              const Spacer(),
              Text('\$${widget.booking.totalPrice.toStringAsFixed(2)}', style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(flight.airlineName, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const Divider(height: 24),
          Text('${widget.booking.passengers.length} Passenger${widget.booking.passengers.length == 1 ? '' : 's'}', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          ...widget.booking.passengers.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(p.fullName, style: AppTextStyles.bodyMedium),
          )).toList(),
        ],
      ),
    );
  }
}
