// lib/features/upcoming_trips/domain/entities/upcoming_trip_entity.dart

import 'package:equatable/equatable.dart';
import 'traveller_entity.dart';

/// One step of the visa tracker the CRM team moves an application along.
class VisaTrackerStep extends Equatable {
  final String key;
  final String label;
  final bool done;
  final String? date; // ISO, set once the step is reached

  const VisaTrackerStep({required this.key, required this.label, required this.done, this.date});

  @override
  List<Object?> get props => [key, label, done, date];
}

/// The visa tracker from the website API: every step, which are done, and
/// whether the application was rejected. [stage] is empty until payment.
class VisaTracker extends Equatable {
  final String stage;
  final String label;
  final bool rejected;
  final String rejectionReason;
  final List<VisaTrackerStep> steps;

  const VisaTracker({
    this.stage = '',
    this.label = '',
    this.rejected = false,
    this.rejectionReason = '',
    this.steps = const [],
  });

  bool get started => stage.isNotEmpty;
  bool get approved => stage == 'approved';

  factory VisaTracker.fromJson(Map<String, dynamic> json) {
    return VisaTracker(
      stage: json['stage'] as String? ?? '',
      label: json['label'] as String? ?? '',
      rejected: json['rejected'] as bool? ?? false,
      rejectionReason: json['rejection_reason'] as String? ?? '',
      steps: ((json['steps'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((s) => VisaTrackerStep(
                key: s['key'] as String? ?? '',
                label: s['label'] as String? ?? '',
                done: s['done'] as bool? ?? false,
                date: s['date'] as String?,
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [stage, label, rejected, rejectionReason, steps];
}

class UpcomingTripEntity extends Equatable {
  final String trackId;
  final VisaTracker tracker;
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
    this.trackId = '',
    this.tracker = const VisaTracker(),
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
    trackId,
    tracker,
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