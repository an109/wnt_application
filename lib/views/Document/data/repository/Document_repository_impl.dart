import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/Document_entity.dart';
import '../../domain/repository/document_repository.dart';
import '../data_source/document_api_service.dart';
import '../models/Document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentVisaApiService apiService;

  DocumentRepositoryImpl(this.apiService);

  @override
  Future<DataState<DocumentVisaEntity>> getDocumentVisaApplication({
    required int applicationId,
  }) async {
    try {
      final response = await apiService.getDocumentVisaApplication(
        applicationId: applicationId,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final applicationData = response.data['application'] as Map<String, dynamic>;
        final application = DocumentVisaModel.fromJson(applicationData);
        return DataSuccess(application);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to fetch visa application',
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: RequestOptions(path: '')),
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<DocumentVisaEntity>> submitDocumentPayment({
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      final response = await apiService.submitDocumentPayment(
        paymentData: paymentData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final applicationData = response.data['application'] as Map<String, dynamic>;
        final application = DocumentVisaModel.fromJson(applicationData);
        return DataSuccess(application);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Payment submission failed',
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: RequestOptions(path: '')),
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<DocumentVisaEntity>> uploadDocuments({
    required int applicationId,
    required List<Map<String, dynamic>> documents,
    required String userEmail,
  }) async {
    try {
      final response = await apiService.uploadDocuments(
        applicationId: applicationId,
        documents: documents,
        userEmail: userEmail,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final applicationData = response.data['application'] as Map<String, dynamic>;
        final application = DocumentVisaModel.fromJson(applicationData);
        return DataSuccess(application);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to upload documents',
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: RequestOptions(path: '')),
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}