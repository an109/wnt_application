import '../../domain/entities/T_SearchEntity.dart';

class TransportSearchModel extends TransportSearchEntity {
  const TransportSearchModel({
    required bool success,
    required SearchData search,
    required LocalData local,
  }) : super(success: success, search: search, local: local);

  factory TransportSearchModel.fromJson(Map<String, dynamic> json) {
    return TransportSearchModel(
      success: json['success'] ?? false,
      search: SearchData.fromJson(json['search'] ?? {}),
      local: LocalData.fromJson(json['local'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'search': (search as SearchData).toJson(),
      'local': (local as LocalData).toJson(),
    };
  }
}

class SearchData {
  final int numPassengers;
  final String pickupDatetime;
  final dynamic flightDatetime;
  final bool includePlatformFee;
  final bool includeTargetPricing;
  final dynamic goCorpId;
  final String searchId;
  final List<dynamic> results;
  final CurrencyInfo currencyInfo;
  final Location startLocation;
  final Location endLocation;
  final int createdAt;
  final int expiresAt;
  final int expiresIn;
  final bool moreComing;
  final bool allowDelayedFlightInfo;
  final int hourlyBookingDuration;
  final String flightType;
  final String resultsSource;

  const SearchData({
    required this.numPassengers,
    required this.pickupDatetime,
    this.flightDatetime,
    required this.includePlatformFee,
    required this.includeTargetPricing,
    this.goCorpId,
    required this.searchId,
    required this.results,
    required this.currencyInfo,
    required this.startLocation,
    required this.endLocation,
    required this.createdAt,
    required this.expiresAt,
    required this.expiresIn,
    required this.moreComing,
    required this.allowDelayedFlightInfo,
    required this.hourlyBookingDuration,
    required this.flightType,
    required this.resultsSource,
  });

  factory SearchData.fromJson(Map<String, dynamic> json) {
    return SearchData(
      numPassengers: json['num_passengers'] ?? 0,
      pickupDatetime: json['pickup_datetime'] ?? '',
      flightDatetime: json['flight_datetime'],
      includePlatformFee: json['include_platform_fee'] ?? false,
      includeTargetPricing: json['include_target_pricing'] ?? false,
      goCorpId: json['go_corp_id'],
      searchId: json['search_id'] ?? '',
      results: json['results'] != null ? List.from(json['results']) : [],
      currencyInfo: CurrencyInfo.fromJson(json['currency_info'] ?? {}),
      startLocation: Location.fromJson(json['start_location'] ?? {}),
      endLocation: Location.fromJson(json['end_location'] ?? {}),
      createdAt: json['created_at'] ?? 0,
      expiresAt: json['expires_at'] ?? 0,
      expiresIn: json['expires_in'] ?? 0,
      moreComing: json['more_coming'] ?? false,
      allowDelayedFlightInfo: json['allow_delayed_flight_info'] ?? false,
      hourlyBookingDuration: json['hourly_booking_duration'] ?? 0,
      flightType: json['flight_type'] ?? '',
      resultsSource: json['results_source'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'num_passengers': numPassengers,
      'pickup_datetime': pickupDatetime,
      'flight_datetime': flightDatetime,
      'include_platform_fee': includePlatformFee,
      'include_target_pricing': includeTargetPricing,
      'go_corp_id': goCorpId,
      'search_id': searchId,
      'results': results,
      'currency_info': (currencyInfo as CurrencyInfo).toJson(),
      'start_location': (startLocation as Location).toJson(),
      'end_location': (endLocation as Location).toJson(),
      'created_at': createdAt,
      'expires_at': expiresAt,
      'expires_in': expiresIn,
      'more_coming': moreComing,
      'allow_delayed_flight_info': allowDelayedFlightInfo,
      'hourly_booking_duration': hourlyBookingDuration,
      'flight_type': flightType,
      'results_source': resultsSource,
    };
  }
}

class LocalData {
  final int id;
  final dynamic reseller;
  final dynamic user;
  final String guestReference;
  final String searchId;
  final String status;
  final String startAddress;
  final String endAddress;
  final String pickupDatetime;
  final dynamic flightDatetime;
  final int numPassengers;
  final String currency;
  final bool moreComing;
  final String expiresAt;
  final String selectedResultId;
  final Map<String, dynamic> rawRequest;
  final Map<String, dynamic> rawResponse;
  final Map<String, dynamic> latestResponse;
  final List<dynamic> results;
  final String created;
  final String updated;

  const LocalData({
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
    required this.rawRequest,
    required this.rawResponse,
    required this.latestResponse,
    required this.results,
    required this.created,
    required this.updated,
  });

  factory LocalData.fromJson(Map<String, dynamic> json) {
    return LocalData(
      id: json['id'] ?? 0,
      reseller: json['reseller'],
      user: json['user'],
      guestReference: json['guest_reference'] ?? '',
      searchId: json['search_id'] ?? '',
      status: json['status'] ?? '',
      startAddress: json['start_address'] ?? '',
      endAddress: json['end_address'] ?? '',
      pickupDatetime: json['pickup_datetime'] ?? '',
      flightDatetime: json['flight_datetime'],
      numPassengers: json['num_passengers'] ?? 0,
      currency: json['currency'] ?? '',
      moreComing: json['more_coming'] ?? false,
      expiresAt: json['expires_at'] ?? '',
      selectedResultId: json['selected_result_id'] ?? '',
      rawRequest: json['raw_request'] ?? {},
      rawResponse: json['raw_response'] ?? {},
      latestResponse: json['latest_response'] ?? {},
      results: json['results'] != null ? List.from(json['results']) : [],
      created: json['created'] ?? '',
      updated: json['updated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reseller': reseller,
      'user': user,
      'guest_reference': guestReference,
      'search_id': searchId,
      'status': status,
      'start_address': startAddress,
      'end_address': endAddress,
      'pickup_datetime': pickupDatetime,
      'flight_datetime': flightDatetime,
      'num_passengers': numPassengers,
      'currency': currency,
      'more_coming': moreComing,
      'expires_at': expiresAt,
      'selected_result_id': selectedResultId,
      'raw_request': rawRequest,
      'raw_response': rawResponse,
      'latest_response': latestResponse,
      'results': results,
      'created': created,
      'updated': updated,
    };
  }
}

class CurrencyInfo {
  final String code;
  final String prefixSymbol;
  final String suffixSymbol;

  const CurrencyInfo({
    required this.code,
    required this.prefixSymbol,
    required this.suffixSymbol,
  });

  factory CurrencyInfo.fromJson(Map<String, dynamic> json) {
    return CurrencyInfo(
      code: json['code'] ?? '',
      prefixSymbol: json['prefix_symbol'] ?? '',
      suffixSymbol: json['suffix_symbol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'prefix_symbol': prefixSymbol,
      'suffix_symbol': suffixSymbol,
    };
  }
}

class Location {
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

  const Location({
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

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      fullAddress: json['full_address'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      timezone: json['timezone'] ?? '',
      iataCode: json['iata_code'] ?? '',
      icaoCode: json['icao_code'] ?? '',
      railIataCode: json['rail_iata_code'] ?? '',
      uicCode: json['uic_code'] ?? '',
      metrolinxCode: json['metrolinx_code'] ?? '',
      placeId: json['place_id'] ?? '',
      type: json['type'] ?? '',
      city: json['city'] ?? '',
      isCruisePort: json['is_cruise_port'] ?? false,
      isTrainStation: json['is_train_station'] ?? false,
      isTransitStation: json['is_transit_station'] ?? false,
      isIncomplete: json['is_incomplete'] ?? false,
      favoriteId: json['favorite_id'],
      favoriteSource: json['favorite_source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_address': fullAddress,
      'formatted_address': formattedAddress,
      'lat': lat,
      'lng': lng,
      'timezone': timezone,
      'iata_code': iataCode,
      'icao_code': icaoCode,
      'rail_iata_code': railIataCode,
      'uic_code': uicCode,
      'metrolinx_code': metrolinxCode,
      'place_id': placeId,
      'type': type,
      'city': city,
      'is_cruise_port': isCruisePort,
      'is_train_station': isTrainStation,
      'is_transit_station': isTransitStation,
      'is_incomplete': isIncomplete,
      'favorite_id': favoriteId,
      'favorite_source': favoriteSource,
    };
  }
}