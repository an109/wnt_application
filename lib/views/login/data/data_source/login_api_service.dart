import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class LoginApiService {
  Future<Response> login({
    required String contactValue,
    required String password,
    required String contactType, // 'email' or 'phone'
  });
}

class LoginApiServiceImpl implements LoginApiService {
  final Dio dio;

  LoginApiServiceImpl(this.dio);

  @override
  Future<Response> login({
    required String contactValue,
    required String password,
    required String contactType,
  }) async {
    try {
      print('CALLING LOGIN API: ${Urls.login}');
      print('Request payload: {${contactType}: $contactValue, password: ***}');

      final response = await dio.post(
        Urls.login,
        data: {
          'email': contactValue,
          // contactType: contactValue,
          'password': password,
        },
      );

      print('LOGIN API Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Login API Error: ${e.message}');
      print('Login API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Login Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.login),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}