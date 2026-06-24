import 'package:wander_nova/views/MyBookings/visa/data/models/travellerModel.dart';
import '../../../../VisaApplication/domain/entity/visaEntity.dart';

class VisaApplicationModel extends VisaApplicationEntity {
  const VisaApplicationModel({
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

  factory VisaApplicationModel.fromJson(Map<String, dynamic> json) {
    List<TravellerModel> travellersList = [];
    if (json['travellers'] != null) {
      travellersList = (json['travellers'] as List)
          .map((traveller) => TravellerModel.fromJson(traveller))
          .toList();
    }

    return VisaApplicationModel(
      id: json['id'] ?? 0,
      destination: json['destination'] ?? '',
      visaType: json['visaType'] ?? '',
      onwardDate: json['onwardDate'] ?? '',
      returnDate: json['returnDate'] ?? '',
      numTravellers: json['numTravellers'] ?? 0,
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      currency: json['currency'] ?? '',
      baseFare: json['baseFare'] ?? '',
      tax: json['tax'] ?? '',
      total: json['total'] ?? '',
      status: json['status'] ?? '',
      currentStep: json['currentStep'] ?? 0,
      paymentReference: json['paymentReference'] ?? '',
      documentsSubmittedAt: json['documentsSubmittedAt']?.toString(),
      travellers: travellersList,
      documents: json['documents'] ?? [],
      created: json['created']?.toString() ?? '',
      updated: json['updated']?.toString() ?? '',
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
      'travellers': travellers.map((t) => (t as TravellerModel).toJson()).toList(),
      'documents': documents,
      'created': created,
      'updated': updated,
    };
  }
}