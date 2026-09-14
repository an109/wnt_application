import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../core/resources/app_colours.dart';

/// Reusable "hotel result" card — image, favourite heart, name, location,
/// price/night and a star row + Book Now button. Figma node 137:1117 reuses
/// this exact card shape for both the "Recently Viewed" and
/// "Luxe - Best Packages" sections, so it's pulled out here instead of being
/// duplicated per-section. Takes the same `{name, location, price, rating,
/// image}` shape already used by [lib/views/NewSection/foryourStay.dart]'s
/// `hotelData` so existing demo entries can be reused as-is.
class HotelListingCard extends StatelessWidget {
  const HotelListingCard({
    super.key,
    required this.hotel,
    this.width,
    this.onTap,
  });

  final Map<String, dynamic> hotel;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? context.w(200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(context.r(14))),
                  child: Image.network(
                    hotel['image'] as String,
                    width: double.infinity,
                    height: context.h(120),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: context.h(120),
                      color: Colors.grey.shade300,
                      child: Icon(Icons.hotel,
                          size: context.iconLarge, color: Colors.grey.shade500),
                    ),
                  ),
                ),
                Positioned(
                  top: context.h(10),
                  right: context.w(10),
                  child: Container(
                    width: context.w(22),
                    height: context.h(22),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/NewIcons/heartHD.png',
                      width: context.w(14),
                      height: context.h(14),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(context.w(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hotel['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/NewIcons/location.svg',
                        width: context.w(11),
                        height: context.w(11),
                      ),
                      SizedBox(width: context.w(4)),
                      Expanded(
                        child: Text(
                          hotel['location'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(11),
                            color: AppColors.subhead,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(6)),
                  Row(
                    children: [
                      Text(
                        '₹${hotel['price']}',
                        style: TextStyle(
                          fontSize: context.fs(13),
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        ' /Night',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          color: AppColors.subhead,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(6)),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          final rating = hotel['rating'] as int? ?? 0;
                          return Padding(
                            padding: EdgeInsets.only(right: context.w(1.5)),
                            child: Image.asset(
                              index < rating
                                  ? 'assets/NewIcons/fillRating.png'
                                  : 'assets/NewIcons/star.png',
                              width: context.fs(9),
                              height: context.fs(9),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(10),
                          vertical: context.h(6),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.OrangeColor,
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                        child: Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: context.fs(10.5),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
