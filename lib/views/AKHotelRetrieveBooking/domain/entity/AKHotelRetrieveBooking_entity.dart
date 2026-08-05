import 'package:equatable/equatable.dart';

class AkHotelRetrieveBookingRequestEntity extends Equatable {
  final String referenceNumber;

  const AkHotelRetrieveBookingRequestEntity({required this.referenceNumber});

  @override
  List<Object?> get props => [referenceNumber];
}

class AkHotelBookingGuestEntity extends Equatable {
  final String title;
  final String firstName;
  final String lastName;

  const AkHotelBookingGuestEntity({required this.title, required this.firstName, required this.lastName});

  @override
  List<Object?> get props => [title, firstName, lastName];
}

class AkHotelBookingRoomEntity extends Equatable {
  final String name;
  final List<AkHotelBookingGuestEntity> guests;
  final double totalRate;
  final double baseRate;
  final List<String> cancellationPolicyTexts;

  const AkHotelBookingRoomEntity({
    required this.name,
    required this.guests,
    required this.totalRate,
    required this.baseRate,
    required this.cancellationPolicyTexts,
  });

  @override
  List<Object?> get props => [name, guests, totalRate, baseRate, cancellationPolicyTexts];
}

class AkHotelRetrieveBookingEntity extends Equatable {
  final String transactionId;
  /// e.g. "I8" = awaiting payment, "B0" = confirmed, "CD" = cancelled.
  final String currentStatus;
  final double grossFare;
  final double netFare;
  final String hotelName;
  final int starRating;
  final String city;
  final String country;
  final List<AkHotelBookingRoomEntity> rooms;

  const AkHotelRetrieveBookingEntity({
    required this.transactionId,
    required this.currentStatus,
    required this.grossFare,
    required this.netFare,
    required this.hotelName,
    required this.starRating,
    required this.city,
    required this.country,
    required this.rooms,
  });

  @override
  List<Object?> get props => [
        transactionId, currentStatus, grossFare, netFare, hotelName, starRating, city, country, rooms,
      ];
}
