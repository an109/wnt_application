import 'package:flutter/material.dart';

import 'package:wander_nova/views/home/flight/flight_calendar_screen.dart';

/// Full-screen check-in / check-out date picker for the hotel search flow —
/// the same calendar the flight SearchCard uses ([FlightCalendarScreen]),
/// just re-worded for hotels ("Check-in" / "Check-out"). Kept as its own
/// screen so `hotel_search_card.dart` opens a dedicated route, exactly like
/// the flight card does.
///
/// Pops `{'departure': DateTime?, 'return': DateTime?}` (the same keys the
/// hotel card already reads for check-in / check-out).
class HotelCalendarScreen extends StatelessWidget {
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DateTime firstDate;
  final DateTime lastDate;

  /// Focus the check-out picker first when the user tapped that half of the
  /// date card.
  final bool startWithCheckOut;

  const HotelCalendarScreen({
    super.key,
    this.checkIn,
    this.checkOut,
    required this.firstDate,
    required this.lastDate,
    this.startWithCheckOut = false,
  });

  @override
  Widget build(BuildContext context) {
    return FlightCalendarScreen(
      initialDeparture: checkIn,
      initialReturn: checkOut,
      // Hotels always need both dates, so the second picker is always shown.
      isRoundTrip: true,
      startWithReturn: startWithCheckOut,
      firstDate: firstDate,
      lastDate: lastDate,
      startLabel: 'Check-in',
      endLabel: 'Check-out',
      startEmptyText: 'Select check-in',
      endEmptyText: 'Select check-out',
    );
  }
}
