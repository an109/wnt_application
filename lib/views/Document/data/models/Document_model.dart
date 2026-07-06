
import '../../domain/entity/Document_entity.dart';

class DocumentVisaModel extends DocumentVisaEntity {
  const DocumentVisaModel({
    required int id,
    required String trackId,
    required String destination,
    required String visaType,
    required String onwardDate,
    required String returnDate,
    required int numTravellers,
    required String contactEmail,
    required String contactPhone,
    required String currency,
    required String baseFare,
    required String tax,
    required String total,
    required String status,
    required int currentStep,
    required String paymentReference,
    required String paymentStatus,
    required DateTime? paymentDate,
    required String paymentMode,
    required DateTime? documentsSubmittedAt,
    required List<TravellerModel> travellers,
    required List<DocumentModel> documents,
    required DateTime created,
    required DateTime updated,
  }) : super(
    id: id,
    trackId: trackId,
    destination: destination,
    visaType: visaType,
    onwardDate: onwardDate,
    returnDate: returnDate,
    numTravellers: numTravellers,
    contactEmail: contactEmail,
    contactPhone: contactPhone,
    currency: currency,
    baseFare: baseFare,
    tax: tax,
    total: total,
    status: status,
    currentStep: currentStep,
    paymentReference: paymentReference,
    paymentStatus: paymentStatus,
    paymentDate: paymentDate,
    paymentMode: paymentMode,
    documentsSubmittedAt: documentsSubmittedAt,
    travellers: travellers,
    documents: documents,
    created: created,
    updated: updated,
  );

  factory DocumentVisaModel.fromJson(Map<String, dynamic> json) {
    return DocumentVisaModel(
      id: json['id'] ?? 0,
      trackId: json['track_id'] ?? '',
      destination: json['destination'] ?? '',
      visaType: json['visaType'] ?? '',
      onwardDate: json['onwardDate'] ?? '',
      returnDate: json['returnDate'] ?? '',
      numTravellers: json['numTravellers'] ?? 0,
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      currency: json['currency'] ?? '',
      baseFare: json['baseFare'] ?? '0',
      tax: json['tax'] ?? '0',
      total: json['total'] ?? '0',
      status: json['status'] ?? '',
      currentStep: json['currentStep'] ?? 0,
      paymentReference: json['paymentReference'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
      paymentMode: json['payment_mode'] ?? '',
      documentsSubmittedAt: json['documentsSubmittedAt'] != null
          ? DateTime.parse(json['documentsSubmittedAt'])
          : null,
      travellers: (json['travellers'] as List<dynamic>?)
          ?.map((t) => TravellerModel.fromJson(t))
          .toList() ??
          [],
      documents: (json['documents'] as List<dynamic>?)
          ?.map((d) => DocumentModel.fromJson(d))
          .toList() ??
          [],
      created: json['created'] != null
          ? DateTime.parse(json['created'])
          : DateTime.now(),
      updated: json['updated'] != null
          ? DateTime.parse(json['updated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'track_id': trackId,
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
      'payment_status': paymentStatus,
      'payment_date': paymentDate?.toIso8601String(),
      'payment_mode': paymentMode,
      'documentsSubmittedAt': documentsSubmittedAt?.toIso8601String(),
      'travellers': travellers.map((t) => t.toString()).toList(),
      'documents': documents.map((d) => d.toString()).toList(),
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }
}

class TravellerModel extends TravellerEntity {
  const TravellerModel({
    required int id,
    required int travellerIndex,
    required String title,
    required String firstName,
    required String lastName,
    required String dob,
    required String nationality,
    required String passportNo,
    required String contactNumber,
    required String emailId,
  }) : super(
    id: id,
    travellerIndex: travellerIndex,
    title: title,
    firstName: firstName,
    lastName: lastName,
    dob: dob,
    nationality: nationality,
    passportNo: passportNo,
    contactNumber: contactNumber,
    emailId: emailId,
  );

  factory TravellerModel.fromJson(Map<String, dynamic> json) {
    return TravellerModel(
      id: json['id'] ?? 0,
      travellerIndex: json['travellerIndex'] ?? 0,
      title: json['title'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dob: json['dob'] ?? '',
      nationality: json['nationality'] ?? '',
      passportNo: json['passportNo'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      emailId: json['emailId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travellerIndex': travellerIndex,
      'title': title,
      'firstName': firstName,
      'lastName': lastName,
      'dob': dob,
      'nationality': nationality,
      'passportNo': passportNo,
      'contactNumber': contactNumber,
      'emailId': emailId,
    };
  }
}

class DocumentModel extends DocumentEntity {
  const DocumentModel({
    required int id,
    required String originalFilename,
    required String fileUrl,
    required DateTime created,
  }) : super(
    id: id,
    originalFilename: originalFilename,
    fileUrl: fileUrl,
    created: created,
  );

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? 0,
      originalFilename: json['originalFilename'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      created: json['created'] != null
          ? DateTime.parse(json['created'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalFilename': originalFilename,
      'fileUrl': fileUrl,
      'created': created.toIso8601String(),
    };
  }
}