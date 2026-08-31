import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/fast_network_image_cache_manager.dart';

class DestinationCard extends StatelessWidget {
  final String image;
  final String country;
  final String type;
  final String price;
  final String processing;
  final VoidCallback? onTap;

  const DestinationCard({
    super.key,
    required this.image,
    required this.country,
    required this.type,
    required this.price,
    required this.processing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1769F6);
    const textDark = Color(0xFF071638);
    const mutedText = Color(0xFF6B7280);
    final cardWidth = context.isMobile ? context.w(188) : context.w(248);
    final imageHeight = context.isMobile ? context.h(132) : context.h(158);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(18)),
          border: Border.all(color: const Color(0xFFE6EAF2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF071638).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// IMAGE SECTION
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(context.r(18)),
                    topRight: Radius.circular(context.r(18)),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    cacheManager: FastNetworkImageCacheManager.instance,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) {
                      return Container(
                        height: imageHeight,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          size: context.iconLarge,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                    placeholder: (context, url) {
                      return Container(
                        height: imageHeight,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryBlue,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// PRICE BADGE - Centered
                Positioned(
                  right: context.w(12),
                  bottom: -context.h(22),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: cardWidth - context.w(28),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(14),
                      vertical: context.h(8),
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(context.r(16)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.24),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Starting from",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.fs(10),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: context.h(1)),
                        Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: context.fs(18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: context.h(30)),

            /// CONTENT SECTION - Center Aligned
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(14),
                0,
                context.w(14),
                context.h(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: context.fs(16),
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Text(
                    type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: context.h(10)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(6),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(context.r(999)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: context.w(13),
                          color: primaryBlue,
                        ),
                        SizedBox(width: context.w(5)),
                        Flexible(
                          child: Text(
                            processing,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(11),
                              color: primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
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
