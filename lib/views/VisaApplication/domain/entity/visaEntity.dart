import 'package:equatable/equatable.dart';

import 'TravellerEntity.dart';

class VisaApplicationEntity extends Equatable {
  final int? id;
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
  final String? paymentReference;
  final String? documentsSubmittedAt;
  final List<TravellerEntity> travellers;
  final List<dynamic> documents;
  final String? created;
  final String? updated;
  final String? userId;

  const VisaApplicationEntity({
    this.id,
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
    this.paymentReference,
    this.documentsSubmittedAt,
    required this.travellers,
    required this.documents,
    this.created,
    this.updated,
    this.userId
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
    userId
  ];
}