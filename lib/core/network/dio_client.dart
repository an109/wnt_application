import 'package:dio/dio.dart';
import '../../injection_container.dart';
import '../constants/urls.dart';
import '../utils/storage/shared_preference.dart';

class DioClient {
  final Dio _dio;
  bool _isRefreshing = false;

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
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = sl<PreferencesManager>();
          final token = prefs.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 && !_isRefreshing) {
            // Skip refresh for auth endpoints themselves
            final path = e.requestOptions.path;
            if (path.contains('auth/token/refresh') ||
                path.contains('auth/login') ||
                path.contains('auth/signup') ||
                path.contains('auth/send-otp') ||
                path.contains('auth/verify-otp')) {
              return handler.next(e);
            }

            _isRefreshing = true;
            try {
              final prefs = sl<PreferencesManager>();
              final refreshToken = prefs.getRefreshToken();

              if (refreshToken == null || refreshToken.isEmpty) {
                _isRefreshing = false;
                return handler.next(e);
              }

              // Call refresh endpoint directly (no interceptors to avoid loops)
              final refreshDio = Dio();
              final refreshResponse = await refreshDio.post(
                Urls.tokenRefresh,
                data: {'refresh': refreshToken},
                options: Options(headers: {'Content-Type': 'application/json'}),
              );

              final newAccessToken = refreshResponse.data['access'] as String?;
              if (newAccessToken == null) {
                _isRefreshing = false;
                return handler.next(e);
              }

              await prefs.saveToken(newAccessToken);
              _isRefreshing = false;

              // Retry the original request with the new token
              final retryOptions = e.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await _dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              _isRefreshing = false;
              // Refresh failed — clear auth so the app redirects to login
              final prefs = sl<PreferencesManager>();
              await prefs.clearToken();
              await prefs.clearUserData();
              await prefs.clearAuth();
              return handler.next(e);
            }
          }
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