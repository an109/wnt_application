
import '../../domain/entity/visaEntity.dart';
import 'TravellerModel.dart';

class VisaApplicationModel extends VisaApplicationEntity {
  const VisaApplicationModel({
    super.id,
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
    super.paymentReference,
    super.documentsSubmittedAt,
    required super.travellers,
    required super.documents,
    super.created,
    super.updated,
  });

  factory VisaApplicationModel.fromJson(Map<String, dynamic> json) {
    return VisaApplicationModel(
      id: json['id'] as int?,
      destination: json['destination'] as String? ?? '',
      visaType: json['visaType'] as String? ?? '',
      onwardDate: json['onwardDate'] as String? ?? '',
      returnDate: json['returnDate'] as String? ?? '',
      numTravellers: json['numTravellers'] as int? ?? 0,
      contactEmail: json['contactEmail'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      baseFare: json['baseFare']?.toString() ?? '0.00',
      tax: json['tax']?.toString() ?? '0.00',
      total: json['total']?.toString() ?? '0.00',
      status: json['status'] as String? ?? '',
      currentStep: json['currentStep'] as int? ?? 1,
      paymentReference: json['paymentReference'] as String?,
      documentsSubmittedAt: json['documentsSubmittedAt'] as String?,
      travellers: (json['travellers'] as List<dynamic>?)
          ?.map((t) => TravellerModel.fromJson(t as Map<String, dynamic>))
          .toList() ??
          [],
      documents: json['documents'] as List<dynamic>? ?? [],
      created: json['created'] as String?,
      updated: json['updated'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
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
      if (paymentReference != null) 'paymentReference': paymentReference,
      if (documentsSubmittedAt != null)
        'documentsSubmittedAt': documentsSubmittedAt,
      'travellersData': travellers.map((t) {
        if (t is TravellerModel) {
          return t.toJson();
        }
        return TravellerModel.fromEntity(t).toJson();
      }).toList(),
      'documents': documents,
      'user_email': contactEmail,
    };
  }

  factory VisaApplicationModel.fromEntity(VisaApplicationEntity entity) {
    return VisaApplicationModel(
      id: entity.id,
      destination: entity.destination,
      visaType: entity.visaType,
      onwardDate: entity.onwardDate,
      returnDate: entity.returnDate,
      numTravellers: entity.numTravellers,
      contactEmail: entity.contactEmail,
      contactPhone: entity.contactPhone,
      currency: entity.currency,
      baseFare: entity.baseFare,
      tax: entity.tax,
      total: entity.total,
      status: entity.status,
      currentStep: entity.currentStep,
      paymentReference: entity.paymentReference,
      documentsSubmittedAt: entity.documentsSubmittedAt,
      travellers: entity.travellers,
      documents: entity.documents,
      created: entity.created,
      updated: entity.updated,
    );
  }
}