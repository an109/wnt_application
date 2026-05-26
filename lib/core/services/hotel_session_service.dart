import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the 15-minute TBO hotel search session.
///
/// TBO rule: Search → PreBook → Book must complete within 15 minutes.
/// Call [markSearchStarted] when the user initiates a hotel search.
/// Check [isSessionExpired] before proceeding to PreBook or Book.
class HotelSessionService {
  HotelSessionService._();
  static final HotelSessionService instance = HotelSessionService._();

  static const String _key = 'tboHotelSearchStartedAt';
  static const Duration _maxDuration = Duration(minutes: 15);

  // In-memory fallback if SharedPreferences is not yet ready.
  int _memoryTimestamp = 0;

  /// Marks the start of a new TBO hotel search session.
  Future<void> markSearchStarted() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _memoryTimestamp = now;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, now);
    } catch (_) {
      // In-memory value is the fallback.
    }
  }

  /// Returns the UTC timestamp (ms) when the search was started, or 0 if none.
  Future<int> getSearchStartedAt() async {
    if (_memoryTimestamp != 0) return _memoryTimestamp;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Returns true if the 15-minute session window has expired (or never started).
  Future<bool> isSessionExpired() async {
    final started = await getSearchStartedAt();
    if (started == 0) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - started;
    return elapsed >= _maxDuration.inMilliseconds;
  }

  /// Returns how many milliseconds remain in the session (0 if expired).
  Future<int> remainingMs() async {
    final started = await getSearchStartedAt();
    if (started == 0) return 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - started;
    final remaining = _maxDuration.inMilliseconds - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  /// Clears the session (call after booking completes or on error).
  Future<void> clear() async {
    _memoryTimestamp = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  /// Returns a human-readable countdown string like "12:34".
  Future<String> remainingFormatted() async {
    final ms = await remainingMs();
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
