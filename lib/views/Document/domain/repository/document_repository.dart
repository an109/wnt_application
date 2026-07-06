import '../../../../core/error/data_state.dart';
import '../entity/Document_entity.dart';

abstract class DocumentRepository {
  Future<DataState<DocumentVisaEntity>> getDocumentVisaApplication({required int applicationId});
  Future<DataState<DocumentVisaEntity>> submitDocumentPayment({required Map<String, dynamic> paymentData});
  Future<DataState<DocumentVisaEntity>> uploadDocuments({
    required int applicationId,
    required List<Map<String, dynamic>> documents,
    required String userEmail,
  });
}