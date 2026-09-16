import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/fast_network_image_cache_manager.dart';
import '../../../../core/resources/app_colours.dart';

/// Small image carousel with a dot-page indicator, shared by the room
/// selection card and the room-rate details screen. The Rooms API carries
/// no per-room photos, so every caller passes the hotel's own gallery
/// images (from Content) rather than anything room-specific.
class AkHotelImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const AkHotelImageCarousel({
    super.key,
    required this.images,
    required this.height,
    this.borderRadius = BorderRadius.zero,
    this.onTap,
  });

  @override
  State<AkHotelImageCarousel> createState() => _AkHotelImageCarouselState();
}

class _AkHotelImageCarouselState extends State<AkHotelImageCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) {
      return ClipRRect(
        // borderRadius: widget.borderRadius,
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: Icon(Icons.hotel, size: context.w(36), color: Colors.grey.shade400),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: widget.height,
                viewportFraction: 1,
                enableInfiniteScroll: images.length > 1,
                onPageChanged: (i, _) => setState(() => _index = i),
              ),
              items: images
                  .map(
                    (url) => CachedNetworkImage(
                      imageUrl: url,
                      cacheManager: FastNetworkImageCacheManager.instance,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade200,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(color: Colors.grey.shade200),
                    ),
                  )
                  .toList(),
            ),
            if (images.length > 1)
              Padding(
                padding: EdgeInsets.only(bottom: context.h(8)),
                // Above ~8 photos, individual dots would overflow a narrow
                // card regardless of dot size, so switch to a compact
                // "index/total" pill instead of trying to fit them all.
                child: images.length <= 8
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: context.w(5),
                            height: context.w(5),
                            margin: EdgeInsets.symmetric(horizontal: context.w(2)),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _index ? AppColors.AppBlue : Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(context.r(10)),
                        ),
                        child: Text(
                          '${_index + 1}/${images.length}',
                          style: TextStyle(color: Colors.white, fontSize: context.fs(10), fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
            if (widget.onTap != null)
              Positioned(
                right: context.w(8),
                bottom: context.h(8),
                child: Container(
                  width: context.w(24),
                  height: context.w(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward, size: context.w(14), color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
