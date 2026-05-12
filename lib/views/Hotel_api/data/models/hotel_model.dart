class HotelModel {
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

  HotelModel({
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

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      hotelCode: json['hotel_code'] ?? '',
      hotelName: json['hotel_name'] ?? '',
      hotelRating: json['hotel_rating'] ?? 0,
      address: json['address'] ?? '',
      cityCode: json['city_code'] ?? '',
      cityName: json['city_name'] ?? '',
      countryCode: json['country_code'] ?? '',
      countryName: json['country_name'] ?? '',
      image: json['image'] ?? '',
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      description: json['description'] ?? '',
      map: json['map'] ?? '',
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : [],
      price: (json['price'] ?? 0).toDouble(),
      totalTax: (json['total_tax'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      originalPrice: (json['original_price'] ?? 0).toDouble(),
      originalTotalTax: (json['original_total_tax'] ?? 0).toDouble(),
      originalCurrency: json['original_currency'] ?? '',
      exchangeRate: json['exchange_rate'],
      roomName: json['room_name'] ?? '',
      bookingCode: json['booking_code'] ?? '',
      isRefundable: json['is_refundable'] ?? false,
      mealType: json['meal_type'] ?? '',
      recommendedSellingRate: (json['recommended_selling_rate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hotel_code': hotelCode,
      'hotel_name': hotelName,
      'hotel_rating': hotelRating,
      'address': address,
      'city_code': cityCode,
      'city_name': cityName,
      'country_code': countryCode,
      'country_name': countryName,
      'image': image,
      'images': images,
      'description': description,
      'map': map,
      'facilities': facilities,
      'price': price,
      'total_tax': totalTax,
      'currency': currency,
      'original_price': originalPrice,
      'original_total_tax': originalTotalTax,
      'original_currency': originalCurrency,
      'exchange_rate': exchangeRate,
      'room_name': roomName,
      'booking_code': bookingCode,
      'is_refundable': isRefundable,
      'meal_type': mealType,
      'recommended_selling_rate': recommendedSellingRate,
    };
  }
}