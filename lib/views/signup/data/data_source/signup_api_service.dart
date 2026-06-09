import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class SignupApiService {
  Future<Response> signup({
    required String firstname,
    required String lastname,
    required String password,
    String? email,
    String? phone,
    String? phoneCode,
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
    String? email,
    String? phone,
    String? phoneCode,
  }) async {
    try {
      print('CALLING SIGNUP API: ${Urls.signup}');

      // Backend accepts email OR phone. Send whichever was provided.
      final Map<String, dynamic> data = {
        'firstname': firstname,
        'lastname': lastname,
        'password': password,
        'platform': 'email',
      };

      final trimmedEmail = (email ?? '').trim();
      final trimmedPhone = (phone ?? '').trim();

      if (trimmedEmail.isNotEmpty) {
        data['email'] = trimmedEmail;
      }
      if (trimmedPhone.isNotEmpty) {
        data['phone'] = trimmedPhone;
        data['phone_code'] = (phoneCode ?? '').trim();
      }

      print('Request payload: $data');

      final response = await dio.post(Urls.signup, data: data);
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
