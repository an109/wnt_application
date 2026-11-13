import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import '../../injection_container.dart';
import '../constants/urls.dart';
import '../utils/storage/shared_preference.dart';

class DioClient {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<({ErrorInterceptorHandler handler, DioException error})> _pendingRequests = [];

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
          if (e.response?.statusCode == 401) {
            final path = e.requestOptions.path;
            if (path.contains('auth/token/refresh') ||
                path.contains('auth/login') ||
                path.contains('auth/signup') ||
                path.contains('auth/send-otp') ||
                path.contains('auth/verify-otp')) {
              return handler.next(e);
            }

            if (_isRefreshing) {
              _pendingRequests.add((handler: handler, error: e));
              return;
            }

            _isRefreshing = true;
            try {
              final prefs = sl<PreferencesManager>();
              final refreshToken = prefs.getRefreshToken();
              final storedUserId = prefs.getUserId();

              if (refreshToken == null || refreshToken.isEmpty) {
                _isRefreshing = false;
                _rejectPending();
                return handler.next(e);
              }

              final refreshDio = Dio();
              final refreshResponse = await refreshDio.post(
                Urls.tokenRefresh,
                data: {'refresh': refreshToken},
                options: Options(headers: {'Content-Type': 'application/json'}),
              );

              final newAccessToken = refreshResponse.data['access'] as String?;
              if (newAccessToken == null) {
                _isRefreshing = false;
                _rejectPending();
                return handler.next(e);
              }

              // Verify the refreshed token belongs to the same user.
              final newTokenUserId = _userIdFromJwt(newAccessToken);
              if (storedUserId != null && newTokenUserId != null && newTokenUserId != storedUserId) {
                developer.log(
                  'Token refresh returned a different user '
                  '(stored=$storedUserId, token=$newTokenUserId). Forcing logout.',
                  name: 'auth',
                );
                _isRefreshing = false;
                _rejectPending();
                await prefs.clearToken();
                await prefs.clearUserData();
                await prefs.clearAuth();
                return handler.next(e);
              }

              await prefs.saveToken(newAccessToken, isNewSession: false);
              _isRefreshing = false;

              _retryPending(newAccessToken);

              final retryOptions = e.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await _dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              _isRefreshing = false;
              _rejectPending();
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

  /// Extracts `user_id` from a JWT access token without a crypto library.
  /// Django Simple JWT stores it in the payload as `user_id`.
  /// Returns null rather than throwing on any malformed input.
  static int? _userIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['user_id'] as int?;
    } catch (_) {
      return null;
    }
  }

  void _retryPending(String newToken) {
    final pending = List.of(_pendingRequests);
    _pendingRequests.clear();
    for (final p in pending) {
      final opts = p.error.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      _dio.fetch(opts).then(
        (r) => p.handler.resolve(r),
        onError: (e) => p.handler.next(e is DioException ? e : p.error),
      );
    }
  }

  void _rejectPending() {
    final pending = List.of(_pendingRequests);
    _pendingRequests.clear();
    for (final p in pending) {
      p.handler.next(p.error);
    }
  }

  Dio get instance => _dio;
}
