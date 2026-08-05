import 'package:equatable/equatable.dart';

class AkHotelAutosuggestRequestEntity extends Equatable {
  final String term;

  const AkHotelAutosuggestRequestEntity({required this.term});

  @override
  List<Object?> get props => [term];
}

/// One suggested location. `type` is one of city | airport | region |
/// multiCity | neighborhood | pointOfInterest | hotel. For `type: "hotel"`
/// entries the real hotel code is [referenceId], not [id] — [id] is always
/// the locationId Search Init expects.
class AkHotelLocationEntity extends Equatable {
  final String id;
  final String name;
  final String fullName;
  final String type;
  final String? state;
  final String? country;
  final String? referenceId;
  final double? lat;
  final double? long;

  const AkHotelLocationEntity({
    required this.id,
    required this.name,
    required this.fullName,
    required this.type,
    this.state,
    this.country,
    this.referenceId,
    this.lat,
    this.long,
  });

  @override
  List<Object?> get props => [id, name, fullName, type, state, country, referenceId, lat, long];
}

class AkHotelAutosuggestEntity extends Equatable {
  final bool success;
  final List<AkHotelLocationEntity> locations;

  const AkHotelAutosuggestEntity({required this.success, required this.locations});

  @override
  List<Object?> get props => [success, locations];
}
