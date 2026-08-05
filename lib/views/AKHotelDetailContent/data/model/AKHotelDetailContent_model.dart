import '../../domain/entity/AKHotelDetailContent_entity.dart';

List<String> _parseImages(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => e is String ? e : (e is Map ? (e['url'] ?? '').toString() : ''))
      .where((s) => s.isNotEmpty)
      .toList();
}

List<String> _parseFacilities(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((f) => (f['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
}

List<String> _parsePolicies(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((p) => (p['text'] ?? '').toString()).where((t) => t.isNotEmpty).toList();
}

List<String> _parseDescriptions(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((d) => (d['text'] ?? '').toString()).where((t) => t.isNotEmpty).toList();
}

List<AkHotelAttractionEntity> _parseAttractions(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((a) => AkHotelAttractionEntity(
            name: (a['name'] ?? '').toString(),
            distance: (a['distance'] as num?)?.toDouble() ?? 0.0,
            unit: (a['unit'] ?? '').toString(),
          ))
      .where((a) => a.name.isNotEmpty)
      .toList();
}

class AkHotelDetailContentModel extends AkHotelDetailContentEntity {
  const AkHotelDetailContentModel({
    required super.id,
    required super.name,
    required super.starRating,
    required super.addressLine1,
    required super.city,
    required super.state,
    required super.country,
    required super.descriptions,
    required super.facilities,
    required super.images,
    required super.heroImage,
    required super.nearByAttractions,
    required super.checkinBeginTime,
    required super.checkoutTime,
    required super.checkinSpecialInstructions,
    required super.policies,
    super.lat,
    super.long,
  });

  factory AkHotelDetailContentModel.fromJson(Map<String, dynamic> json) {
    final hotel = json['hotel'] as Map<String, dynamic>? ?? {};
    final contact = hotel['contact'] as Map<String, dynamic>? ?? {};
    final geoCode = hotel['geoCode'] as Map<String, dynamic>?;
    final address = contact['address'] as Map<String, dynamic>? ?? {};
    final checkinInfo = hotel['checkinInfo'] as Map<String, dynamic>? ?? {};
    final checkoutInfo = hotel['checkoutInfo'] as Map<String, dynamic>? ?? {};
    final rawSpecialInstructions = checkinInfo['specialInstructions'] as List<dynamic>? ?? [];

    return AkHotelDetailContentModel(
      id: hotel['id']?.toString() ?? '',
      name: hotel['name']?.toString() ?? '',
      starRating: (hotel['starRating'] as num?)?.toDouble() ?? 0.0,
      addressLine1: (address['line1'] ?? '').toString(),
      city: (address['city'] ?? '').toString(),
      state: (address['state'] ?? '').toString(),
      country: (address['country'] ?? '').toString(),
      descriptions: _parseDescriptions(hotel['descriptions']),
      facilities: _parseFacilities(hotel['facilities']),
      images: _parseImages(hotel['images']),
      heroImage: hotel['heroImage']?.toString() ?? '',
      nearByAttractions: _parseAttractions(hotel['nearByAttractions']),
      checkinBeginTime: checkinInfo['beginTime']?.toString() ?? '',
      checkoutTime: checkoutInfo['time']?.toString() ?? '',
      checkinSpecialInstructions: rawSpecialInstructions.map((s) => s.toString()).toList(),
      policies: _parsePolicies(hotel['policies']),
      lat: (geoCode?['lat'] as num?)?.toDouble(),
      long: (geoCode?['long'] as num?)?.toDouble(),
    );
  }
}
