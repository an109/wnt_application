import 'package:equatable/equatable.dart';

class AkHotelContactInfoEntity extends Equatable {
  final String title;
  final String fName;
  final String lName;
  final String mobile;
  final String email;
  final String address;
  final String state;
  final String city;
  final String pin;
  final String countryCode;
  final String mobileCountryCode;
  final bool isGuest;

  const AkHotelContactInfoEntity({
    required this.title,
    required this.fName,
    required this.lName,
    required this.mobile,
    required this.email,
    this.address = 'NA',
    this.state = 'NA',
    this.city = 'NA',
    this.pin = '000000',
    this.countryCode = 'IN',
    this.mobileCountryCode = '+91',
    required this.isGuest,
  });

  @override
  List<Object?> get props => [title, fName, lName, mobile, email, address, state, city, pin, countryCode, mobileCountryCode, isGuest];
}

class AkHotelGuestEntity extends Equatable {
  final String guestId;
  final String title;
  final String firstName;
  final String lastName;
  /// 'A' (adult) or 'C' (child), per Benzy's GuestCode convention.
  final String paxType;
  final String email;

  const AkHotelGuestEntity({
    required this.guestId,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.paxType,
    required this.email,
  });

  @override
  List<Object?> get props => [guestId, title, firstName, lastName, paxType, email];
}

class AkHotelItineraryRoomEntity extends Equatable {
  final String roomId;
  final String roomGroupId;
  final String supplierName;

  /// `|<occupancyId>|<numAdults>:A:25|` — built by the caller. Benzy's doc
  /// only shows the single-adult-per-room example; multi-adult/child
  /// encoding beyond that isn't documented, so this is best-effort for
  /// anything more complex (flagged where it's built).
  final String guestCode;
  final List<AkHotelGuestEntity> guests;

  const AkHotelItineraryRoomEntity({
    required this.roomId,
    required this.roomGroupId,
    required this.supplierName,
    required this.guestCode,
    required this.guests,
  });

  @override
  List<Object?> get props => [roomId, roomGroupId, supplierName, guestCode, guests];
}

class AkHotelCreateItineraryRequestEntity extends Equatable {
  final String searchId;
  final String searchTracingKey;
  final String hotelCode;
  final String recommendationId;
  final String netAmount;
  /// YYYY-MM-DD — unlike Search Init's MM/DD/YYYY.
  final String checkInDate;
  final String checkOutDate;
  final String travelingFor;
  final AkHotelContactInfoEntity contactInfo;
  final List<AkHotelItineraryRoomEntity> rooms;

  const AkHotelCreateItineraryRequestEntity({
    required this.searchId,
    required this.searchTracingKey,
    required this.hotelCode,
    required this.recommendationId,
    required this.netAmount,
    required this.checkInDate,
    required this.checkOutDate,
    this.travelingFor = 'NTF',
    required this.contactInfo,
    required this.rooms,
  });

  @override
  List<Object?> get props => [
        searchId, searchTracingKey, hotelCode, recommendationId, netAmount,
        checkInDate, checkOutDate, travelingFor, contactInfo, rooms,
      ];
}

class AkHotelCreateItineraryEntity extends Equatable {
  final bool success;
  final String transactionId;
  final double netAmount;
  final String code;

  const AkHotelCreateItineraryEntity({
    required this.success,
    required this.transactionId,
    required this.netAmount,
    required this.code,
  });

  @override
  List<Object?> get props => [success, transactionId, netAmount, code];
}
