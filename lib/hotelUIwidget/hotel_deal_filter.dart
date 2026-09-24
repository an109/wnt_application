import '../views/ExclusiveDeals/domain/entities/exclusive_deal_entity.dart';

/// Deals relevant to the Hotel home screen — same "hotel" category/owner-tab
/// match [DealsSection] already uses for its own HOTEL tab, so "Collections"
/// and "Luxe - Best Packages" only ever show real hotel deals, never a
/// flight/holiday banner mislabeled as a hotel.
List<ExclusiveDealEntity> hotelCategoryDeals(List<ExclusiveDealEntity> deals) {
  return deals.where((deal) {
    final category = deal.category.toLowerCase();
    final ownerTab = deal.ownerTab.toLowerCase();
    return (category.contains('hotel') || ownerTab.contains('hotel')) &&
        deal.imageUrl.isNotEmpty;
  }).toList();
}
