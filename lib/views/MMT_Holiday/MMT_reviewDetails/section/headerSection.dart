import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

class PackageHeaderSection extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final CarouselSliderController carouselController;
  final Function(int) onIndexChanged;

  const PackageHeaderSection({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.carouselController,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          carouselController: carouselController,
          options: CarouselOptions(
            height: context.hp(26),
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              onIndexChanged(index);
            },
          ),
          items: images.map((imageUrl) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: context.gapSmall),
        // Image indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: images.asMap().entries.map((entry) {
            return Container(
              width: context.wp(2),
              height: context.hp(0.8),
              margin: EdgeInsets.symmetric(horizontal: context.gapXXSmall),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: currentIndex == entry.key
                    ? AppColors.primary
                    : AppColors.divider,
              ),
            );
          }).toList(),
        ),
        SizedBox(height: context.gapMedium),
      ],
    );
  }
}