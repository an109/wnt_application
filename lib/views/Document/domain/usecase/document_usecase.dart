import '../../../../core/error/data_state.dart';
import '../entity/Document_entity.dart';
import '../repository/document_repository.dart';

class GetDocumentVisaUseCase {
  final DocumentRepository repository;

  GetDocumentVisaUseCase(this.repository);

  Future<DataState<DocumentVisaEntity>> call({required int applicationId}) async {
    return await repository.getDocumentVisaApplication(applicationId: applicationId);
  }
}