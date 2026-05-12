import 'package:equatable/equatable.dart';

class HotelEntity extends Equatable {
  final String hotelCode;
  final String hotelName;
  final int hotelRating;
  final String address;
  final String cityCode;
  final String cityName;
  final String countryCode;
  final String countryName;
  final String image;
  final List<String> images;
  final String description;
  final String map;
  final List<String> facilities;
  final double price;
  final double totalTax;
  final String currency;
  final double originalPrice;
  final double originalTotalTax;
  final String originalCurrency;
  final String? exchangeRate;
  final String roomName;
  final String bookingCode;
  final bool isRefundable;
  final String mealType;
  final double recommendedSellingRate;

  const HotelEntity({
    required this.hotelCode,
    required this.hotelName,
    required this.hotelRating,
    required this.address,
    required this.cityCode,
    required this.cityName,
    required this.countryCode,
    required this.countryName,
    required this.image,
    required this.images,
    required this.description,
    required this.map,
    required this.facilities,
    required this.price,
    required this.totalTax,
    required this.currency,
    required this.originalPrice,
    required this.originalTotalTax,
    required this.originalCurrency,
    this.exchangeRate,
    required this.roomName,
    required this.bookingCode,
    required this.isRefundable,
    required this.mealType,
    required this.recommendedSellingRate,
  });

  factory HotelEntity.fromModel(dynamic model) {
    return HotelEntity(
      hotelCode: model.hotelCode,
      hotelName: model.hotelName,
      hotelRating: model.hotelRating,
      address: model.address,
      cityCode: model.cityCode,
      cityName: model.cityName,
      countryCode: model.countryCode,
      countryName: model.countryName,
      image: model.image,
      images: model.images,
      description: model.description,
      map: model.map,
      facilities: model.facilities,
      price: model.price,
      totalTax: model.totalTax,
      currency: model.currency,
      originalPrice: model.originalPrice,
      originalTotalTax: model.originalTotalTax,
      originalCurrency: model.originalCurrency,
      exchangeRate: model.exchangeRate,
      roomName: model.roomName,
      bookingCode: model.bookingCode,
      isRefundable: model.isRefundable,
      mealType: model.mealType,
      recommendedSellingRate: model.recommendedSellingRate,
    );
  }

  @override
  List<Object?> get props => [
    hotelCode,
    hotelName,
    hotelRating,
    address,
    cityCode,
    cityName,
    countryCode,
    countryName,
    image,
    images,
    description,
    map,
    facilities,
    price,
    totalTax,
    currency,
    originalPrice,
    originalTotalTax,
    originalCurrency,
    exchangeRate,
    roomName,
    bookingCode,
    isRefundable,
    mealType,
    recommendedSellingRate,
  ];
}