import 'package:equatable/equatable.dart';

class DocumentVisaEntity extends Equatable {
  final int id;
  final String trackId;
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
  final String paymentStatus;
  final DateTime? paymentDate;
  final String paymentMode;
  final DateTime? documentsSubmittedAt;
  final List<TravellerEntity> travellers;
  final List<DocumentEntity> documents;
  final DateTime created;
  final DateTime updated;

  const DocumentVisaEntity({
    required this.id,
    required this.trackId,
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
    required this.paymentStatus,
    required this.paymentDate,
    required this.paymentMode,
    required this.documentsSubmittedAt,
    required this.travellers,
    required this.documents,
    required this.created,
    required this.updated,
  });

  @override
  List<Object?> get props => [
    id,
    trackId,
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
    paymentStatus,
    paymentDate,
    paymentMode,
    documentsSubmittedAt,
    travellers,
    documents,
    created,
    updated,
  ];
}

class TravellerEntity extends Equatable {
  final int id;
  final int travellerIndex;
  final String title;
  final String firstName;
  final String lastName;
  final String dob;
  final String nationality;
  final String passportNo;
  final String contactNumber;
  final String emailId;

  const TravellerEntity({
    required this.id,
    required this.travellerIndex,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.nationality,
    required this.passportNo,
    required this.contactNumber,
    required this.emailId,
  });

  @override
  List<Object?> get props => [
    id,
    travellerIndex,
    title,
    firstName,
    lastName,
    dob,
    nationality,
    passportNo,
    contactNumber,
    emailId,
  ];
}

class DocumentEntity extends Equatable {
  final int id;
  final String originalFilename;
  final String fileUrl;
  final DateTime created;

  const DocumentEntity({
    required this.id,
    required this.originalFilename,
    required this.fileUrl,
    required this.created,
  });

  @override
  List<Object?> get props => [id, originalFilename, fileUrl, created];
}