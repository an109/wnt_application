import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class DestinationCard extends StatelessWidget {
  final String image;
  final String country;
  final String type;
  final String price;
  final String processing;

  const DestinationCard({
    super.key,
    required this.image,
    required this.country,
    required this.type,
    required this.price,
    required this.processing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.isMobile ? context.wp(60) : context.wp(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: context.wp(2.5),
            offset: Offset(0, context.hp(0.5)),
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
                  topLeft: Radius.circular(context.borderRadiusLarge),
                  topRight: Radius.circular(context.borderRadiusLarge),
                ),
                child: Image.network(
                  image,
                  height: context.isMobile ? context.hp(21) : context.hp(18),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: context.isMobile ? context.hp(21) : context.hp(18),
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        size: context.iconLarge,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: context.isMobile ? context.hp(21) : context.hp(18),
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xff21409A),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// PRICE BADGE - Centered
              Positioned(
                bottom: -context.hp(3),
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.wp(5),
                      vertical: context.hp(1),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff21409A),
                      borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "STARTING",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.sp(10),
                            fontWeight: FontWeight.w600,
                            letterSpacing: context.letterSpacingWide,
                          ),
                        ),
                        Text(
                          price,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: context.sp(20),
                          ),
                        ),
                        Text(
                          "ONLY",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.sp(10),
                            fontWeight: FontWeight.w600,
                            letterSpacing: context.letterSpacingWide,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.hp(6)),

          /// CONTENT SECTION - Center Aligned
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  country,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: context.gapXSmall),
                Text(
                  type,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.gapMedium),
                Text(
                  "Processing Time: $processing",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.gapMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}