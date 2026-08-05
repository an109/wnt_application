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

  const AkHotelResultContentEntity({
    required this.searchId,
    required this.locationName,
    required this.total,
    required this.hotels,
  });

  @override
  List<Object?> get props => [searchId, locationName, total, hotels];
}
