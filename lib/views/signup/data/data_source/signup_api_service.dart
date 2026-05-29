import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class SignupApiService {
  Future<Response> signup({
    required String firstname,
    required String lastname,
    required String password,
    required String phone,
    required String phoneCode,
  });
}

class SignupApiServiceImpl implements SignupApiService {
  final Dio dio;

  SignupApiServiceImpl(this.dio);

  @override
  Future<Response> signup({
    required String firstname,
    required String lastname,
    required String password,
    required String phone,
    required String phoneCode,
  }) async {
    try {
      print('CALLING SIGNUP API: ${Urls.signup}');
      print('Request payload: {firstname: $firstname, lastname: $lastname, phone: $phone, phone_code: $phoneCode}');

      final response = await dio.post(
        Urls.signup,
        data: {
          'firstname': firstname,
          'lastname': lastname,
          'password': password,
          'phone': phone,
          'phone_code': phoneCode,
        },
      );
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.signup),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}