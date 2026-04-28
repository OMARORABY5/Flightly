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
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:flightly/features/booking/domain/models/passenger.dart';

class BookingOverviewScreen extends ConsumerStatefulWidget {
  final Flight flight;

  const BookingOverviewScreen({super.key, required this.flight});

  @override
  ConsumerState<BookingOverviewScreen> createState() => _BookingOverviewScreenState();
}

class _BookingOverviewScreenState extends ConsumerState<BookingOverviewScreen> {
  bool _termsAccepted = false;
  bool _isCreating = false;

  Future<void> _submitBooking() async {
    if (!_termsAccepted) {
      showTopSnackBar(Overlay.of(context), const CustomSnackBar.error(message: 'Please accept the Terms & Conditions'));
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
        cabinClass: widget.flight.cabinClass,
        passengerIds: selectedPassengers.map((e) => e.id).toList(),
        contactEmail: email,
        contactPhone: phone.isEmpty ? null : phone,
      );

      final repo = ref.read(bookingRepositoryProvider);
      final booking = await repo.createBooking(req);

      // Successfully created booking! Clear selection.
      ref.read(selectedPassengersProvider.notifier).clear();
      ref.read(contactEmailProvider.notifier).state = '';
      ref.read(contactPhoneProvider.notifier).state = '';

      if (!mounted) return;
      
      // Proceed to Payment (Phase 7)
      showTopSnackBar(Overlay.of(context), const CustomSnackBar.success(message: 'Booking reserved! Proceeding to Payment...'));
      
      context.go('/payment', extra: booking); 
      
    } catch (e) {
      showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: e.toString().replaceAll('Exception: ', '')));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPassengers = ref.watch(selectedPassengersProvider);
    final email = ref.watch(contactEmailProvider);
    final phone = ref.watch(contactPhoneProvider);
    final totalPrice = widget.flight.basePrice * selectedPassengers.length;

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
          const AmbientBackground(child: SizedBox()),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildItinerary(),
                    const SizedBox(height: 16),
                    _buildPassengersList(selectedPassengers),
                    const SizedBox(height: 16),
                    _buildContactSummary(email, phone),
                    const SizedBox(height: 16),
                    _buildPricing(selectedPassengers.length, totalPrice),
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
                left: 20, right: 20, top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isCreating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Proceed to Payment', style: AppTextStyles.button),
                ),
              ),
            ),
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
          const SizedBox(height: 12),
          Text('${widget.flight.originIata} → ${widget.flight.destinationIata}', style: AppTextStyles.headingMedium),
          Text(DateFormat('EEEE, MMM dd, yyyy').format(widget.flight.departureTime), style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('HH:mm').format(widget.flight.departureTime)} - ${DateFormat('HH:mm').format(widget.flight.arrivalTime)}',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersList(List<Passenger> selectedPassengers) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Travelers (${selectedPassengers.length})', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          ...selectedPassengers.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.fullName, style: AppTextStyles.bodyMedium),
                Text(p.passportNumber, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          )).toList(),
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

  Widget _buildPricing(int count, double total) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Breakdown', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${count}x ${widget.flight.cabinClass.toUpperCase()} Ticket', style: AppTextStyles.bodyMedium),
              Text('\$${total.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.headingMedium),
              Text('\$${total.toStringAsFixed(2)}', style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
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
