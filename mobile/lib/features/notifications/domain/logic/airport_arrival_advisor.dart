// airport_arrival_advisor.dart — FLIGHTLY Airport Arrival Rule Engine
// Pure Dart, zero dependencies, fully testable.
// Produces a recommended airport arrival time and notification copy
// based on flight characteristics using conservative rule-based logic.
//
// RULES (confirmed by user):
//   - Always treat all flights as international (3h base buffer — safest default)
//   - Has checked baggage → +30 min
//   - Passenger count > 2 → +15 min
//   - Evening peak departure (16:00–20:00) → +15 min
//   - Maximum cap: 4h before departure

import 'package:flightly/features/notifications/domain/models/travel_reminder.dart';

class AirportArrivalAdvisor {
  static const int _baseBufferMinutes = 180; // 3h — always international
  static const int _baggageBufferMinutes = 30;
  static const int _largeGroupBufferMinutes = 15;
  static const int _eveningPeakBufferMinutes = 15;
  static const int _maxBufferMinutes = 240; // 4h cap

  /// Computes the recommended arrival time and generates message copy.
  ArrivalAdvice advise({
    required DateTime departureTime,
    required int passengerCount,
    required int baggageCheckedKg,
  }) {
    int bufferMinutes = _baseBufferMinutes;

    // Add buffer for checked baggage
    if (baggageCheckedKg > 0) {
      bufferMinutes += _baggageBufferMinutes;
    }

    // Add buffer for large groups
    if (passengerCount > 2) {
      bufferMinutes += _largeGroupBufferMinutes;
    }

    // Add buffer for evening peak departure
    final hour = departureTime.hour;
    final bool isEveningPeak = hour >= 16 && hour < 20;
    if (isEveningPeak) {
      bufferMinutes += _eveningPeakBufferMinutes;
    }

    // Cap at max
    bufferMinutes = bufferMinutes.clamp(0, _maxBufferMinutes);

    final recommendedArrival = departureTime.subtract(Duration(minutes: bufferMinutes));

    final arrivalHour = recommendedArrival.hour.toString().padLeft(2, '0');
    final arrivalMinute = recommendedArrival.minute.toString().padLeft(2, '0');
    final arrivalTimeStr = '$arrivalHour:$arrivalMinute';

    String bodyText;
    if (isEveningPeak) {
      bodyText =
          'Evening departures tend to be busy. We suggest arriving by $arrivalTimeStr for a smooth check-in experience.';
    } else if (baggageCheckedKg > 0) {
      bodyText =
          'Baggage drop and security may take extra time. Recommended airport arrival: $arrivalTimeStr.';
    } else {
      bodyText =
          'Recommended airport arrival: by $arrivalTimeStr for a comfortable check-in experience.';
    }

    return ArrivalAdvice(
      recommendedArrivalTime: recommendedArrival,
      bodyText: bodyText,
    );
  }

  /// Returns the formatted recommended arrival time as a human-readable string.
  String formatArrivalTime(DateTime arrivalTime) {
    final h = arrivalTime.hour.toString().padLeft(2, '0');
    final m = arrivalTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
