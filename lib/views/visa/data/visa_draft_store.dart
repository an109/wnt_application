import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Unsent visa application forms, one per destination, so the landing page
/// can offer "Resume application".
class VisaDraftStore {
  VisaDraftStore._();

  static String _key(int destinationId) => 'visa_draft_$destinationId';

  static Future<Map<String, dynamic>?> load(int destinationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(destinationId));
      if (raw == null) return null;
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(int destinationId, Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(destinationId), jsonEncode(draft));
  }

  static Future<void> clear(int destinationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(destinationId));
  }
}
