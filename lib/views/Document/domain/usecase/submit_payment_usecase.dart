import '../../../../core/error/data_state.dart';
import '../entity/Document_entity.dart';
import '../repository/document_repository.dart';

class SubmitDocumentPaymentUseCase {
  final DocumentRepository repository;

  SubmitDocumentPaymentUseCase(this.repository);

  Future<DataState<DocumentVisaEntity>> call({required Map<String, dynamic> paymentData}) async {
    return await repository.submitDocumentPayment(paymentData: paymentData);
  }
}