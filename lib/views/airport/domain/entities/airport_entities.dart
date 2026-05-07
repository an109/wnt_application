import 'package:equatable/equatable.dart';

class AirportEntity extends Equatable {
  final String airportCode;
  final String airportName;
  final String cityCode;
  final String cityName;
  final String countryCode;

  const AirportEntity({
    required this.airportCode,
    required this.airportName,
    required this.cityCode,
    required this.cityName,
    required this.countryCode,
  });

  @override
  List<Object?> get props => [
    airportCode,
    airportName,
    cityCode,
    cityName,
    countryCode,
  ];
}