// booking.dart - Booking Domain Model
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/booking/domain/models/passenger.dart';

class Booking {
  final String id;
  final String reference;
  final String status;
  final String paymentStatus;
  final String tripType;
  final String cabinClass;
  final double totalPrice;
  final String contactEmail;
  final String? contactPhone;
  final DateTime createdAt;
  final Flight outboundFlight;
  final Flight? returnFlight;
  final List<Passenger> passengers;

  Booking({
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
    required this.outboundFlight,
    this.returnFlight,
    required this.passengers,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      reference: json['reference'],
      status: json['status'],
      paymentStatus: json['payment_status'],
      tripType: json['trip_type'],
      cabinClass: json['cabin_class'],
      totalPrice: (json['total_price'] as num).toDouble(),
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      createdAt: DateTime.parse(json['created_at']),
      outboundFlight: Flight.fromJson(json['outbound_flight'] ?? json['flight']),
      returnFlight: json['return_flight'] != null 
          ? Flight.fromJson(json['return_flight']) 
          : null,
      passengers: json['passengers'] != null
          ? (json['passengers'] as List).map((e) => Passenger.fromJson(e)).toList()
          : [],
    );
  }
}
