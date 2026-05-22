import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

class PackageBottomBar extends StatelessWidget {
  final int originalPrice;
  final int discountedPrice;
  final int offersCount;
  final VoidCallback onBookNow;

  const PackageBottomBar({
    super.key,
    required this.originalPrice,
    required this.discountedPrice,
    required this.offersCount,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.wp(4),
            vertical: context.gapMedium,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹$originalPrice',
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        color: AppColors.textLight,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹$discountedPrice',
                          style: TextStyle(
                            fontSize: context.headlineSmall,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(width: context.gapXXSmall),
                        Text(
                          'Per person',
                          style: TextStyle(
                            fontSize: context.labelSmall,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Offers Button
              Container(
                margin: EdgeInsets.only(right: context.gapMedium),
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(3),
                  vertical: context.hp(1),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.white),
                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$offersCount Offers',
                      style: TextStyle(
                        fontSize: context.labelMedium,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(width: context.gapXXSmall),
                    Icon(Icons.keyboard_arrow_up, color: AppColors.white, size: context.iconXSmall),
                  ],
                ),
              ),
              // Book Now Button
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(6),
                  vertical: context.hp(2),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4FC3F7),
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                ),
                child: GestureDetector(
                  onTap: onBookNow,
                  child: Text(
                    'BOOK NOW',
                    style: TextStyle(
                      fontSize: context.titleSmall,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}