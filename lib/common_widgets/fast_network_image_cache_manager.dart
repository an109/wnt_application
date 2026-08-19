import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// flutter_cache_manager's default [HttpFileService] never applies a
/// timeout to its request — `_httpClient.send(req)` is awaited with no
/// bound at all. A slow or hanging host therefore hangs that fetch
/// forever, not just "for a while". That alone would only make one image
/// slow, but [FileService.concurrentFetches] defaults to 10 *per cache
/// manager instance*, and every [CachedNetworkImage] in the app shares the
/// same default manager — so a handful of hung requests fill that queue
/// and every other image (this card, this screen, or anywhere else in the
/// app using the default manager) stalls behind them indefinitely. That's
/// the "no image is loading" symptom this app hit before: it isn't that
/// images fail, it's that the shared fetch queue is wedged.
class _TimeoutBoundHttpFileService extends HttpFileService {
  _TimeoutBoundHttpFileService({super.httpClient});

  static const _timeout = Duration(seconds: 10);

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) {
    return super.get(url, headers: headers).timeout(
          _timeout,
          onTimeout: () => throw TimeoutException('Image fetch timed out after ${_timeout.inSeconds}s: $url'),
        );
  }
}

/// A [CacheManager] dedicated to hotel/listing photos: same disk+memory
/// caching as the default manager, but every fetch is bounded so a slow
/// host degrades to the error/fallback state within [_TimeoutBoundHttpFileService._timeout]
/// instead of hanging — and a raised [Config.fileService] concurrency limit
/// means one slow image no longer queues up every other card behind it.
class FastNetworkImageCacheManager {
  static const key = 'fastNetworkImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 300,
      fileService: _TimeoutBoundHttpFileService(httpClient: http.Client())..concurrentFetches = 24,
    ),
  );
}
