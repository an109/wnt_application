// lib/features/hotel_details/data/models/hotel_details_model.dart
import '../../domain/entities/hotel_details_entity.dart';

class HotelDetailsModel extends HotelDetailsEntity {
  const HotelDetailsModel({
    required super.hotelCode,
    required super.hotelName,
    required super.description,
    required super.hotelFacilities,
    required super.attractions,
    required super.image,
    required super.images,
    required super.address,
    required super.pinCode,
    required super.cityId,
    required super.countryName,
    required super.phoneNumber,
    required super.email,
    required super.hotelWebsiteUrl,
    required super.faxNumber,
    required super.map,
    required super.hotelRating,
    required super.cityName,
    required super.countryCode,
    required super.checkInTime,
    required super.checkOutTime,
    super.hotelFees,
  });

  factory HotelDetailsModel.fromJson(Map<String, dynamic> json) {
    return HotelDetailsModel(
      hotelCode: json['HotelCode'] ?? '',
      hotelName: json['HotelName'] ?? '',
      description: json['Description'] ?? '',
      hotelFacilities: json['HotelFacilities'] != null
          ? List<String>.from(json['HotelFacilities'])
          : [],
      attractions: json['Attractions'] != null
          ? Map<String, String>.from(json['Attractions'])
          : {},
      image: json['Image'] ?? '',
      images: json['Images'] != null ? List<String>.from(json['Images']) : [],
      address: json['Address'] ?? '',
      pinCode: json['PinCode'] ?? '',
      cityId: json['CityId'] ?? '',
      countryName: json['CountryName'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? '',
      email: json['Email'] ?? '',
      hotelWebsiteUrl: json['HotelWebsiteUrl'] ?? '',
      faxNumber: json['FaxNumber'] ?? '',
      map: json['Map'] ?? '',
      hotelRating: json['HotelRating'] ?? 0,
      cityName: json['CityName'] ?? '',
      countryCode: json['CountryCode'] ?? '',
      checkInTime: json['CheckInTime'] ?? '',
      checkOutTime: json['CheckOutTime'] ?? '',
      hotelFees: json['HotelFees'] != null
          ? HotelFeesModel.fromJson(json['HotelFees'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'HotelCode': hotelCode,
      'HotelName': hotelName,
      'Description': description,
      'HotelFacilities': hotelFacilities,
      'Attractions': attractions,
      'Image': image,
      'Images': images,
      'Address': address,
      'PinCode': pinCode,
      'CityId': cityId,
      'CountryName': countryName,
      'PhoneNumber': phoneNumber,
      'Email': email,
      'HotelWebsiteUrl': hotelWebsiteUrl,
      'FaxNumber': faxNumber,
      'Map': map,
      'HotelRating': hotelRating,
      'CityName': cityName,
      'CountryCode': countryCode,
      'CheckInTime': checkInTime,
      'CheckOutTime': checkOutTime,
      'HotelFees': hotelFees?.toString(),
    };
  }
}

class HotelFeesModel extends HotelFeesEntity {
  const HotelFeesModel({
    required super.hotelId,
    required super.optional,
    required super.mandatory,
  });

  factory HotelFeesModel.fromJson(Map<String, dynamic> json) {
    return HotelFeesModel(
      hotelId: json['HotelId'] ?? '',
      optional: json['Optional'] != null
          ? (json['Optional'] as List)
          .map((fee) => HotelFeeModel.fromJson(fee))
          .toList()
          : [],
      mandatory: json['Mandatory'] != null
          ? (json['Mandatory'] as List)
          .map((fee) => HotelFeeModel.fromJson(fee))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'HotelId': hotelId,
      'Optional': optional.map((fee) => fee.toString()).toList(),
      'Mandatory': mandatory.map((fee) => fee.toString()).toList(),
    };
  }
}

class HotelFeeModel extends HotelFeeEntity {
  const HotelFeeModel({
    required super.feesType,
    required super.feesValue,
    required super.feesCategory,
    required super.currency,
    required super.chargeType,
    required super.feesInclusion,
  });

  factory HotelFeeModel.fromJson(Map<String, dynamic> json) {
    return HotelFeeModel(
      feesType: json['FeesType'] ?? '',
      feesValue: json['FeesValue'] ?? 0,
      feesCategory: json['FeesCategory'] ?? '',
      currency: json['Currency'] ?? '',
      chargeType: json['ChargeType'] ?? '',
      feesInclusion: json['FeesInclusion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FeesType': feesType,
      'FeesValue': feesValue,
      'FeesCategory': feesCategory,
      'Currency': currency,
      'ChargeType': chargeType,
      'FeesInclusion': feesInclusion,
    };
  }
}