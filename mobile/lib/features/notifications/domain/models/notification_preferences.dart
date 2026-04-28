import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  final bool bookingUpdates;
  final bool priceAlerts;
  final bool scheduleUpdates;
  final bool promotional;

  const NotificationPreferences({
    this.bookingUpdates = true,
    this.priceAlerts = true,
    this.scheduleUpdates = true,
    this.promotional = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      bookingUpdates: json['booking_updates'] as bool? ?? true,
      priceAlerts: json['price_alerts'] as bool? ?? true,
      scheduleUpdates: json['schedule_updates'] as bool? ?? true,
      promotional: json['promotional'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_updates': bookingUpdates,
      'price_alerts': priceAlerts,
      'schedule_updates': scheduleUpdates,
      'promotional': promotional,
    };
  }

  NotificationPreferences copyWith({
    bool? bookingUpdates,
    bool? priceAlerts,
    bool? scheduleUpdates,
    bool? promotional,
  }) {
    return NotificationPreferences(
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      scheduleUpdates: scheduleUpdates ?? this.scheduleUpdates,
      promotional: promotional ?? this.promotional,
    );
  }

  @override
  List<Object?> get props => [bookingUpdates, priceAlerts, scheduleUpdates, promotional];
}
