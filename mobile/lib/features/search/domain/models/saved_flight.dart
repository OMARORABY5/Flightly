// saved_flight.dart
import 'package:flightly/features/search/domain/models/flight.dart';

class SavedFlight {
  final String saveId;
  final double savedPrice;
  final double currentPrice;
  final bool priceChanged;
  final double priceDifference;
  final DateTime savedAt;
  final Flight flight;

  SavedFlight({
    required this.saveId,
    required this.savedPrice,
    required this.currentPrice,
    required this.priceChanged,
    required this.priceDifference,
    required this.savedAt,
    required this.flight,
  });

  factory SavedFlight.fromJson(Map<String, dynamic> json) {
    return SavedFlight(
      saveId: json['save_id'],
      savedPrice: (json['saved_price'] as num).toDouble(),
      currentPrice: (json['current_price'] as num).toDouble(),
      priceChanged: json['price_changed'] ?? false,
      priceDifference: (json['price_difference'] as num).toDouble(),
      savedAt: DateTime.parse(json['saved_at']),
      flight: Flight.fromJson(json), // The query flattens flight fields into the top level
    );
  }
}
