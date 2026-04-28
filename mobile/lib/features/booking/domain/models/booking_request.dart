// booking_request.dart - Request model for creating a booking
class BookingRequest {
  final String userId;
  final String flightId;
  final String? returnFlightId;
  final String tripType;
  final String cabinClass;
  final List<String> passengerIds;
  final String contactEmail;
  final String? contactPhone;

  BookingRequest({
    required this.userId,
    required this.flightId,
    this.returnFlightId,
    this.tripType = 'one_way',
    required this.cabinClass,
    required this.passengerIds,
    required this.contactEmail,
    this.contactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'flight_id': flightId,
      if (returnFlightId != null) 'return_flight_id': returnFlightId,
      'trip_type': tripType,
      'cabin_class': cabinClass,
      'passenger_ids': passengerIds,
      'contact_email': contactEmail,
      if (contactPhone != null) 'contact_phone': contactPhone,
    };
  }
}
