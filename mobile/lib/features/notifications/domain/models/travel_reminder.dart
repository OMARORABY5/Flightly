// travel_reminder.dart — FLIGHTLY Smart Travel Reminders
// Typed model representing a single scheduled local notification for a trip.

enum TravelReminderType {
  flight24h,       // 24 hours before departure
  flight12h,       // 12 hours before departure
  flight6h,        // 6 hours before departure
  flight2h,        // 2 hours before departure
  baggage,         // Baggage allowance info (fired at booking time)
  arrivalAdvisory, // Airport arrival recommendation (fired 6h before)
  returnFlight24h,
  returnFlight12h,
  returnFlight6h,
  returnFlight2h,
  returnBaggage,
  returnArrivalAdvisory,
  watchlistPriceDrop,
  watchlistFlexibleDate,
  watchlistGoodPrice,
}

class TravelReminder {
  final int notificationId; // Unique int ID for flutter_local_notifications
  final TravelReminderType type;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String bookingId;
  final String? payload; // GoRouter path opened on tap, e.g. '/trips/{bookingId}'

  const TravelReminder({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.bookingId,
    this.payload,
  });
}

class ArrivalAdvice {
  final DateTime recommendedArrivalTime;
  final String bodyText;

  const ArrivalAdvice({
    required this.recommendedArrivalTime,
    required this.bodyText,
  });
}
