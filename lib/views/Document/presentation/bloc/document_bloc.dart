import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/Document_entity.dart';
import '../../domain/usecase/document_usecase.dart';
import '../../domain/usecase/submit_payment_usecase.dart';
import '../../domain/usecase/upload_document_usecase.dart';
import 'document_event.dart';
import 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final GetDocumentVisaUseCase getDocumentVisaUseCase;
  final SubmitDocumentPaymentUseCase submitDocumentPaymentUseCase;
  final UploadDocumentsUseCase uploadDocumentsUseCase;

  DocumentBloc({
    required this.getDocumentVisaUseCase,
    required this.submitDocumentPaymentUseCase,
    required this.uploadDocumentsUseCase,
  }) : super(const DocumentInitial()) {
    on<LoadDocumentVisa>(_onLoadDocumentVisa);
    on<SubmitDocumentPayment>(_onSubmitDocumentPayment);
    on<UploadDocuments>(_onUploadDocuments);
    on<RefreshDocumentVisa>(_onRefreshDocumentVisa);
    on<ClearDocumentState>(_onClearDocumentState);
  }

  Future<void> _onLoadDocumentVisa(
      LoadDocumentVisa event,
      Emitter<DocumentState> emit,
      ) async {
    emit(const DocumentLoading());

    final result = await getDocumentVisaUseCase(
      applicationId: event.applicationId,
    );

    if (result is DataSuccess<DocumentVisaEntity>) {
      emit(DocumentLoaded(application: result.data!));
    } else if (result is DataFailed<DocumentVisaEntity>) {
      emit(DocumentError(
        message: result.error?.message ?? 'Failed to load application',
      ));
    }
  }

  Future<void> _onSubmitDocumentPayment(
      SubmitDocumentPayment event,
      Emitter<DocumentState> emit,
      ) async {
    emit(const DocumentPaymentProcessing());

    final result = await submitDocumentPaymentUseCase(
      paymentData: event.paymentData,
    );

    if (result is DataSuccess<DocumentVisaEntity>) {
      emit(DocumentPaymentSuccess(application: result.data!));
    } else if (result is DataFailed<DocumentVisaEntity>) {
      emit(DocumentError(
        message: result.error?.message ?? 'Payment failed',
      ));
    }
  }

  Future<void> _onUploadDocuments(
      UploadDocuments event,
      Emitter<DocumentState> emit,
      ) async {
    emit(const DocumentUploading());

    final result = await uploadDocumentsUseCase(
      applicationId: event.applicationId,
      documents: event.documents,
      userEmail: event.userEmail,
    );

    if (result is DataSuccess<DocumentVisaEntity>) {
      emit(DocumentUploadSuccess(application: result.data!));
    } else if (result is DataFailed<DocumentVisaEntity>) {
      emit(DocumentError(
        message: result.error?.message ?? 'Failed to upload documents',
      ));
    }
  }

  Future<void> _onRefreshDocumentVisa(
      RefreshDocumentVisa event,
      Emitter<DocumentState> emit,
      ) async {
    final result = await getDocumentVisaUseCase(
      applicationId: event.applicationId,
    );

    if (result is DataSuccess<DocumentVisaEntity>) {
      emit(DocumentLoaded(application: result.data!));
    } else if (result is DataFailed<DocumentVisaEntity>) {
      emit(DocumentError(
        message: result.error?.message ?? 'Failed to refresh application',
      ));
    }
  }

  void _onClearDocumentState(
      ClearDocumentState event,
      Emitter<DocumentState> emit,
      ) {
    emit(const DocumentInitial());
  }
}