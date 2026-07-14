import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/reset_password_model.dart';

abstract class ResetPasswordApiService {
  Future<ResetPasswordModel> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}

class ResetPasswordApiServiceImpl implements ResetPasswordApiService {
  final Dio dio;

  ResetPasswordApiServiceImpl(this.dio);

  @override
  Future<ResetPasswordModel> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      print('CALLING RESET PASSWORD API: ${Urls.resetPassword}');

      final requestBody = {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      };

      print('Request Body: $requestBody');

      final response = await dio.post(
        Urls.resetPassword,
        data: requestBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      return ResetPasswordModel.fromJson(response.data);
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.resetPassword),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
