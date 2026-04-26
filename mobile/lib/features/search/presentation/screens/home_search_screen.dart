import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';
import 'package:flightly/features/search/presentation/widgets/airport_search_popup.dart';
import 'package:flightly/features/search/presentation/widgets/date_selection_screen.dart';
import 'package:flightly/features/search/presentation/widgets/passenger_class_popup.dart';

class HomeSearchScreen extends ConsumerWidget {
  const HomeSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchFormProvider);

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Where to?', style: AppTextStyles.displayLarge),
                              const SizedBox(height: 4),
                              Text('Let\'s explore the world', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                          const CircleAvatar(
                            backgroundColor: AppColors.surface,
                            child: Icon(LucideIcons.user, color: AppColors.textSecondary),
                          )
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Search Card
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Trip Type Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildTripTypeButton(
                                      title: 'One-way',
                                      isSelected: query.tripType == TripType.oneWay,
                                      onTap: () {
                                        ref.read(searchFormProvider.notifier).updateQuery(
                                          query.copyWith(tripType: TripType.oneWay, returnDate: null),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildTripTypeButton(
                                      title: 'Round-trip',
                                      isSelected: query.tripType == TripType.roundTrip,
                                      onTap: () {
                                        ref.read(searchFormProvider.notifier).updateQuery(
                                          query.copyWith(tripType: TripType.roundTrip),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Origin & Destination
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  children: [
                                    _buildAirportField(
                                      context: context,
                                      ref: ref,
                                      icon: LucideIcons.planeTakeoff,
                                      label: 'From',
                                      value: query.origin?.iataCode,
                                      subValue: query.origin?.city,
                                      isOrigin: true,
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 40),
                                      child: Divider(color: AppColors.surface, height: 1),
                                    ),
                                    _buildAirportField(
                                      context: context,
                                      ref: ref,
                                      icon: LucideIcons.planeLanding,
                                      label: 'To',
                                      value: query.destination?.iataCode,
                                      subValue: query.destination?.city,
                                      isOrigin: false,
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () {
                                      ref.read(searchFormProvider.notifier).swapOriginDestination();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: const Icon(LucideIcons.arrowUpDown, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Dates
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoField(
                                    context: context,
                                    icon: LucideIcons.calendar,
                                    label: 'Departure',
                                    value: query.departureDate != null ? DateFormat('E, d MMM').format(query.departureDate!) : 'Select',
                                    onTap: () => DateSelectionScreen.show(context),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Opacity(
                                    opacity: query.tripType == TripType.oneWay ? 0.3 : 1.0,
                                    child: _buildInfoField(
                                      context: context,
                                      icon: LucideIcons.calendarClock,
                                      label: 'Return',
                                      value: query.returnDate != null ? DateFormat('E, d MMM').format(query.returnDate!) : 'Select',
                                      onTap: query.tripType == TripType.roundTrip ? () => DateSelectionScreen.show(context) : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Passengers & Class
                            _buildInfoField(
                              context: context,
                              icon: LucideIcons.users,
                              label: 'Passengers & Class',
                              value: '${query.totalPassengers} Passenger${query.totalPassengers > 1 ? 's' : ''}',
                              subValue: query.cabinClass.name.replaceAll('Economy', ' Economy').toUpperCase(),
                              onTap: () => PassengerClassPopup.show(context),
                            ),
                            const SizedBox(height: 24),
                            
                            // Search Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: query.isValid ? () {
                                  // TODO: Navigate to Results Screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Searching flights...')),
                                  );
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: query.isValid ? 8 : 0,
                                  shadowColor: AppColors.primary.withOpacity(0.5),
                                ),
                                child: Text('Search Flights', style: AppTextStyles.button),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripTypeButton({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAirportField({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required String? value,
    required String? subValue,
    required bool isOrigin,
  }) {
    return InkWell(
      onTap: () async {
        final airport = await AirportSearchPopup.show(context);
        if (airport != null) {
          final query = ref.read(searchFormProvider);
          ref.read(searchFormProvider.notifier).updateQuery(
            isOrigin ? query.copyWith(origin: airport) : query.copyWith(destination: airport)
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  if (value != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(value, style: AppTextStyles.headingMedium),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(subValue ?? '', 
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text('Select Airport', style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary.withOpacity(0.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  if (subValue != null) ...[
                    const SizedBox(height: 2),
                    Text(subValue, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
