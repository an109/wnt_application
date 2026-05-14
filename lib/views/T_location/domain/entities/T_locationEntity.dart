import 'package:equatable/equatable.dart';

class T_locationEntity extends Equatable {
  final String id;
  final String source;
  final String type;
  final String label;
  final String displayName;
  final String name;
  final String description;
  final String formattedAddress;
  final String fullAddress;
  final String address;
  final String city;
  final String country;
  final String iataCode;
  final String icaoCode;
  final String placeId;
  final double? lat;
  final double? lng;
  final String timezone;
  final Map<String, dynamic>? raw;

  const T_locationEntity({
    required this.id,
    required this.source,
    required this.type,
    required this.label,
    required this.displayName,
    required this.name,
    required this.description,
    required this.formattedAddress,
    required this.fullAddress,
    required this.address,
    required this.city,
    required this.country,
    required this.iataCode,
    required this.icaoCode,
    required this.placeId,
    required this.lat,
    required this.lng,
    required this.timezone,
    required this.raw,
  });

  @override
  List<Object?> get props => [
    id,
    source,
    type,
    label,
    displayName,
    name,
    description,
    formattedAddress,
    fullAddress,
    address,
    city,
    country,
    iataCode,
    icaoCode,
    placeId,
    lat,
    lng,
    timezone,
    raw,
  ];
}