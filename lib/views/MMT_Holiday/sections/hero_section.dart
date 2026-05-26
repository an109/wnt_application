import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';
import '../data/dummy.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: context.hp(28),
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            viewportFraction: 1.06,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          items: DummyData.heroImages.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: context.gapSmall),
                  decoration: BoxDecoration(
                    // borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: context.responsivePadding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summer Special',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: context.labelMedium,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: context.gapXXSmall),
                            Text(
                              'Up to 40% Off on Hill Stations',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: context.headlineSmall,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        SizedBox(height: context.gapSmall),
        // Carousel Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: DummyData.heroImages.asMap().entries.map((entry) {
            return Container(
              width: context.wp(2),
              height: context.hp(0.8),
              margin: EdgeInsets.symmetric(horizontal: context.gapXXSmall),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentIndex == entry.key
                    ? AppColors.primary
                    : AppColors.divider,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}