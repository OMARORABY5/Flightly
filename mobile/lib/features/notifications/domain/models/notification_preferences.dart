import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  final bool bookingUpdates;
  final bool priceAlerts;
  final bool scheduleUpdates;
  final bool promotional;
  final bool flightReminders;  // 24h/12h/6h/2h departure countdown
  final bool travelAdvisory;   // baggage allowance + airport arrival recommendation

  const NotificationPreferences({
    this.bookingUpdates = true,
    this.priceAlerts = true,
    this.scheduleUpdates = true,
    this.promotional = false,
    this.flightReminders = true,
    this.travelAdvisory = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      bookingUpdates: json['booking_updates'] as bool? ?? true,
      priceAlerts: json['price_alerts'] as bool? ?? true,
      scheduleUpdates: json['schedule_updates'] as bool? ?? true,
      promotional: json['promotional'] as bool? ?? false,
      flightReminders: json['flight_reminders'] as bool? ?? true,
      travelAdvisory: json['travel_advisory'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_updates': bookingUpdates,
      'price_alerts': priceAlerts,
      'schedule_updates': scheduleUpdates,
      'promotional': promotional,
      'flight_reminders': flightReminders,
      'travel_advisory': travelAdvisory,
    };
  }

  NotificationPreferences copyWith({
    bool? bookingUpdates,
    bool? priceAlerts,
    bool? scheduleUpdates,
    bool? promotional,
    bool? flightReminders,
    bool? travelAdvisory,
  }) {
    return NotificationPreferences(
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      scheduleUpdates: scheduleUpdates ?? this.scheduleUpdates,
      promotional: promotional ?? this.promotional,
      flightReminders: flightReminders ?? this.flightReminders,
      travelAdvisory: travelAdvisory ?? this.travelAdvisory,
    );
  }

  @override
  List<Object?> get props => [bookingUpdates, priceAlerts, scheduleUpdates, promotional, flightReminders, travelAdvisory];
}
