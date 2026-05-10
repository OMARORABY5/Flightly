import 'package:flightly/features/search/domain/models/airport.dart';

enum TripType { oneWay, roundTrip }
enum CabinClass { economy, business, first }

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
    this.tripType = TripType.oneWay,
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
    bool clearReturnDate = false,
    int? adults,
    int? children,
    int? infants,
    CabinClass? cabinClass,
  }) {
    final newTripType = tripType ?? this.tripType;
    return SearchQuery(
      tripType: newTripType,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      returnDate: newTripType == TripType.oneWay 
          ? null 
          : (clearReturnDate ? null : (returnDate ?? this.returnDate)),
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
      cabinClass: cabinClass ?? this.cabinClass,
    );
  }

  int get totalPassengers => adults + children + infants;
  
  bool get isValid => validationError == null;

  String? get validationError {
    if (origin == null || destination == null) return 'Please select origin and destination airports.';
    if (origin == destination) return 'Origin and destination cannot be the same.';
    if (departureDate == null) return 'Please select a departure date.';
    if (tripType == TripType.roundTrip && returnDate == null) return 'Please select a return date.';
    if (returnDate != null && returnDate!.isBefore(departureDate!)) return 'Return date cannot be before departure date.';
    if (adults < 1) return 'Please select at least 1 adult passenger.';
    if (infants > adults) return 'Number of infants cannot exceed number of adults.';
    if (totalPassengers > 8) return 'Maximum 8 passengers allowed per booking.';
    return null;
  }
}
