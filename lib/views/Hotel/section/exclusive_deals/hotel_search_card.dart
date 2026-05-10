import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../Listing/hotel_listing.dart';

class HotelSearchCard extends StatelessWidget {
  const HotelSearchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          /// TOP TWO FIELDS
          Row(
            children: [
              Expanded(
                child: _buildField(
                  context,
                  title: "Guest Nationality",
                  value: "India",
                  subtitle: "For rates & pricing",
                  icon: Icons.keyboard_arrow_down,
                ),
              ),

              Container(
                width: 1,
                height: context.hp(12),
                color: Colors.grey.shade300,
              ),

              Expanded(
                child: _buildField(
                  context,
                  title: "Enter Your Destination",
                  value: "Select\nDestination...",
                  icon: Icons.keyboard_arrow_down,
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapLarge),

          /// DATE SECTION
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context,
                  title: "Check-In",
                  date: "9 May'26",
                  day: "Saturday",
                ),
              ),

              SizedBox(width: context.gapMedium),

              Expanded(
                child: _buildDateField(
                  context,
                  title: "Check-Out",
                  date: "10 May'26",
                  day: "Sunday",
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapLarge),

          /// ROOM + BUTTON
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ROOMS & GUESTS",
                      style: TextStyle(
                        fontSize: context.labelMedium,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: context.gapSmall),

                    Text(
                      "1 Room, 1\nGuest",
                      style: TextStyle(
                        fontSize: context.titleLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: context.gapSmall),

                    Text(
                      "Adults & Children",
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: context.gapMedium),

              Expanded(
                child: SizedBox(
                  height: context.buttonHeight + 10,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.borderRadius,
                        ),
                      ),
                    ),
                    onPressed: () {
                      print("SEARCH CLICKED");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HotelListingScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text(
                          "SEARCH",
                          style: TextStyle(
                            fontSize: context.labelLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(width: context.gapSmall),

                        const Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      BuildContext context, {
        required String title,
        required String value,
        String? subtitle,
        IconData? icon,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: context.labelMedium,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (icon != null)
                Icon(
                  icon,
                  size: context.iconMedium,
                  color: Colors.grey.shade600,
                ),
            ],
          ),

          SizedBox(height: context.gapSmall),

          Text(
            value,
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (subtitle != null) ...[
            SizedBox(height: context.gapSmall),

            Text(
              subtitle,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField(
      BuildContext context, {
        required String title,
        required String date,
        required String day,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: context.iconSmall,
              color: Colors.grey.shade600,
            ),

            SizedBox(width: context.gapSmall),

            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: context.labelMedium,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: context.gapSmall),

        Text(
          date,
          style: TextStyle(
            fontSize: context.titleLarge,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: context.gapSmall),

        Text(
          day,
          style: TextStyle(
            fontSize: context.bodySmall,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}