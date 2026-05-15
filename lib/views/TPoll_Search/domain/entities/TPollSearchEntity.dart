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
  final String vehicleType;
  final String vehicleName;
  final String totalPriceAmount;
  final String totalPriceCurrency;
  final bool bookable;
  final String vehicleImageUrl;
  final int maxPassengers;
  final int maxBags;
  final List<AmenityEntity> amenities;

  const SearchResultEntity({
    required this.resultId,
    required this.vehicleId,
    required this.providerName,
    required this.vehicleType,
    required this.vehicleName,
    required this.totalPriceAmount,
    required this.totalPriceCurrency,
    required this.bookable,
    required this.vehicleImageUrl,
    required this.maxPassengers,
    required this.maxBags,
    required this.amenities,
  });

  @override
  List<Object?> get props => [
    resultId,
    vehicleId,
    providerName,
    vehicleType,
    vehicleName,
    totalPriceAmount,
    totalPriceCurrency,
    bookable,
    vehicleImageUrl,
    maxPassengers,
    maxBags,
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
  final PriceInfoEntity? price;

  const AmenityEntity({
    required this.key,
    required this.name,
    required this.description,
    required this.included,
    required this.chargeable,
    this.price,
  });

  @override
  List<Object?> get props => [key, name,description, included, chargeable, price];
}

class PriceInfoEntity extends Equatable {
  final String value;
  final String display;
  final String compact;
  final String currency;

  const PriceInfoEntity({
    required this.value,
    required this.display,
    required this.compact,
    required this.currency,
  });

  @override
  List<Object?> get props => [value, display, compact, currency];
}