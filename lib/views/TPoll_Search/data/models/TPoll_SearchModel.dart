import 'package:equatable/equatable.dart';

class TpollSearchModel extends Equatable {
  final bool success;
  final SearchDataModel search;

  const TpollSearchModel({
    required this.success,
    required this.search,
  });

  factory TpollSearchModel.fromJson(Map<String, dynamic> json) {
    return TpollSearchModel(
      success: json['success'] ?? false,
      search: SearchDataModel.fromJson(json['search'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [success, search];
}

class SearchDataModel extends Equatable {
  final int numPassengers;
  final String pickupDatetime;
  final String? flightDatetime;
  final String searchId;
  final List<SearchResultModel> results;
  final LocationInfoModel startLocation;
  final LocationInfoModel endLocation;
  final CurrencyInfoModel currencyInfo;
  final int expiresIn;
  final bool moreComing;


  const SearchDataModel({
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

  factory SearchDataModel.fromJson(Map<String, dynamic> json) {
    return SearchDataModel(
      numPassengers: json['num_passengers'] ?? 1,
      pickupDatetime: json['pickup_datetime'] ?? '',
      flightDatetime: json['flight_datetime'],
      searchId: json['search_id'] ?? '',
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => SearchResultModel.fromJson(e))
          .toList() ??
          [],
      startLocation: LocationInfoModel.fromJson(json['start_location'] ?? {}),
      endLocation: LocationInfoModel.fromJson(json['end_location'] ?? {}),
      currencyInfo: CurrencyInfoModel.fromJson(json['currency_info'] ?? {}),
      expiresIn: json['expires_in'] ?? 0,
      moreComing: json['more_coming'] ?? false,

    );
  }

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

class SearchResultModel extends Equatable {
  final String resultId;
  final String vehicleId;
  final TotalPriceModel totalPrice;
  final String providerName;
  final String vehicleType;
  final String vehicleName;
  final bool bookable;
  final List<StepModel> steps;
  final String totalPriceAmount;
  final String totalPriceCurrency;

  const SearchResultModel({
    required this.resultId,
    required this.vehicleId,
    required this.totalPrice,
    required this.providerName,
    required this.vehicleType,
    required this.vehicleName,
    required this.bookable,
    required this.steps,
    required this.totalPriceAmount,
    required this.totalPriceCurrency,

  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      resultId: json['result_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      totalPrice: TotalPriceModel.fromJson(json['total_price'] ?? {}),
      providerName: json['provider_name'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      bookable: json['bookable'] ?? false,
      totalPriceAmount: json['total_price_amount'] ?? '0',
      totalPriceCurrency: json['total_price_currency'] ?? 'USD',
      // steps: (json['steps'] as List<dynamic>?)
      //     ?.map((e) => StepModel.fromJson(e))
      //     .toList() ??
      //     [],
      steps: (json['raw_result']?['steps'] as List<dynamic>?)?.map((e) => StepModel.fromJson(e)).toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [
    resultId,
    vehicleId,
    totalPrice,
    providerName,
    vehicleType,
    vehicleName,
    bookable,
    steps,
    totalPriceAmount,
    totalPriceCurrency
  ];
}

class TotalPriceModel extends Equatable {
  final PriceInfoModel totalPrice;

  const TotalPriceModel({required this.totalPrice});

  factory TotalPriceModel.fromJson(Map<String, dynamic> json) {
    return TotalPriceModel(
      totalPrice: PriceInfoModel.fromJson(json['total_price'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [totalPrice];
}

class PriceInfoModel extends Equatable {
  final String value;
  final String display;
  final String compact;
  final String currency;

  const PriceInfoModel({
    required this.value,
    required this.display,
    required this.compact,
    required this.currency,
  });

  factory PriceInfoModel.fromJson(Map<String, dynamic> json) {
    return PriceInfoModel(
      value: json['value'] ?? '0',
      display: json['display'] ?? '',
      compact: json['compact'] ?? '',
      currency: json['currency'] ?? 'USD',
    );
  }

  @override
  List<Object?> get props => [value, display, compact, currency];
}

class StepModel extends Equatable {
  final bool main;
  final String stepType;
  final StepDetailsModel details;

  const StepModel({
    required this.main,
    required this.stepType,
    required this.details,
  });

  factory StepModel.fromJson(Map<String, dynamic> json) {
    return StepModel(
      main: json['main'] ?? false,
      stepType: json['step_type'] ?? '',
      details: StepDetailsModel.fromJson(json['details'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [main, stepType, details];
}

class StepDetailsModel extends Equatable {
  final String description;
  final VehicleModel vehicle;
  final int time;
  final ProviderModel provider;
  final PriceModel price;
  final String departureDatetime;
  final List<AmenityModel> amenities;
  final bool bookable;

  const StepDetailsModel({
    required this.description,
    required this.vehicle,
    required this.time,
    required this.provider,
    required this.price,
    required this.departureDatetime,
    required this.amenities,
    required this.bookable,
  });

  factory StepDetailsModel.fromJson(Map<String, dynamic> json) {
    return StepDetailsModel(
      description: json['description'] ?? '',
      vehicle: VehicleModel.fromJson(json['vehicle'] ?? {}),
      time: json['time'] ?? 0,
      provider: ProviderModel.fromJson(json['provider'] ?? {}),
      price: PriceModel.fromJson(json['price'] ?? {}),
      departureDatetime: json['departure_datetime'] ?? '',
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((e) => AmenityModel.fromJson(e))
          .toList() ??
          [],
      bookable: json['bookable'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    description,
    vehicle,
    time,
    provider,
    price,
    departureDatetime,
    amenities,
    bookable,
  ];
}

class VehicleModel extends Equatable {
  final String image;
  final String make;
  final String model;
  final VehicleTypeModel vehicleType;
  final int maxBags;
  final int maxPassengers;
  final VehicleCategoryModel category;

  const VehicleModel({
    required this.image,
    required this.make,
    required this.model,
    required this.vehicleType,
    required this.maxBags,
    required this.maxPassengers,
    required this.category,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      image: json['image'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      vehicleType: VehicleTypeModel.fromJson(json['vehicle_type'] ?? {}),
      maxBags: json['max_bags'] ?? 0,
      maxPassengers: json['max_passengers'] ?? 0,
      category: VehicleCategoryModel.fromJson(json['category'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [image, make, model, vehicleType, maxBags, maxPassengers, category];
}

class VehicleTypeModel extends Equatable {
  final int key;
  final String name;

  const VehicleTypeModel({required this.key, required this.name});

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      key: json['key'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  @override
  List<Object?> get props => [key, name];
}

class VehicleCategoryModel extends Equatable {
  final int id;
  final String name;

  const VehicleCategoryModel({required this.id, required this.name});

  factory VehicleCategoryModel.fromJson(Map<String, dynamic> json) {
    return VehicleCategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class ProviderModel extends Equatable {
  final String name;
  final String displayName;
  final String logoUrl;
  final num? rating;
  final int? ratingCount;
  final num? supplierScore;
  final String? ratingWithDecimals;

  const ProviderModel({
    required this.name,
    required this.displayName,
    required this.logoUrl,
    this.rating,
    this.ratingCount,
    this.supplierScore,
    this.ratingWithDecimals,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      rating: json['rating'],
      ratingCount: json['rating_count'],
      supplierScore: json['supplier_score'],
      ratingWithDecimals: json['rating_with_decimals'],
    );
  }

  @override
  List<Object?> get props => [name, displayName, logoUrl, rating, ratingCount, supplierScore, ratingWithDecimals];
}

class PriceModel extends Equatable {
  final PriceInfoModel price;
  final bool tollsIncluded;

  const PriceModel({required this.price, required this.tollsIncluded});

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      price: PriceInfoModel.fromJson(json['price'] ?? {}),
      tollsIncluded: json['tolls_included'] ?? false,
    );
  }

  @override
  List<Object?> get props => [price, tollsIncluded];
}

class AmenityModel extends Equatable {
  final String key;
  final String name;
  final String description;
  final bool included;
  final bool chargeable;
  final PriceInfoModel? price;

  const AmenityModel({
    required this.key,
    required this.name,
    required this.description,
    required this.included,
    required this.chargeable,
    this.price,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      included: json['included'] ?? false,
      chargeable: json['chargeable'] ?? false,
      price: json['price'] != null && (json['price'] as Map).isNotEmpty
          ? PriceInfoModel.fromJson(json['price'])
          : null,
    );
  }

  @override
  List<Object?> get props => [key, name, description, included, chargeable, price];
}

class LocationInfoModel extends Equatable {
  final String fullAddress;
  final String city;
  final String iataCode;

  const LocationInfoModel({
    required this.fullAddress,
    required this.city,
    required this.iataCode,
  });

  factory LocationInfoModel.fromJson(Map<String, dynamic> json) {
    return LocationInfoModel(
      fullAddress: json['full_address'] ?? '',
      city: json['city'] ?? '',
      iataCode: json['iata_code'] ?? '',
    );
  }

  @override
  List<Object?> get props => [fullAddress, city, iataCode];
}

class CurrencyInfoModel extends Equatable {
  final String code;
  final String prefixSymbol;

  const CurrencyInfoModel({required this.code, required this.prefixSymbol});

  factory CurrencyInfoModel.fromJson(Map<String, dynamic> json) {
    return CurrencyInfoModel(
      code: json['code'] ?? 'USD',
      prefixSymbol: json['prefix_symbol'] ?? '\$',
    );
  }

  @override
  List<Object?> get props => [code, prefixSymbol];
}