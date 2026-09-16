import '../../../../UI_helper/currency_converter.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';

/// Same client-side filtering [_AkHotelResultsScreenState] always applied
/// (min/max price, star rating, amenities, refundable, meal type), pulled
/// out to a standalone function so [AkHotelViewAllScreen] can layer its own
/// local filter drawer on top of an already-filtered section snapshot
/// without duplicating (and risking drifting from) this logic.
List<HotelUiModel> applyAkHotelClientFilters(
  List<HotelUiModel> hotels,
  Map<String, dynamic> filters,
) {
  var result = hotels;
  final f = filters;

  final minPrice = f['min_price'];
  final maxPrice = f['max_price'];
  final starRating = f['star_rating'];
  final amenities = f['amenities'];
  final refundableOnly = f['Refundable'] == true;
  final mealType = f['MealType'];

  // HotelFilterDrawer always sends min_price/max_price in INR, but
  // h.numericPrice is already converted to the user's preferred currency —
  // convert the bounds to match before comparing, otherwise filtering
  // silently breaks for any non-INR currency.
  final currentCurrency = CurrencyConverter.getPreferredCurrency();
  if (minPrice != null) {
    final minPriceConverted = CurrencyConverter.convert(
      amount: (minPrice as num).toDouble(),
      fromCurrency: 'INR',
      toCurrency: currentCurrency,
    );
    result = result.where((h) => h.numericPrice >= minPriceConverted).toList();
  }
  if (maxPrice != null) {
    final maxPriceConverted = CurrencyConverter.convert(
      amount: (maxPrice as num).toDouble(),
      fromCurrency: 'INR',
      toCurrency: currentCurrency,
    );
    result = result.where((h) => h.numericPrice <= maxPriceConverted).toList();
  }
  if (starRating != null) {
    result = result.where((h) => h.rating == (starRating as num).toInt()).toList();
  }
  if (amenities != null && (amenities as List).isNotEmpty) {
    final required = amenities.map((a) => a.toString().toLowerCase()).toList();
    result = result.where((h) {
      final facilityText = h.facilities.join(' ').toLowerCase();
      return required.every((a) => facilityText.contains(a));
    }).toList();
  }
  if (refundableOnly) {
    result = result.where((h) => h.isRefundable).toList();
  }
  if (mealType != null && mealType != 'All') {
    result = result
        .where((h) => h.mealType.toLowerCase().contains(mealType.toString().toLowerCase()))
        .toList();
  }

  // From AkHotelFilterScreen's "Search for locality / hotel name" box.
  final searchQuery = (f['search_query'] as String?)?.trim().toLowerCase();
  if (searchQuery != null && searchQuery.isNotEmpty) {
    result = result
        .where((h) =>
            h.hotelName.toLowerCase().contains(searchQuery) ||
            h.address.toLowerCase().contains(searchQuery))
        .toList();
  }

  return result;
}
