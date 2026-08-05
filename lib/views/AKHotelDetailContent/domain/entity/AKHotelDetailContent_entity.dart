import 'package:equatable/equatable.dart';

class AkHotelDetailContentRequestEntity extends Equatable {
  final String searchId;
  final String hotelId;
  final String priceProvider;

  const AkHotelDetailContentRequestEntity({
    required this.searchId,
    required this.hotelId,
    required this.priceProvider,
  });

  @override
  List<Object?> get props => [searchId, hotelId, priceProvider];
}

class AkHotelAttractionEntity extends Equatable {
  final String name;
  final double distance;
  final String unit;

  const AkHotelAttractionEntity({required this.name, required this.distance, required this.unit});

  @override
  List<Object?> get props => [name, distance, unit];
}

class AkHotelDetailContentEntity extends Equatable {
  final String id;
  final String name;
  final double starRating;
  final String addressLine1;
  final String city;
  final String state;
  final String country;
  final List<String> descriptions;
  final List<String> facilities;
  final List<String> images;
  final String heroImage;
  final List<AkHotelAttractionEntity> nearByAttractions;
  final String checkinBeginTime;
  final String checkoutTime;
  final List<String> checkinSpecialInstructions;
  final List<String> policies;
  final double? lat;
  final double? long;

  const AkHotelDetailContentEntity({
    required this.id,
    required this.name,
    required this.starRating,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.country,
    required this.descriptions,
    required this.facilities,
    required this.images,
    required this.heroImage,
    required this.nearByAttractions,
    required this.checkinBeginTime,
    required this.checkoutTime,
    required this.checkinSpecialInstructions,
    required this.policies,
    this.lat,
    this.long,
  });

  @override
  List<Object?> get props => [
        id, name, starRating, addressLine1, city, state, country, descriptions, facilities,
        images, heroImage, nearByAttractions, checkinBeginTime, checkoutTime, checkinSpecialInstructions, policies,
        lat, long,
      ];
}
