import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
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
  final bool isReturnLeg;
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

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time.toLocal());
  String _formatDate(DateTime date) => DateFormat('E, MMM d').format(date.toLocal());
  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  Future<void> _toggleSave(bool isCurrentlySaved) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(message: 'Please log in to save flights'),
      );
      return;
    }

    final repo = ref.read(searchRepositoryProvider);
    final userId = authState.user.id;

    try {
      if (isCurrentlySaved) {
        await repo.unsaveFlight(userId, widget.flightId);
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.info(message: 'Flight removed from watchlist'),
        );
      } else {
        await repo.saveFlight(userId, widget.flightId);
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
    if (flight == null) return;

    final query = ref.read(searchFormProvider);
    final isRoundTrip = query.tripType == TripType.roundTrip;

    if (!widget.isReturnLeg && isRoundTrip) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReturnFlightResultsScreen(outboundFlight: flight),
        ),
      );
    } else {
      context.push('/booking', extra: {
        'flight': widget.isReturnLeg ? widget.outboundFlight! : flight,
        'returnFlight': widget.isReturnLeg ? flight : null,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final flightAsync = ref.watch(flightDetailsProvider(widget.flightId));
    final savedAsync = ref.watch(isFlightSavedProvider(widget.flightId));
    final isSaved = savedAsync.value?['is_saved'] == true;
    final query = ref.watch(searchFormProvider);
    final isRoundTrip = query.tripType == TripType.roundTrip;

    String headerText = 'Flight Details';
    if (isRoundTrip) {
      headerText = widget.isReturnLeg ? 'Inbound' : 'Outbound';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Flight Details',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: flightAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(child: Text('Error loading details')),
        data: (flight) {
          if (flight == null) return const Center(child: Text('Flight not found'));

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 120 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blue Header Bar
                    Container(
                      width: double.infinity,
                      color: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            headerText,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDuration(flight.durationMinutes),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    
                    // Timeline Card
                    Container(
                      color: AppColors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Origin -> Destination & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(flight.originIata, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.flight_takeoff, size: 16, color: AppColors.textPrimary),
                                  ),
                                  Text(flight.destinationIata, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(_formatDate(flight.departureTime), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Timeline
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side times & line
                              SizedBox(
                                width: 50,
                                child: Column(
                                  children: [
                                    Text(_formatTime(flight.departureTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Text(_formatDuration(flight.durationMinutes), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 16),
                                    Text(_formatTime(flight.arrivalTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              
                              // Line with dots
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 6),
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.surfaceBorder, shape: BoxShape.circle)),
                                    Container(
                                      height: 60,
                                      width: 2,
                                      child: CustomPaint(painter: _VerticalDottedPainter()),
                                    ),
                                    const Icon(LucideIcons.plane, size: 14, color: AppColors.surfaceBorder),
                                    Container(
                                      height: 60,
                                      width: 2,
                                      child: CustomPaint(painter: _VerticalDottedPainter()),
                                    ),
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.surfaceBorder, shape: BoxShape.circle)),
                                  ],
                                ),
                              ),
                              
                              // Right side info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${flight.originIata} ${flight.originCity ?? ""}', style: const TextStyle(fontSize: 16)),
                                        const Text('Terminal -', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Airline Box
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.error,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: flight.airlineLogoUrl != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    flight.airlineLogoUrl!,
                                                    width: 32,
                                                    height: 32,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.plane, color: Colors.white, size: 16),
                                                  ),
                                                )
                                              : Text(
                                                  flight.airlineCode.isNotEmpty ? flight.airlineCode.substring(0, 2) : 'FL',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(flight.airlineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                Text(flight.flightNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${flight.destinationIata} ${flight.destinationCity ?? ""}', style: const TextStyle(fontSize: 16)),
                                        const Text('Terminal -', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Good to know
                    Container(
                      color: AppColors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Good to know', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(LucideIcons.clock, color: AppColors.textSecondary, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Timezone differences may apply', style: TextStyle(fontSize: 15)),
                                    Text('Between ${flight.originCity ?? flight.originIata} and ${flight.destinationCity ?? flight.destinationIata}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Save Flight
                    Container(
                      color: AppColors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Not ready to book yet?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _toggleSave(isSaved),
                            child: Row(
                              children: [
                                Icon(isSaved ? Icons.star : Icons.star_border, color: isSaved ? AppColors.primary : AppColors.textSecondary, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Save this flight', style: TextStyle(fontSize: 15)),
                                      const Text('So you can always come back and find it', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Sticky Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${flight.totalPrice.toStringAsFixed(0)} EGP',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Total (${query.totalPassengers} adult${query.totalPassengers > 1 ? 's' : ''})',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isCheckingPrice ? null : _handleBookNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676), // Bright cyan/green from Figma
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                          ),
                          child: _isCheckingPrice
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Builder(builder: (context) {
                                  final isOutboundOfRoundTrip = !widget.isReturnLeg && isRoundTrip;
                                  return Text(
                                    isOutboundOfRoundTrip ? 'Select Return' : 'Book now',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  );
                                }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerticalDottedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceBorder
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(size.width / 2, startY), Offset(size.width / 2, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
