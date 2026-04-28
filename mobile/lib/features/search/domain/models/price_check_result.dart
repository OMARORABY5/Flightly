// price_check_result.dart
class PriceCheckResult {
  final String flightId;
  final bool priceChanged;
  final bool unavailable;
  final double? currentPrice;
  final double seenPrice;
  final double difference;
  final int seatsRemaining;
  final String message;

  PriceCheckResult({
    required this.flightId,
    required this.priceChanged,
    required this.unavailable,
    this.currentPrice,
    required this.seenPrice,
    required this.difference,
    required this.seatsRemaining,
    required this.message,
  });

  factory PriceCheckResult.fromJson(Map<String, dynamic> json) {
    return PriceCheckResult(
      flightId: json['flight_id'],
      priceChanged: json['price_changed'] ?? false,
      unavailable: json['unavailable'] ?? false,
      currentPrice: json['current_price'] != null ? (json['current_price'] as num).toDouble() : null,
      seenPrice: (json['seen_price'] as num).toDouble(),
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      seatsRemaining: json['seats_remaining'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
