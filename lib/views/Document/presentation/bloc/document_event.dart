import 'package:equatable/equatable.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocumentVisa extends DocumentEvent {
  final int applicationId;

  const LoadDocumentVisa({required this.applicationId});

  @override
  List<Object?> get props => [applicationId];
}

class SubmitDocumentPayment extends DocumentEvent {
  final Map<String, dynamic> paymentData;

  const SubmitDocumentPayment({required this.paymentData});

  @override
  List<Object?> get props => [paymentData];
}

class UploadDocuments extends DocumentEvent {
  final int applicationId;
  final List<Map<String, dynamic>> documents;
  final String userEmail;

  const UploadDocuments({
    required this.applicationId,
    required this.documents,
    required this.userEmail,
  });

  @override
  List<Object?> get props => [applicationId, documents, userEmail];
}

class RefreshDocumentVisa extends DocumentEvent {
  final int applicationId;

  const RefreshDocumentVisa({required this.applicationId});

  @override
  List<Object?> get props => [applicationId];
}

class ClearDocumentState extends DocumentEvent {
  const ClearDocumentState();

  @override
  List<Object?> get props => [];
}