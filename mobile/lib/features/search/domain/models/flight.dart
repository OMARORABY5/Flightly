// flight.dart - Flight Model
import 'package:flightly/features/search/domain/models/airport.dart';

class Flight {
  final String id;
  final String flightNumber;
  final String airlineCode;
  final String airlineName;
  final String? airlineLogoUrl;
  final String originIata;
  final String destinationIata;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int durationMinutes;
  final int stops;
  final String cabinClass;
  final double basePrice;
  final int availableSeats;
  final int baggageCabinKg;
  final int baggageCheckedKg;
  final bool isRefundable;
  final double totalPrice;
  final List<String> labels;

  // Enriched fields from joining airports
  final String? originCity;
  final String? originName;
  final String? destinationCity;
  final String? destinationName;

  // Phase 5: Smart Pricing & Details fields (only present in /flights/:id response)
  final String? seatAvailability;
  final String? priceTrend;
  final int? priceChangePercent;
  final String? fareLabel;
  final Map<String, dynamic>? policy;

  Flight({
    required this.id,
    required this.flightNumber,
    required this.airlineCode,
    required this.airlineName,
    this.airlineLogoUrl,
    required this.originIata,
    required this.destinationIata,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.stops,
    required this.cabinClass,
    required this.basePrice,
    required this.availableSeats,
    required this.baggageCabinKg,
    required this.baggageCheckedKg,
    required this.isRefundable,
    required this.totalPrice,
    required this.labels,
    this.originCity,
    this.originName,
    this.destinationCity,
    this.destinationName,
    this.seatAvailability,
    this.priceTrend,
    this.priceChangePercent,
    this.fareLabel,
    this.policy,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'] ?? json['flight_id'] ?? '',
      flightNumber: json['flight_number'] ?? '',
      airlineCode: json['airline_code'] ?? '',
      airlineName: json['airline_name'] ?? '',
      airlineLogoUrl: json['airline_logo_url'],
      originIata: json['origin_iata'] ?? '',
      destinationIata: json['destination_iata'] ?? '',
      departureTime: json['departure_time'] != null ? DateTime.parse(json['departure_time']) : DateTime.now(),
      arrivalTime: json['arrival_time'] != null ? DateTime.parse(json['arrival_time']) : DateTime.now(),
      durationMinutes: json['duration_minutes'] ?? 0,
      stops: json['stops'] ?? 0,
      cabinClass: json['cabin_class'] ?? json['flight_cabin'] ?? 'economy',
      basePrice: json['base_price'] is num ? (json['base_price'] as num).toDouble() : double.tryParse(json['base_price']?.toString() ?? '0') ?? 0.0,
      availableSeats: json['available_seats'] ?? 0,
      baggageCabinKg: json['baggage_cabin_kg'] ?? 7,
      baggageCheckedKg: json['baggage_checked_kg'] ?? 23,
      isRefundable: json['is_refundable'] ?? false,
      totalPrice: json['total_price'] is num ? (json['total_price'] as num).toDouble() : double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      labels: (json['labels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      originCity: json['origin_city'],
      originName: json['origin_name'],
      destinationCity: json['destination_city'],
      destinationName: json['destination_name'],
      seatAvailability: json['seat_availability'],
      priceTrend: json['price_trend'],
      priceChangePercent: json['price_change_percent'],
      fareLabel: json['fare_label'],
      policy: json['policy'] != null ? Map<String, dynamic>.from(json['policy']) : null,
    );
  }
}

class PaginatedFlightResponse {
  final List<Flight> flights;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginatedFlightResponse({
    required this.flights,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginatedFlightResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] ?? {};
    return PaginatedFlightResponse(
      flights: (json['flights'] as List<dynamic>?)?.map((e) => Flight.fromJson(e)).toList() ?? [],
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 20,
      total: pagination['total'] ?? 0,
      totalPages: pagination['total_pages'] ?? 1,
      hasNext: pagination['has_next'] ?? false,
      hasPrev: pagination['has_prev'] ?? false,
    );
  }
}
