import 'package:flutter/material.dart';
import 'package:flightly/core/presentation/widgets/premium_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/features/search/domain/models/filter_options.dart';
import 'package:flightly/features/search/domain/providers/flight_results_provider.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/presentation/widgets/flight_card.dart';
import 'package:flightly/features/search/presentation/screens/filter_screen.dart';
import 'package:flightly/features/search/presentation/screens/flight_details_screen.dart';
import 'package:flightly/features/search/domain/smart_pricing/smart_pricing_provider.dart';
import 'package:intl/intl.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flightResultsProvider.notifier).searchFlights();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(flightResultsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchFormProvider);
    final resultsState = ref.watch(flightResultsProvider);
    final filters = ref.watch(filterOptionsProvider);
    final badgeMap = ref.watch(flightBadgeMapProvider);

    final dateStr = query.departureDate != null 
        ? DateFormat('MMM d, yyyy').format(query.departureDate!) 
        : '';
        
    final paxStr = '${query.totalPassengers} Passenger${query.totalPassengers > 1 ? 's' : ''}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.surfaceElevated,
      appBar: PremiumAppBar(
        height: 80, // Taller header to comfortably fit two lines of text
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(query.origin?.iataCode ?? '', style: AppTextStyles.headingMedium),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
                ),
                Text(query.destination?.iataCode ?? '', style: AppTextStyles.headingMedium),
              ],
            ),
            const SizedBox(height: 2),
            Text('$dateStr • $paxStr • ${query.cabinClass}', 
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.primary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FilterScreen()),
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
                )
            ],
          ),
        ],
      ),
      body: AmbientBackground(
        child: RefreshIndicator(
          onRefresh: () => ref.read(flightResultsProvider.notifier).searchFlights(),
          color: AppColors.primary,
          edgeOffset: MediaQuery.of(context).padding.top + 80 + 16,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 80 + 16),
              ),

              // Step indicator for round-trip
              if (query.tripType == TripType.roundTrip)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.looks_one, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Step 1: Select Outbound Flight',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

              // Sort Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: SortOption.values.map((option) {
                      final isSelected = filters.sortOption == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(option.label, style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected ? AppColors.surface : AppColors.textSecondary
                          )),
                          backgroundColor: Colors.transparent,
                          selectedColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(filterOptionsProvider.notifier).state = 
                                  filters.copyWith(sortOption: option);
                              ref.read(flightResultsProvider.notifier).searchFlights();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Results List
              if (resultsState.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (resultsState.error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Failed to load flights', style: AppTextStyles.headingMedium),
                        Text(resultsState.error!, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(flightResultsProvider.notifier).searchFlights(),
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  ),
                )
              else if (resultsState.flights.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.airplanemode_inactive, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text('No flights found', style: AppTextStyles.headingMedium),
                        const SizedBox(height: 8),
                        Text('Try adjusting your filters or changing dates', 
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == resultsState.flights.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: FlightCard(
                            flight: resultsState.flights[index],
                            badgeLabel: badgeMap[resultsState.flights[index].id],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FlightDetailsScreen(
                                    flightId: resultsState.flights[index].id,
                                    seenPrice: resultsState.flights[index].basePrice,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: resultsState.flights.length + (resultsState.hasMore ? 1 : 0),
                    ),
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
