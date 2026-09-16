import 'package:flutter/material.dart';

/// Ordered category labels used by both [AkHotelAmenitiesScreen] and the
/// rate-details screen's amenities accordion — kept in one place so the two
/// screens bucket the same facility string into the same category.
const List<String> akHotelAmenityCategoryOrder = [
  'Basic Facilities',
  'Room Amenities',
  'Health & Wellness',
  'Food & Drink',
  'Safety & Security',
];

/// Buckets a hotel's flat `facilities` list (Content API gives no category,
/// just names) into the categories above by keyword match. Anything that
/// doesn't match a known keyword lands in "Basic Facilities" rather than
/// being dropped, so no real facility the API returned goes missing.
/// Empty categories are removed, and [akHotelAmenityCategoryOrder]'s order
/// is preserved.
Map<String, List<String>> categorizeAkHotelAmenities(List<String> facilities) {
  final map = <String, List<String>>{for (final c in akHotelAmenityCategoryOrder) c: []};
  for (final f in facilities) {
    final n = f.toLowerCase();
    if (n.contains('spa') || n.contains('gym') || n.contains('fitness') || n.contains('sauna') || n.contains('steam') || n.contains('massage') || n.contains('yoga')) {
      map['Health & Wellness']!.add(f);
    } else if (n.contains('restaurant') || n.contains('bar') || n.contains('breakfast') || n.contains('dining') || n.contains('cafe') || n.contains('kitchen')) {
      map['Food & Drink']!.add(f);
    } else if (n.contains('security') || n.contains('cctv') || n.contains('fire') || n.contains('safe') || n.contains('smoke') || n.contains('first aid') || n.contains('doctor')) {
      map['Safety & Security']!.add(f);
    } else if (n.contains('room service') || n.contains(' tv') || n.contains('television') || n.contains('air condition') || n.contains('heater') || n.contains('wardrobe') || n.contains('balcony') || n.contains('minibar') || n.contains('iron') || n.contains('hairdryer') || n.contains('bathtub') || n.contains('mineral') || n.contains('sofa')) {
      map['Room Amenities']!.add(f);
    } else {
      map['Basic Facilities']!.add(f);
    }
  }
  map.removeWhere((key, value) => value.isEmpty);
  return map;
}

/// Same icon mapping for a facility name, used everywhere a category list
/// is rendered.
IconData iconForAkHotelAmenity(String name) {
  final n = name.toLowerCase();
  if (n.contains('pool')) return Icons.pool;
  if (n.contains('restaurant') || n.contains('dining')) return Icons.restaurant;
  if (n.contains('spa') || n.contains('sauna') || n.contains('steam')) return Icons.spa;
  if (n.contains('wifi') || n.contains('internet') || n.contains('lan')) return Icons.wifi;
  if (n.contains('parking')) return Icons.local_parking;
  if (n.contains('gym') || n.contains('fitness')) return Icons.fitness_center;
  if (n.contains('bar')) return Icons.local_bar;
  if (n.contains('air condition')) return Icons.ac_unit;
  if (n.contains('breakfast')) return Icons.free_breakfast;
  if (n.contains('laundry')) return Icons.local_laundry_service;
  if (n.contains('elevator') || n.contains('lift')) return Icons.elevator;
  if (n.contains('power') || n.contains('backup')) return Icons.power;
  if (n.contains('security') || n.contains('cctv')) return Icons.security;
  if (n.contains('room service')) return Icons.room_service;
  if (n.contains('tv') || n.contains('television')) return Icons.tv;
  if (n.contains('bathtub')) return Icons.bathtub;
  if (n.contains('hairdryer')) return Icons.dry;
  if (n.contains('sofa')) return Icons.weekend;
  if (n.contains('mineral') || n.contains('water')) return Icons.water_drop;
  if (n.contains('first aid') || n.contains('doctor')) return Icons.medical_services;
  return Icons.check_circle_outline;
}

/// Short chip label for a category, used by the quick-jump row on
/// [AkHotelAmenitiesScreen] (the first chip keeps the full name, the rest
/// are shortened to fit).
String shortAkHotelAmenityCategoryLabel(String category) {
  switch (category) {
    case 'Room Amenities':
      return 'Room';
    case 'Health & Wellness':
      return 'Health';
    case 'Food & Drink':
      return 'Food';
    case 'Safety & Security':
      return 'Safety';
    default:
      return category;
  }
}
