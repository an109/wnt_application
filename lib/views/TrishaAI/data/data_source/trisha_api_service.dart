import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/urls.dart';
import '../model/trisha_models.dart';

/// What a customer sees when Thrisha can't be reached. Debug builds add how to
/// fix it locally; release builds never show server or adb details.
String _offline(String detail) => kDebugMode
    ? "Thrisha is offline right now. ($detail. Dev: check the thrisha-ai service on the server)"
    : "Thrisha is offline right now. Please check your internet connection and try again.";

class TrishaException implements Exception {
  final String message;
  const TrishaException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Trisha AI service. Uses the app's [DioClient] Dio, so the
/// customer's access token (and its refresh-on-401) is attached for free; the
/// absolute URL bypasses that client's main-backend baseUrl.
///
/// Someone who has not logged in can still chat: [guestId] is sent as
/// `X-Guest-Id` on every call (also when logged in, so a chat begun as a guest
/// can follow them through a login). Without a token AND without that id the
/// service answers 401 "Login required". Past chats and the expert handover
/// still need a real login.
class TrishaApiService {
  final Dio _dio;

  /// The device's anonymous id; see `PreferencesManager.getThrishaGuestId`.
  final String Function()? _guestId;

  TrishaApiService(this._dio, {String Function()? guestId}) : _guestId = guestId;

  /// Header that identifies a visitor who has not logged in.
  Map<String, String> get _headers {
    final id = _guestId?.call() ?? '';
    return id.isEmpty ? const {} : {'X-Guest-Id': id};
  }

  /// Where Thrisha is: the live service on the production server, in debug and
  /// release builds alike. To use a Thrisha running on this Mac instead:
  ///   flutter run --dart-define=TRISHA_URL=http://127.0.0.1:8090
  /// (with `scripts/connect-phone.sh` for a real phone).
  static List<String> get candidates => [
        Urls.trishaBaseUrl.isNotEmpty ? Urls.trishaBaseUrl : Urls.trishaProductionUrl,
      ];

  static String? _resolved;

  /// Pins the service address so tests do not probe the network.
  @visibleForTesting
  static set resolvedBaseForTest(String? url) => _resolved = url;

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
    throw TrishaException(_offline('tried ${candidates.join(', ')}'));
  }

  // A flight search polls the supplier for up to ~45 s and ticketing can take
  // ~90 s, so replies may be slow.
  Options get _chatOptions => Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 150),
        headers: _headers,
      );

  Options get _plainOptions => Options(headers: _headers);

  /// Opening a chat is quick on the server, so an unreachable server is
  /// reported after 15 s instead of the long reply timeout.
  Future<TrishaReply> startChat() => _post('/v1/chat/start', null).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TrishaException(_offline('no answer from $baseUrl')),
      );

  Future<TrishaReply> sendMessage({required String sessionId, required String text}) =>
      _post('/v1/chat', {'session_id': sessionId, 'message': text});

  /// [label] is what the chat showed as the user's bubble; it is kept for the
  /// chat history only.
  Future<TrishaReply> sendAction({
    required String sessionId,
    required String type,
    Map<String, dynamic> data = const {},
    String? label,
  }) =>
      _post('/v1/chat', {
        'session_id': sessionId,
        'action': {'type': type, 'data': data},
        if (label != null && label.isNotEmpty) 'label': label.length > 120 ? label.substring(0, 120) : label,
      });

  // ---- chat history -------------------------------------------------------------

  /// The user's past chats, newest first; pass the last row's [before] for more.
  /// Needs a login: a guest's chats are not kept in a list.
  Future<List<TrishaChatSummary>> listChats({DateTime? before, int limit = 20}) async {
    final body = await _get('/v1/chats', {
      'limit': limit,
      if (before != null) 'before': before.toUtc().toIso8601String(),
    });
    return (body['chats'] as List? ?? const [])
        .whereType<Map>()
        .map((c) => TrishaChatSummary.fromJson(c.cast<String, dynamic>()))
        .toList();
  }

  Future<TrishaChatHistory> getChat(String sessionId) async =>
      TrishaChatHistory.fromJson(await _get('/v1/chats/$sessionId', null));

  // ---- expert handoff -----------------------------------------------------------

  Future<TrishaExpertTicket> requestExpert(String sessionId) async {
    try {
      final res = await _dio.post('${await _base()}/v1/chat/handoff',
          data: {'session_id': sessionId}, options: _plainOptions);
      return TrishaExpertTicket.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  /// The open expert chat, or `active: false`. A visitor who has not logged in
  /// has none (the service answers 401), which is not an error.
  Future<TrishaExpertChat> getActiveExpertChat() async {
    try {
      final res = await _dio.get('${await _base()}/v1/chat/active', options: _plainOptions);
      return TrishaExpertChat.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 401) return const TrishaExpertChat(active: false);
      throw _error(e);
    }
  }

  Future<void> closeActiveExpertChat() async {
    try {
      await _dio.delete('${await _base()}/v1/chat/active', options: _plainOptions);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw _error(e);
    }
  }

  Future<void> deleteChat(String sessionId) async {
    try {
      await _dio.delete('${await _base()}/v1/chats/$sessionId', options: _plainOptions);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return; // already gone
      throw _error(e);
    }
  }

  Future<Map<String, dynamic>> _get(String path, Map<String, dynamic>? query) async {
    try {
      final res = await _dio.get('${await _base()}$path', queryParameters: query, options: _plainOptions);
      return (res.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw const TrishaException('This chat is no longer available.');
      throw _error(e);
    }
  }

  TrishaException _error(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return const TrishaException('Please log in to use this.');
    if (status == null) {
      _resolved = null;
      return TrishaException(_offline('lost $baseUrl'));
    }
    return const TrishaException('Something went wrong. Please try again.');
  }

  Future<TrishaReply> _post(String path, Map<String, dynamic>? body) async {
    try {
      final res = await _dio.post('${await _base()}$path', data: body, options: _chatOptions);
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
        throw TrishaException(_offline('lost $baseUrl'));
      }
      throw const TrishaException('Something went wrong. Please try again.');
    }
  }
}
