import 'package:equatable/equatable.dart';

enum DestinationType { city, hotel, country, airport }

class DestinationEntity extends Equatable {
  final String id;
  final String name;
  final DestinationType type;
  final String? countryCode;
  final String? countryName;
  final String? cityCode;
  final String? additionalInfo;

  const DestinationEntity({
    required this.id,
    required this.name,
    required this.type,
    this.countryCode,
    this.cityCode,
    this.countryName,
    this.additionalInfo,
  });

  String get displayName {
    switch (type) {
      case DestinationType.city:
        return '$name, $countryName';
      case DestinationType.hotel:
        return '$name - $cityName';
      case DestinationType.country:
        return name;
      case DestinationType.airport:
        return '$name ($countryCode)';
    }
  }

  String get cityName {
    if (type == DestinationType.hotel && additionalInfo != null) {
      return additionalInfo!;
    }
    return name;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    countryCode,
    countryName,
    additionalInfo,
    cityCode
  ];
}