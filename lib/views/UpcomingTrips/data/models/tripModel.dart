

import '../../../../UI_helper/currency_converter.dart';
import '../../domain/entity/upcomingTrip_entity.dart';

class TripItem {
  final String refId;
  final String destination;
  final String type;
  final double price; // Original price from API
  final String originalCurrency; // Currency from API (e.g., "INR")
  final String status;
  final String bookedDate;
  final String applicantCount;
  final String category;
  final int entityId;
  final String onwardDate;
  final String returnDate;

  const TripItem({
    required this.refId,
    required this.destination,
    required this.type,
    required this.price,
    required this.originalCurrency,
    required this.status,
    required this.bookedDate,
    required this.applicantCount,
    required this.category,
    required this.entityId,
    required this.onwardDate,
    required this.returnDate,
  });

  /// Factory to build a TripItem from the API entity
  factory TripItem.fromEntity(UpcomingTripEntity entity) {
    return TripItem(
      refId: 'VISA',
      destination: entity.destination,
      type: entity.visaType,
      price: _parsePrice(entity.total),
      originalCurrency: entity.currency,
      status: _formatStatus(entity.status),
      bookedDate: _formatBookedDate(entity.created),
      applicantCount: entity.numTravellers.toString(),
      category: 'Visa',
      entityId: entity.id,
      onwardDate: entity.onwardDate,
      returnDate: entity.returnDate,
    );
  }

  /// Get the price converted to user's preferred currency
  double getConvertedPrice() {
    final preferredCurrency = CurrencyConverter.getPreferredCurrency();

    // If already in preferred currency, return as-is
    if (originalCurrency.toUpperCase() == preferredCurrency.toUpperCase()) {
      return price;
    }

    // Convert using existing CurrencyConverter.convert method
    return CurrencyConverter.convert(
      amount: price,
      fromCurrency: originalCurrency,
      toCurrency: preferredCurrency,
    );
  }

  /// Get the preferred currency code
  String getPreferredCurrencyCode() {
    return CurrencyConverter.getPreferredCurrency();
  }

  /// Get formatted price with symbol in preferred currency
  String getFormattedPrice() {
    final preferredCurrency = getPreferredCurrencyCode();
    final convertedPrice = getConvertedPrice();
    return CurrencyConverter.format(convertedPrice, preferredCurrency);
  }

  static double _parsePrice(String priceStr) {
    try {
      return double.parse(priceStr.replaceAll(',', '').trim());
    } catch (_) {
      return 0.0;
    }
  }

  static String _formatStatus(String status) {
    if (status.isEmpty) return '';
    return status
        .split('_')
        .map((word) =>
    word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static String _formatBookedDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (_) {
      return isoDate;
    }
  }
}