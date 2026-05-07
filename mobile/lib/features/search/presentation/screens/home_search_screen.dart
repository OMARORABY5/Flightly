import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';
import 'package:flightly/features/search/presentation/widgets/airport_search_popup.dart';
import 'package:flightly/features/search/presentation/widgets/date_selection_screen.dart';
import 'package:flightly/features/search/presentation/widgets/passenger_class_popup.dart';
import 'package:flightly/features/search/presentation/screens/search_results_screen.dart';

class HomeSearchScreen extends ConsumerWidget {
  const HomeSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Vibrant Gradient Header
            Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.skyBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
            
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar with Profile Picture
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'), // Mock profile pic
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Title (White for contrast against gradient)
                    Text(
                      'Travel made\nsimple.',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.95),
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Main Search Card (Softer, colored shadow)
                    Container(
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
                      padding: const EdgeInsets.all(24),
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
                                    context: context,
                                    ref: ref,
                                    icon: LucideIcons.mapPin,
                                    label: query.origin?.iataCode != null ? '${query.origin?.city} (${query.origin?.iataCode})' : 'Where from?',
                                    isOrigin: true,
                                    hasValue: query.origin != null,
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 11, top: 8, bottom: 8),
                                    height: 24,
                                    width: 2,
                                    child: CustomPaint(painter: _DottedLinePainter()),
                                  ),
                                  _buildLocationRow(
                                    context: context,
                                    ref: ref,
                                    icon: LucideIcons.plane,
                                    label: query.destination?.iataCode != null ? '${query.destination?.city} (${query.destination?.iataCode})' : 'Where to?',
                                    isOrigin: false,
                                    hasValue: query.destination != null,
                                  ),
                                ],
                              ),
                              // Swap Button
                              GestureDetector(
                                onTap: () {
                                  ref.read(searchFormProvider.notifier).swapOriginDestination();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.skyBlue],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: const Icon(LucideIcons.arrowUpDown, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Dates Row
                          GestureDetector(
                            onTap: () => DateSelectionScreen.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppColors.paleIceBlue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.paleIceBlue.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    query.departureDate != null ? DateFormat('E, MMM d').format(query.departureDate!) : 'Select Date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: query.departureDate != null ? AppColors.primary : AppColors.textSecondary,
                                      fontWeight: query.departureDate != null ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                  if (query.tripType == TripType.roundTrip) ...[
                                    const Text('-', style: TextStyle(color: AppColors.textSecondary)),
                                    Text(
                                      query.returnDate != null ? DateFormat('E, MMM d').format(query.returnDate!) : 'Select Date',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: query.returnDate != null ? AppColors.primary : AppColors.textSecondary,
                                        fontWeight: query.returnDate != null ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Filters Row
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: GestureDetector(
                            onTap: () {
                              // Toggle trip type
                              final newType = query.tripType == TripType.oneWay ? TripType.roundTrip : TripType.oneWay;
                              ref.read(searchFormProvider.notifier).updateQuery(
                                query.copyWith(tripType: newType, returnDate: newType == TripType.oneWay ? null : query.returnDate),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.arrowRightLeft, size: 18, color: query.tripType == TripType.roundTrip ? AppColors.primary : AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    query.tripType == TripType.roundTrip ? 'Return' : 'One-way',
                                    style: TextStyle(
                                      fontSize: 15, 
                                      color: query.tripType == TripType.roundTrip ? AppColors.primary : AppColors.textSecondary,
                                      fontWeight: query.tripType == TripType.roundTrip ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: GestureDetector(
                            onTap: () => PassengerClassPopup.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.users, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text('${query.totalPassengers}', style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.child_care, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  const Text('0', style: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  const Icon(LucideIcons.briefcase, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  const Text('0', style: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Search Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          if (query.isValid) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(query.validationError ?? 'Invalid search query.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                          shadowColor: AppColors.primary.withOpacity(0.5),
                        ).copyWith(
                          elevation: WidgetStateProperty.resolveWith<double>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) return 4;
                              return 12; // Nice healthy shadow
                            },
                          ),
                        ),
                        child: const Text('Search Flights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildLocationRow({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required bool isOrigin,
    required bool hasValue,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.paleIceBlue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: hasValue ? FontWeight.bold : FontWeight.w600,
                  color: hasValue ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
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
