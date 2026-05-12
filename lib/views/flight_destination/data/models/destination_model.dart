import 'package:equatable/equatable.dart';
import '../../domain/entities/destination_entity.dart';

class CityModel extends Equatable {
  final String code;
  final String name;
  final String countryCode;
  final String countryName;
  final String source;

  const CityModel({
    required this.code,
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.source,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      countryName: json['countryName']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }

  DestinationEntity toEntity() {
    return DestinationEntity(
      id: code,
      name: name,
      type: DestinationType.city,
      countryCode: countryCode,
      countryName: countryName,
    );
  }

  @override
  List<Object?> get props => [code, name, countryCode, countryName, source];
}

class HotelModel extends Equatable {
  final String hotelCode;
  final String hotelName;
  final String hotelRating;
  final String address;
  final String cityCode;
  final String cityName;
  final String countryCode;
  final String countryName;
  final String source;

  const HotelModel({
    required this.hotelCode,
    required this.hotelName,
    required this.hotelRating,
    required this.address,
    required this.cityCode,
    required this.cityName,
    required this.countryCode,
    required this.countryName,
    required this.source,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      hotelCode: json['hotelCode']?.toString() ?? '',
      hotelName: json['hotelName']?.toString() ?? '',
      hotelRating: json['hotelRating']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      cityCode: json['cityCode']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      countryName: json['countryName']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }

  DestinationEntity toEntity() {
    return DestinationEntity(
      id: hotelCode,
      name: hotelName,
      type: DestinationType.hotel,
      countryCode: countryCode,
      cityCode: cityCode,
      countryName: countryName,
      additionalInfo: cityName,
    );
  }

  @override
  List<Object?> get props => [
    hotelCode, hotelName, hotelRating, address,
    cityCode, cityName, countryCode, countryName, source,
  ];
}

class DestinationSearchModel extends Equatable {
  final List<dynamic> countries;
  final List<CityModel> cities;
  final List<HotelModel> hotels;

  const DestinationSearchModel({
    this.countries = const [],
    this.cities = const [],
    this.hotels = const [],
  });

  factory DestinationSearchModel.fromJson(Map<String, dynamic> json) {
    return DestinationSearchModel(
      countries: json['countries'] != null
          ? List<dynamic>.from(json['countries'])
          : [],
      cities: json['cities'] != null
          ? (json['cities'] as List)
          .map((city) => CityModel.fromJson(city))
          .toList()
          : [],
      hotels: json['hotels'] != null
          ? (json['hotels'] as List)
          .map((hotel) => HotelModel.fromJson(hotel))
          .toList()
          : [],
    );
  }

  List<DestinationEntity> getAllDestinations() {
    return [
      ...cities.map((city) => city.toEntity()),
      ...hotels.map((hotel) => hotel.toEntity()),
    ];
  }

  @override
  List<Object?> get props => [countries, cities, hotels];
}