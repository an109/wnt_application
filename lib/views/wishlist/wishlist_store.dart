import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../injection_container.dart';

/// Something the user hearted: a destination, route, hotel or package.
class WishlistItem {
  final String id;
  final String title;
  final String subtitle;
  final List<String> images;

  const WishlistItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.images = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'images': images,
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        images: [
          for (final i in (json['images'] as List? ?? const [])) i.toString(),
        ].where((i) => i.isNotEmpty).toList(),
      );
}

/// Kept on the device: there is no wishlist endpoint on the backend yet.
class WishlistStore extends ChangeNotifier {
  WishlistStore._() {
    _load();
  }

  static final WishlistStore instance = WishlistStore._();

  static const _key = 'wishlist_items_v1';

  final List<WishlistItem> _items = [];

  List<WishlistItem> get items => List.unmodifiable(_items);

  bool contains(String id) => _items.any((i) => i.id == id);

  void toggle(WishlistItem item) {
    if (contains(item.id)) {
      _items.removeWhere((i) => i.id == item.id);
    } else {
      _items.insert(0, item);
    }
    _save();
    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((i) => i.id == id);
    _save();
    notifyListeners();
  }

  void _load() {
    try {
      final raw = sl<SharedPreferences>().getString(_key);
      if (raw == null) return;
      _items
        ..clear()
        ..addAll([
          for (final e in jsonDecode(raw) as List)
            WishlistItem.fromJson(Map<String, dynamic>.from(e as Map)),
        ]);
    } catch (e) {
      debugPrint('Wishlist load failed: $e');
    }
  }

  void _save() {
    sl<SharedPreferences>()
        .setString(_key, jsonEncode([for (final i in _items) i.toJson()]));
  }
}
