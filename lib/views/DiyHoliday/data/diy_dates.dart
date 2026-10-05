import 'package:flutter/material.dart';

/// Departure-date rules for the DIY flow.
///
/// The price endpoint (**API 5 — POST /packages/{share_id}/price/**) refuses
/// a departure that has already gone, so the form, the calendar and the
/// restored search all clamp to at least today.
class DiyDates {
  const DiyDates._();

  /// Days ahead the form opens on. Far enough out that live fares exist for
  /// the with-flight price call rather than last-minute-only inventory.
  static const int defaultLeadDays = 7;

  static DateTime today() => DateUtils.dateOnly(DateTime.now());

  /// The earliest date the API will price: today.
  static DateTime earliestDeparture() => today();

  /// What the search form opens on.
  static DateTime defaultDeparture() =>
      today().add(const Duration(days: defaultLeadDays));

  /// Pushes a date forward to [earliestDeparture] if it has gone; passes
  /// null through untouched.
  static DateTime? clampToFuture(DateTime? date) {
    if (date == null) return null;
    final earliest = earliestDeparture();
    final dateOnly = DateUtils.dateOnly(date);
    return dateOnly.isBefore(earliest) ? earliest : dateOnly;
  }
}
