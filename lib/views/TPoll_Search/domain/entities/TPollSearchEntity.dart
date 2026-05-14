import 'package:equatable/equatable.dart';

class TpollSearchEntity extends Equatable {
  final bool success;
  final SearchDataEntity search;

  const TpollSearchEntity({
    required this.success,
    required this.search,
  });

  @override
  List<Object?> get props => [success, search];
}

class SearchDataEntity extends Equatable {
  final int numPassengers;
  final String pickupDatetime;
  final String? flightDatetime;
  final String searchId;
  final List<SearchResultEntity> results;
  final LocationInfoEntity startLocation;
  final LocationInfoEntity endLocation;
  final CurrencyInfoEntity currencyInfo;
  final int expiresIn;
  final bool moreComing;

  const SearchDataEntity({
    required this.numPassengers,
    required this.pickupDatetime,
    this.flightDatetime,
    required this.searchId,
    required this.results,
    required this.startLocation,
    required this.endLocation,
    required this.currencyInfo,
    required this.expiresIn,
    required this.moreComing,
  });

  @override
  List<Object?> get props => [
    numPassengers,
    pickupDatetime,
    flightDatetime,
    searchId,
    results,
    startLocation,
    endLocation,
    currencyInfo,
    expiresIn,
    moreComing,
  ];
}

class SearchResultEntity extends Equatable {
  final String resultId;
  final String vehicleId;
  final String providerName;
  final String providerLogoUrl;
  final double providerRating;
  final int providerRatingCount;
  final String vehicleType;
  final String vehicleName;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleCategory;
  final String totalPriceAmount;
  final String totalPriceCurrency;
  final String totalPriceDisplay;
  final bool bookable;
  final String vehicleImageUrl;
  final int maxPassengers;
  final int maxBags;
  final int travelTimeMinutes;
  final int waitTimeMinutesIncluded;
  final String waitingMinutePriceDisplay;
  final bool flightInfoRequired;
  final double cancellationNoticeHours;
  final List<AmenityEntity> amenities;


  const SearchResultEntity({
    required this.resultId,
    required this.vehicleId,
    required this.providerName,
    required this.providerLogoUrl,
    required this.providerRating,
    required this.providerRatingCount,
    required this.vehicleType,
    required this.vehicleName,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleCategory,
    required this.totalPriceAmount,
    required this.totalPriceCurrency,
    required this.totalPriceDisplay,
    required this.bookable,
    required this.vehicleImageUrl,
    required this.maxPassengers,
    required this.maxBags,
    required this.travelTimeMinutes,
    required this.waitTimeMinutesIncluded,
    required this.waitingMinutePriceDisplay,
    required this.flightInfoRequired,
    required this.cancellationNoticeHours,
    required this.amenities,
  });

  @override
  List<Object?> get props => [
    resultId,
    vehicleId,
    providerName,
    providerLogoUrl,
    providerRating,
    providerRatingCount,
    vehicleType,
    vehicleName,
    vehicleMake,
    vehicleModel,
    vehicleCategory,
    totalPriceAmount,
    totalPriceCurrency,
    totalPriceDisplay,
    bookable,
    vehicleImageUrl,
    maxPassengers,
    maxBags,
    travelTimeMinutes,
    waitTimeMinutesIncluded,
    waitingMinutePriceDisplay,
    flightInfoRequired,
    cancellationNoticeHours,
    amenities,
  ];
}

class LocationInfoEntity extends Equatable {
  final String fullAddress;
  final String city;
  final String iataCode;

  const LocationInfoEntity({
    required this.fullAddress,
    required this.city,
    required this.iataCode,
  });

  @override
  List<Object?> get props => [fullAddress, city, iataCode];
}

class CurrencyInfoEntity extends Equatable {
  final String code;
  final String prefixSymbol;

  const CurrencyInfoEntity({
    required this.code,
    required this.prefixSymbol,
  });

  @override
  List<Object?> get props => [code, prefixSymbol];
}

class AmenityEntity extends Equatable {
  final String key;
  final String name;
  final String description;
  final bool included;
  final bool chargeable;
  final String priceDisplay;

  const AmenityEntity({
    required this.key,
    required this.name,
    required this.description,
    required this.included,
    required this.chargeable,
    required this.priceDisplay,
  });

  @override
  List<Object?> get props => [
    key,
    name,
    description,
    included,
    chargeable,
    priceDisplay,
  ];
}
