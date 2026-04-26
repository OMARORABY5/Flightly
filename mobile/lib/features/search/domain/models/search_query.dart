import 'package:flightly/features/search/domain/models/airport.dart';

enum TripType { oneWay, roundTrip }
enum CabinClass { economy, premiumEconomy, business, first }

class SearchQuery {
  final TripType tripType;
  final Airport? origin;
  final Airport? destination;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final int adults;
  final int children;
  final int infants;
  final CabinClass cabinClass;

  SearchQuery({
    this.tripType = TripType.roundTrip,
    this.origin,
    this.destination,
    this.departureDate,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.cabinClass = CabinClass.economy,
  });

  SearchQuery copyWith({
    TripType? tripType,
    Airport? origin,
    Airport? destination,
    DateTime? departureDate,
    DateTime? returnDate,
    int? adults,
    int? children,
    int? infants,
    CabinClass? cabinClass,
  }) {
    return SearchQuery(
      tripType: tripType ?? this.tripType,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
      cabinClass: cabinClass ?? this.cabinClass,
    );
  }

  int get totalPassengers => adults + children + infants;
  
  bool get isValid {
    if (origin == null || destination == null) return false;
    if (origin == destination) return false;
    if (departureDate == null) return false;
    if (tripType == TripType.roundTrip && returnDate == null) return false;
    if (returnDate != null && returnDate!.isBefore(departureDate!)) return false;
    if (adults < 1) return false;
    if (infants > adults) return false;
    if (totalPassengers > 8) return false;
    return true;
  }
}
