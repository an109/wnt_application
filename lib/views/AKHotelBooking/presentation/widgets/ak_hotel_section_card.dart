import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/fast_network_image_cache_manager.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';

/// Small carousel-style hotel card used on [AkHotelResultsScreen]'s
/// horizontal "Near by" / "Recommended Hotel" / "Match" rows and reused
/// (at a wider size) in [AkHotelViewAllScreen]'s 2-column grid — matches the
/// Figma reference's card styling. Every value shown comes from
/// [HotelUiModel] (itself built from live Content+Rate API data upstream);
/// nothing here is hardcoded.
class AkHotelSectionCard extends StatefulWidget {
  final HotelUiModel hotel;
  final VoidCallback? onTap;
  /// Design-pixel width for a horizontal-scroll row card. Leave null when
  /// the card sits inside a grid cell (e.g. [AkHotelViewAllScreen]) so it
  /// fills whatever width that cell already gives it instead of fighting it.
  final double? width;

  const AkHotelSectionCard({
    super.key,
    required this.hotel,
    this.onTap,
    this.width = 180,
  });

  @override
  State<AkHotelSectionCard> createState() => _AkHotelSectionCardState();
}

class _AkHotelSectionCardState extends State<AkHotelSectionCard> {
  static const _navy = AppColors.black;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;

  final PageController _pageController = PageController();
  int _page = 0;
  bool _favorite = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _images {
    final hotel = widget.hotel;
    if (hotel.images.isNotEmpty) return hotel.images;
    if (hotel.image.isNotEmpty) return [hotel.image];
    return const [];
  }

  /// Only ever derived from the hotel's own real originalPrice vs. its
  /// current (already-converted) price — never a fabricated/static number.
  int get _discountPercent {
    final hotel = widget.hotel;
    if (hotel.originalPrice <= 0 || hotel.numericPrice <= 0) return 0;
    if (hotel.originalPrice <= hotel.numericPrice) return 0;
    return (((hotel.originalPrice - hotel.numericPrice) / hotel.originalPrice) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width != null ? context.w(widget.width!) : double.infinity;
    final hotel = widget.hotel;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(14)),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.w(10), context.h(10), context.w(10), 0),
              child: _buildImageArea(context),
            ),
            // Expanded so the text block fills whatever height the parent
            // (the section's fixed-height horizontal strip, or a View All
            // grid cell) actually gives the card — otherwise, with only the
            // image's height fixed, leftover space collects below the text
            // instead of the rating/price row sitting flush at the card's
            // bottom edge.
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.w(10), context.h(8), context.w(10), context.h(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hotel.hotelName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w600,
                              color: _navy,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Share.share(
                            'Check out ${hotel.hotelName}${hotel.address.isNotEmpty ? ' in ${hotel.address}' : ''}!',
                          ),
                          behavior: HitTestBehavior.opaque,
                          child: Icon(Icons.share, size: context.w(15), color: _muted),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(4)),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: context.w(12), color: _muted),
                        SizedBox(width: context.w(3)),
                        Expanded(
                          child: Text(
                            hotel.address.isNotEmpty ? hotel.address : hotel.cityName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: context.fs(11), color: _muted, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    // Pushes the rating/price row all the way down to the
                    // bottom edge, no matter how much (or little) text sits
                    // above it — that row's position stops depending on
                    // content length this way.
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hotel.rating > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              hotel.rating.clamp(0, 5),
                              (_) => Icon(Icons.star_rounded, size: context.w(11), color: Colors.amber),
                            ),
                          ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              hotel.price,
                              style: TextStyle(
                                fontSize: context.fs(14),
                                fontWeight: FontWeight.w900,
                                color: AppColors.AppBlue,
                              ),
                            ),
                            Text(
                              ' /night',
                              style: TextStyle(fontSize: context.fs(6), color: _muted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea(BuildContext context) {
    final images = _images;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      // borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(14))),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            images.isEmpty
                ? _fallbackImage(context)
                : PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) => _NetworkImage(url: images[index]),
                  ),
            if (_discountPercent > 0)
              Positioned(
                top: context.h(8),
                left: context.w(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(2)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(context.r(6)),
                  ),
                  child: Text(
                    '$_discountPercent% OFF',
                    style: TextStyle(
                      fontSize: context.fs(9.5),
                      fontWeight: FontWeight.w800,
                      color: AppColors.AppBlue,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: context.h(6),
              right: context.w(6),
              child: GestureDetector(
                onTap: () => setState(() => _favorite = !_favorite),
                child: Container(
                  padding: EdgeInsets.all(context.w(5)),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(
                    _favorite ? Icons.favorite : Icons.favorite_border,
                    size: context.w(13),
                    color: _favorite ? const Color(0xFFFF4D4F) : Color(0xFFFF4D4F),
                  ),
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: context.h(6),
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (i) => Container(
                      margin: EdgeInsets.symmetric(horizontal: context.w(1.5)),
                      width: context.w(i == _page ? 12 : 5),
                      height: context.h(5),
                      decoration: BoxDecoration(
                        color: i == _page ? Colors.white : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(context.r(4)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.hotel, size: context.iconLarge, color: Colors.grey.shade400),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  final String url;
  const _NetworkImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.hotel, size: context.iconLarge, color: Colors.grey.shade400),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: FastNetworkImageCacheManager.instance,
      fit: BoxFit.cover,
      memCacheWidth: 500,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.hotel, size: context.iconLarge, color: Colors.grey.shade400),
      ),
    );
  }
}

/// Shimmering placeholder shaped like [AkHotelSectionCard], shown in the
/// "Match" slot while [AkHotelResultsScreen] is still hunting a later
/// Content page for the hotel the user actually searched for — so that
/// section isn't just silently missing for however long that takes.
class AkHotelSectionCardSkeleton extends StatelessWidget {
  final double width;

  const AkHotelSectionCardSkeleton({super.key, this.width = 180});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: context.w(width),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(14)),
          border: Border.all(color: const Color(0xFFE2E7F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.w(10), context.h(10), context.w(10), 0),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  decoration:
                      BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(context.r(10))),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.w(10), context.h(8), context.w(10), context.h(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: context.h(11), width: double.infinity, color: Colors.grey.shade300),
                    SizedBox(height: context.h(6)),
                    Container(height: context.h(11), width: context.w(90), color: Colors.grey.shade300),
                    const Spacer(),
                    Container(height: context.h(14), width: context.w(55), color: Colors.grey.shade300),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
