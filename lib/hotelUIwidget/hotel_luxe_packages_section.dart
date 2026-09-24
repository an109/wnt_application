import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../views/ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../views/ExclusiveDeals/presentation/bloc/exclusive_deals_state.dart';
import '../views/ExclusiveDeals/presentation/screen/dealDetails_Screen.dart';
import 'hotel_deal_filter.dart';
import 'hotel_home_card.dart';
import 'hotel_section_heading.dart';

/// "Luxe - Best Packages" section — cards redesigned to match
/// `AkHotelSectionCard` (the "Near by" card style on the Akbar results
/// screen) via the shared [HotelHomeCard].
///
/// Built from the real hotel deals already fetched by the
/// [ExclusiveDealsBloc] that [DealsSection] loads elsewhere on this screen
/// (a `BlocProvider<ExclusiveDealsBloc>` must be an ancestor) — there's no
/// dedicated "Luxe/Best Packages" API, so this reuses that already-loaded
/// data instead of a static demo list. An [ExclusiveDealEntity] has no
/// price/rating fields, so the card only ever shows what's real: image,
/// title, category and (if the deal has one) its discount text as a badge —
/// never a fabricated price or star rating.
class HotelLuxePackagesSection extends StatelessWidget {
  const HotelLuxePackagesSection({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExclusiveDealsBloc, ExclusiveDealsState>(
      builder: (context, state) {
        if (state is! ExclusiveDealsLoaded) return const SizedBox.shrink();

        final deals = hotelCategoryDeals(state.deals);
        if (deals.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HotelSectionHeading(
                title: 'Luxe - Best Packages',
                subtitle: 'Explore your best hotel according to you',
                onViewAll: onViewAll,
              ),
              SizedBox(height: context.h(14)),
              SizedBox(
                // Same row height AkHotelSectionCard's own sections use —
                // this card shares that widget's text-block structure, so
                // it needs the same slack to avoid a RenderFlex overflow.
                height: context.h(240),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: deals.length,
                  separatorBuilder: (_, __) => SizedBox(width: context.w(12)),
                  itemBuilder: (_, index) {
                    final deal = deals[index];
                    return HotelHomeCard(
                      images: [deal.imageUrl],
                      title: deal.title,
                      subtitle: deal.brand.isNotEmpty ? deal.brand : deal.category,
                      subtitleIcon: Icons.local_offer_outlined,
                      badgeText: deal.discountText.isNotEmpty ? deal.discountText : null,
                      width: 170,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DealDetailsScreen(deal: deal)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
