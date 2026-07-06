import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class DocumentVisaApiService {
  Future<Response> getDocumentVisaApplication({required int applicationId});
  Future<Response> submitDocumentPayment({required Map<String, dynamic> paymentData});
  Future<Response> uploadDocuments({
    required int applicationId,
    required List<Map<String, dynamic>> documents,
    required String userEmail,
  });
}

class DocumentVisaApiServiceImpl implements DocumentVisaApiService {
  final Dio dio;

  DocumentVisaApiServiceImpl(this.dio);

  @override
  Future<Response> getDocumentVisaApplication({required int applicationId}) async {
    try {
      final url = '${Urls.baseUrl}visa-applications/$applicationId/';

      print('CALLING GET DOCUMENT VISA API: $url');

      final response = await dio.get(url);
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '${Urls.baseUrl}visa-applications/$applicationId/'),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<Response> submitDocumentPayment({required Map<String, dynamic> paymentData}) async {
    try {
      final url = '${Urls.baseUrl}visa-applications/payment/';

      print('CALLING SUBMIT DOCUMENT PAYMENT API: $url');
      print('Payment Data: $paymentData');

      final response = await dio.post(
        url,
        data: paymentData,
      );
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '${Urls.baseUrl}visa-applications/payment/'),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<Response> uploadDocuments({
    required int applicationId,
    required List<Map<String, dynamic>> documents,
    required String userEmail,
  }) async {
    try {
      final url = '${Urls.baseUrl}visa-applications/$applicationId/documents/';

      print('CALLING UPLOAD DOCUMENTS API: $url');
      print('Application ID: $applicationId');
      print('User Email: $userEmail');
      print('Documents count: ${documents.length}');

      // Create FormData for multipart upload
      final formData = FormData();

      // Add user_email as required by backend
      formData.fields.add(MapEntry('user_email', userEmail));

      // Add each document as a file
      for (int i = 0; i < documents.length; i++) {
        final doc = documents[i];
        final file = doc['file']; // PlatformFile

        if (file != null) {
          formData.files.add(
            MapEntry(
              'files',
              await MultipartFile.fromFile(
                file.path,
                filename: file.name,
              ),
            ),
          );

          // Add document type/metadata if available
          if (doc['type'] != null) {
            formData.fields.add(MapEntry('document_types[$i]', doc['type']));
          }
        }
      }

      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('UPLOAD SUCCESS: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      if (e.response != null) {
        print('Error Response: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '${Urls.baseUrl}visa-applications/$applicationId/documents/'),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}