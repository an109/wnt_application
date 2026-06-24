import 'package:dio/dio.dart';

import '../../../../../core/constants/urls.dart';

abstract class VApiService {
  Future<Response> getVisaApplications({String? userEmail});
}

class VApiServiceImpl implements VApiService {
  final Dio dio;

  VApiServiceImpl(this.dio);

  @override
  Future<Response> getVisaApplications({String? userEmail}) async {
    try {
      String url = Urls.visaApplications;
      Map<String, dynamic> queryParams = {};

      if (userEmail != null && userEmail.trim().isNotEmpty) {
        queryParams['user_email'] = userEmail.trim();
      }

      print('CALLING VISA APPLICATIONS API: $url');
      if (queryParams.isNotEmpty) {
        print('Query params: $queryParams');
      }

      final response = await dio.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('API Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Error Type: ${e.type}');
      print('Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.visaApplications),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}