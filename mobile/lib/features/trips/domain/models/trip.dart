// trip.dart — FLIGHTLY My Trips Domain Model
// Represents a summarised booking for the My Trips tab list.

class TripFlight {
  final String flightNumber;
  final String airlineName;
  final String airlineCode;
  final String? airlineLogoUrl;
  final String originIata;
  final String destinationIata;
  final String? originCity;
  final String? originName;
  final String? destinationCity;
  final String? destinationName;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int durationMinutes;
  final int stops;

  TripFlight({
    required this.flightNumber,
    required this.airlineName,
    required this.airlineCode,
    this.airlineLogoUrl,
    required this.originIata,
    required this.destinationIata,
    this.originCity,
    this.originName,
    this.destinationCity,
    this.destinationName,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.stops,
  });

  factory TripFlight.fromJson(Map<String, dynamic> json) {
    return TripFlight(
      flightNumber: json['flight_number'] ?? '',
      airlineName: json['airline_name'] ?? '',
      airlineCode: json['airline_code'] ?? '',
      airlineLogoUrl: json['airline_logo_url'],
      originIata: json['origin_iata'] ?? '',
      destinationIata: json['destination_iata'] ?? '',
      originCity: json['origin_city'],
      originName: json['origin_name'],
      destinationCity: json['destination_city'],
      destinationName: json['destination_name'],
      departureTime: DateTime.parse(json['departure_time']),
      arrivalTime: DateTime.parse(json['arrival_time']),
      durationMinutes: json['duration_minutes'] ?? 0,
      stops: json['stops'] ?? 0,
    );
  }
}

class Trip {
  final String id;
  final String reference;
  final String status;          // pending | confirmed | cancelled
  final String paymentStatus;   // unpaid | paid | refunded
  final String tripType;        // one_way | round_trip
  final String cabinClass;
  final double totalPrice;
  final String contactEmail;
  final String? contactPhone;
  final DateTime createdAt;
  final int passengerCount;
  final List<String> passengers;
  final TripFlight flight;
  final TripFlight? returnFlight; // Only set for round_trip bookings

  // Modify & Cancel Feature
  final double? refundAmount;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  Trip({
    required this.id,
    required this.reference,
    required this.status,
    required this.paymentStatus,
    required this.tripType,
    required this.cabinClass,
    required this.totalPrice,
    required this.contactEmail,
    this.contactPhone,
    required this.createdAt,
    required this.passengerCount,
    required this.passengers,
    required this.flight,
    this.returnFlight,
    this.refundAmount,
    this.cancelledAt,
    this.cancellationReason,
  });

  bool get isRoundTrip => tripType == 'round_trip';

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      reference: json['reference'] ?? '',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      tripType: json['trip_type'] ?? 'one_way',
      cabinClass: json['cabin_class'] ?? 'economy',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      contactEmail: json['contact_email'] ?? '',
      contactPhone: json['contact_phone'],
      createdAt: DateTime.parse(json['created_at']),
      passengerCount: json['passenger_count'] ?? 1,
      passengers: (json['passengers'] as List<dynamic>?)?.map((e) => e['full_name'] as String).toList() ?? [],
      flight: TripFlight.fromJson(json['flight'] ?? {}),
      returnFlight: json['return_flight'] != null
          ? TripFlight.fromJson(json['return_flight'])
          : null,
      refundAmount: (json['refund_amount'] as num?)?.toDouble(),
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
      cancellationReason: json['cancellation_reason'],
    );
  }

  bool get isUpcoming => status == 'confirmed' && flight.departureTime.isAfter(DateTime.now());
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'confirmed' && flight.departureTime.isBefore(DateTime.now());
}
