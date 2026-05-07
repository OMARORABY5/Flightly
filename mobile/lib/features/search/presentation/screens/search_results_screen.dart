import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/domain/models/filter_options.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/providers/flight_results_provider.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';
import 'package:flightly/features/search/presentation/widgets/flight_card.dart';
import 'package:flightly/features/search/presentation/screens/filter_screen.dart';
import 'package:intl/intl.dart';
import 'package:flightly/core/widgets/empty_widget.dart';
import 'package:flightly/core/constants/app_assets.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

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

    final String originCode = query.origin?.iataCode ?? 'ORG';
    final String destCode = query.destination?.iataCode ?? 'DST';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Overlapping Header Section
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Blue Gradient Background
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.skyBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        alignment: Alignment.center,
                        child: Text(
                          '$originCode - $destCode',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(LucideIcons.filter, color: Colors.white, size: 22),
                          if (filters.hasActiveFilters)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              ),
                            )
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FilterScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Header Card (Summary of search query) overlapping the background
              Container(
                margin: const EdgeInsets.only(top: 100, left: 20, right: 20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Origin and Destination with Swap
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLocationRow(
                              icon: LucideIcons.mapPin,
                              label: query.origin?.city != null ? '${query.origin?.city} (${query.origin?.iataCode})' : 'Origin',
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
                              height: 20,
                              width: 2,
                              child: CustomPaint(painter: _DottedLinePainter()),
                            ),
                            _buildLocationRow(
                              icon: LucideIcons.plane,
                              label: query.destination?.city != null ? '${query.destination?.city} (${query.destination?.iataCode})' : 'Destination',
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.paleIceBlue.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.arrowUpDown, color: AppColors.primary, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Dates Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.paleIceBlue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.paleIceBlue.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            query.departureDate != null ? DateFormat('E, MMM d').format(query.departureDate!) : 'Select',
                            style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          const Text('-', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            query.returnDate != null ? DateFormat('E, MMM d').format(query.returnDate!) : (query.tripType == TripType.roundTrip ? 'Select' : 'One-way'),
                            style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Details Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.arrowRightLeft, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              query.tripType == TripType.roundTrip ? 'Return' : 'One-way',
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(LucideIcons.users, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('${query.totalPassengers}', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            const Icon(Icons.child_care, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            const Text('0', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            const Icon(LucideIcons.briefcase, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            const Text('0', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sort Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: SortOption.values.map((option) {
                final isSelected = filters.sortOption == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(filterOptionsProvider.notifier).state = filters.copyWith(sortOption: option);
                      ref.read(flightResultsProvider.notifier).searchFlights();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.skyBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ) : null,
                        color: isSelected ? null : AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ] : [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Results List
          Expanded(
            child: resultsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : resultsState.error != null
                    ? Center(
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
                      )
                    : resultsState.flights.isEmpty
                        ? const AppEmptyWidget(
                            title: 'No flights found',
                            message: 'Try adjusting your filters or changing dates',
                            imagePath: AppAssets.emptySearch,
                            icon: Icons.airplanemode_inactive,
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(flightResultsProvider.notifier).searchFlights(),
                            color: AppColors.primary,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: resultsState.flights.length + (resultsState.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == resultsState.flights.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                return FlightCard(
                                  flight: resultsState.flights[index],
                                  onTap: () {
                                    // Navigate to flight details
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary.withOpacity(0.5), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
