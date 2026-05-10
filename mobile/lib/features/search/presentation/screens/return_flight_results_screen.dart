// return_flight_results_screen.dart
// Shows available return flights for the second leg of a round-trip.
// Mirrors SearchResultsScreen but uses returnFlightResultsProvider
// and passes isReturnLeg: true to FlightDetailsScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/features/search/domain/models/filter_options.dart';
import 'package:flightly/features/search/domain/providers/return_flight_results_provider.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';
import 'package:flightly/features/search/domain/providers/return_flight_provider.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/presentation/widgets/flight_card.dart';
import 'package:flightly/features/search/presentation/screens/return_filter_screen.dart';
import 'package:flightly/features/search/presentation/screens/flight_details_screen.dart';
import 'package:intl/intl.dart';

class ReturnFlightResultsScreen extends ConsumerStatefulWidget {
  /// The outbound flight the user already selected.
  final Flight outboundFlight;

  const ReturnFlightResultsScreen({
    Key? key,
    required this.outboundFlight,
  }) : super(key: key);

  @override
  ConsumerState<ReturnFlightResultsScreen> createState() =>
      _ReturnFlightResultsScreenState();
}

class _ReturnFlightResultsScreenState
    extends ConsumerState<ReturnFlightResultsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Store the outbound flight selection in the provider
      ref.read(selectedOutboundFlightProvider.notifier).state =
          widget.outboundFlight;
      // Kick off the return search
      ref.read(returnFlightResultsProvider.notifier).searchFlights();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(returnFlightResultsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchFormProvider);
    final resultsState = ref.watch(returnFlightResultsProvider);
    final filters = ref.watch(returnFilterOptionsProvider);

    final returnDateStr = query.returnDate != null
        ? DateFormat('MMM d, yyyy').format(query.returnDate!)
        : '';
    final paxStr =
        '${query.totalPassengers} Passenger${query.totalPassengers > 1 ? 's' : ''}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Return leg is dest→origin
                              Text(query.destination?.iataCode ?? '',
                                  style: AppTextStyles.headingMedium),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward,
                                    size: 16,
                                    color: AppColors.textSecondary),
                              ),
                              Text(query.origin?.iataCode ?? '',
                                  style: AppTextStyles.headingMedium),
                            ],
                          ),
                          Text(
                            '$returnDateStr • $paxStr • ${query.cabinClass}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune, color: AppColors.primary),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ReturnFilterScreen()),
                            );
                          },
                        ),
                        if (filters.hasActiveFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Return leg context chip ─────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Outbound: ${widget.outboundFlight.originIata} → '
                        '${widget.outboundFlight.destinationIata}  '
                        '${DateFormat('HH:mm').format(widget.outboundFlight.departureTime)}  '
                        '• EGP ${widget.outboundFlight.basePrice.toStringAsFixed(0)}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Sort Chips ──────────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: SortOption.values.map((option) {
                    final isSelected = filters.sortOption == option;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(option.label,
                            style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.surface
                                    : AppColors.textSecondary)),
                        backgroundColor: Colors.transparent,
                        selectedColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceBorder,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(returnFilterOptionsProvider.notifier)
                                .state = filters.copyWith(sortOption: option);
                            ref
                                .read(returnFlightResultsProvider.notifier)
                                .searchFlights();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Results List ────────────────────────────────────────────────
              Expanded(
                child: resultsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : resultsState.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: AppColors.error),
                                const SizedBox(height: 16),
                                Text('Failed to load return flights',
                                    style: AppTextStyles.headingMedium),
                                Text(resultsState.error!,
                                    style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => ref
                                      .read(returnFlightResultsProvider.notifier)
                                      .searchFlights(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : resultsState.flights.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.airplanemode_inactive,
                                        size: 64,
                                        color: AppColors.textSecondary),
                                    const SizedBox(height: 16),
                                    Text('No return flights found',
                                        style: AppTextStyles.headingMedium),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your filters or return date',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => ref
                                    .read(returnFlightResultsProvider.notifier)
                                    .searchFlights(),
                                color: AppColors.primary,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(20),
                                  itemCount: resultsState.flights.length +
                                      (resultsState.hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == resultsState.flights.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 20),
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()),
                                      );
                                    }
                                    final flight = resultsState.flights[index];
                                    return FlightCard(
                                      flight: flight,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FlightDetailsScreen(
                                              flightId: flight.id,
                                              seenPrice: flight.basePrice,
                                              isReturnLeg: true,
                                              outboundFlight: widget.outboundFlight,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
