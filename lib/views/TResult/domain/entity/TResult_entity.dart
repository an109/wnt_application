import 'package:equatable/equatable.dart';

class TransportResultEntity extends Equatable {
  final bool success;
  final SearchEntity search;
  final List<TransportResultItemEntity> results;
  final LocalSearchEntity? local;
  final CurrencyInfoEntity? currencyInfo;
  final LocationEntity? startLocation;
  final LocationEntity? endLocation;

  const TransportResultEntity({
    required this.success,
    required this.search,
    required this.results,
    this.local,
    this.currencyInfo,
    this.startLocation,
    this.endLocation,
  });

  @override
  List<Object?> get props => [
    success,
    search,
    results,
    local,
    currencyInfo,
    startLocation,
    endLocation,
  ];
}

class SearchEntity extends Equatable {
  final int numPassengers;
  final String pickupDatetime;
  final String? flightDatetime;
  final bool includePlatformFee;
  final bool includeTargetPricing;
  final String? goCorpId;
  final String searchId;

  const SearchEntity({
    required this.numPassengers,
    required this.pickupDatetime,
    this.flightDatetime,
    required this.includePlatformFee,
    required this.includeTargetPricing,
    this.goCorpId,
    required this.searchId,
  });

  @override
  List<Object?> get props => [
    numPassengers,
    pickupDatetime,
    flightDatetime,
    includePlatformFee,
    includeTargetPricing,
    goCorpId,
    searchId,
  ];
}

class TransportResultItemEntity extends Equatable {
  final String resultId;
  final String vehicleId;
  final TotalPriceEntity totalPrice;
  final List<String> tags;
  final List<StepEntity> steps;
  final bool bookable;
  final String? providerName;
  final String? vehicleName;
  final String? vehicleType;

  const TransportResultItemEntity({
    required this.resultId,
    required this.vehicleId,
    required this.totalPrice,
    required this.tags,
    required this.steps,
    required this.bookable,
    this.providerName,
    this.vehicleName,
    this.vehicleType,
  });

  @override
  List<Object?> get props => [
    resultId,
    vehicleId,
    totalPrice,
    tags,
    steps,
    bookable,
    providerName,
    vehicleName,
    vehicleType,
  ];
}

class TotalPriceEntity extends Equatable {
  final PriceDetailsEntity totalPrice;
  final dynamic totalPriceWithoutPlatformFee;
  final dynamic platformFee;
  final dynamic totalPriceWithoutPartnerFee;
  final dynamic partnerFee;
  final dynamic slashedPrice;

  const TotalPriceEntity({
    required this.totalPrice,
    this.totalPriceWithoutPlatformFee,
    this.platformFee,
    this.totalPriceWithoutPartnerFee,
    this.partnerFee,
    this.slashedPrice,
  });

  @override
  List<Object?> get props => [
    totalPrice,
    totalPriceWithoutPlatformFee,
    platformFee,
    totalPriceWithoutPartnerFee,
    partnerFee,
    slashedPrice,
  ];
}

class PriceDetailsEntity extends Equatable {
  final String value;
  final String display;
  final String compact;
  final String currency;

  const PriceDetailsEntity({
    required this.value,
    required this.display,
    required this.compact,
    required this.currency,
  });

  @override
  List<Object?> get props => [value, display, compact, currency];
}

class StepEntity extends Equatable {
  final bool main;
  final String stepType;
  final StepDetailsEntity details;

  const StepEntity({
    required this.main,
    required this.stepType,
    required this.details,
  });

  @override
  List<Object?> get props => [main, stepType, details];
}

class StepDetailsEntity extends Equatable {
  final String description;
  final VehicleEntity vehicle;
  final int maximumPickupTimeBuffer;
  final int time;
  final ProviderEntity provider;
  final String providerName;
  final PriceEntity price;
  final String departureDatetime;
  final CancellationEntity cancellation;
  final WaitTimeEntity waitTime;
  final List<AmenityEntity> amenities;
  final bool bookable;
  final bool flightInfoRequired;
  final bool extraPaxRequired;

  const StepDetailsEntity({
    required this.description,
    required this.vehicle,
    required this.maximumPickupTimeBuffer,
    required this.time,
    required this.provider,
    required this.providerName,
    required this.price,
    required this.departureDatetime,
    required this.cancellation,
    required this.waitTime,
    required this.amenities,
    required this.bookable,
    required this.flightInfoRequired,
    required this.extraPaxRequired,
  });

  @override
  List<Object?> get props => [
    description,
    vehicle,
    maximumPickupTimeBuffer,
    time,
    provider,
    providerName,
    price,
    departureDatetime,
    cancellation,
    waitTime,
    amenities,
    bookable,
    flightInfoRequired,
    extraPaxRequired,
  ];
}

class VehicleEntity extends Equatable {
  final String image;
  final VehicleTypeEntity vehicleType;
  final int maxBags;
  final bool isMaxBagsPerPerson;
  final int maxPassengers;
  final VehicleCategoryEntity category;
  final int numVehicles;
  final int totalBags;
  final String? model;
  final String? make;
  final int vehicleClass;
  final VehicleClassDetailEntity? vehicleClassDetail;

  const VehicleEntity({
    required this.image,
    required this.vehicleType,
    required this.maxBags,
    required this.isMaxBagsPerPerson,
    required this.maxPassengers,
    required this.category,
    required this.numVehicles,
    required this.totalBags,
    this.model,
    this.make,
    required this.vehicleClass,
    this.vehicleClassDetail,
  });

  @override
  List<Object?> get props => [
    image,
    vehicleType,
    maxBags,
    isMaxBagsPerPerson,
    maxPassengers,
    category,
    numVehicles,
    totalBags,
    model,
    make,
    vehicleClass,
    vehicleClassDetail,
  ];
}

class VehicleTypeEntity extends Equatable {
  final int key;
  final String name;

  const VehicleTypeEntity({
    required this.key,
    required this.name,
  });

  @override
  List<Object?> get props => [key, name];
}

class VehicleCategoryEntity extends Equatable {
  final int id;
  final String name;

  const VehicleCategoryEntity({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}

class VehicleClassDetailEntity extends Equatable {
  final String displayName;
  final int vehicleClassId;

  const VehicleClassDetailEntity({
    required this.displayName,
    required this.vehicleClassId,
  });

  @override
  List<Object?> get props => [displayName, vehicleClassId];
}

class ProviderEntity extends Equatable {
  final String name;
  final String displayName;
  final String logoUrl;
  final int rating;
  final int ratingCount;
  final String ratingWithDecimals;
  final double supplierScore;

  const ProviderEntity({
    required this.name,
    required this.displayName,
    required this.logoUrl,
    required this.rating,
    required this.ratingCount,
    required this.ratingWithDecimals,
    required this.supplierScore,
  });

  @override
  List<Object?> get props => [
    name,
    displayName,
    logoUrl,
    rating,
    ratingCount,
    ratingWithDecimals,
    supplierScore,
  ];
}

class PriceEntity extends Equatable {
  final PriceDetailsEntity price;
  final bool tollsIncluded;
  final bool gratuityIncluded;
  final bool gratuityAccepted;

  const PriceEntity({
    required this.price,
    required this.tollsIncluded,
    required this.gratuityIncluded,
    required this.gratuityAccepted,
  });

  @override
  List<Object?> get props => [
    price,
    tollsIncluded,
    gratuityIncluded,
    gratuityAccepted,
  ];
}

class CancellationEntity extends Equatable {
  final bool cancellableOnline;
  final bool cancellableOffline;
  final bool amendable;
  final List<CancellationPolicyEntity> policy;

  const CancellationEntity({
    required this.cancellableOnline,
    required this.cancellableOffline,
    required this.amendable,
    required this.policy,
  });

  @override
  List<Object?> get props => [
    cancellableOnline,
    cancellableOffline,
    amendable,
    policy,
  ];
}

class CancellationPolicyEntity extends Equatable {
  final int notice;
  final int refundPercent;

  const CancellationPolicyEntity({
    required this.notice,
    required this.refundPercent,
  });

  @override
  List<Object?> get props => [notice, refundPercent];
}

class WaitTimeEntity extends Equatable {
  final int minutesIncluded;
  final dynamic waitingMinutePrice;

  const WaitTimeEntity({
    required this.minutesIncluded,
    this.waitingMinutePrice,
  });

  @override
  List<Object?> get props => [minutesIncluded, waitingMinutePrice];
}

class AmenityEntity extends Equatable {
  final String key;
  final String name;
  final String description;
  final String imageUrl;
  final String pngImageUrl;
  final String inputType;
  final bool included;
  final bool selected;
  final PriceDetailsEntity? price;
  final bool internal;
  final String? priceAmount;
  final String currency;
  final bool chargeable;
  final int quantity;
  final int maxQuantity;
  final bool requiresSpecialInstructionForMultiple;

  const AmenityEntity({
    required this.key,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.pngImageUrl,
    required this.inputType,
    required this.included,
    required this.selected,
    this.price,
    required this.internal,
    this.priceAmount,
    required this.currency,
    required this.chargeable,
    required this.quantity,
    required this.maxQuantity,
    required this.requiresSpecialInstructionForMultiple,
  });

  @override
  List<Object?> get props => [
    key,
    name,
    description,
    imageUrl,
    pngImageUrl,
    inputType,
    included,
    selected,
    price,
    internal,
    priceAmount,
    currency,
    chargeable,
    quantity,
    maxQuantity,
    requiresSpecialInstructionForMultiple,
  ];
}

class LocalSearchEntity extends Equatable {
  final int id;
  final String? reseller;
  final String? user;
  final String guestReference;
  final String searchId;
  final String status;
  final String startAddress;
  final String endAddress;
  final String pickupDatetime;
  final String? flightDatetime;
  final int numPassengers;
  final String currency;
  final bool moreComing;
  final String expiresAt;
  final String selectedResultId;

  const LocalSearchEntity({
    required this.id,
    this.reseller,
    this.user,
    required this.guestReference,
    required this.searchId,
    required this.status,
    required this.startAddress,
    required this.endAddress,
    required this.pickupDatetime,
    this.flightDatetime,
    required this.numPassengers,
    required this.currency,
    required this.moreComing,
    required this.expiresAt,
    required this.selectedResultId,
  });

  @override
  List<Object?> get props => [
    id,
    reseller,
    user,
    guestReference,
    searchId,
    status,
    startAddress,
    endAddress,
    pickupDatetime,
    flightDatetime,
    numPassengers,
    currency,
    moreComing,
    expiresAt,
    selectedResultId,
  ];
}

class CurrencyInfoEntity extends Equatable {
  final String code;
  final String prefixSymbol;
  final String suffixSymbol;

  const CurrencyInfoEntity({
    required this.code,
    required this.prefixSymbol,
    required this.suffixSymbol,
  });

  @override
  List<Object?> get props => [code, prefixSymbol, suffixSymbol];
}

class LocationEntity extends Equatable {
  final String fullAddress;
  final String formattedAddress;
  final double lat;
  final double lng;
  final String timezone;
  final String iataCode;
  final String icaoCode;
  final String railIataCode;
  final String uicCode;
  final String metrolinxCode;
  final String placeId;
  final String type;
  final String city;
  final bool isCruisePort;
  final bool isTrainStation;
  final bool isTransitStation;
  final bool isIncomplete;
  final dynamic favoriteId;
  final dynamic favoriteSource;

  const LocationEntity({
    required this.fullAddress,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
    required this.timezone,
    required this.iataCode,
    required this.icaoCode,
    required this.railIataCode,
    required this.uicCode,
    required this.metrolinxCode,
    required this.placeId,
    required this.type,
    required this.city,
    required this.isCruisePort,
    required this.isTrainStation,
    required this.isTransitStation,
    required this.isIncomplete,
    this.favoriteId,
    this.favoriteSource,
  });

  @override
  List<Object?> get props => [
    fullAddress,
    formattedAddress,
    lat,
    lng,
    timezone,
    iataCode,
    icaoCode,
    railIataCode,
    uicCode,
    metrolinxCode,
    placeId,
    type,
    city,
    isCruisePort,
    isTrainStation,
    isTransitStation,
    isIncomplete,
    favoriteId,
    favoriteSource,
  ];
}