import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/storage/shared_preference.dart';
import 'diy_dates.dart';
import 'diy_origins.dart';
import 'models/diy_models.dart';

/// Everything the holiday search form collects, carried through the flow.
class DiySearchQuery {
  final DiyOrigin origin;
  final DiyDestination? destination;
  final DateTime? departureDate;
  final int rooms;
  final int adults;
  final int children;

  const DiySearchQuery({
    required this.origin,
    this.destination,
    this.departureDate,
    this.rooms = 1,
    this.adults = 2,
    this.children = 0,
  });

  DiySearchQuery copyWith({
    DiyOrigin? origin,
    DiyDestination? destination,
    DateTime? departureDate,
    int? rooms,
    int? adults,
    int? children,
    bool clearDestination = false,
  }) {
    return DiySearchQuery(
      origin: origin ?? this.origin,
      destination: clearDestination ? null : (destination ?? this.destination),
      departureDate: departureDate ?? this.departureDate,
      rooms: rooms ?? this.rooms,
      adults: adults ?? this.adults,
      children: children ?? this.children,
    );
  }

  bool get isComplete => destination != null;

  Map<String, dynamic> toJson() => {
        'origin': origin.toJson(),
        'destination': destination?.toJson(),
        'departureDate': departureDate?.toIso8601String(),
        'rooms': rooms,
        'adults': adults,
        'children': children,
      };

  static DiySearchQuery fromJson(Map<String, dynamic> j) {
    final dest = j['destination'];
    return DiySearchQuery(
      origin: DiyOrigin.fromJson(j['origin']) ?? DiyOrigins.defaultOrigin,
      destination: dest is Map
          ? DiyDestination.fromJson(Map<String, dynamic>.from(dest))
          : null,
      departureDate: j['departureDate'] != null
          ? DateTime.tryParse(j['departureDate'].toString())
          : null,
      rooms: (j['rooms'] as num?)?.toInt() ?? 1,
      adults: (j['adults'] as num?)?.toInt() ?? 2,
      children: (j['children'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Persistence for the holiday search form.
///
/// Uses its own prefs key rather than PreferencesManager's single shared
/// `saveLastSearch`/`getLastSearch` pair (owned by the flight card), so a
/// holiday search never clobbers — or gets clobbered by — a flight search.
class DiySearchStore {
  static const String _lastSearchKey = 'diy_holiday_last_search';
  static const String _recentDestinationsKey = 'diy_holiday_recent_destinations';
  static const String _recentOriginsKey = 'diy_holiday_recent_origins';
  static const int _maxRecent = 6;

  static Future<PreferencesManager> _prefs() async =>
      PreferencesManager.create(await SharedPreferences.getInstance());

  static Future<void> saveLastSearch(DiySearchQuery query) async {
    try {
      final p = await _prefs();
      await p.setString(_lastSearchKey, jsonEncode(query.toJson()));
      // Also surface it in the home screen's Recent Searches list. That
      // reader keys holiday entries off `destination.id` and renders
      // name/city/country from the same map, so the shape has to match.
      final destination = query.destination;
      if (destination != null) {
        await p.addToSearchHistory({
          'type': 'holiday',
          'destination': {
            'id': destination.slug,
            'name': destination.name,
            'city': destination.kind == 'city' ? destination.name : '',
            'country': destination.countryName,
          },
          'origin': {
            'id': query.origin.slug,
            'name': query.origin.name,
          },
          'departureDate': query.departureDate?.toIso8601String(),
          'adults': query.adults,
          'children': query.children,
          'rooms': query.rooms,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('DiySearchStore.saveLastSearch failed: $e');
    }
  }

  static Future<DiySearchQuery?> loadLastSearch() async {
    try {
      final raw = (await _prefs()).getString(_lastSearchKey);
      if (raw == null || raw.isEmpty) return null;
      final query =
          DiySearchQuery.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      // Never restore a departure the price API would reject.
      final clamped = DiyDates.clampToFuture(query.departureDate);
      if (clamped != query.departureDate) {
        return query.copyWith(departureDate: clamped);
      }
      return query;
    } catch (e) {
      debugPrint('DiySearchStore.loadLastSearch failed: $e');
      return null;
    }
  }

  // ----------------------------------------------------- recent searches

  static Future<void> addRecentDestination(DiyDestination d) =>
      _addRecent(_recentDestinationsKey, d.toJson(), (j) => j['slug']);

  static Future<List<DiyDestination>> recentDestinations() async {
    final raw = await _readRecent(_recentDestinationsKey);
    return raw.map(DiyDestination.fromJson).toList();
  }

  static Future<void> addRecentOrigin(DiyOrigin o) =>
      _addRecent(_recentOriginsKey, o.toJson(), (j) => j['slug']);

  static Future<List<DiyOrigin>> recentOrigins() async {
    final raw = await _readRecent(_recentOriginsKey);
    return raw.map(DiyOrigin.fromJson).whereType<DiyOrigin>().toList();
  }

  static Future<void> _addRecent(
    String key,
    Map<String, dynamic> entry,
    Object? Function(Map<String, dynamic>) identity,
  ) async {
    try {
      final p = await _prefs();
      final existing = await _readRecent(key);
      final id = identity(entry);
      existing.removeWhere((e) => identity(e) == id);
      existing.insert(0, entry);
      final trimmed = existing.take(_maxRecent).toList();
      await p.setString(key, jsonEncode(trimmed));
    } catch (e) {
      debugPrint('DiySearchStore._addRecent failed: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _readRecent(String key) async {
    try {
      final raw = (await _prefs()).getString(key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('DiySearchStore._readRecent failed: $e');
      return [];
    }
  }
}
