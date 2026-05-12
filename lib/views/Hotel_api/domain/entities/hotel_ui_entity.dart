import '../../domain/entities/hotel_entity.dart';

class HotelUiModel {
  final String image;
  final String hotelName;
  final String address;
  final String price;
  final String taxes;
  final int rating;
  final String roomInfo;
  final String description;
  final List<String> images;
  final String currency;
  final double originalPrice;
  final String hotelCode;
  final String bookingCode;
  final bool isRefundable;
  final String mealType;
  final List<String> facilities;
  final String cityName;
  final String countryName;

  HotelUiModel({
    required this.image,
    required this.hotelName,
    required this.address,
    required this.price,
    required this.taxes,
    required this.rating,
    required this.roomInfo,
    required this.description,
    required this.images,
    required this.currency,
    required this.originalPrice,
    required this.hotelCode,
    required this.bookingCode,
    required this.isRefundable,
    required this.mealType,
    required this.facilities,
    required this.cityName,
    required this.countryName,
  });

  factory HotelUiModel.fromEntity(HotelEntity entity) {
    // Format price with currency
    final formattedPrice = entity.currency == 'USD'
        ? '\$${entity.price.toStringAsFixed(2)}'
        : '${entity.currency} ${entity.price.toStringAsFixed(2)}';

    final formattedTax = entity.currency == 'USD'
        ? '\$${entity.totalTax.toStringAsFixed(2)}'
        : '${entity.currency} ${entity.totalTax.toStringAsFixed(2)}';

    return HotelUiModel(
      image: entity.images.isNotEmpty ? entity.images.first : entity.image,
      hotelName: entity.hotelName,
      address: entity.address,
      price: formattedPrice,
      taxes: formattedTax,
      rating: entity.hotelRating,
      roomInfo: entity.roomName,
      description: _stripHtmlTags(entity.description),
      images: entity.images,
      currency: entity.currency,
      originalPrice: entity.originalPrice,
      hotelCode: entity.hotelCode,
      bookingCode: entity.bookingCode,
      isRefundable: entity.isRefundable,
      mealType: entity.mealType,
      facilities: entity.facilities,
      cityName: entity.cityName,
      countryName: entity.countryName,
    );
  }

  // Helper to strip HTML tags from description
  static String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}