import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/presentation/screens/flight_details_screen.dart' as flightly_details;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flightly/features/search/presentation/widgets/smart_badge.dart';

class FlightCard extends StatelessWidget {
  final Flight flight;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;
  final String? badgeLabel;

  const FlightCard({
    super.key,
    required this.flight,
    this.onTap,
    this.onViewDetails,
    this.badgeLabel,
  });

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCDD5E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (onViewDetails != null) {
            onViewDetails!();
          } else if (onTap != null) {
            onTap!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => flightly_details.FlightDetailsScreen(
                  flightId: flight.id,
                  seenPrice: flight.basePrice,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badgeLabel != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SmartBadge.fromLabel(badgeLabel!, showExplanation: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              // Main Flight Leg Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Airline Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error, // Red like in the Figma design (Vietjet)
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: flight.airlineLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              flight.airlineLogoUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.plane, color: Colors.white, size: 20),
                            ),
                          )
                        : Text(
                            flight.airlineCode.isNotEmpty ? flight.airlineCode.substring(0, 2) : 'FL',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Times and Plane Icon
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatTime(flight.departureTime),
                              style: AppTextStyles.timeDisplay,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(LucideIcons.arrowRight, size: 16, color: AppColors.textHint),
                            ),
                            Text(
                              _formatTime(flight.arrivalTime),
                              style: AppTextStyles.timeDisplay,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${flight.originIata} - ${flight.destinationIata}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                ', ${flight.airlineName}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Duration and Stops
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        flight.stops == 0 ? 'direct flight' : '${flight.stops} stop(s)',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(flight.durationMinutes),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              const SizedBox(height: 16),
              
              // Bottom row with Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Flight to ${flight.destinationCity ?? flight.destinationIata}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${flight.totalPrice.toStringAsFixed(0)} EGP',
                        style: AppTextStyles.priceLarge,
                      ),
                      Text(
                        'per person',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
