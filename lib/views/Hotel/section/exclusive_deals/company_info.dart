import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';

class CompanyInformationSection extends StatefulWidget {
  const CompanyInformationSection({super.key});

  @override
  State<CompanyInformationSection> createState() =>
      _CompanyInformationSectionState();
}

class _CompanyInformationSectionState
    extends State<CompanyInformationSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedIndex = 0;

  final List<InfoTab> tabs = [
    InfoTab(
      title: "Why WANDER NOVA?",
      content:
      "WANDER NOVA brings unbeatable value with daily flight deals, exclusive discounts, seasonal offers and one of the widest selections of flights, hotels, and holiday packages. Travellers can compare fares across multiple airlines, explore different flights and choose from countless stay options worldwide. Add visa services, sightseeing activities, and travel insurance, browse multiple tour packages – all in one place.",
      icon: Icons.explore_rounded,
    ),
    InfoTab(
      title: "Company Information",
      content:
      "WANDER NOVA is one of the country's leading travel booking platforms, offering a full range of travel services including flight bookings, hotel reservations, visa assistance, holiday packages, travel insurance, and corporate travel solutions.",
      icon: Icons.business_center_rounded,
    ),
    InfoTab(
      title: "Our Mission",
      content:
      "At WANDER NOVA, our mission is to democratize travel by making it accessible, affordable, and enjoyable for everyone. We strive to provide seamless booking experiences, unparalleled customer service, and innovative travel solutions.",
      icon: Icons.rocket_launch_rounded,
    ),
    InfoTab(
      title: "Why Choose Us",
      content:
      "Choose WANDER NOVA for unbeatable prices, 24/7 customer support, instant booking confirmation, flexible cancellation policies, and exclusive member benefits.",
      icon: Icons.star_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = tabs[selectedIndex];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.hp(2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Discover WANDER NOVA",
                  style: TextStyle(
                    fontSize: context.sp(24),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),

                SizedBox(height: context.hp(1)),

                Container(
                  width: context.wp(10),
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: AppColors.chipGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.hp(3)),

          /// TABS
          SizedBox(
            height: context.hp(7),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: context.wp(5)),
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: context.wp(6)),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = selectedIndex  == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });

                    _tabController.animateTo(index);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            tab.icon,
                            size: context.iconMedium,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade500,
                          ),

                          SizedBox(width: context.gapSmall),

                          Text(
                            tab.title,
                            style: TextStyle(
                              fontSize: context.sp(14),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.hp(1)),

                      /// DYNAMIC UNDERLINE
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: 3,
                        width: isSelected
                            ? (tab.title.length * 7).toDouble()
                            : 0,
                        decoration: BoxDecoration(
                          gradient: AppColors.chipGradient,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: context.hp(2.5)),

          /// CONTENT CARD
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildContentCard(context, currentTab),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, InfoTab tab) {
    return Container(
      key: ValueKey(tab.title),

      margin: EdgeInsets.symmetric(horizontal: context.wp(5)),

      padding: EdgeInsets.all(context.wp(5)),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.gapSmall),

                decoration: BoxDecoration(
                  gradient: AppColors.chipGradient,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(
                  tab.icon,
                  color: Colors.white,
                  size: context.iconMedium,
                ),
              ),

              SizedBox(width: context.wp(4)),

              Expanded(
                child: Text(
                  tab.title,
                  style: TextStyle(
                    fontSize: context.sp(18),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.hp(2.2)),

          /// CONTENT TEXT
          Text(
            tab.content,
            style: TextStyle(
              fontSize: context.sp(14),
              height: 1.8,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}

class InfoTab {
  final String title;
  final String content;
  final IconData icon;

  InfoTab({
    required this.title,
    required this.content,
    required this.icon,
  });
}