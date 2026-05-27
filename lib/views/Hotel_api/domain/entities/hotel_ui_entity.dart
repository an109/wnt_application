import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
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

  // factory HotelUiModel.fromEntity(HotelEntity entity) {
  //   // Format price with currency
  //   final formattedPrice = entity.currency == 'USD'
  //       ? '\$${entity.price.toStringAsFixed(2)}'
  //       : '${entity.currency} ${entity.price.toStringAsFixed(2)}';
  //
  //   final formattedTax = entity.currency == 'USD'
  //       ? '\$${entity.totalTax.toStringAsFixed(2)}'
  //       : '${entity.currency} ${entity.totalTax.toStringAsFixed(2)}';
  //
  //   return HotelUiModel(
  //     image: entity.images.isNotEmpty ? entity.images.first : entity.image,
  //     hotelName: entity.hotelName,
  //     address: entity.address,
  //     price: formattedPrice,
  //     taxes: formattedTax,
  //     rating: entity.hotelRating,
  //     roomInfo: entity.roomName,
  //     description: _stripHtmlTags(entity.description),
  //     images: entity.images,
  //     currency: entity.currency,
  //     originalPrice: entity.originalPrice,
  //     hotelCode: entity.hotelCode,
  //     bookingCode: entity.bookingCode,
  //     isRefundable: entity.isRefundable,
  //     mealType: entity.mealType,
  //     facilities: entity.facilities,
  //     cityName: entity.cityName,
  //     countryName: entity.countryName,
  //   );
  // }
  factory HotelUiModel.fromEntity(HotelEntity entity) {
    // 🔹 MINIMAL CHANGE: Convert price to user's preferred currency
    double priceValue = entity.price;
    double taxValue = entity.totalTax;
    String displayCurrency = entity.currency;

    // Get user's preferred currency (defaults to INR)
    try {
      final prefs = sl<PreferencesManager>();
      final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';

      // Convert if different from API currency
      if (entity.currency.isNotEmpty &&
          entity.currency.toUpperCase() != targetCurrency.toUpperCase()) {

        priceValue = CurrencyConverter.convert(
          amount: entity.price,
          fromCurrency: entity.currency,
          toCurrency: targetCurrency,
        );
        taxValue = CurrencyConverter.convert(
          amount: entity.totalTax,
          fromCurrency: entity.currency,
          toCurrency: targetCurrency,
        );
        displayCurrency = targetCurrency;
      }
    } catch (e) {
      print('HotelUiModel: Currency conversion error: $e');
      // Fallback: use original values
    }

    // Format price with currency symbol based on display currency
    final formattedPrice = _formatPriceWithSymbol(priceValue, displayCurrency);
    final formattedTax = _formatPriceWithSymbol(taxValue, displayCurrency);

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
      currency: displayCurrency, // Use display currency (converted)
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

  // 🔹 NEW HELPER: Format price with currency symbol
  static String _formatPriceWithSymbol(double amount, String currency) {
    final code = currency.toUpperCase();
    final intAmount = amount.toInt();

    if (code == 'INR') {
      return '₹${_formatIndianNumber(intAmount)}';
    } else if (code == 'USD') {
      return '\$${intAmount.toStringAsFixed(0)}';
    } else if (code == 'EUR') {
      return '€${intAmount.toStringAsFixed(0)}';
    } else if (code == 'GBP') {
      return '£${intAmount.toStringAsFixed(0)}';
    } else if (code == 'AED') {
      return 'د.إ ${intAmount.toStringAsFixed(0)}';
    }
    return '$code ${intAmount.toStringAsFixed(0)}';
  }

  // 🔹 REUSE: Indian number formatting (1,00,000 style)
  static String _formatIndianNumber(int num) {
    if (num < 1000) return num.toString();
    final str = num.toString();
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    var formatted = '';
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        formatted += ',';
      }
      formatted += remaining[i];
    }
    return '$formatted,$lastThree';
  }

  // Helper to strip HTML tags from description
  static String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}