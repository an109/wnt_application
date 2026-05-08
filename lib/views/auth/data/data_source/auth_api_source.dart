// lib/features/auth/data/data_source/auth_api_service.dart

import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/google_auth_request_model.dart';
import '../model/google_auth_response_model.dart';

abstract class AuthApiService {
  Future<GoogleAuthResponseModel> googleLogin(GoogleAuthRequestModel request);
}

class AuthApiServiceImpl implements AuthApiService {
  final Dio dio;

  AuthApiServiceImpl(this.dio);

  @override
  Future<GoogleAuthResponseModel> googleLogin(GoogleAuthRequestModel request) async {
    try {
      final response = await dio.post(
        Urls.googleAuth,
        data: request.toJson(),
      );

      return GoogleAuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      // Log the error for debugging
      print(' DioException in googleLogin: ${e.message}');
      print(' Response: ${e.response?.data}');

      if (e.response?.data != null) {
        return GoogleAuthResponseModel.fromJson(e.response!.data);
      }
      rethrow;
    } catch (e) {
      print(' Unknown error in googleLogin: $e');
      rethrow;
    }
  }
}