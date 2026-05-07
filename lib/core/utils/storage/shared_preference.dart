import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  static const String _tokenKey = 'auth_token';
  static const String _userTypeKey = 'user_type';

  final SharedPreferences _prefs;

  PreferencesManager._(this._prefs);

  static Future<PreferencesManager> create(SharedPreferences prefs) async {
    return PreferencesManager._(prefs);
  }

  // Token methods
  String? getToken() => _prefs.getString(_tokenKey);
  Future<bool> saveToken(String token) => _prefs.setString(_tokenKey, token);
  Future<bool> clearToken() => _prefs.remove(_tokenKey);

  // User type methods
  int? getUserType() => _prefs.getInt(_userTypeKey);
  Future<bool> saveUserType(int type) => _prefs.setInt(_userTypeKey, type);

  // Generic methods (following your pattern)
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setStringMap(String key, Map<String, String> value) {
    return _prefs.setStringList(key, value.entries.map((e) => '${e.key}=${e.value}').toList());
  }

  Map<String, String>? getStringMap(String key) {
    final list = _prefs.getStringList(key);
    if (list == null) return null;
    return Map.fromEntries(list.map((item) {
      final parts = item.split('=');
      return MapEntry(parts[0], parts.sublist(1).join('='));
    }));
  }

  Future<bool> clear() => _prefs.clear();
}