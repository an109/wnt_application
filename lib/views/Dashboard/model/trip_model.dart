import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- DATA MODEL ---
class TripItem {
  final String refId;
  final String destination;
  final String type;
  final int price;
  final String status;
  final String bookedDate;
  final String applicantCount;

  TripItem({
    required this.refId,
    required this.destination,
    required this.type,
    required this.price,
    required this.status,
    required this.bookedDate,
    required this.applicantCount,
  });
}