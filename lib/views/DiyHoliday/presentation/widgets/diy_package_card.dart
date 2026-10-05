import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../data/diy_features.dart';
import '../../data/models/diy_models.dart';
import 'diy_common.dart';

/// One row of the search results — the package summary returned by
/// **API 3 — GET /packages/**, laid out as the Figma results card.
///
/// Four bands of the design have no data behind them on the live API, so they
/// are built but gated in [DiyFeatures] rather than filled with invented
/// values: the DEAL OF THE DAY ribbon, the wishlist heart, the star rating
/// row, and the "Book this now by paying only …" part-payment line. Everything
/// else is real: the nights badge, destination, the Airport Pickup & Drop chip
/// (from `has_cab_itinerary`), the theme chips, and both prices.
class DiyPackageCard extends StatelessWidget {
  final DiyPackageSummary package;
  final bool withFlight;
  final VoidCallback onTap;
  final VoidCallback? onShare;
  final VoidCallback? onWishlistToggle;
  final bool isWishlisted;

  const DiyPackageCard({
    super.key,
    required this.package,
    required this.withFlight,
    required this.onTap,
    this.onShare,
    this.onWishlistToggle,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    // POST /packages/search/ sends both figures for the fare searched: per
    // adult, and that times the party searched. The GET search sends only the
    // saved party total, so fall back to dividing it — never by zero.
    final saved = package.priceFor(withFlight);
    final perPerson = package.perPerson > 0
        ? package.perPerson
        : (package.adults > 0 ? saved / package.adults : saved);
    final total =
        package.totalForParty > 0 ? package.totalForParty : saved;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: DiyTokens.line), // <-- add this
            borderRadius: BorderRadius.circular(context.r(14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageBand(context),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(12),
                  context.h(10),
                  context.w(12),
                  context.h(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleRow(context),
                    SizedBox(height: context.h(3)),
                    _locationRow(context),
                    SizedBox(height: context.h(6)),
                    _ratingAndNightsRow(context),
                    SizedBox(height: context.h(9)),
                    _featureChips(context),
                    SizedBox(height: context.h(10)),
                    _priceBand(context, total: total, perPerson: perPerson),
                    if (package.priceIsStale) ...[
                      SizedBox(height: context.h(8)),
                      _staleNote(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- image band

  Widget _imageBand(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: ClipRect(
            child: DiyImage(
              url: package.image,
              width: double.infinity,
              height: context.h(150),
              radius: BorderRadius.circular(context.r(10)),
            ),
          ),
        ),
        // Figma: DEAL OF THE DAY ribbon. Needs a `deal { ends_at, label }` on
        // the search row before it can show a real countdown.
        if (DiyFeatures.dealOfTheDay)
          Positioned(
            left: 0,
            top: context.h(10),
            child: _dealRibbon(context),
          )
        else
          Positioned(
            left: context.w(10),
            top: context.h(10),
            child: _badge(
              context,
              '${package.days}D / ${package.nights}N',
              background: Colors.black.withOpacity(0.55),
            ),
          ),
        // Saved with flights: the customer can add them when opening it, priced
        // live from their own city. The price on the card stays land-only.
        if (package.includesFlight && !DiyFeatures.wishlist)
          Positioned(
            right: context.w(10),
            top: context.h(10),
            child: _badge(
              context,
              '✈ Flight option',
              background: DiyTokens.blue.withOpacity(0.92),
            ),
          ),
        // Figma: wishlist heart. Needs a saved/wishlist endpoint.
        if (DiyFeatures.wishlist)
          Positioned(
            right: context.w(10),
            top: context.h(10),
            child: _heartButton(context),
          )
        // else if (package.hasCabItinerary)
        //   Positioned(
        //     right: context.w(10),
        //     top: context.h(10),
        //     child: _badge(
        //       context,
        //       'Cab included',
        //       background: DiyTokens.blue.withOpacity(0.92),
        //     ),
        //   ),
      ],
    );
  }

  Widget _dealRibbon(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE23744),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(context.r(20)),
          bottomRight: Radius.circular(context.r(20)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: context.w(13), color: Colors.white),
          SizedBox(width: context.w(4)),
          Text(
            'DEAL OF THE DAY${package.dealEndsInLabel.isEmpty ? '' : ' • Ends in ${package.dealEndsInLabel}'}',
            style: TextStyle(
              fontSize: context.fs(9.5),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heartButton(BuildContext context) {
    return GestureDetector(
      onTap: onWishlistToggle,
      child: Container(
        width: context.w(28),
        height: context.w(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: context.w(16),
          color: const Color(0xFFE23744),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ body

  Widget _titleRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            package.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(15),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
        ),
        if (onShare != null) ...[
          SizedBox(width: context.w(8)),
          GestureDetector(
            onTap: onShare,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.share_outlined,
              size: context.w(17),
              color: DiyTokens.navy,
            ),
          ),
        ],
      ],
    );
  }

  Widget _locationRow(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: context.w(13),
          color: DiyTokens.subGrey,
        ),
        SizedBox(width: context.w(4)),
        Expanded(
          child: Text(
            package.area.isNotEmpty
                ? package.area
                : '${package.destination} • From ${package.origin}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(11.5),
              color: DiyTokens.subGrey,
            ),
          ),
        ),
      ],
    );
  }

  /// Figma puts the star rating on the left and the nights summary on the
  /// right. Without ratings the row would be a lone right-aligned badge, so
  /// the nights summary simply takes the whole row instead.
  Widget _ratingAndNightsRow(BuildContext context) {
    final nights = Text(
      package.nightsLabel.isNotEmpty
          ? '${package.nightsLabel} (${package.nights}N/${package.days}D)'
          : '${package.nights}N ${package.destination} '
              '(${package.nights}N/${package.days}D)',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: context.fs(11.5),
        fontWeight: FontWeight.w700,
        color: DiyTokens.blue,
      ),
    );

    // The search sends the hotels' guest score but no review count, so the
    // stars show whenever there is a score and the count only when one comes.
    if (!DiyFeatures.ratings && package.rating <= 0) return nights;

    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < package.rating.round()
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: context.w(14),
            color: const Color(0xFFF2B01E),
          ),
        SizedBox(width: context.w(5)),
        Text(
          package.rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: context.fs(11.5),
            fontWeight: FontWeight.w700,
            color: DiyTokens.navy,
          ),
        ),
        if (package.reviewCount > 0) ...[
          SizedBox(width: context.w(3)),
          Text(
            '(${package.reviewCount})',
            style: TextStyle(
              fontSize: context.fs(9),
              color: DiyTokens.labelGrey,
            ),
          ),
        ],
        SizedBox(width: context.w(8)),
        const Spacer(),
        Flexible(child: nights),
      ],
    );
  }

  /// The Figma shows "4 Star Hotel · Selected Meals · Airport Pickup & Drop".
  /// Only the last one is knowable from a search row (`has_cab_itinerary`);
  /// the hotel class and meal plan arrive with the package detail, so they
  /// ride the ratings flag. Theme chips are real and always shown.
  Widget _featureChips(BuildContext context) {
    // POST /packages/search/ sends the chips ready-made, read out of the
    // package's own hotels and transfers. The GET search does not, so the
    // old guesswork stays as the fallback.
    final chips = package.inclusions.isNotEmpty
        ? package.inclusions.take(3).toList()
        : <String>[
            if (package.hotelClassLabel.isNotEmpty) package.hotelClassLabel,
            if (package.mealPlanLabel.isNotEmpty) package.mealPlanLabel,
            if (package.hasCabItinerary) 'Airport Pickup & Drop',
            ...package.themes,
          ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: context.w(6),
      runSpacing: context.h(6),
      children: [
        for (final chip in chips)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(9),
              vertical: context.h(4),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: DiyTokens.line),
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
            child: Text(
              chip,
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w600,
                color: DiyTokens.subGrey,
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------ price band

  Widget _priceBand(
    BuildContext context, {
    required double total,
    required double perPerson,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: DiyFeatures.partPayment
                // Figma: "Book this now by paying only ₹8,411".
                ? Text(
                    'Book this now by paying\nonly ${diyMoney(package.partPaymentAmount, currency: package.currency)}',
                    style: TextStyle(
                      fontSize: context.fs(10.5),
                      color: DiyTokens.subGrey,
                      height: 1.35,
                    ),
                  )
                : Text(
                    withFlight
                        ? 'Price with flight'
                        : package.includesFlight
                            ? 'Without flight · add flights\nwhen you open it'
                            : 'Land package price',
                    style: TextStyle(
                      fontSize: context.fs(10.5),
                      color: DiyTokens.subGrey,
                    ),
                  ),
          ),
          SizedBox(width: context.w(8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: diyMoney(perPerson, currency: package.currency),
                      style: TextStyle(
                        fontSize: context.fs(17),
                        fontWeight: FontWeight.w800,
                        color: AppColors.AppBlue,
                      ),
                    ),
                    TextSpan(
                      text: '/Person',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w600,
                        color: DiyTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(1)),
              Text(
                'Total Price ${diyMoney(total, currency: package.currency)}',
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: DiyTokens.subGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _staleNote(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: context.w(13),
          color: DiyTokens.orange,
        ),
        SizedBox(width: context.w(5)),
        Expanded(
          child: Text(
            'Indicative price — we will reprice it for your dates.',
            style: TextStyle(
              fontSize: context.fs(10),
              color: DiyTokens.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(
    BuildContext context,
    String text, {
    required Color background,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.r(20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(10),
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
