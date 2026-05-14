import 'package:flutter/material.dart';
import 'package:flightly/core/presentation/widgets/premium_app_bar.dart';
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
import 'package:flightly/features/search/presentation/screens/search_results_screen.dart';
import 'package:flightly/features/notifications/domain/providers/notification_provider.dart';
import 'package:go_router/go_router.dart';

class HomeSearchScreen extends ConsumerStatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  ConsumerState<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends ConsumerState<HomeSearchScreen> {

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchFormProvider);
    final isRoundTrip = query.tripType == TripType.roundTrip;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24, // Compact top padding directly below status bar
                left: 24,
                right: 24,
                bottom: 24,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Where next?', style: AppTextStyles.displayLarge),
                              const SizedBox(height: 4),
                              Text('Find smarter flights in seconds.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(LucideIcons.bell, color: AppColors.textSecondary, size: 22),
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, child) {
                                  final notificationState = ref.watch(notificationNotifierProvider);
                                  if (notificationState.unreadCount > 0) {
                                    return Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${notificationState.unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28), // 28px gap before search card
                    // Search Card
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Trip Type Toggle
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedAlign(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOutCubic,
                                    alignment: isRoundTrip ? Alignment.centerRight : Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: 0.5,
                                      child: Container(
                                        margin: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            ref.read(searchFormProvider.notifier).updateQuery(
                                              query.copyWith(tripType: TripType.oneWay, returnDate: null),
                                            );
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Center(
                                            child: Text(
                                              'One-way',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: !isRoundTrip ? Colors.white : AppColors.textSecondary,
                                                fontWeight: !isRoundTrip ? FontWeight.w600 : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            ref.read(searchFormProvider.notifier).updateQuery(
                                              query.copyWith(tripType: TripType.roundTrip),
                                            );
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Center(
                                            child: Text(
                                              'Round-trip',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: isRoundTrip ? Colors.white : AppColors.textSecondary,
                                                fontWeight: isRoundTrip ? FontWeight.w600 : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                      padding: EdgeInsets.only(left: 52),
                                      child: Divider(color: AppColors.surfaceBorder, height: 1),
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
                                            color: AppColors.primary.withValues(alpha: 0.3),
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
                            
                            // Departure Date
                            _buildInfoField(
                              context: context,
                              icon: LucideIcons.calendar,
                              label: 'Departure',
                              value: query.departureDate != null ? DateFormat('E, d MMM').format(query.departureDate!) : 'Select',
                              onTap: () => DateSelectionScreen.show(context),
                            ),
                            
                            // Return Date (Animated)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOutCubic,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: isRoundTrip ? 1.0 : 0.0,
                                child: isRoundTrip
                                    ? Column(
                                        children: [
                                          const SizedBox(height: 16),
                                          _buildInfoField(
                                            context: context,
                                            icon: LucideIcons.calendarCheck,
                                            label: 'Return',
                                            value: query.returnDate != null ? DateFormat('E, d MMM').format(query.returnDate!) : 'Select',
                                            onTap: () => DateSelectionScreen.show(context),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            // Passengers & Class
                            _buildInfoField(
                              context: context,
                              icon: LucideIcons.users,
                              label: 'Passengers & Class',
                              value: query.totalPassengers > 0 
                                  ? '${query.totalPassengers} Passenger${query.totalPassengers > 1 ? 's' : ''}'
                                  : 'Select',
                              subValue: query.totalPassengers > 0 
                                  ? query.cabinClass.name.replaceAll('Economy', ' Economy').toUpperCase()
                                  : null,
                              onTap: () => PassengerClassPopup.show(context),
                            ),
                            const SizedBox(height: 24),
                            
                            // Search Button
                            ElevatedButton(
                              onPressed: () {
                                if (query.isValid) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select origin, destination, and dates.')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.surface,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: query.isValid ? 8 : 0,
                                shadowColor: AppColors.primary.withValues(alpha: 0.5),
                              ),
                              child: Text('Search Flights', style: AppTextStyles.button),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                        Text(value, style: AppTextStyles.displayMedium),
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
                    Text('Select Airport', style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5))),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.8), width: 0.7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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
                  Text(value, style: AppTextStyles.headingMedium),
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
