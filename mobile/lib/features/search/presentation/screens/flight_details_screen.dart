import 'package:flutter/material.dart';
import 'package:flightly/core/presentation/widgets/premium_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flightly/features/booking/presentation/screens/booking_screen.dart';
import 'package:flightly/features/search/presentation/screens/return_flight_results_screen.dart';
import 'package:flightly/features/search/presentation/screens/round_trip_summary_screen.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/smart_pricing/smart_pricing_provider.dart';
import 'package:flightly/features/search/presentation/widgets/smart_suggestion_card.dart';

class FlightDetailsScreen extends ConsumerStatefulWidget {
  final String flightId;
  final double seenPrice;

  /// When set, this screen is acting as the return-flight details page.
  /// The CTA will navigate to RoundTripSummaryScreen with both flights.
  final Flight? outboundFlight;

  const FlightDetailsScreen({
    super.key,
    required this.flightId,
    required this.seenPrice,
    this.outboundFlight,
  });

  @override
  ConsumerState<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends ConsumerState<FlightDetailsScreen> {
  bool _isCheckingPrice = false;
  bool? _optimisticSavedState;

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);
  String _formatDate(DateTime date) => DateFormat('EEE, d MMM').format(date);
  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  Future<void> _toggleSave(bool isCurrentlySaved) async {
    setState(() {
      _optimisticSavedState = !isCurrentlySaved;
    });

    final repo = ref.read(searchRepositoryProvider);
    const testUserId = '11111111-1111-1111-1111-111111111111';

    try {
      if (isCurrentlySaved) {
        await repo.unsaveFlight(testUserId, widget.flightId);
      } else {
        await repo.saveFlight(testUserId, widget.flightId);
      }
      ref.invalidate(isFlightSavedProvider(widget.flightId));
      ref.invalidate(savedFlightsProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticSavedState = isCurrentlySaved; // revert on fail
        });
      }
    }
  }

  Future<void> _handleBookNow() async {
    setState(() => _isCheckingPrice = true);

    try {
      final repo = ref.read(searchRepositoryProvider);
      final result = await repo.priceCheck(widget.flightId, widget.seenPrice);

      setState(() => _isCheckingPrice = false);

      if (!mounted) return;

      if (result.unavailable) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.bottomSlide,
          title: 'Flight Unavailable',
          desc: result.message,
          btnOkOnPress: () {},
          btnOkText: 'OK',
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
    final flight = ref.read(flightDetailsProvider(widget.flightId)).value;
    if (flight == null) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: 'Error: Flight details not loaded'),
      );
      return;
    }

    // ── Return-flight context: go directly to trip summary ────────────────
    if (widget.outboundFlight != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoundTripSummaryScreen(
            outboundFlight: widget.outboundFlight!,
            returnFlight: flight,
          ),
        ),
      );
      return;
    }

    final query = ref.read(searchFormProvider);

    if (query.tripType == TripType.roundTrip) {
      // Navigate to select return flight
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReturnFlightResultsScreen(outboundFlight: flight),
        ),
      );
    } else {
      // ── Navigate to booking ──
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingScreen(
            flight: flight,
          ),
        ),
      );
    }
  }

  /// Label for the primary action button.
  String get _buttonLabel {
    // Return-flight context
    if (widget.outboundFlight != null) return 'Confirm Return Flight';
    final query = ref.read(searchFormProvider);
    if (query.tripType == TripType.roundTrip) return 'Choose Return';
    return 'Book Now';
  }

  /// Icon shown beside the button label.
  IconData get _buttonIcon {
    if (widget.outboundFlight != null) return LucideIcons.planeLanding;
    final query = ref.read(searchFormProvider);
    if (query.tripType == TripType.roundTrip) return LucideIcons.arrowLeftRight;
    return LucideIcons.plane;
  }

  @override
  Widget build(BuildContext context) {
    final flightAsync = ref.watch(flightDetailsProvider(widget.flightId));
    final savedAsync = ref.watch(isFlightSavedProvider(widget.flightId));
    final recommendation = widget.outboundFlight != null 
        ? ref.watch(returnFlightRecommendationProvider(widget.flightId))
        : ref.watch(flightRecommendationProvider(widget.flightId));
    
    // Use optimistic state if available, otherwise fall back to backend state
    final isSaved = _optimisticSavedState ?? (savedAsync.value?['is_saved'] == true);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PremiumAppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                key: ValueKey<bool>(isSaved),
                color: isSaved ? AppColors.error : AppColors.textSecondary,
              ),
            ),
            onPressed: () => _toggleSave(isSaved),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AmbientBackground(child: SizedBox.shrink()),
          flightAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('Error loading details', style: AppTextStyles.bodyLarge),
            ),
            data: (flight) {
              if (flight == null) {
                return const Center(child: Text('Flight not found'));
              }
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.top + kToolbarHeight + 16 + 16, // PremiumAppBar height + padding
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildFlightHeader(flight),
                        const SizedBox(height: 24),
                        if (flight.seatAvailability != null || flight.priceTrend != null)
                          _buildSmartPricingBanner(flight),
                        const SizedBox(height: 24),
                        _buildTripDetails(flight),
                        const SizedBox(height: 24),
                        _buildBaggageAndClass(flight),
                        const SizedBox(height: 24),
                        _buildPolicies(flight),
                        const SizedBox(height: 24),
                        if (recommendation != null) ...[
                          SmartSuggestionCard(
                            recommendation: recommendation,
                            onViewAlternative: (altFlight) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FlightDetailsScreen(
                                    flightId: altFlight.id,
                                    seenPrice: altFlight.totalPrice,
                                    outboundFlight: widget.outboundFlight, // Pass the outbound flight if we are in return mode
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 120), // Padding for bottom booking bar
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      // ── Sticky Bottom Bar via bottomNavigationBar ─────────────────────────
      bottomNavigationBar: flightAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (flight) {
          if (flight == null) return const SizedBox.shrink();
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price + CTA row
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
                            Text(
                              'Price',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              '${flight.basePrice.toStringAsFixed(0)} EGP',
                              style: AppTextStyles.displayMedium
                                  .copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                          onPressed: _isCheckingPrice ? null : _handleBookNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.surfaceElevated,
                            minimumSize: const Size(160, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          icon: _isCheckingPrice
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(_buttonIcon, size: 18, color: Colors.white),
                          label: _isCheckingPrice
                              ? Text('Checking…', style: AppTextStyles.button)
                              : Text(_buttonLabel, style: AppTextStyles.button),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildFlightHeader(Flight flight) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(flight.airlineName, style: AppTextStyles.labelMedium),
              Text(flight.flightNumber, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Origin
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

              // Arrow
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

              // Destination
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
          const SizedBox(height: 20),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(flight.departureTime), style: AppTextStyles.bodyMedium),
              Text(_formatDate(flight.arrivalTime), style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartPricingBanner(Flight flight) {
    bool isRising = flight.priceTrend == 'rising';
    bool isCritical = flight.seatAvailability == 'critical';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical
            ? AppColors.error.withValues(alpha: 0.1)
            : (isRising ? AppColors.warning.withValues(alpha: 0.1) : AppColors.accent.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical
              ? AppColors.error.withValues(alpha: 0.3)
              : (isRising ? AppColors.warning.withValues(alpha: 0.3) : AppColors.accent.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: isCritical ? AppColors.error : AppColors.primaryDark),
              const SizedBox(width: 8),
              Text('Smart Pricing Insights', style: AppTextStyles.labelMedium),
            ],
          ),
          const SizedBox(height: 12),
          if (flight.priceTrend != null)
            Row(
              children: [
                Icon(
                  isRising
                      ? LucideIcons.trendingUp
                      : (flight.priceTrend == 'falling' ? LucideIcons.trendingDown : LucideIcons.minus),
                  size: 16,
                  color: isRising ? AppColors.warning : AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prices are ${flight.priceTrend} '
                  '${flight.priceChangePercent != null && flight.priceChangePercent != 0 ? '(${flight.priceChangePercent! > 0 ? '+' : ''}${flight.priceChangePercent}%)' : ''}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          if (flight.seatAvailability != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.armchair,
                  size: 16,
                  color: isCritical ? AppColors.error : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  isCritical
                      ? 'Only ${flight.availableSeats} seats left!'
                      : '${flight.seatAvailability!.toUpperCase()} availability',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isCritical ? AppColors.error : AppColors.textPrimary,
                    fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTripDetails(Flight flight) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Flight Details', style: AppTextStyles.headingMedium),
          const SizedBox(height: 16),
          _detailRow(LucideIcons.planeTakeoff, 'Departure', '${flight.originName} (${flight.originIata})'),
          const SizedBox(height: 12),
          _detailRow(LucideIcons.clock, 'Duration', _formatDuration(flight.durationMinutes)),
          const SizedBox(height: 12),
          _detailRow(LucideIcons.planeLanding, 'Arrival', '${flight.destinationName} (${flight.destinationIata})'),
        ],
      ),
    );
  }

  Widget _buildBaggageAndClass(Flight flight) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cabin & Baggage', style: AppTextStyles.headingMedium),
          const SizedBox(height: 16),
          _detailRow(LucideIcons.armchair, 'Cabin Class', flight.fareLabel ?? flight.cabinClass.toUpperCase()),
          const SizedBox(height: 12),
          _detailRow(LucideIcons.briefcase, 'Cabin Baggage', '${flight.baggageCabinKg} kg included'),
          const SizedBox(height: 12),
          _detailRow(LucideIcons.luggage, 'Checked Baggage', '${flight.baggageCheckedKg} kg included'),
        ],
      ),
    );
  }

  Widget _buildPolicies(Flight flight) {
    final hoursUntilDeparture = flight.departureTime.difference(DateTime.now()).inHours;
    final isRefundable = flight.isRefundable;
    
    // We default to 10% for the gap between 16 and 24 hours (>= 16h)
    final double cancelFeePercentage = hoursUntilDeparture >= 16 ? 0.10 : 0.20;
    
    final double basePrice = flight.basePrice;
    final double cancelFeeAmount = basePrice * cancelFeePercentage;
    final double estimatedRefund = basePrice - cancelFeeAmount;

    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Policies', style: AppTextStyles.headingMedium),
          ),
          
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(
              children: [
                _buildCancellationPolicyTile(isRefundable, hoursUntilDeparture, cancelFeePercentage),
                const Divider(color: AppColors.surfaceBorder, height: 1),
                _buildModificationPolicyTile(),
                if (isRefundable) ...[
                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  _buildRefundInfoTile(estimatedRefund),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicyTile(bool isRefundable, int hoursUntilDeparture, double feePercentage) {
    final feeText = '${(feePercentage * 100).toInt()}%';
    
    return ExpansionTile(
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.textSecondary,
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isRefundable ? AppColors.info.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isRefundable ? LucideIcons.refreshCcw : LucideIcons.ban, 
          size: 20, 
          color: isRefundable ? AppColors.info : AppColors.error,
        ),
      ),
      title: Text('Cancellation Policy', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(
        isRefundable ? 'Refundable (Conditions Apply)' : 'Non-Refundable',
        style: AppTextStyles.labelSmall.copyWith(
          color: isRefundable ? AppColors.success : AppColors.error,
        ),
      ),
      childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isRefundable)
          Text(
            'This fare type is strictly non-refundable. Cancellations will not yield any refund to the original payment method.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          )
        else ...[
          Text(
            'Cancellation Fees:',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          _bulletPoint('More than 16h before departure → 10% fee'),
          _bulletPoint('Less than 16h before departure → 20% fee'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.clock, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hoursUntilDeparture > 0 
                        ? 'You have $hoursUntilDeparture hours left. Current cancellation fee: $feeText.'
                        : 'Flight has already departed. Cancellation may not be available.',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModificationPolicyTile() {
    return ExpansionTile(
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.textSecondary,
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(LucideIcons.edit3, size: 20, color: AppColors.primary),
      ),
      title: Text('Modification Policy', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text('Changes allowed with restrictions', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Allowed modifications after booking:',
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        _bulletPoint('Passenger details (e.g., spelling corrections)'),
        _bulletPoint('Contact information'),
        _bulletPoint('Cabin upgrades (subject to availability)'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Note: Changing the actual flight route or date is currently unsupported.',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefundInfoTile(double estimatedRefund) {
    return ExpansionTile(
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.textSecondary,
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(LucideIcons.banknote, size: 20, color: AppColors.success),
      ),
      title: Text('Refund Information', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text('Estimated calculation & timelines', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Refund:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text('${estimatedRefund.toStringAsFixed(2)} EGP', style: AppTextStyles.labelMedium.copyWith(color: AppColors.success)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.info, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Refunds are processed to the original payment method within 5-7 business days after cancellation confirmation.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 4, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
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
