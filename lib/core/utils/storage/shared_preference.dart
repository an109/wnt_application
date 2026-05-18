// import 'package:shared_preferences/shared_preferences.dart';
//
// class PreferencesManager {
//   static const String _tokenKey = 'auth_token';
//   static const String _userTypeKey = 'user_type';
//
//   final SharedPreferences _prefs;
//
//   PreferencesManager._(this._prefs);
//
//   static Future<PreferencesManager> create(SharedPreferences prefs) async {
//     return PreferencesManager._(prefs);
//   }
//
//   // Token methods
//   String? getToken() => _prefs.getString(_tokenKey);
//   Future<bool> saveToken(String token) => _prefs.setString(_tokenKey, token);
//   Future<bool> clearToken() => _prefs.remove(_tokenKey);
//
//   // User type methods
//   int? getUserType() => _prefs.getInt(_userTypeKey);
//   Future<bool> saveUserType(int type) => _prefs.setInt(_userTypeKey, type);
//
//   // Generic methods (following your pattern)
//   Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
//   int? getInt(String key) => _prefs.getInt(key);
//
//   Future<bool> setStringMap(String key, Map<String, String> value) {
//     return _prefs.setStringList(key, value.entries.map((e) => '${e.key}=${e.value}').toList());
//   }
//
//   Map<String, String>? getStringMap(String key) {
//     final list = _prefs.getStringList(key);
//     if (list == null) return null;
//     return Map.fromEntries(list.map((item) {
//       final parts = item.split('=');
//       return MapEntry(parts[0], parts.sublist(1).join('='));
//     }));
//   }
//
//   Future<bool> clear() => _prefs.clear();
// }

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  static const String _tokenKey = 'auth_token';
  static const String _userTypeKey = 'user_type';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

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

  // User data methods (NEW)
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _prefs.setString(_userDataKey, jsonString);
    return _prefs.setBool(_isLoggedInKey, true);
  }

  Map<String, dynamic>? getUserData() {
    final jsonString = _prefs.getString(_userDataKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  bool isLoggedIn() => _prefs.getBool(_isLoggedInKey) ?? false;

  Future<bool> clearUserData() async {
    await _prefs.remove(_userDataKey);
    return _prefs.setBool(_isLoggedInKey, false);
  }

  // Generic methods
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

  Future<bool> clear() async {
    await _prefs.clear();
    return true;
  }
}