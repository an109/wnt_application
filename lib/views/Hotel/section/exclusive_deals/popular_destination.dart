import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class HotelPopularDestinationsSection extends StatefulWidget {
  const HotelPopularDestinationsSection({super.key});

  @override
  State<HotelPopularDestinationsSection> createState() =>
      _HotelPopularDestinationsSectionState();
}

class _HotelPopularDestinationsSectionState
    extends State<HotelPopularDestinationsSection> {
  int selectedIndex = 1;

  final List<String> filters = [
    "ALL DESTINATIONS",
    "DOMESTIC",
    "INTERNATIONAL",
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TITLE
          Text(
            "Popular Destinations",
            style: TextStyle(
              fontSize: context.headlineSmall,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: context.gapLarge),

          /// FILTERS
          Wrap(
            spacing: context.gapLarge,
            runSpacing: context.gapMedium,
            children: List.generate(
              filters.length,
                  (index) {
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.only(
                      bottom: context.gapSmall,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? const Color(0xffD62828)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      filters[index],
                      style: TextStyle(
                        fontSize: context.titleMedium,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xffD62828)
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: context.hp(2)),

          /// EMPTY STATE
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.gapLarge),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(
                context.borderRadius,
              ),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                SizedBox(height: context.gapMedium),

                Text(
                  _getEmptyTitle(),
                  style: TextStyle(
                    fontSize: context.titleLarge,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: context.gapMedium),

                Text(
                  _getDescription(),
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    color: Colors.blueGrey,
                    height: 1.6,
                  ),
                ),

                SizedBox(height: context.gapLarge),
              ],
            ),
          ),

          SizedBox(height: context.hp(3)),
        ],
      ),
    );
  }

  String _getEmptyTitle() {
    switch (selectedIndex) {
      case 1:
        return "Domestic destinations coming soon";
      case 2:
        return "International destinations coming soon";
      default:
        return "Popular destinations are not available";
    }
  }

  String _getDescription() {
    switch (selectedIndex) {
      case 1:
        return "Domestic hotel destinations are not configured yet. Add destinations from admin dashboard or connect with API.";

      case 2:
        return "International hotel destinations are not configured yet. Add destinations from admin dashboard or connect with API.";

      default:
        return "Popular hotel destinations are not configured yet. Add them from the reseller dashboard.";
    }
  }

  String _getTag() {
    switch (selectedIndex) {
      case 1:
        return "DOMESTIC";
      case 2:
        return "INTERNATIONAL";
      default:
        return "ALL DESTINATIONS";
    }
  }
}