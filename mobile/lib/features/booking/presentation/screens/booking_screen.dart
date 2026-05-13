// booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/booking/domain/providers/booking_provider.dart';
import 'package:flightly/features/booking/presentation/screens/booking_overview_screen.dart';
import 'package:flightly/features/booking/presentation/screens/passengers_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flightly/features/booking/domain/models/passenger.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';
import 'package:flightly/features/search/domain/smart_pricing/smart_pricing_provider.dart';
import 'package:flightly/features/search/presentation/widgets/smart_suggestion_card.dart';

class BookingScreen extends ConsumerStatefulWidget {
  /// The outbound flight (always required).
  final Flight flight;

  /// The return flight (only for round-trip bookings).
  final Flight? returnFlight;

  const BookingScreen({
    super.key,
    required this.flight,
    this.returnFlight,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool get _isRoundTrip => widget.returnFlight != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailController.text = ref.read(contactEmailProvider);
      final savedPhone = ref.read(contactPhoneProvider);
      if (savedPhone.startsWith('+20')) {
        _phoneController.text = savedPhone.substring(3).trim().replaceFirst(RegExp(r'^0+'), '');
      } else {
        _phoneController.text = savedPhone.replaceFirst(RegExp(r'^0+'), '');
      }

      _emailController.addListener(() {
        ref.read(contactEmailProvider.notifier).state = _emailController.text;
      });
      _phoneController.addListener(() {
        final digits = _phoneController.text.trim();
        if (digits.isNotEmpty) {
          ref.read(contactPhoneProvider.notifier).state = '+20$digits';
        } else {
          ref.read(contactPhoneProvider.notifier).state = '';
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob, DateTime flightDate) {
    int age = flightDate.year - dob.year;
    if (flightDate.month < dob.month ||
        (flightDate.month == dob.month && flightDate.day < dob.day)) {
      age--;
    }
    return age;
  }

  void _proceedToOverview() {
    final selectedPassengers = ref.read(selectedPassengersProvider);
    final query = ref.read(searchFormProvider);

    if (selectedPassengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one passenger.')),
      );
      return;
    }

    int actualAdults = 0;
    int actualChildren = 0;
    int actualInfants = 0;

    for (final p in selectedPassengers) {
      final age = _calculateAge(p.dateOfBirth, widget.flight.departureTime);
      if (age >= 12) {
        actualAdults++;
      } else if (age >= 2) {
        actualChildren++;
      } else {
        actualInfants++;
      }
    }

    if (actualAdults != query.adults ||
        actualChildren != query.children ||
        actualInfants != query.infants) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selection mismatch! You need: ${query.adults} Adult(s), '
            '${query.children} Child(ren), ${query.infants} Infant(s).',
          ),
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid contact email.')),
      );
      return;
    }

    final phoneText = _phoneController.text.trim();
    if (phoneText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number.')),
      );
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(phoneText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number contains invalid characters. Please use digits only.')),
      );
      return;
    }

    if (phoneText.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is too short. It must be exactly 10 digits after +20.')),
      );
      return;
    }

    if (phoneText.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is too long. It must be exactly 10 digits after +20.')),
      );
      return;
    }

    if (!phoneText.startsWith('1')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Egyptian mobile number. It should start with 1 (e.g., 10, 11, 12, 15).')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingOverviewScreen(
          flight: widget.flight,
          returnFlight: widget.returnFlight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPassengers = ref.watch(selectedPassengersProvider);
    final recommendation = ref.watch(flightRecommendationProvider(widget.flight.id));
    final pricePerPax = widget.flight.basePrice +
        (widget.returnFlight?.basePrice ?? 0.0);
    final totalPrice =
        pricePerPax * (selectedPassengers.isEmpty ? 1 : selectedPassengers.length);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isRoundTrip ? 'Round-trip Booking' : 'Booking',
          style: AppTextStyles.headingMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AmbientBackground(child: SizedBox.shrink()),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Trip-type badge
                    if (_isRoundTrip) ...[
                      _buildTripTypeBadge(),
                      const SizedBox(height: 16),
                    ],
                    _buildFlightSummary(
                      label: _isRoundTrip ? 'Outbound Flight' : 'Flight',
                      flight: widget.flight,
                    ),
                    if (_isRoundTrip) ...[
                      const SizedBox(height: 12),
                      _buildFlightSummary(
                        label: 'Return Flight',
                        flight: widget.returnFlight!,
                        isReturn: true,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildPassengersSection(selectedPassengers),
                    const SizedBox(height: 24),
                    _buildContactSection(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      // Bottom Sticky Bar handles safe area and keyboard automatically
      bottomNavigationBar: Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (recommendation != null) ...[
                    SmartSuggestionCard(
                      recommendation: recommendation,
                      compact: true,
                      onViewAlternative: (_) {
                        Navigator.pop(context); // Go back to details/results
                      },
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total (${selectedPassengers.isEmpty ? 1 : selectedPassengers.length} traveler${selectedPassengers.length == 1 ? '' : 's'})',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              '${totalPrice.toStringAsFixed(0)} EGP',
                              style: AppTextStyles.displayMedium
                                  .copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _proceedToOverview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(180, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Review',
                            style: AppTextStyles.button.copyWith(fontSize: 18)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTripTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.arrowLeftRight,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Round-trip Booking',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildFlightSummary({
    required String label,
    required Flight flight,
    bool isReturn = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReturn ? LucideIcons.planeLanding : LucideIcons.planeTakeoff,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${flight.originIata} → ${flight.destinationIata}',
                style: AppTextStyles.headingMedium,
              ),
              Text(
                DateFormat('MMM dd').format(flight.departureTime),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                flight.airlineName,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              Text(
                '${DateFormat('HH:mm').format(flight.departureTime)} → ${DateFormat('HH:mm').format(flight.arrivalTime)}',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                flight.cabinClass.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              Text(
                '${flight.basePrice.toStringAsFixed(0)} EGP',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
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
                  const Icon(LucideIcons.users,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Passengers', style: AppTextStyles.headingSmall),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassengersScreen())),
                child: Text(
                  selectedPassengers.isEmpty ? 'Select' : 'Manage',
                  style: AppTextStyles.button
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedPassengers.isEmpty)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(10 * (1 - value), 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.userX, size: 20, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please select at least one passenger to continue.',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            ...selectedPassengers.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.userCheck,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(p.fullName,
                              style: AppTextStyles.bodyMedium)),
                      Text(p.passportNumber,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _NoLeadingZeroFormatter(),
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              hintText: '101 234 5678',
              prefixIcon: Container(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('+20', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 24, color: AppColors.surfaceBorder),
                  ],
                ),
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.startsWith('0')) {
      final newText = newValue.text.replaceFirst(RegExp(r'^0+'), '');
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    return newValue;
  }
}
