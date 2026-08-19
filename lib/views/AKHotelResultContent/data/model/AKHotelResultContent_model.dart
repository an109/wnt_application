// import '../../domain/entity/AKHotelResultContent_entity.dart';
//
// List<String> _parseImages(dynamic raw) {
//   if (raw is! List) return const [];
//   return raw
//       .map((e) {
//         if (e is String) return e;
//         if (e is Map) return (e['url'] ?? '').toString();
//         return '';
//       })
//       .where((s) => s.isNotEmpty)
//       .toList();
// }
//
// List<AkHotelFacilityEntity> _parseFacilities(dynamic raw) {
//   if (raw is! List) return const [];
//   return raw
//       .whereType<Map>()
//       .map((f) => AkHotelFacilityEntity(name: (f['name'] ?? '').toString()))
//       .where((f) => f.name.isNotEmpty)
//       .toList();
// }
//
// class AkHotelContentItemModel extends AkHotelContentItemEntity {
//   const AkHotelContentItemModel({
//     required super.id,
//     required super.name,
//     required super.starRating,
//     required super.address,
//     required super.heroImage,
//     required super.images,
//     required super.facilities,
//     super.lat,
//     super.long,
//     required super.provider,
//     required super.reviewCount,
//     required super.reviewRating,
//     required super.isSoldOut,
//     required super.chainName,
//     required super.countryCode,
//   });
//
//   factory AkHotelContentItemModel.fromJson(Map<String, dynamic> json) {
//     final geoCode = json['geoCode'] as Map<String, dynamic>?;
//     final userReview = json['userReview'] as Map<String, dynamic>?;
//     return AkHotelContentItemModel(
//       id: json['id']?.toString() ?? '',
//       name: json['name']?.toString() ?? '',
//       starRating: (json['starRating'] as num?)?.toDouble() ?? 0.0,
//       address: json['address']?.toString() ?? '',
//       heroImage: json['heroImage']?.toString() ?? '',
//       images: _parseImages(json['images']),
//       facilities: _parseFacilities(json['facilities']),
//       lat: (geoCode?['lat'] as num?)?.toDouble(),
//       long: (geoCode?['long'] as num?)?.toDouble(),
//       provider: json['provider']?.toString() ?? '',
//       reviewCount: (userReview?['count'] as num?)?.toInt() ?? 0,
//       reviewRating: (userReview?['rating'] as num?)?.toDouble() ?? 0.0,
//       isSoldOut: json['isSoldOut'] == true,
//       chainName: json['chainName']?.toString() ?? '',
//       countryCode: json['countryCode']?.toString() ?? '',
//     );
//   }
//
//   /// `curatedHotels` rows are a sparser shape than `hotels` — notably
//   /// `starRating` comes back as a numeric *string* ("4") rather than a
//   /// number, and there's no heroImage/images/facilities/geoCode/provider/
//   /// userReview/isSoldOut/chainName/countryCode at all — so this can't
//   /// reuse [fromJson] as-is (that `as num?` cast would throw on a string).
//   /// Everything not present here just takes the same default [fromJson]
//   /// would've fallen back to when a field was missing.
//   factory AkHotelContentItemModel.fromCuratedJson(Map<String, dynamic> json) {
//     return AkHotelContentItemModel(
//       id: json['id']?.toString() ?? '',
//       name: json['name']?.toString() ?? '',
//       starRating: double.tryParse(json['starRating']?.toString() ?? '') ?? 0.0,
//       address: json['address']?.toString() ?? '',
//       heroImage: '',
//       images: const [],
//       facilities: const [],
//       provider: '',
//       reviewCount: 0,
//       reviewRating: 0.0,
//       isSoldOut: false,
//       chainName: '',
//       countryCode: '',
//     );
//   }
// }
//
// class AkHotelResultContentModel extends AkHotelResultContentEntity {
//   const AkHotelResultContentModel({
//     required super.searchId,
//     required super.locationName,
//     required super.total,
//     required super.hotels,
//     super.curatedHotels,
//   });
//
//   factory AkHotelResultContentModel.fromJson(Map<String, dynamic> json) {
//     final rawHotels = json['hotels'] as List<dynamic>? ?? [];
//     final rawCurated = json['curatedHotels'] as List<dynamic>? ?? [];
//     return AkHotelResultContentModel(
//       searchId: json['searchId']?.toString() ?? '',
//       locationName: json['locationName']?.toString() ?? '',
//       total: (json['total'] as num?)?.toInt() ?? 0,
//       hotels: rawHotels.whereType<Map<String, dynamic>>().map(AkHotelContentItemModel.fromJson).toList(),
//       curatedHotels: rawCurated
//           .whereType<Map<String, dynamic>>()
//           .map(AkHotelContentItemModel.fromCuratedJson)
//           .where((h) => h.id.isNotEmpty)
//           .toList(),
//     );
//   }
// }


import '../../domain/entity/AKHotelResultContent_entity.dart';

// === UPDATED: Now takes full json for room extraction ===
List<String> _parseImages(dynamic raw, Map<String, dynamic> json) {
  List<String> images = [];

  // First try the direct 'images' field
  if (raw is List) {
    images = raw
        .map((e) {
      if (e is String) return e;
      if (e is Map) return (e['url'] ?? '').toString();
      return '';
    })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // If no images found, try to extract from roomGroups
  if (images.isEmpty) {
    try {
      final roomGroups = json['roomGroups'] as List? ?? [];
      if (roomGroups.isNotEmpty) {
        final firstRoomGroup = roomGroups.first as Map<String, dynamic>;
        final room = firstRoomGroup['room'] as Map<String, dynamic>?;
        if (room != null) {
          final roomImages = room['images'] as List? ?? [];
          images = roomImages
              .map((e) {
            if (e is String) return e;
            if (e is Map) return (e['url'] ?? '').toString();
            return '';
          })
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      // If extraction fails, keep images empty
    }
  }

  return images;
}

// === NEW: Helper to get hero image ===
String _getHeroImage(Map<String, dynamic> json) {
  // First try heroImage field
  final hero = json['heroImage']?.toString() ?? '';
  if (hero.isNotEmpty) return hero;

  // If empty, try to get first room image
  final images = _parseImages(json['images'], json);
  if (images.isNotEmpty) return images.first;

  return '';
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
      heroImage: _getHeroImage(json),
      images: _parseImages(json['images'], json),
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

  /// `curatedHotels` rows are a sparser shape than `hotels` — notably
  /// `starRating` comes back as a numeric *string* ("4") rather than a
  /// number, and there's no heroImage/images/facilities/geoCode/provider/
  /// userReview/isSoldOut/chainName/countryCode at all — so this can't
  /// reuse [fromJson] as-is (that `as num?` cast would throw on a string).
  /// Everything not present here just takes the same default [fromJson]
  /// would've fallen back to when a field was missing.
  factory AkHotelContentItemModel.fromCuratedJson(Map<String, dynamic> json) {
    return AkHotelContentItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      starRating: double.tryParse(json['starRating']?.toString() ?? '') ?? 0.0,
      address: json['address']?.toString() ?? '',
      heroImage: '',
      images: const [],
      facilities: const [],
      provider: '',
      reviewCount: 0,
      reviewRating: 0.0,
      isSoldOut: false,
      chainName: '',
      countryCode: '',
    );
  }
}

class AkHotelResultContentModel extends AkHotelResultContentEntity {
  const AkHotelResultContentModel({
    required super.searchId,
    required super.locationName,
    required super.total,
    required super.hotels,
    super.curatedHotels,
  });

  factory AkHotelResultContentModel.fromJson(Map<String, dynamic> json) {
    final rawHotels = json['hotels'] as List<dynamic>? ?? [];
    final rawCurated = json['curatedHotels'] as List<dynamic>? ?? [];
    return AkHotelResultContentModel(
      searchId: json['searchId']?.toString() ?? '',
      locationName: json['locationName']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      hotels: rawHotels.whereType<Map<String, dynamic>>().map(AkHotelContentItemModel.fromJson).toList(),
      curatedHotels: rawCurated
          .whereType<Map<String, dynamic>>()
          .map(AkHotelContentItemModel.fromCuratedJson)
          .where((h) => h.id.isNotEmpty)
          .toList(),
    );
  }
}
