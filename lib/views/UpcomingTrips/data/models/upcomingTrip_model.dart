import '../../domain/entity/upcomingTrip_entity.dart';
import 'traveller_model.dart';

class UpcomingTripModel extends UpcomingTripEntity {
  const UpcomingTripModel({
    required super.id,
    required super.destination,
    required super.visaType,
    required super.onwardDate,
    required super.returnDate,
    required super.numTravellers,
    required super.contactEmail,
    required super.contactPhone,
    required super.currency,
    required super.baseFare,
    required super.tax,
    required super.total,
    required super.status,
    required super.currentStep,
    required super.paymentReference,
    super.documentsSubmittedAt,
    required super.travellers,
    required super.documents,
    required super.created,
    required super.updated,
  });

  factory UpcomingTripModel.fromJson(Map<String, dynamic> json) {
    return UpcomingTripModel(
      id: json['id'] as int? ?? 0,
      destination: json['destination'] as String? ?? '',
      visaType: json['visaType'] as String? ?? '',
      onwardDate: json['onwardDate'] as String? ?? '',
      returnDate: json['returnDate'] as String? ?? '',
      numTravellers: json['numTravellers'] as int? ?? 0,
      contactEmail: json['contactEmail'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      baseFare: json['baseFare'] as String? ?? '0.00',
      tax: json['tax'] as String? ?? '0.00',
      total: json['total'] as String? ?? '0.00',
      status: json['status'] as String? ?? '',
      currentStep: json['currentStep'] as int? ?? 0,
      paymentReference: json['paymentReference'] as String? ?? '',
      documentsSubmittedAt: json['documentsSubmittedAt'] as String?,
      travellers: (json['travellers'] as List<dynamic>?)
          ?.map((e) => TravellerModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      documents: json['documents'] as List<dynamic>? ?? [],
      created: json['created'] as String? ?? '',
      updated: json['updated'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination,
      'visaType': visaType,
      'onwardDate': onwardDate,
      'returnDate': returnDate,
      'numTravellers': numTravellers,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'currency': currency,
      'baseFare': baseFare,
      'tax': tax,
      'total': total,
      'status': status,
      'currentStep': currentStep,
      'paymentReference': paymentReference,
      'documentsSubmittedAt': documentsSubmittedAt,
      'travellers': travellers.map((e) => (e as TravellerModel).toJson()).toList(),
      'documents': documents,
      'created': created,
      'updated': updated,
    };
  }
}