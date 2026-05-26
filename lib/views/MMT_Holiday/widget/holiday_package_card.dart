import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';
import '../models/holiday_package.dart';

class HolidayPackageCard extends StatelessWidget {
  final HolidayPackage package;
  final VoidCallback? onTap;

  const HolidayPackageCard({
    super.key,
    required this.package,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.only(bottom: context.gapMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(context.borderRadiusMedium),
                  ),
                  child: Image.network(
                    package.imageUrl,
                    height: context.hp(25),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: context.hp(25),
                      color: AppColors.lightBg,
                      child: Icon(
                        Icons.image_not_supported,
                        size: context.iconLarge,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
                // Rating Badge
                Positioned(
                  top: context.gapSmall,
                  right: context.gapSmall,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.wp(2),
                      vertical: context.hp(0.5),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: context.iconXSmall,
                        ),
                        SizedBox(width: context.gapXXSmall),
                        Text(
                          package.rating.toString(),
                          style: TextStyle(
                            fontSize: context.labelSmall,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Discount Badge
                if (package.discount != null)
                  Positioned(
                    top: context.gapSmall,
                    left: context.gapSmall,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(2),
                        vertical: context.hp(0.5),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${package.discount}% OFF',
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content Section
            Padding(
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.title,
                    style: TextStyle(
                      fontSize: context.titleMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.gapXXSmall),
                  Text(
                    package.location,
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: context.gapSmall),

                  // Duration & People
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: context.iconXSmall,
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: context.gapXXSmall),
                      Text(
                        '${package.duration} Days',
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: context.gapMedium),
                      Icon(
                        Icons.people,
                        size: context.iconXSmall,
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: context.gapXXSmall),
                      Text(
                        '${package.maxPeople} People',
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.gapSmall),

                  // Price Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (package.originalPrice != null)
                            Text(
                              '₹${package.originalPrice}',
                              style: TextStyle(
                                fontSize: context.bodySmall,
                                color: AppColors.textLight,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '₹${package.price}',
                            style: TextStyle(
                              fontSize: context.titleLarge,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.wp(4),
                            vertical: context.hp(1),
                          ),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'View',
                          style: TextStyle(
                            fontSize: context.labelMedium,
                            fontWeight: FontWeight.w500,
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