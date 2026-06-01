import 'package:dio/dio.dart';
import '../../injection_container.dart';
import '../utils/storage/shared_preference.dart';

class DioClient {
  final Dio _dio;

  DioClient(String baseUrl)
      : _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  ) {
    // Logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );

    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final _prefs = sl<PreferencesManager>();
          final token = _prefs.getToken();

          if (options.path.contains('auth/logout')) {
            print('LOGOUT DEBUG: token retrieved = ${token != null ? 'EXISTS' : 'NULL'}, isEmpty = ${token?.isEmpty ?? true}');
            if (token != null && token.isNotEmpty) {
              print('LOGOUT DEBUG: first 20 chars of token = ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
            }
          }

          if (options.path.contains('auth/')) {
            final rawToken = _prefs.getString('auth_token');
            print('AUTH DEBUG: path=${options.path}, tokenExists=${token != null}, rawTokenEmpty=${rawToken?.isEmpty}');
          }

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';

            if (options.path.contains('auth/logout')) {
              print('LOGOUT DEBUG: Authorization header set = true');
            }
          } else {
            if (options.path.contains('auth/logout')) {
              print('LOGOUT DEBUG: SKIPPED setting Authorization header - token missing');
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Global error handling
          // You can add custom error mapping here
          return handler.next(e);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
      ),
    );
  }

  Dio get instance => _dio;
}