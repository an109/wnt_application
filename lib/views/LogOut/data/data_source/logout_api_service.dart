import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';

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

      // Send the refresh token so the server can blacklist it and prevent
      // it from minting new access tokens after the user has signed out.
      final refreshToken = sl<PreferencesManager>().getRefreshToken();

      final response = await dio.post(
        Urls.logout,
        data: {
          if (refreshToken != null && refreshToken.isNotEmpty)
            'refresh': refreshToken,
        },
      );

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