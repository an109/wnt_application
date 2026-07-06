import '../../../../core/error/data_state.dart';
import '../entity/Document_entity.dart';
import '../repository/document_repository.dart';

class UploadDocumentsUseCase {
  final DocumentRepository repository;

  UploadDocumentsUseCase(this.repository);

  Future<DataState<DocumentVisaEntity>> call({
    required int applicationId,
    required List<Map<String, dynamic>> documents,
    required String userEmail,
  }) async {
    return await repository.uploadDocuments(
      applicationId: applicationId,
      documents: documents,
      userEmail: userEmail,
    );
  }
}