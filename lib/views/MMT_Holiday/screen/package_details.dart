import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../core/resources/app_colours.dart';
import '../models/holiday_package.dart';

class PackageDetailsScreen extends StatelessWidget {
  final HolidayPackage package;

  const PackageDetailsScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: context.hp(35),
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    package.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: context.gapMedium,
                    left: context.wp(4),
                    right: context.wp(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.title,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: context.headlineMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: context.gapXXSmall),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.white,
                              size: context.iconSmall,
                            ),
                            SizedBox(width: context.gapXXSmall),
                            Text(
                              package.location,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: context.bodyMedium,
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: AppColors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.white),
                onPressed: () {},
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price & Rating Row
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
                                fontSize: context.bodyMedium,
                                color: AppColors.textLight,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '₹${package.price}',
                            style: TextStyle(
                              fontSize: context.headlineSmall,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'per person',
                            style: TextStyle(
                              fontSize: context.labelSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.wp(3),
                          vertical: context.hp(1),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: context.iconSmall,
                            ),
                            SizedBox(width: context.gapXXSmall),
                            Text(
                              '${package.rating}',
                              style: TextStyle(
                                fontSize: context.bodyMedium,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.gapLarge),

                  // Highlights
                  Text(
                    'Highlights',
                    style: TextStyle(
                      fontSize: context.titleMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: context.gapSmall),
                  Wrap(
                    spacing: context.gapSmall,
                    runSpacing: context.gapSmall,
                    children: package.highlights.map((highlight) => Chip(
                      label: Text(
                        highlight,
                        style: TextStyle(fontSize: context.labelSmall),
                      ),
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    )).toList(),
                  ),
                  SizedBox(height: context.gapLarge),

                  // Description
                  Text(
                    'About this trip',
                    style: TextStyle(
                      fontSize: context.titleMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: context.gapSmall),
                  Text(
                    package.description,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: context.gapXLarge),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Book Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(4),
          vertical: context.gapMedium,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              // Handle booking
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: context.hp(2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadiusMedium),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Book Now - ₹${package.price}',
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}