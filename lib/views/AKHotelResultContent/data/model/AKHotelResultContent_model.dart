import '../../domain/entity/AKHotelResultContent_entity.dart';

List<String> _parseImages(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) {
        if (e is String) return e;
        if (e is Map) return (e['url'] ?? '').toString();
        return '';
      })
      .where((s) => s.isNotEmpty)
      .toList();
}

List<AkHotelFacilityEntity> _parseFacilities(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((f) => AkHotelFacilityEntity(name: (f['name'] ?? '').toString()))
      .where((f) => f.name.isNotEmpty)
      .toList();
}

class AkHotelContentItemModel extends AkHotelContentItemEntity {
  const AkHotelContentItemModel({
    required super.id,
    required super.name,
    required super.starRating,
    required super.address,
    required super.heroImage,
    required super.images,
    required super.facilities,
    super.lat,
    super.long,
    required super.provider,
    required super.reviewCount,
    required super.reviewRating,
    required super.isSoldOut,
    required super.chainName,
    required super.countryCode,
  });

  factory AkHotelContentItemModel.fromJson(Map<String, dynamic> json) {
    final geoCode = json['geoCode'] as Map<String, dynamic>?;
    final userReview = json['userReview'] as Map<String, dynamic>?;
    return AkHotelContentItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      starRating: (json['starRating'] as num?)?.toDouble() ?? 0.0,
      address: json['address']?.toString() ?? '',
      heroImage: json['heroImage']?.toString() ?? '',
      images: _parseImages(json['images']),
      facilities: _parseFacilities(json['facilities']),
      lat: (geoCode?['lat'] as num?)?.toDouble(),
      long: (geoCode?['long'] as num?)?.toDouble(),
      provider: json['provider']?.toString() ?? '',
      reviewCount: (userReview?['count'] as num?)?.toInt() ?? 0,
      reviewRating: (userReview?['rating'] as num?)?.toDouble() ?? 0.0,
      isSoldOut: json['isSoldOut'] == true,
      chainName: json['chainName']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
    );
  }
}

class AkHotelResultContentModel extends AkHotelResultContentEntity {
  const AkHotelResultContentModel({
    required super.searchId,
    required super.locationName,
    required super.total,
    required super.hotels,
  });

  factory AkHotelResultContentModel.fromJson(Map<String, dynamic> json) {
    final rawHotels = json['hotels'] as List<dynamic>? ?? [];
    return AkHotelResultContentModel(
      searchId: json['searchId']?.toString() ?? '',
      locationName: json['locationName']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      hotels: rawHotels.whereType<Map<String, dynamic>>().map(AkHotelContentItemModel.fromJson).toList(),
    );
  }
}
