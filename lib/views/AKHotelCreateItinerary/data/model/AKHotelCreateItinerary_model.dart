import '../../domain/entity/AKHotelCreateItinerary_entity.dart';

class AkHotelCreateItineraryRequestModel extends AkHotelCreateItineraryRequestEntity {
  const AkHotelCreateItineraryRequestModel({
    required super.searchId,
    required super.searchTracingKey,
    required super.hotelCode,
    required super.recommendationId,
    required super.netAmount,
    required super.checkInDate,
    required super.checkOutDate,
    super.travelingFor,
    required super.contactInfo,
    required super.rooms,
  });

  factory AkHotelCreateItineraryRequestModel.fromEntity(AkHotelCreateItineraryRequestEntity e) {
    return AkHotelCreateItineraryRequestModel(
      searchId: e.searchId,
      searchTracingKey: e.searchTracingKey,
      hotelCode: e.hotelCode,
      recommendationId: e.recommendationId,
      netAmount: e.netAmount,
      checkInDate: e.checkInDate,
      checkOutDate: e.checkOutDate,
      travelingFor: e.travelingFor,
      contactInfo: e.contactInfo,
      rooms: e.rooms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SearchId': searchId,
      'search_tracing_key': searchTracingKey,
      'HotelCode': hotelCode,
      'RecommendationId': recommendationId,
      'NetAmount': netAmount,
      'CheckInDate': checkInDate,
      'CheckOutDate': checkOutDate,
      'TravelingFor': travelingFor,
      'ContactInfo': {
        'Title': contactInfo.title,
        'FName': contactInfo.fName,
        'LName': contactInfo.lName,
        'Mobile': contactInfo.mobile,
        'Email': contactInfo.email,
        'Address': contactInfo.address,
        'State': contactInfo.state,
        'City': contactInfo.city,
        'PIN': contactInfo.pin,
        'CountryCode': contactInfo.countryCode,
        'MobileCountryCode': contactInfo.mobileCountryCode,
        'UpdateProfile': false,
        'IsGuest': contactInfo.isGuest,
      },
      'Rooms': rooms
          .map((r) => {
                'RoomId': r.roomId,
                'RoomGroupId': r.roomGroupId,
                'SupplierName': r.supplierName,
                'GuestCode': r.guestCode,
                'Guests': r.guests
                    .map((g) => {
                          'GuestID': g.guestId,
                          'Title': g.title,
                          'FirstName': g.firstName,
                          'LastName': g.lastName,
                          'PaxType': g.paxType,
                          'Email': g.email,
                        })
                    .toList(),
              })
          .toList(),
      'Auxiliaries': [
        {
          'Code': 'PROMO',
          'Parameters': [
            {'Type': 'Code', 'Value': ''},
            {'Type': 'ID', 'Value': ''},
            {'Type': 'Amount', 'Value': ''},
          ],
        },
        {
          'Code': 'CUSTOMER DETAILS',
          'parameters': [
            {'Type': 'Nationality', 'Value': contactInfo.countryCode},
            {'Type': 'Country of Residence', 'Value': contactInfo.countryCode},
          ],
        },
      ],
    };
  }
}

class AkHotelCreateItineraryModel extends AkHotelCreateItineraryEntity {
  const AkHotelCreateItineraryModel({
    required super.success,
    required super.transactionId,
    required super.netAmount,
    required super.code,
  });

  factory AkHotelCreateItineraryModel.fromJson(Map<String, dynamic> json) {
    return AkHotelCreateItineraryModel(
      success: json['success'] == true,
      transactionId: json['TransactionID']?.toString() ?? '',
      netAmount: (json['NetAmount'] as num?)?.toDouble() ?? 0.0,
      code: json['Code']?.toString() ?? '',
    );
  }
}
