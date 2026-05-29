// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class PreferencesManager {
//   static const String _tokenKey = 'auth_token';
//   static const String _userTypeKey = 'user_type';
//   static const String _userDataKey = 'user_data';
//   static const String _isLoggedInKey = 'is_logged_in';
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
//   // User data methods (NEW)
//   Future<bool> saveUserData(Map<String, dynamic> userData) async {
//     final jsonString = jsonEncode(userData);
//     await _prefs.setString(_userDataKey, jsonString);
//     return _prefs.setBool(_isLoggedInKey, true);
//   }
//
//   Map<String, dynamic>? getUserData() {
//     final jsonString = _prefs.getString(_userDataKey);
//     if (jsonString == null) return null;
//     return jsonDecode(jsonString) as Map<String, dynamic>;
//   }
//
//   bool isLoggedIn() => _prefs.getBool(_isLoggedInKey) ?? false;
//
//   Future<bool> clearUserData() async {
//     await _prefs.remove(_userDataKey);
//     return _prefs.setBool(_isLoggedInKey, false);
//   }
//
//   // Generic methods
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
//   Future<bool> clear() async {
//     await _prefs.clear();
//     return true;
//   }
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

  static const String _preferredCurrencyKey = 'preferred_currency';
  static const String _exchangeRatesKey = 'exchange_rates_cache';

  // Token methods
  String? getToken() => _prefs.getString(_tokenKey);
  Future<bool> saveToken(String token) => _prefs.setString(_tokenKey, token);
  Future<bool> clearToken() => _prefs.remove(_tokenKey);

  // User type methods
  int? getUserType() => _prefs.getInt(_userTypeKey);
  Future<bool> saveUserType(int type) => _prefs.setInt(_userTypeKey, type);

  // User data methods
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

  // ============ GENERIC METHODS ============

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

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

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() async {
    await _prefs.clear();
    return true;
  }


  Future<void> saveRefreshToken(String token) async {
    await _prefs?.setString('refresh_token', token);
  }

  Future<void> saveUserId(int id) async {
    await _prefs?.setInt('user_id', id);
  }

  Future<void> saveUserEmail(String email) async {
    await _prefs?.setString('user_email', email);
  }

  Future<void> saveUserName(String name) async {
    await _prefs?.setString('user_name', name);
  }

  String? getRefreshToken() => _prefs?.getString('refresh_token');
  int? getUserId() => _prefs?.getInt('user_id');

  Future<void> clearAuth() async {
    await _prefs?.remove('access_token');
    await _prefs?.remove('refresh_token');
    await _prefs?.remove('user_id');
    await _prefs?.remove('user_email');
    await _prefs?.remove('user_name');
  }

  String? getPreferredCurrency() => _prefs.getString(_preferredCurrencyKey);

  Future<bool> savePreferredCurrency(String currency) => _prefs.setString(_preferredCurrencyKey, currency);

  Map<String, double>? getCachedExchangeRates() {
    final jsonString = _prefs.getString(_exchangeRatesKey);
    if (jsonString == null) return null;
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      Map<String, dynamic>? ratesMap;
      if (decoded['AED'] != null || decoded['INR'] != null) {
        ratesMap = decoded;
      } else if (decoded['conversion_rates'] != null) {
        ratesMap = decoded['conversion_rates'] as Map<String, dynamic>;
      } else if (decoded['rates'] != null) {
        ratesMap = decoded['rates'] as Map<String, dynamic>;
      } else {
        return null;
      }
      final result = <String, double>{};
      for (final entry in ratesMap.entries) {
        if (entry.value is num) {
          result[entry.key.toString().toUpperCase()] = (entry.value as num).toDouble();
        }
      }
      return result;
    } catch (e) {
      return null;
    }
  }
}