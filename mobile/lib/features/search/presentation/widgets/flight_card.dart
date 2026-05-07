import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/presentation/screens/flight_details_screen.dart' as flightly_details;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FlightCard extends StatelessWidget {
  final Flight flight;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;

  const FlightCard({
    super.key,
    required this.flight,
    this.onTap,
    this.onViewDetails,
  });

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time.toLocal());
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (onViewDetails != null) {
            onViewDetails!();
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(LucideIcons.plane, size: 16, color: AppColors.primary),
                            ),
                            Text(
                              _formatTime(flight.arrivalTime),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${flight.originIata} - ${flight.destinationIata}, ${flight.airlineName}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
              const Divider(color: AppColors.surface, height: 1),
              const SizedBox(height: 16),
              
              // Bottom row with Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Flight to ${flight.destinationCity ?? flight.destinationIata}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${flight.totalPrice.toStringAsFixed(0)} EGP',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
