import '../../domain/entity/AKHotelSearchInit_entity.dart';

class AkHotelSearchInitRequestModel extends AkHotelSearchInitRequestEntity {
  const AkHotelSearchInitRequestModel({
    super.locationId,
    super.geoCode,
    required super.checkIn,
    required super.checkOut,
    required super.rooms,
    required super.nationality,
    required super.countryOfResidence,
    required super.destinationCountryCode,
  });

  factory AkHotelSearchInitRequestModel.fromEntity(AkHotelSearchInitRequestEntity entity) {
    return AkHotelSearchInitRequestModel(
      locationId: entity.locationId,
      geoCode: entity.geoCode,
      checkIn: entity.checkIn,
      checkOut: entity.checkOut,
      rooms: entity.rooms,
      nationality: entity.nationality,
      countryOfResidence: entity.countryOfResidence,
      destinationCountryCode: entity.destinationCountryCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      if (geoCode != null) 'geoCode': {'lat': geoCode!.lat, 'long': geoCode!.long},
      'checkIn': checkIn,
      'checkOut': checkOut,
      'rooms': rooms
          .map((r) => {
                'adults': r.adults,
                'children': r.children,
                'childAges': r.childAges,
              })
          .toList(),
      'nationality': nationality,
      'countryOfResidence': countryOfResidence,
      'destinationCountryCode': destinationCountryCode,
    };
  }
}

class AkHotelSearchInitModel extends AkHotelSearchInitEntity {
  const AkHotelSearchInitModel({
    required super.success,
    required super.searchId,
    required super.searchTracingKey,
    required super.status,
  });

  factory AkHotelSearchInitModel.fromJson(Map<String, dynamic> json) {
    return AkHotelSearchInitModel(
      success: json['success'] == true,
      searchId: json['searchId']?.toString() ?? '',
      searchTracingKey: json['searchTracingKey']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
