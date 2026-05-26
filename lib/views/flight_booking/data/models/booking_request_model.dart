class BookingPassengerModel {
  final String title;
  final String firstName;
  final String lastName;
  final int paxType;
  final String dateOfBirth;
  final int gender;
  final String passportNo;
  final String passportExpiry;
  final String addressLine1;
  final String city;
  final String countryCode;
  final String countryName;
  final String nationality;
  final String contactNo;
  final String email;
  final bool isLeadPax;
  final Map<String, dynamic>? fare;
  final List<Map<String, dynamic>> baggage;
  final List<Map<String, dynamic>> mealDynamic;
  final List<Map<String, dynamic>> seatDynamic;

  BookingPassengerModel({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.paxType,
    required this.dateOfBirth,
    required this.gender,
    required this.passportNo,
    required this.passportExpiry,
    this.addressLine1 = 'Test Address',
    this.city = 'Test City',
    this.countryCode = 'IN',
    this.countryName = 'India',
    required this.nationality,
    required this.contactNo,
    required this.email,
    required this.isLeadPax,
    this.fare,
    this.baggage = const [],
    this.mealDynamic = const [],
    this.seatDynamic = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'FirstName': firstName,
      'LastName': lastName,
      'PaxType': paxType,
      'DateOfBirth': dateOfBirth,
      'Gender': gender,
      'PassportNo': passportNo,
      'PassportExpiry': passportExpiry,
      'AddressLine1': addressLine1,
      'City': city,
      'CountryCode': countryCode,
      'CountryName': countryName,
      'Nationality': nationality,
      'ContactNo': contactNo,
      'Email': email,
      'IsLeadPax': isLeadPax,
      if (fare != null) 'Fare': fare,
      'Baggage': baggage,
      'MealDynamic': mealDynamic,
      'SeatDynamic': seatDynamic,
    };
  }
}

class BookingRequestModel {
  final String endUserIp;
  final String traceId;
  final String tokenId;
  final String resultIndex;
  final List<BookingPassengerModel> passengers;

  BookingRequestModel({
    required this.endUserIp,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    required this.passengers,
  });

  Map<String, dynamic> toJson() {
    return {
      'EndUserIp': endUserIp,
      'TraceId': traceId,
      'TokenId': tokenId,
      'ResultIndex': resultIndex,
      'Passengers': passengers.map((p) => p.toJson()).toList(),
    };
  }
}
