import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/urls.dart';
import '../model/trisha_models.dart';

class TrishaException implements Exception {
  final String message;
  const TrishaException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Trisha AI service. Uses the app's [DioClient] Dio, so the
/// customer's access token (and its refresh-on-401) is attached for free; the
/// absolute URL bypasses that client's main-backend baseUrl.
class TrishaApiService {
  final Dio _dio;

  TrishaApiService(this._dio);

  /// Where Trisha may be, in order of preference:
  /// - TRISHA_URL (--dart-define), when given;
  /// - 127.0.0.1: the iOS simulator, or a phone after `adb reverse tcp:8090 tcp:8090`
  ///   (works over USB and wireless debugging, whatever the Mac's IP is);
  /// - 10.0.2.2: the Android emulator's name for the Mac.
  static List<String> get candidates => [
        if (Urls.trishaBaseUrl.isNotEmpty) Urls.trishaBaseUrl,
        'http://127.0.0.1:8090',
        if (Platform.isAndroid) 'http://10.0.2.2:8090',
      ];

  static String? _resolved;

  /// The first candidate whose /health answers; remembered for the session.
  static String get baseUrl => _resolved ?? candidates.first;

  Future<String> _base() async {
    if (_resolved != null) return _resolved!;
    final probe = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    ));
    for (final url in candidates) {
      try {
        final res = await probe.get('$url/health');
        if (res.statusCode == 200) return _resolved = url;
      } on DioException {
        continue;
      }
    }
    throw TrishaException(
      "I can't reach Thrisha (tried ${candidates.join(', ')}). "
      'Is the server running? On a phone, run: adb reverse tcp:8090 tcp:8090',
    );
  }

  // A flight search polls the supplier for up to ~45 s and ticketing can take
  // ~90 s, so replies may be slow.
  static final _options = Options(
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 150),
  );

  /// Opening a chat is quick on the server, so an unreachable server is
  /// reported after 15 s instead of the long reply timeout.
  Future<TrishaReply> startChat() => _post('/v1/chat/start', null).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TrishaException("I can't reach Thrisha at $baseUrl. Is the server running?"),
      );

  Future<TrishaReply> sendMessage({required String sessionId, required String text}) =>
      _post('/v1/chat', {'session_id': sessionId, 'message': text});

  Future<TrishaReply> sendAction({
    required String sessionId,
    required String type,
    Map<String, dynamic> data = const {},
  }) =>
      _post('/v1/chat', {
        'session_id': sessionId,
        'action': {'type': type, 'data': data},
      });

  Future<TrishaReply> _post(String path, Map<String, dynamic>? body) async {
    try {
      final res = await _dio.post('${await _base()}$path', data: body, options: _options);
      return TrishaReply.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        throw const TrishaException('Please log in to chat with Thrisha.');
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        throw const TrishaException('This is taking longer than usual. Please try again.');
      }
      if (status == null) {
        _resolved = null; // the server may have moved; probe again next time
        throw TrishaException("I can't reach Thrisha at $baseUrl. Please check the server and your connection.");
      }
      throw const TrishaException('Something went wrong. Please try again.');
    }
  }
}
