// travel_reminder_scheduler.dart — FLIGHTLY Travel Reminder Orchestrator
// Given a confirmed Booking, produces and schedules all relevant reminders:
//   - 4 flight countdown reminders (24h, 12h, 6h, 2h before departure)
//   - 1 baggage allowance reminder (immediate at booking time)
//   - 1 airport arrival advisory (6h before departure)
// For round-trip bookings, a second set is scheduled for the return leg.
//
// Scheduling is gated by user's NotificationPreferences:
//   - flightReminders  → controls 24h/12h/6h/2h countdown reminders
//   - travelAdvisory   → controls baggage + arrival advisory

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flightly/features/booking/domain/models/booking.dart';
import 'package:flightly/features/search/domain/models/flight.dart';
import 'package:flightly/features/notifications/domain/models/travel_reminder.dart';
import 'package:flightly/features/notifications/domain/logic/airport_arrival_advisor.dart';
import 'package:flightly/features/notifications/services/travel_reminder_service.dart';

class TravelReminderScheduler {
  final TravelReminderService _service;
  final AirportArrivalAdvisor _advisor = AirportArrivalAdvisor();

  static const String _permissionAskedKey = 'travel_reminder_permission_asked';

  TravelReminderScheduler(this._service);

  // ─── Public entry point ───────────────────────────────────────────────────────
  Future<void> scheduleForBooking(Booking booking) async {
    await _service.initialize();

    // Request permission on first booking confirmation (once only)
    await _requestPermissionIfNeeded();

    final prefs = await _loadPrefs();

    // Outbound flight reminders
    await _scheduleFlightReminders(
      booking: booking,
      flight: booking.outboundFlight,
      passengerCount: booking.passengers.length,
      isReturn: false,
      flightRemindersEnabled: prefs['flightReminders'] as bool,
      travelAdvisoryEnabled: prefs['travelAdvisory'] as bool,
    );

    // Return flight reminders (round-trip only)
    if (booking.returnFlight != null) {
      await _scheduleFlightReminders(
        booking: booking,
        flight: booking.returnFlight!,
        passengerCount: booking.passengers.length,
        isReturn: true,
        flightRemindersEnabled: prefs['flightReminders'] as bool,
        travelAdvisoryEnabled: prefs['travelAdvisory'] as bool,
      );
    }

    debugPrint('[TravelReminderScheduler] Scheduling complete for booking ${booking.reference}');
  }

  // ─── Schedule reminders for one leg ──────────────────────────────────────────
  Future<void> _scheduleFlightReminders({
    required Booking booking,
    required Flight flight,
    required int passengerCount,
    required bool isReturn,
    required bool flightRemindersEnabled,
    required bool travelAdvisoryEnabled,
  }) async {
    final departure = flight.departureTime;
    final dest = flight.destinationCity ?? flight.destinationIata;
    final flightNum = flight.flightNumber;
    final depTime = DateFormat('HH:mm').format(departure);

    // ── Flight Countdown Reminders ─────────────────────────────────────────────
    if (flightRemindersEnabled) {
      final countdowns = isReturn
          ? [
              (TravelReminderType.returnFlight24h, const Duration(hours: 24)),
              (TravelReminderType.returnFlight12h, const Duration(hours: 12)),
              (TravelReminderType.returnFlight6h, const Duration(hours: 6)),
              (TravelReminderType.returnFlight2h, const Duration(hours: 2)),
            ]
          : [
              (TravelReminderType.flight24h, const Duration(hours: 24)),
              (TravelReminderType.flight12h, const Duration(hours: 12)),
              (TravelReminderType.flight6h, const Duration(hours: 6)),
              (TravelReminderType.flight2h, const Duration(hours: 2)),
            ];

      for (final (type, offset) in countdowns) {
        final scheduledAt = departure.subtract(offset);
        final reminder = TravelReminder(
          notificationId: TravelReminderService.notificationIdFor(booking.id, type),
          type: type,
          title: _titleFor(type, dest, flightNum, depTime),
          body: _bodyFor(type, dest, flightNum, depTime),
          scheduledAt: scheduledAt,
          bookingId: booking.id,
          payload: '/trips/${booking.id}',
        );
        await _service.scheduleReminder(reminder);
      }
    }

    // ── Baggage Allowance Reminder ─────────────────────────────────────────────
    if (travelAdvisoryEnabled) {
      final baggageType =
          isReturn ? TravelReminderType.returnBaggage : TravelReminderType.baggage;
      final baggageReminder = TravelReminder(
        notificationId: TravelReminderService.notificationIdFor(booking.id, baggageType),
        type: baggageType,
        title: 'Your baggage allowance${isReturn ? ' (Return)' : ''}',
        body: _baggageBody(flight),
        scheduledAt: DateTime.now().add(const Duration(seconds: 5)), // Immediate
        bookingId: booking.id,
        payload: '/trips/${booking.id}',
      );
      await _service.scheduleReminder(baggageReminder);

      // ── Arrival Advisory ──────────────────────────────────────────────────────
      final advice = _advisor.advise(
        departureTime: departure,
        passengerCount: passengerCount,
        baggageCheckedKg: flight.baggageCheckedKg,
      );

      final advisoryType =
          isReturn ? TravelReminderType.returnArrivalAdvisory : TravelReminderType.arrivalAdvisory;
      final advisoryScheduledAt = departure.subtract(const Duration(hours: 6));

      final advisoryReminder = TravelReminder(
        notificationId: TravelReminderService.notificationIdFor(booking.id, advisoryType),
        type: advisoryType,
        title: 'Time to head to the airport${isReturn ? ' (Return)' : ''}',
        body: advice.bodyText,
        scheduledAt: advisoryScheduledAt,
        bookingId: booking.id,
        payload: '/trips/${booking.id}',
      );
      await _service.scheduleReminder(advisoryReminder);
    }
  }

  // ─── Notification copy ────────────────────────────────────────────────────────
  String _titleFor(TravelReminderType type, String dest, String flightNum, String time) {
    switch (type) {
      case TravelReminderType.flight24h:
      case TravelReminderType.returnFlight24h:
        return 'Your flight is tomorrow ✈️';
      case TravelReminderType.flight12h:
      case TravelReminderType.returnFlight12h:
        return 'Flight Reminder';
      case TravelReminderType.flight6h:
      case TravelReminderType.returnFlight6h:
        return 'Time to prepare';
      case TravelReminderType.flight2h:
      case TravelReminderType.returnFlight2h:
        return 'Boarding is approaching';
      default:
        return 'Flight Reminder';
    }
  }

  String _bodyFor(TravelReminderType type, String dest, String flightNum, String time) {
    switch (type) {
      case TravelReminderType.flight24h:
      case TravelReminderType.returnFlight24h:
        return 'Flight $flightNum to $dest departs at $time. Have a smooth journey.';
      case TravelReminderType.flight12h:
      case TravelReminderType.returnFlight12h:
        return 'Check your documents and pack your bags. Departure to $dest is in 12 hours.';
      case TravelReminderType.flight6h:
      case TravelReminderType.returnFlight6h:
        return 'Your flight to $dest departs in 6 hours. Consider heading to the airport soon.';
      case TravelReminderType.flight2h:
      case TravelReminderType.returnFlight2h:
        return 'Please ensure you are at the airport. Flight $flightNum to $dest boards soon.';
      default:
        return 'Your flight is approaching.';
    }
  }

  String _baggageBody(Flight flight) {
    final cabin = flight.baggageCabinKg;
    final checked = flight.baggageCheckedKg;
    if (checked == 0) {
      return 'Your ticket includes ${cabin}kg cabin baggage. No checked baggage is included with this fare.';
    }
    return 'Your ticket includes ${cabin}kg cabin baggage and ${checked}kg checked baggage. Excess baggage fees may apply if exceeded.';
  }

  // ─── Permission (once only) ───────────────────────────────────────────────────
  Future<void> _requestPermissionIfNeeded() async {
    final sp = await SharedPreferences.getInstance();
    final asked = sp.getBool(_permissionAskedKey) ?? false;
    if (!asked) {
      await _service.requestPermission();
      await sp.setBool(_permissionAskedKey, true);
    }
  }

  // ─── Load preferences from SharedPreferences ─────────────────────────────────
  Future<Map<String, dynamic>> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    return {
      'flightReminders': sp.getBool('pref_flight_reminders') ?? true,
      'travelAdvisory': sp.getBool('pref_travel_advisory') ?? true,
    };
  }
}

// ─── Riverpod Provider ────────────────────────────────────────────────────────
final travelReminderSchedulerProvider = Provider<TravelReminderScheduler>((ref) {
  final service = ref.read(travelReminderServiceProvider);
  return TravelReminderScheduler(service);
});
