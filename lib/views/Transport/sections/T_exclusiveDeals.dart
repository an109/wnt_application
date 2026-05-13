import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class TransportExclusiveDealsSection extends StatefulWidget {
  const TransportExclusiveDealsSection({super.key});

  @override
  State<TransportExclusiveDealsSection> createState() =>
      _TransportExclusiveDealsSectionState();
}

class _TransportExclusiveDealsSectionState
    extends State<TransportExclusiveDealsSection> {
  int selectedTab = 1;
  int currentIndex = 0;

  final List<String> tabs = [
    "HOT DEAL",
    "FLIGHT",
    "HOTEL",
    "HOLIDAYS",
  ];

  final List<String> banners = [
    "https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=1200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?q=80&w=1200&auto=format&fit=crop",
  ];

  final CarouselSliderController _carouselController =
  CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            "Exclusive Deals",
            style: TextStyle(
              fontSize: context.headlineSmall,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: context.gapLarge),

          /// TABS
          SizedBox(
            height: context.hp(5),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final isSelected = selectedTab == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTab = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: context.gapLarge),
                    child: Column(
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: context.bodyLarge,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xff005B7F)
                                : Colors.black54,
                          ),
                        ),

                        SizedBox(height: context.gapSmall),

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 3,
                          width: context.wp(17),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xff005B7F)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),

          SizedBox(height: context.gapMedium),

          /// ARROWS + VIEW ALL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildArrowButton(
                    context,
                    icon: Icons.arrow_back_ios_new,
                    onTap: () {
                      _carouselController.previousPage();
                    },
                  ),

                  SizedBox(width: context.gapMedium),

                  _buildArrowButton(
                    context,
                    icon: Icons.arrow_forward_ios,
                    onTap: () {
                      _carouselController.nextPage();
                    },
                  ),
                ],
              ),

              GestureDetector(
                onTap: () {
                  debugPrint("View all clicked");
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff005B7F),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapLarge),

          /// BANNER CAROUSEL
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: banners.length,
            itemBuilder: (context, index, realIndex) {
              return _buildBannerCard(
                context,
                image: banners[index],
              );
            },
            options: CarouselOptions(
              height: context.isMobile
                  ? context.hp(16)
                  : context.hp(22),
              viewportFraction: 1,
              autoPlay: true,
              enlargeCenterPage: false,
              onPageChanged: (index, reason) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
          ),

          SizedBox(height: context.gapMedium),

          /// DOTS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: context.gapSmall / 2,
                ),
                width: currentIndex == index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: currentIndex == index
                      ? const Color(0xff005B7F)
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),

          SizedBox(height: context.gapLarge),
        ],
      ),
    );
  }

  Widget _buildArrowButton(
      BuildContext context, {
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        height: context.hp(5.5),
        width: context.hp(5.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: context.iconMedium,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildBannerCard(
      BuildContext context, {
        required String image,
      }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: context.gapSmall,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          context.borderRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}