import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../UI_helper/responsive_layout.dart';
import '../common_widgets/fast_network_image_cache_manager.dart';
import '../core/resources/app_colours.dart';

/// Shared card for the plain Hotel home screen's "Recently Viewed" and
/// "Luxe - Best Packages" sections — same visual language as
/// `AkHotelSectionCard` (the card used on the Akbar results screen's "Near
/// by" row): a border-only white card, a swipeable photo carousel with a
/// shimmer placeholder, an optional top-left badge, and a text body with a
/// title, subtitle and optional rating/price rows.
///
/// Every value is passed in by the caller — nothing here is hardcoded, so a
/// caller with no real rating/price for its data (e.g. an Exclusive Deal has
/// no room price) simply omits that row instead of showing a fake one.
class HotelHomeCard extends StatefulWidget {
  final List<String> images;
  final String title;
  final String subtitle;
  final IconData subtitleIcon;
  final String? badgeText;
  final String? priceLabel;
  final String priceSuffix;
  final int? starRating;
  final double? reviewRating;
  final int? reviewCount;
  final double? width;
  final VoidCallback? onTap;

  const HotelHomeCard({
    super.key,
    required this.images,
    required this.title,
    required this.subtitle,
    this.subtitleIcon = Icons.location_on,
    this.badgeText,
    this.priceLabel,
    this.priceSuffix = ' /night',
    this.starRating,
    this.reviewRating,
    this.reviewCount,
    this.width = 180,
    this.onTap,
  });

  @override
  State<HotelHomeCard> createState() => _HotelHomeCardState();
}

class _HotelHomeCardState extends State<HotelHomeCard> {
  static const _navy = AppColors.black;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;

  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _hasRating => (widget.starRating ?? 0) > 0 || (widget.reviewCount ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final width = widget.width != null ? context.w(widget.width!) : double.infinity;

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
            // Expanded so the text block fills whatever height the parent's
            // fixed-height horizontal strip gives the card — otherwise the
            // rating/price row doesn't sit flush at the card's bottom edge.
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.w(10), context.h(8), context.w(10), context.h(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w600, color: _navy),
                    ),
                    SizedBox(height: context.h(4)),
                    Row(
                      children: [
                        Icon(widget.subtitleIcon, size: context.w(12), color: _muted),
                        SizedBox(width: context.w(3)),
                        Expanded(
                          child: Text(
                            widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: context.fs(11), color: _muted, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    // Pushes the rating/price rows to the bottom edge
                    // regardless of how much text sits above them.
                    const Spacer(),
                    if (_hasRating) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((widget.starRating ?? 0) > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                widget.starRating!.clamp(0, 5),
                                (_) => Icon(Icons.star_rounded, size: context.w(11), color: Colors.amber),
                              ),
                            ),
                          if ((widget.reviewCount ?? 0) > 0) ...[
                            SizedBox(width: context.w(3)),
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: (widget.reviewRating ?? 0).toStringAsFixed(1),
                                      style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w800, color: _navy),
                                    ),
                                    TextSpan(
                                      text: ' (${widget.reviewCount})',
                                      style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.w500, color: _muted),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: context.h(3)),
                    ],
                    if (widget.priceLabel != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              widget.priceLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w900, color: AppColors.AppBlue),
                            ),
                          ),
                          Text(
                            widget.priceSuffix,
                            style: TextStyle(fontSize: context.fs(6), color: _muted, fontWeight: FontWeight.w600),
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
    final images = widget.images;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
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
            if ((widget.badgeText ?? '').isNotEmpty)
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
                    widget.badgeText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(9.5), fontWeight: FontWeight.w800, color: AppColors.AppBlue),
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

/// Shimmering placeholder shaped like [HotelHomeCard], for a "loading" strip
/// while real data is still being fetched — never a substitute for real data.
class HotelHomeCardSkeleton extends StatelessWidget {
  final double width;

  const HotelHomeCardSkeleton({super.key, this.width = 180});

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
                aspectRatio: 1.6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
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
