import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/models/filter_options.dart';
import 'package:flightly/features/search/domain/providers/flight_results_provider.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  late double? _maxPrice;
  late int? _maxStops;
  late int? _maxDuration;
  late List<String> _preferredAirlines;
  
  @override
  void initState() {
    super.initState();
    final filters = ref.read(filterOptionsProvider);
    _maxPrice = filters.maxPrice;
    _maxStops = filters.maxStops;
    _maxDuration = filters.maxDuration;
    _preferredAirlines = List.from(filters.preferredAirlines);
    
    // Trigger fetch if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(availableAirlinesProvider);
    });
  }

  void _applyFilters() {
    final filters = ref.read(filterOptionsProvider);
    ref.read(filterOptionsProvider.notifier).state = filters.copyWith(
      maxPrice: _maxPrice ?? -1.0,
      maxStops: _maxStops ?? -1, // Use -1 to clear
      maxDuration: _maxDuration ?? -1,
      preferredAirlines: _preferredAirlines,
    );
    ref.read(flightResultsProvider.notifier).searchFlights();
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _maxPrice = null;
      _maxStops = null;
      _maxDuration = null;
      _preferredAirlines = [];
    });
    ref.read(filterOptionsProvider.notifier).state = const FilterOptions();
    ref.read(flightResultsProvider.notifier).searchFlights();
  }

  Widget _buildStopsOption(String label, int? value) {
    final isSelected = _maxStops == value;
    return GestureDetector(
      onTap: () => setState(() => _maxStops = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final airlinesAsync = ref.watch(availableAirlinesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text('Filters', style: AppTextStyles.headingMedium),
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text('Reset', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stops Filter
                      Text('Stops', style: AppTextStyles.headingMedium),
                      const SizedBox(height: 16),
                      _buildStopsOption('Any number of stops', null),
                      _buildStopsOption('Direct flights only', 0),
                      _buildStopsOption('Up to 1 stop', 1),
                      const SizedBox(height: 32),

                      // Price Range
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Max Price', style: AppTextStyles.headingMedium),
                          if (_maxPrice != null)
                            Text(
                              '\$${_maxPrice!.toStringAsFixed(0)}',
                              style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: AppColors.surfaceBorder,
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primary.withValues(alpha: 0.2),
                                valueIndicatorTextStyle: AppTextStyles.labelSmall,
                              ),
                              child: Slider(
                                value: _maxPrice ?? 2000,
                                min: 50,
                                max: 2000,
                                divisions: 39, // $50 increments
                                label: '\$${(_maxPrice ?? 2000).toStringAsFixed(0)}',
                                onChanged: (value) => setState(() => _maxPrice = value),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('\$50', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                                  Text('\$2000+', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Duration Range
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Max Flight Duration', style: AppTextStyles.headingMedium),
                          if (_maxDuration != null)
                            Text(
                              '${_maxDuration! ~/ 60}h ${_maxDuration! % 60}m',
                              style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: AppColors.surfaceBorder,
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primary.withValues(alpha: 0.2),
                                valueIndicatorTextStyle: AppTextStyles.labelSmall,
                              ),
                              child: Slider(
                                value: _maxDuration?.toDouble() ?? 1440.0, // 24h
                                min: 60, // 1h
                                max: 1440, // 24h
                                divisions: 23,
                                label: '${((_maxDuration ?? 1440) ~/ 60)}h',
                                onChanged: (value) => setState(() => _maxDuration = value.toInt()),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('1h', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                                  Text('24h+', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Airlines Multi-select
                      Text('Airlines', style: AppTextStyles.headingMedium),
                      const SizedBox(height: 16),
                      airlinesAsync.when(
                        data: (airlines) {
                          if (airlines.isEmpty) {
                            return Text('No airlines available for filtering.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary));
                          }
                          return GlassCard(
                            padding: const EdgeInsets.all(8),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: airlines.length,
                              itemBuilder: (context, index) {
                                final airlineCode = airlines[index]['airline_code'] as String;
                                final airlineName = airlines[index]['airline_name'] as String;
                                final isSelected = _preferredAirlines.contains(airlineCode);
                                
                                return CheckboxListTile(
                                  title: Text(airlineName, style: AppTextStyles.bodyMedium),
                                  value: isSelected,
                                  activeColor: AppColors.primary,
                                  checkColor: AppColors.white,
                                  side: const BorderSide(color: AppColors.textSecondary),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _preferredAirlines.add(airlineCode);
                                      } else {
                                        _preferredAirlines.remove(airlineCode);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error loading airlines: $err', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Sticky Bottom Button
      bottomNavigationBar: Container(
        color: AppColors.background.withValues(alpha: 0.9),
        padding: EdgeInsets.only(
          left: 20, 
          right: 20, 
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 20,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Apply Filters', style: AppTextStyles.button),
          ),
        ),
      ),
    );
  }
}
