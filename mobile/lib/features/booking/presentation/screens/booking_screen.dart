// booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/booking/domain/providers/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flightly/features/booking/domain/models/passenger.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Flight flight;

  const BookingScreen({super.key, required this.flight});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize fields with current provider values if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailController.text = ref.read(contactEmailProvider);
      _phoneController.text = ref.read(contactPhoneProvider);
      
      _emailController.addListener(() {
        ref.read(contactEmailProvider.notifier).state = _emailController.text;
      });
      _phoneController.addListener(() {
        ref.read(contactPhoneProvider.notifier).state = _phoneController.text;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _proceedToOverview() {
    final selectedPassengers = ref.read(selectedPassengersProvider);
    if (selectedPassengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one passenger.')),
      );
      return;
    }
    if (_emailController.text.trim().isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid contact email.')),
      );
      return;
    }

    context.push('/booking/overview', extra: widget.flight);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPassengers = ref.watch(selectedPassengersProvider);
    final totalPrice = widget.flight.basePrice * (selectedPassengers.isEmpty ? 1 : selectedPassengers.length);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Booking', style: AppTextStyles.headingMedium),
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
                    _buildFlightSummary(),
                    const SizedBox(height: 24),
                    _buildPassengersSection(selectedPassengers),
                    const SizedBox(height: 24),
                    _buildContactSection(),
                    const SizedBox(height: 120), // Bottom padding
                  ]),
                ),
              ),
            ],
          ),
          
          // Bottom Sticky Bar
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total (${selectedPassengers.isEmpty ? 1 : selectedPassengers.length} traveler${selectedPassengers.length == 1 ? '' : 's'})', 
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)
                        ),
                        Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    width: 180,
                    child: ElevatedButton(
                      onPressed: _proceedToOverview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Review', style: AppTextStyles.button.copyWith(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightSummary() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.plane, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Flight Summary', style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.flight.originIata} → ${widget.flight.destinationIata}', style: AppTextStyles.headingMedium),
              Text(DateFormat('MMM dd').format(widget.flight.departureTime), style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.flight.airlineName, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPassengersSection(List<Passenger> selectedPassengers) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.users, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Passengers', style: AppTextStyles.headingSmall),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/booking/passengers'),
                child: Text(selectedPassengers.isEmpty ? 'Select' : 'Manage', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedPassengers.isEmpty)
            Text('No passengers selected.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))
          else
            ...selectedPassengers.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(LucideIcons.userCheck, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.fullName, style: AppTextStyles.bodyMedium)),
                  Text(p.passportNumber, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mail, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Contact Details', style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              hintText: 'For e-ticket & updates',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
