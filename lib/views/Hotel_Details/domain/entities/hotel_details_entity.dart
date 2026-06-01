import 'package:equatable/equatable.dart';
import 'package:wander_nova/views/Hotel_Details/domain/entities/rooms_entity.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HotelDetailsEntity extends Equatable {
  final String hotelCode;
  final String hotelName;
  final String description;
  final List<String> hotelFacilities;
  final Map<String, String> attractions;
  final String image;
  final List<String> images;
  final String address;
  final String pinCode;
  final String cityId;
  final String countryName;
  final String phoneNumber;
  final String email;
  final String hotelWebsiteUrl;
  final String faxNumber;
  final String map;
  final int hotelRating;
  final String cityName;
  final String countryCode;
  final String checkInTime;
  final String checkOutTime;
  final HotelFeesEntity? hotelFees;
  final List<RoomEntity> searchRooms;
  final String currency;

  const HotelDetailsEntity({
    required this.hotelCode,
    required this.hotelName,
    required this.description,
    required this.hotelFacilities,
    required this.attractions,
    required this.image,
    required this.images,
    required this.address,
    required this.pinCode,
    required this.cityId,
    required this.countryName,
    required this.phoneNumber,
    required this.email,
    required this.hotelWebsiteUrl,
    required this.faxNumber,
    required this.map,
    required this.hotelRating,
    required this.cityName,
    required this.countryCode,
    required this.checkInTime,
    required this.checkOutTime,
    this.hotelFees,
    required this.searchRooms,
    required this.currency,
  });

  @override
  List<Object?> get props => [
    hotelCode,
    hotelName,
    description,
    hotelFacilities,
    attractions,
    image,
    images,
    address,
    pinCode,
    cityId,
    countryName,
    phoneNumber,
    email,
    hotelWebsiteUrl,
    faxNumber,
    map,
    hotelRating,
    cityName,
    countryCode,
    checkInTime,
    checkOutTime,
    hotelFees,
    searchRooms,
    currency,
  ];
}

class HotelFeesEntity extends Equatable {
  final String hotelId;
  final List<HotelFeeEntity> optional;
  final List<HotelFeeEntity> mandatory;

  const HotelFeesEntity({
    required this.hotelId,
    required this.optional,
    required this.mandatory,
  });

  @override
  List<Object?> get props => [hotelId, optional, mandatory];
}

class HotelFeeEntity extends Equatable {
  final String feesType;
  final num feesValue;
  final String feesCategory;
  final String currency;
  final String chargeType;
  final String feesInclusion;

  const HotelFeeEntity({
    required this.feesType,
    required this.feesValue,
    required this.feesCategory,
    required this.currency,
    required this.chargeType,
    required this.feesInclusion,
  });

  @override
  List<Object?> get props => [
    feesType,
    feesValue,
    feesCategory,
    currency,
    chargeType,
    feesInclusion,
  ];
}

// lib/features/hotel_details/domain/entities/hotel_details_entity.dart
extension HotelDetailsEntityExtension on HotelDetailsEntity {
  LatLng? get hotelLatLng {
    // Your API returns "latitude|longitude" format
    final mapString = map; // e.g., "9.584293|76.422252"
    if (mapString.isEmpty || !mapString.contains('|')) return null;

    try {
      final parts = mapString.split('|');
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());
      return LatLng(lat, lng);
    } catch (e) {
      print('Error parsing map coordinates: $e');
      return null;
    }
  }
}