// lib/features/upcoming_trips/domain/entities/upcoming_trip_entity.dart

import 'package:equatable/equatable.dart';
import 'traveller_entity.dart';

class UpcomingTripEntity extends Equatable {
  final int id;
  final String destination;
  final String visaType;
  final String onwardDate;
  final String returnDate;
  final int numTravellers;
  final String contactEmail;
  final String contactPhone;
  final String currency;
  final String baseFare;
  final String tax;
  final String total;
  final String status;
  final int currentStep;
  final String paymentReference;
  final String? documentsSubmittedAt;
  final List<TravellerEntity> travellers;
  final List<dynamic> documents;
  final String created;
  final String updated;

  const UpcomingTripEntity({
    required this.id,
    required this.destination,
    required this.visaType,
    required this.onwardDate,
    required this.returnDate,
    required this.numTravellers,
    required this.contactEmail,
    required this.contactPhone,
    required this.currency,
    required this.baseFare,
    required this.tax,
    required this.total,
    required this.status,
    required this.currentStep,
    required this.paymentReference,
    this.documentsSubmittedAt,
    required this.travellers,
    required this.documents,
    required this.created,
    required this.updated,
  });

  @override
  List<Object?> get props => [
    id,
    destination,
    visaType,
    onwardDate,
    returnDate,
    numTravellers,
    contactEmail,
    contactPhone,
    currency,
    baseFare,
    tax,
    total,
    status,
    currentStep,
    paymentReference,
    documentsSubmittedAt,
    travellers,
    documents,
    created,
    updated,
  ];
}