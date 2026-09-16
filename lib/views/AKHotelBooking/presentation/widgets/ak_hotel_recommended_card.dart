import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/fast_network_image_cache_manager.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';

/// Wide, landscape card just for the "Recommended Hotel" section — a
/// deliberately different shape from [AkHotelSectionCard] (image on the
/// left, text on the right, a single star + numeric rating instead of a
/// row of stars) to match the Figma reference for this one section. Every
/// value shown still comes straight from the same [HotelUiModel] as every
/// other card.
class AkHotelRecommendedCard extends StatefulWidget {
  final HotelUiModel hotel;
  final VoidCallback? onTap;

  const AkHotelRecommendedCard({super.key, required this.hotel, this.onTap});

  @override
  State<AkHotelRecommendedCard> createState() => _AkHotelRecommendedCardState();
}

class _AkHotelRecommendedCardState extends State<AkHotelRecommendedCard> {
  static const _navy = AppColors.black;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;
  static const _imageSize = 68.0;

  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final imageUrl = hotel.images.isNotEmpty ? hotel.images.first : hotel.image;
    final imageSize = context.w(_imageSize);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: context.w(250),
        padding: EdgeInsets.all(context.w(10)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(14)),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: imageSize,
              height: imageSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(context.r(10)),
                    child: imageUrl.isEmpty
                        ? Container(color: Colors.grey.shade200)
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            cacheManager: FastNetworkImageCacheManager.instance,
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey.shade200,
                              highlightColor: Colors.grey.shade100,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(color: Colors.grey.shade200),
                          ),
                  ),
                  Positioned(
                    top: context.h(4),
                    right: context.w(4),
                    child: GestureDetector(
                      onTap: () => setState(() => _favorite = !_favorite),
                      child: Container(
                        padding: EdgeInsets.all(context.w(4)),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          _favorite ? Icons.favorite : Icons.favorite_border,
                          size: context.w(11),
                          color: _favorite ? const Color(0xFFFF4D4F) : Color(0xFFFF4D4F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: SizedBox(
                height: imageSize,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                hotel.hotelName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: _navy),
                              ),
                            ),
                            if (hotel.rating > 0) ...[
                              SizedBox(width: context.w(4)),
                              Icon(Icons.star_rounded, size: context.w(12), color: Colors.amber),
                              Text(
                                hotel.rating.toDouble().toStringAsFixed(1),
                                style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w700, color: _navy),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: context.h(4)),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: context.w(10), color: _muted),
                            SizedBox(width: context.w(3)),
                            Expanded(
                              child: Text(
                                (hotel.address.isNotEmpty ? hotel.address : hotel.cityName)
                                    .replaceAll(', ', ',\u00A0'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.fs(8),
                                  color: _muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          hotel.price,
                          style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: AppColors.AppBlue),
                        ),
                        SizedBox(width: context.w(3)),
                        Text(
                          '/night',
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
}
