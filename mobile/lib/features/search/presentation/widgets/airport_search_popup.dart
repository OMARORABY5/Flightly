import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/domain/models/airport.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';

class AirportSearchPopup extends ConsumerStatefulWidget {
  const AirportSearchPopup({super.key});

  @override
  ConsumerState<AirportSearchPopup> createState() => _AirportSearchPopupState();

  static Future<Airport?> show(BuildContext context) {
    return showModalBottomSheet<Airport>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AirportSearchPopup(),
    );
  }
}

class _AirportSearchPopupState extends ConsumerState<AirportSearchPopup> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(airportSearchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final airportsAsync = ref.watch(airportSearchProvider);
    final query = ref.watch(airportSearchQueryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search city, airport, or code',
                hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (query.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Popular Airports', style: AppTextStyles.h3),
              ),
            ),
          Expanded(
            child: airportsAsync.when(
              data: (airports) {
                if (airports.isEmpty && query.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.plane, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No airports found', style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        Text('Try searching for another city or code.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: airports.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.surface, height: 1),
                  itemBuilder: (context, index) {
                    final airport = airports[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          airport.iataCode,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(airport.city, style: AppTextStyles.bodyLarge),
                      subtitle: Text('${airport.name}, ${airport.country}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      onTap: () => Navigator.of(context).pop(airport),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(
                child: Text('Error loading airports', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
