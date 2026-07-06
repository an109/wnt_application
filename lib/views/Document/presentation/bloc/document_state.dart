import 'package:equatable/equatable.dart';

import '../../domain/entity/Document_entity.dart';

abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object?> get props => [];
}

class DocumentInitial extends DocumentState {
  const DocumentInitial();
}

class DocumentLoading extends DocumentState {
  const DocumentLoading();
}

class DocumentLoaded extends DocumentState {
  final DocumentVisaEntity application;

  const DocumentLoaded({required this.application});

  @override
  List<Object?> get props => [application];
}

class DocumentPaymentProcessing extends DocumentState {
  const DocumentPaymentProcessing();
}

class DocumentPaymentSuccess extends DocumentState {
  final DocumentVisaEntity application;

  const DocumentPaymentSuccess({required this.application});

  @override
  List<Object?> get props => [application];
}

class DocumentUploading extends DocumentState {
  const DocumentUploading();
}

class DocumentUploadSuccess extends DocumentState {
  final DocumentVisaEntity application;

  const DocumentUploadSuccess({required this.application});

  @override
  List<Object?> get props => [application];
}

class DocumentError extends DocumentState {
  final String message;

  const DocumentError({required this.message});

  @override
  List<Object?> get props => [message];
}