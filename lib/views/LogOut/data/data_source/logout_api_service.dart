import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class LogoutApiService {
  Future<Response> logout();
}

class LogoutApiServiceImpl implements LogoutApiService {
  final Dio dio;

  LogoutApiServiceImpl(this.dio);

  @override
  Future<Response> logout() async {
    try {
      print('CALLING LOGOUT API: ${Urls.logout}');

      final response = await dio.post(Urls.logout);

      print('LOGOUT RESPONSE STATUS: ${response.statusCode}');
      print('LOGOUT RESPONSE DATA: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.logout),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}