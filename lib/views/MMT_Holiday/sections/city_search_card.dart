import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';

class CitySearchScreen extends StatefulWidget {
  final String title;

  const CitySearchScreen({
    super.key,
    required this.title,
  });

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  final List<String> _cities = [
    'Bangalore',
    'Chennai',
    'Cochin',
    'Hyderabad',
    'Kolkata',
    'Mumbai',
    'New Delhi',
    'Pune',
    'Agartala',
    'Agatti',
    'Ahmedabad',
    'Jaipur',
    'Goa',
  ];

  List<String> filteredCities = [];

  @override
  void initState() {
    super.initState();
    filteredCities = _cities;

    _searchController.addListener(() {
      _filterCities();
    });
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      filteredCities = _cities
          .where(
            (city) =>
            city.toLowerCase().contains(query),
      )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [

            /// SEARCH BAR
            Padding(
              padding: EdgeInsets.all(context.wp(4)),
              child: Container(
                height: context.hp(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7FD),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF90CAF9),
                  ),
                ),
                child: Row(
                  children: [

                    SizedBox(width: context.wp(3)),

                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 30,
                      ),
                    ),

                    SizedBox(width: context.wp(3)),

                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: widget.title,
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: context.titleMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: context.titleMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// CURRENT LOCATION
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(5),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pop(
                    context,
                    'Current Location',
                  );
                },
                child: Row(
                  children: [

                    Icon(
                      Icons.navigation_outlined,
                      size: 28,
                      color: AppColors.textPrimary,
                    ),

                    SizedBox(width: context.wp(4)),

                    Text(
                      'Use Current Location',
                      style: TextStyle(
                        fontSize: context.titleMedium,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.hp(2)),

            Divider(
              color: Colors.grey.shade300,
              height: 1,
            ),

            /// CITY LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredCities.length,
                itemBuilder: (context, index) {
                  final city = filteredCities[index];

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context, city);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(5),
                        vertical: context.hp(2.3),
                      ),
                      child: Row(
                        children: [

                          Icon(
                            Icons.location_on_outlined,
                            size: 32,
                            color: Colors.black87,
                          ),

                          SizedBox(width: context.wp(5)),

                          Text(
                            city,
                            style: TextStyle(
                              fontSize: context.titleMedium,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}