import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class SummaryTimelineSection extends StatelessWidget {
  const SummaryTimelineSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TOP TIMELINE
          _timelineRow(
            context,
            icon: Icons.directions_car_filled,
            title: 'Airport to hotel in Goa',
          ),

          SizedBox(height: context.hp(1.2)),

          /// MAIN CARD
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.wp(4)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: Column(
              children: [

                /// HEADER
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.wp(4),
                    vertical: context.hp(1.7),
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4E7C9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Goa ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: context.titleMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '(4 Nights Stay)',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: context.bodyMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// DAYS
                _dayTile(
                  context,
                  day: 'Day 1',
                  date: 'Jun 22, Mon',
                  icon: Icons.apartment,
                  title:
                  'Check in to Sharanam Greens Resort, 3 Star',
                ),

                _dayTile(
                  context,
                  day: 'Day 2',
                  date: 'Jun 23, Tue',
                  icon: Icons.restaurant,
                  title:
                  'Day Meals: Breakfast : Included at Sharanam Greens Resort , Goa',
                ),

                _dayTile(
                  context,
                  day: 'Day 3',
                  date: 'Jun 24, Wed',
                  icon: Icons.restaurant,
                  title:
                  'Day Meals: Breakfast : Included at Sharanam Greens Resort , Goa',
                ),

                _dayTile(
                  context,
                  day: 'Day 4',
                  date: 'Jun 25, Thu',
                  icon: Icons.restaurant,
                  title:
                  'Day Meals: Breakfast : Included at Sharanam Greens Resort , Goa',
                ),

                _dayTile(
                  context,
                  day: 'Day 5',
                  date: 'Jun 26, Fri',
                  icon: Icons.restaurant,
                  title:
                  'Day Meals: Breakfast : Included at Sharanam Greens Resort , Goa',
                  isLast: false,
                ),

                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFE6E6E6),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// LEFT EMPTY
                      Container(
                        width: context.wp(23),
                        padding: EdgeInsets.symmetric(
                          vertical: context.hp(2),
                        ),
                        color: const Color(0xFFF7F7F7),
                      ),

                      /// RIGHT CONTENT
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(context.wp(4)),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.apartment,
                                size: 22,
                              ),

                              SizedBox(width: context.wp(3)),

                              Expanded(
                                child: Text(
                                  'Checkout from Hotel in Goa',
                                  style: TextStyle(
                                    fontSize: context.bodyMedium,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.hp(1.2)),

          /// BOTTOM TIMELINE
          _timelineRow(
            context,
            icon: Icons.directions_car_filled,
            title: 'Hotel in Goa to Airport',
          ),

          SizedBox(height: context.hp(1.6)),
        ],
      ),
    );
  }

  Widget _timelineRow(
      BuildContext context, {
        required IconData icon,
        required String title,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TIMELINE
          Column(
            children: [
              Container(
                width: 2,
                height: 14,
                color: Colors.grey.shade400,
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                ),
              ),
              Container(
                width: 2,
                height: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),

          SizedBox(width: context.wp(3)),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: context.hp(1)),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayTile(
      BuildContext context, {
        required String day,
        required String date,
        required IconData icon,
        required String title,
        bool isLast = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(
            color: Color(0xFFE6E6E6),
          ),
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(
            color: Color(0xFFE6E6E6),
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [

            /// LEFT DAY
            Container(
              width: context.wp(23),
              padding: EdgeInsets.all(context.wp(3)),
              color: const Color(0xFFF7F7F7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: context.hp(0.2)),

                  Text(
                    date,
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            /// RIGHT DETAILS
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(context.wp(4)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                    ),

                    SizedBox(width: context.wp(3)),

                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          height: 1.45,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}