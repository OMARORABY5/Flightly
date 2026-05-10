// booking_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/booking/domain/providers/booking_provider.dart';
import 'package:flightly/features/booking/domain/models/booking_request.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:flightly/features/booking/domain/models/passenger.dart';

class BookingOverviewScreen extends ConsumerStatefulWidget {
  /// The outbound flight (always required).
  final Flight flight;

  /// The return flight (only for round-trip bookings).
  final Flight? returnFlight;

  const BookingOverviewScreen({
    super.key,
    required this.flight,
    this.returnFlight,
  });

  @override
  ConsumerState<BookingOverviewScreen> createState() =>
      _BookingOverviewScreenState();
}

class _BookingOverviewScreenState
    extends ConsumerState<BookingOverviewScreen> {
  bool _termsAccepted = false;
  bool _isCreating = false;

  bool get _isRoundTrip => widget.returnFlight != null;

  Future<void> _submitBooking() async {
    if (!_termsAccepted) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(
            message: 'Please accept the Terms & Conditions'),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final selectedPassengers = ref.read(selectedPassengersProvider);
      final email = ref.read(contactEmailProvider);
      final phone = ref.read(contactPhoneProvider);
      final userId = ref.read(currentUserIdProvider);

      final req = BookingRequest(
        userId: userId,
        flightId: widget.flight.id,
        returnFlightId: widget.returnFlight?.id,
        tripType: _isRoundTrip ? 'round_trip' : 'one_way',
        cabinClass: widget.flight.cabinClass,
        passengerIds: selectedPassengers.map((e) => e.id).toList(),
        contactEmail: email,
        contactPhone: phone.isEmpty ? null : phone,
      );

      final repo = ref.read(bookingRepositoryProvider);
      final booking = await repo.createBooking(req);

      ref.read(selectedPassengersProvider.notifier).clear();
      ref.read(contactEmailProvider.notifier).state = '';
      ref.read(contactPhoneProvider.notifier).state = '';

      if (!mounted) return;

      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(
            message: 'Booking reserved! Proceeding to Payment...'),
      );

      context.go('/payment', extra: booking);
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
            message: e.toString().replaceAll('Exception: ', '')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPassengers = ref.watch(selectedPassengersProvider);
    final email = ref.watch(contactEmailProvider);
    final phone = ref.watch(contactPhoneProvider);

    final outboundPrice =
        widget.flight.basePrice * selectedPassengers.length;
    final returnPrice =
        (widget.returnFlight?.basePrice ?? 0.0) * selectedPassengers.length;
    final totalPrice = outboundPrice + returnPrice;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Review Booking', style: AppTextStyles.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: AmbientBackground(child: SizedBox.shrink())),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                    height:
                        MediaQuery.of(context).padding.top + kToolbarHeight + 16),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTripTypeBadge(),
                    const SizedBox(height: 16),
                    _buildItinerary(),
                    const SizedBox(height: 16),
                    _buildPassengersList(selectedPassengers),
                    const SizedBox(height: 16),
                    _buildContactSummary(email, phone),
                    const SizedBox(height: 16),
                    _buildPricing(selectedPassengers.length, outboundPrice,
                        returnPrice, totalPrice),
                    const SizedBox(height: 24),
                    _buildTerms(),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isCreating ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Proceed to Payment', style: AppTextStyles.button),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeBadge() {
    final isRound = _isRoundTrip;
    final color = isRound ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRound ? LucideIcons.arrowLeftRight : LucideIcons.arrowRight,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            isRound ? 'Round-trip' : 'One-way',
            style: AppTextStyles.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerary() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Itinerary', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          _buildLegRow(
            label: _isRoundTrip ? 'Outbound' : null,
            flight: widget.flight,
            icon: LucideIcons.planeTakeoff,
          ),
          if (_isRoundTrip) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: AppColors.surfaceBorder, height: 1),
            ),
            _buildLegRow(
              label: 'Return',
              flight: widget.returnFlight!,
              icon: LucideIcons.planeLanding,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegRow({
    required Flight flight,
    required IconData icon,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(
          '${flight.originIata} → ${flight.destinationIata}',
          style: AppTextStyles.headingMedium,
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMM dd, yyyy').format(flight.departureTime),
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          '${DateFormat('HH:mm').format(flight.departureTime)} – '
          '${DateFormat('HH:mm').format(flight.arrivalTime)}   •   '
          '${flight.airlineName}',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPassengersList(List<Passenger> selectedPassengers) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Travelers (${selectedPassengers.length})',
              style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          ...selectedPassengers.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.fullName, style: AppTextStyles.bodyMedium),
                    Text(p.passportNumber,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContactSummary(String email, String phone) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Information', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          Text(email, style: AppTextStyles.bodyMedium),
          if (phone.isNotEmpty) Text(phone, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildPricing(
      int count, double outboundTotal, double returnTotal, double grand) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Breakdown', style: AppTextStyles.headingSmall),
          const SizedBox(height: 14),
          // Outbound
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${count}x ${widget.flight.cabinClass.toUpperCase()} (Outbound)',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                'EGP ${outboundTotal.toStringAsFixed(0)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          // Return leg (if applicable)
          if (_isRoundTrip) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${count}x ${widget.returnFlight!.cabinClass.toUpperCase()} (Return)',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  'EGP ${returnTotal.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ],
          const Divider(height: 28, color: AppColors.surfaceBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.headingMedium),
              Text(
                'EGP ${grand.toStringAsFixed(0)}',
                style: AppTextStyles.headingMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTerms() {
    return CheckboxListTile(
      value: _termsAccepted,
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        'I agree to the Fare Rules, Privacy Policy, and Terms of Service.',
        style: AppTextStyles.bodySmall,
      ),
      onChanged: (val) => setState(() => _termsAccepted = val ?? false),
    );
  }
}
