import 'package:equatable/equatable.dart';

class AkHotelResultContentRequestEntity extends Equatable {
  final String searchId;
  final String searchTracingKey;
  final int limit;
  final int offset;

  const AkHotelResultContentRequestEntity({
    required this.searchId,
    required this.searchTracingKey,
    this.limit = 50,
    this.offset = -1,
  });

  @override
  List<Object?> get props => [searchId, searchTracingKey, limit, offset];
}

class AkHotelFacilityEntity extends Equatable {
  final String name;

  const AkHotelFacilityEntity({required this.name});

  @override
  List<Object?> get props => [name];
}

/// One hotel's static content — name, images, address, rating. Fields that
/// only Rate fills in (rate, isRefundable, freeBreakfast, freeCancellation)
/// live on [AkHotelRateItemEntity] instead; merge the two lists by [id].
class AkHotelContentItemEntity extends Equatable {
  final String id;
  final String name;
  final double starRating;
  final String address;
  final String heroImage;
  final List<String> images;
  final List<AkHotelFacilityEntity> facilities;
  final double? lat;
  final double? long;
  final String provider;
  final int reviewCount;
  final double reviewRating;
  final bool isSoldOut;
  final String chainName;
  final String countryCode;

  const AkHotelContentItemEntity({
    required this.id,
    required this.name,
    required this.starRating,
    required this.address,
    required this.heroImage,
    required this.images,
    required this.facilities,
    this.lat,
    this.long,
    required this.provider,
    required this.reviewCount,
    required this.reviewRating,
    required this.isSoldOut,
    required this.chainName,
    required this.countryCode,
  });

  @override
  List<Object?> get props => [
        id, name, starRating, address, heroImage, images, facilities, lat, long,
        provider, reviewCount, reviewRating, isSoldOut, chainName, countryCode,
      ];
}

class AkHotelResultContentEntity extends Equatable {
  final String searchId;
  final String locationName;
  final int total;
  final List<AkHotelContentItemEntity> hotels;

  /// A separate, much larger, lower-detail sibling list Content returns
  /// alongside [hotels] (no images/facilities/geoCode/rating-as-double —
  /// just id/name/starRating/address). For a property-type search (the user
  /// searched a specific hotel by name, e.g. "Velvet Revive Munnar"), the
  /// matched hotel itself often only exists here — it never appears in
  /// [hotels] at any page offset — so callers that want that hotel to be
  /// reachable at all need to consult this list too. Kept separate from
  /// [hotels]/[total] on purpose so existing pagination math (which counts
  /// strictly against [total]) is untouched by it.
  final List<AkHotelContentItemEntity> curatedHotels;

  const AkHotelResultContentEntity({
    required this.searchId,
    required this.locationName,
    required this.total,
    required this.hotels,
    this.curatedHotels = const [],
  });

  @override
  List<Object?> get props => [searchId, locationName, total, hotels, curatedHotels];
}
