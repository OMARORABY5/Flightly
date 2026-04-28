import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/search/presentation/screens/flight_details_screen.dart' as flightly_details;
import 'package:intl/intl.dart';

class FlightCard extends StatefulWidget {
  final Flight flight;
  final VoidCallback? onTap;

  const FlightCard({
    Key? key,
    required this.flight,
    this.onTap,
  }) : super(key: key);

  @override
  State<FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<FlightCard> {
  bool _isExpanded = false;

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Airline info & Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (widget.flight.airlineLogoUrl != null) ...[
                            Image.network(
                              widget.flight.airlineLogoUrl!,
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.flight, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 8),
                          ] else
                            const Icon(Icons.flight, color: AppColors.primary, size: 24),
                          Expanded(
                            child: Text(
                              widget.flight.airlineName, 
                              style: AppTextStyles.labelLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.flight.labels.isNotEmpty)
                      const SizedBox(width: 8),
                    if (widget.flight.labels.isNotEmpty)
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 4,
                          runSpacing: 4,
                          children: widget.flight.labels.map((label) {
                            Color badgeColor;
                            switch (label) {
                              case 'cheapest':
                                badgeColor = AppColors.success;
                                break;
                              case 'fastest':
                                badgeColor = AppColors.warning;
                                break;
                              default:
                                badgeColor = AppColors.primary;
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                label.toUpperCase(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: badgeColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Times and Route
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Origin
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatTime(widget.flight.departureTime), style: AppTextStyles.displayMedium),
                        const SizedBox(height: 4),
                        Text(widget.flight.originIata, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),

                    // Duration line
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              _formatDuration(widget.flight.durationMinutes),
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.circle_outlined, size: 8, color: AppColors.primary),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                if (widget.flight.stops > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.surfaceBorder),
                                    ),
                                    child: Text(
                                      '${widget.flight.stops} stop${widget.flight.stops > 1 ? 's' : ''}',
                                      style: AppTextStyles.labelSmall.copyWith(fontSize: 8),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                                const Icon(Icons.flight_land, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Destination
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatTime(widget.flight.arrivalTime), style: AppTextStyles.displayMedium),
                        const SizedBox(height: 4),
                        Text(widget.flight.destinationIata, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Bottom Row: Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.flight.cabinClass.replaceAll('_', ' ').toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                        Text(
                          '\$${widget.flight.totalPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),

                // Expanded Area
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: AppColors.surfaceBorder),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.luggage, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text('${widget.flight.baggageCheckedKg}kg checked', style: AppTextStyles.bodySmall),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.event_seat, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text('${widget.flight.availableSeats} seats left', style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => flightly_details.FlightDetailsScreen(
                                  flightId: widget.flight.id,
                                  seenPrice: widget.flight.basePrice,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('View Details', style: AppTextStyles.button),
                        ),
                      ),
                    ],
                  ),
                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
