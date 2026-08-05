import 'package:equatable/equatable.dart';

class AkHotelSearchInitRoomEntity extends Equatable {
  final int adults;
  final int children;
  final List<int> childAges;

  const AkHotelSearchInitRoomEntity({
    required this.adults,
    this.children = 0,
    this.childAges = const [],
  });

  @override
  List<Object?> get props => [adults, children, childAges];
}

class AkHotelGeoCodeEntity extends Equatable {
  final String lat;
  final String long;

  const AkHotelGeoCodeEntity({required this.lat, required this.long});

  @override
  List<Object?> get props => [lat, long];
}

class AkHotelSearchInitRequestEntity extends Equatable {
  /// The Autosuggest-picked locationId. Null when searching by [geoCode]
  /// instead — exactly one of the two must be set, never neither.
  final String? locationId;
  final AkHotelGeoCodeEntity? geoCode;

  /// MM/DD/YYYY, per the Akbar hotels API — not ISO.
  final String checkIn;
  final String checkOut;
  final List<AkHotelSearchInitRoomEntity> rooms;
  final String nationality;
  final String countryOfResidence;
  final String destinationCountryCode;

  const AkHotelSearchInitRequestEntity({
    this.locationId,
    this.geoCode,
    required this.checkIn,
    required this.checkOut,
    required this.rooms,
    required this.nationality,
    required this.countryOfResidence,
    required this.destinationCountryCode,
  });

  @override
  List<Object?> get props => [
        locationId,
        geoCode,
        checkIn,
        checkOut,
        rooms,
        nationality,
        countryOfResidence,
        destinationCountryCode,
      ];
}

class AkHotelSearchInitEntity extends Equatable {
  final bool success;
  final String searchId;
  final String searchTracingKey;
  final String status;

  const AkHotelSearchInitEntity({
    required this.success,
    required this.searchId,
    required this.searchTracingKey,
    required this.status,
  });

  @override
  List<Object?> get props => [success, searchId, searchTracingKey, status];
}
