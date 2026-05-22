import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';
import '../MMT_reviewDetails/screen/paackage_details_screen.dart';

class RecentlyViewedSection extends StatelessWidget {
  const RecentlyViewedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.gapMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Viewed Packages',
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.gapMedium),
          _buildRecentlyViewedCard(context),
        ],
      ),
    );
  }

  Widget _buildRecentlyViewedCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PackageDetailsScreen(
              packageData: {
                'title': 'Most Wanted Goa Package',
                'duration': '4N / 5D',
                'location': 'Goa',
                'price': 7084,
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(context.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: context.responsivePadding,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Most Wanted Goa Package',
                          // style: TextStyle(
                          //   fontSize: context.labelMedium,
                          //   color: AppColors.textSecondary,
                          // ),
                      style: GoogleFonts.poppins(
                            fontSize: context.titleLarge,
                            fontWeight: FontWeight.w700,
                            // color: AppColors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: context.gapXXSmall),
                        Text(
                          '4N Goa',
                          style: TextStyle(
                            fontSize: context.bodyMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: context.gapXXSmall),
                        Text(
                          '22 Jun 26 • 2 Travellers',
                          style: TextStyle(
                            fontSize: context.labelSmall,
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(height: context.gapSmall),
                        Text(
                          '₹7,084/person',
                          style: TextStyle(
                            fontSize: context.titleMedium,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.gapMedium),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                        child: Image.network(
                          'https://picsum.photos/seed/goa/150/100',
                          width: context.wp(20),
                          height: context.hp(10),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: context.wp(20),
                            height: context.hp(10),
                            color: AppColors.lightBg,
                            child: Icon(
                              Icons.image,
                              color: AppColors.textLight,
                              size: context.iconMedium,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: context.gapXXSmall,
                        right: context.gapXXSmall,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.wp(1.5),
                            vertical: context.hp(0.3),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '4N/5D',
                            style: TextStyle(
                              fontSize: context.labelSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.divider, height: 1),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.gapSmall,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(context.borderRadiusMedium),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: context.iconXSmall,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: context.gapXXSmall),
                      Text(
                        'Viewed by You',
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'VIEW',
                    style: TextStyle(
                      fontSize: context.labelMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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