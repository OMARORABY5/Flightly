import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/presentation/screens/return_flight_results_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:go_router/go_router.dart';

class FlightDetailsScreen extends ConsumerStatefulWidget {
  final String flightId;
  final double seenPrice;

  /// true when the user is selecting the RETURN leg of a round-trip.
  final bool isReturnLeg;

  /// The already-chosen outbound flight (only meaningful when [isReturnLeg] is true).
  final Flight? outboundFlight;

  const FlightDetailsScreen({
    super.key,
    required this.flightId,
    required this.seenPrice,
    this.isReturnLeg = false,
    this.outboundFlight,
  });

  @override
  ConsumerState<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends ConsumerState<FlightDetailsScreen> {
  bool _isCheckingPrice = false;

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);
  String _formatDate(DateTime date) => DateFormat('EEE, d MMM').format(date);
  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  Future<void> _toggleSave(bool isCurrentlySaved) async {
    final repo = ref.read(searchRepositoryProvider);
    const testUserId = '11111111-1111-1111-1111-111111111111';

    try {
      if (isCurrentlySaved) {
        await repo.unsaveFlight(testUserId, widget.flightId);
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.info(message: 'Flight removed from watchlist'),
        );
      } else {
        await repo.saveFlight(testUserId, widget.flightId);
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Flight saved to watchlist'),
        );
      }
      ref.invalidate(isFlightSavedProvider(widget.flightId));
      ref.invalidate(savedFlightsProvider);
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: 'Failed to update watchlist'),
      );
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
          btnOkOnPress: () => Navigator.pop(context),
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

    if (widget.isReturnLeg) {
      // Return leg selected — go straight to booking with both legs
      context.push('/booking', extra: {
        'flight': widget.outboundFlight!,
        'returnFlight': flight,
      });
    } else {
      final query = ref.read(searchFormProvider);
      if (query.tripType == TripType.roundTrip) {
        // Outbound selected for a round-trip — show return results screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReturnFlightResultsScreen(outboundFlight: flight),
          ),
        );
      } else {
        // One-way — go directly to booking
        context.push('/booking', extra: {
          'flight': flight,
          'returnFlight': null,
        });
      }
    }
  }

  /// Label for the primary action button.
  String get _buttonLabel {
    if (widget.isReturnLeg) return 'Complete Booking';
    final query = ref.read(searchFormProvider);
    if (query.tripType == TripType.roundTrip) return 'Select Return Flight';
    return 'Book Now';
  }

  /// Icon shown beside the button label.
  IconData get _buttonIcon {
    if (widget.isReturnLeg) return LucideIcons.checkCircle2;
    final query = ref.read(searchFormProvider);
    if (query.tripType == TripType.roundTrip) return LucideIcons.arrowRight;
    return LucideIcons.plane;
  }

  @override
  Widget build(BuildContext context) {
    final flightAsync = ref.watch(flightDetailsProvider(widget.flightId));
    final savedAsync = ref.watch(isFlightSavedProvider(widget.flightId));
    final isSaved = savedAsync.value?['is_saved'] == true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.isReturnLeg
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.arrowLeftRight, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Return Flight', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                  ],
                ),
              )
            : null,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? AppColors.error : AppColors.textSecondary,
            ),
            onPressed: () => _toggleSave(isSaved),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: AmbientBackground(child: SizedBox.shrink())),
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
                      height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
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
                // Outbound summary chip (only on return leg)
                if (widget.isReturnLeg && widget.outboundFlight != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(color: AppColors.surfaceBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Outbound: ${widget.outboundFlight!.originIata} → '
                            '${widget.outboundFlight!.destinationIata}  '
                            '${DateFormat('HH:mm').format(widget.outboundFlight!.departureTime)}  '
                            '• EGP ${widget.outboundFlight!.basePrice.toStringAsFixed(0)}',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

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
                              widget.isReturnLeg ? 'Return Price' : 'Price',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              'EGP ${flight.basePrice.toStringAsFixed(0)}',
                              style: AppTextStyles.displayMedium
                                  .copyWith(color: AppColors.primary),
                            ),
                            if (widget.isReturnLeg && widget.outboundFlight != null)
                              Text(
                                'Total: EGP ${(flight.basePrice + widget.outboundFlight!.basePrice).toStringAsFixed(0)}',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.textSecondary),
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
    final policy = flight.policy;
    if (policy == null) return const SizedBox();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Policies', style: AppTextStyles.headingMedium),
          const SizedBox(height: 16),
          _detailRow(
            LucideIcons.ban,
            'Cancellation',
            policy['cancellation_policy'] ?? (flight.isRefundable ? 'Refundable' : 'Non-refundable'),
          ),
          const SizedBox(height: 12),
          _detailRow(
            LucideIcons.refreshCcw,
            'Changes',
            policy['change_policy'] ?? 'Changes may incur fees',
          ),
          if (policy['change_fee'] != null) ...[
            const SizedBox(height: 12),
            _detailRow(
              LucideIcons.banknote,
              'Change Fee',
              '\$${policy['change_fee']}',
            ),
          ]
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
