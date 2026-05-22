import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

class ItinerarySection extends StatefulWidget {
  final Map<String, dynamic> packageData;

  const ItinerarySection({
    super.key,
    required this.packageData,
  });

  @override
  State<ItinerarySection> createState() => _ItinerarySectionState();
}

class _ItinerarySectionState extends State<ItinerarySection>
    with TickerProviderStateMixin {
  bool _isExpanded = true;

  int _selectedDay = 0;

  bool _isFlightExpanded = true;
  bool _isTransferExpanded = true;
  bool _isHotelExpanded = true;

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      5,
          (index) => DateTime(2026, 6, 22).add(Duration(days: index)),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.wp(3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Row(
            children: [
              Text(
                'Itinerary',
                style: TextStyle(
                  fontSize: context.titleLarge,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              const Spacer(),

              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: AnimatedRotation(
                  turns: _isExpanded ? 0 : 0.5,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: const Color(0xFF2196F3),
                    size: context.iconMedium,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.hp(0.3)),

          Text(
            'Day Wise Details of your package',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),

          SizedBox(height: context.hp(1.6)),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
              children: [

                /// TOP CHIPS
                _buildTopTabs(),

                SizedBox(height: context.hp(1.4)),

                /// DAYS
                _buildDateSelector(dates),

                SizedBox(height: context.hp(1.6)),

                /// CONTENT
                _buildDayContent(),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// TOP TABS
  Widget _buildTopTabs() {
    return Container(
      padding: EdgeInsets.all(context.wp(2)),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [

          Expanded(child: _buildChip('Day Plan', true)),

          SizedBox(width: context.wp(2)),

          Expanded(child: _buildChip('2 Transfers', false)),

          SizedBox(width: context.wp(2)),

          Expanded(child: _buildChip('1 Hotels', false)),

          SizedBox(width: context.wp(2)),

          Expanded(child: _buildChip('4 Meals', false)),
        ],
      ),
    );
  }

  Widget _buildChip(String text, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: context.hp(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? const Color(0xFF2196F3)
              : Colors.black12,
          width: selected ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? const Color(0xFF2196F3)
              : Colors.black87,
        ),
      ),
    );
  }

  /// DATE SELECTOR
  Widget _buildDateSelector(List<DateTime> dates) {
    return Container(
      padding: EdgeInsets.all(context.wp(2)),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: dates.asMap().entries.map((entry) {
          final index = entry.key;
          final date = entry.value;

          final isSelected = _selectedDay == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(
                  right: index == dates.length - 1
                      ? 0
                      : context.wp(2),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: context.hp(1),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2196F3)
                        : Colors.black12,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : [],
                ),
                child: Column(
                  children: [

                    Text(
                      DateFormat('EEE').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : Colors.black54,
                      ),
                    ),

                    SizedBox(height: context.hp(0.3)),

                    Text(
                      DateFormat('dd').format(date),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// CONTENT
  Widget _buildDayContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(0.7),
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF6B57),
                    Color(0xFFFF856D),
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Day ${_selectedDay + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),

            SizedBox(width: context.wp(3)),

            Expanded(
              child: Text(
                'Includes: Transfer • Hotel',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: context.hp(1.8)),

        /// FLIGHT
        _buildTimelineSection(
          icon: Icons.flight,
          title: 'Flight',
          expanded: _isFlightExpanded,
          onTap: () {
            setState(() {
              _isFlightExpanded = !_isFlightExpanded;
            });
          },
          child: _buildFlightCard(),
        ),

        /// TRANSFER
        _buildTimelineSection(
          icon: Icons.directions_car,
          title: 'TRANSFER',
          expanded: _isTransferExpanded,
          onTap: () {
            setState(() {
              _isTransferExpanded = !_isTransferExpanded;
            });
          },
          child: _buildTransferCard(),
        ),

        /// HOTEL
        _buildTimelineSection(
          icon: Icons.apartment,
          title: 'RESORT • 4 Nights • In Goa',
          expanded: _isHotelExpanded,
          onTap: () {
            setState(() {
              _isHotelExpanded = !_isHotelExpanded;
            });
          },
          child: _buildHotelCard(),
        ),
      ],
    );
  }

  /// TIMELINE
  Widget _buildTimelineSection({
    required IconData icon,
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// LEFT LINE
          Column(
            children: [

              Container(
                width: 2,
                height: 10,
                color: Colors.black26,
              ),

              Icon(
                icon,
                size: 18,
                color: Colors.black54,
              ),

              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.black12,
                ),
              ),
            ],
          ),

          SizedBox(width: context.wp(3)),

          Expanded(
            child: Column(
              children: [

                InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: context.hp(0.6),
                    ),
                    child: Row(
                      children: [

                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        AnimatedRotation(
                          turns: expanded ? 0 : 0.5,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(
                            Icons.keyboard_arrow_up,
                            size: 22,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  child: expanded
                      ? child
                      : const SizedBox.shrink(),
                ),

                SizedBox(height: context.hp(1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// FLIGHT
  Widget _buildFlightCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          'Arrival in Goa',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: context.hp(0.8)),

        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 13,
            ),
            children: [
              TextSpan(
                text: 'Please Note : ',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'You need to reach Goa on your own',
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: context.hp(1.5)),

        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.wp(4),
            vertical: context.hp(1.5),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F7FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'There are more ways to reach your destination',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 3),

              const Text(
                'VIEW TRANSPORT OPTION(S)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// TRANSFER
  Widget _buildTransferCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          'Transfer From Airport to hotel in Goa',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),

        SizedBox(height: context.hp(1.5)),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Expanded(
              child: Text(
                'Private Transfer',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),

            Image.asset(
              'assets/car.png',
              width: context.wp(26),
              height: context.wp(18),
              fit: BoxFit.contain,
            ),
          ],
        ),

        SizedBox(height: context.hp(1.2)),

        Row(
          children: [

            const Text(
              'Remove',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1E88E5),
                fontWeight: FontWeight.w600,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                height: 14,
                width: 1,
                color: Colors.black26,
              ),
            ),

            const Text(
              'Change',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1E88E5),
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            const Text(
              'View Details',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1E88E5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// HOTEL
  Widget _buildHotelCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B5ED7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '4.1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      const Text(
                        'Very Good',
                        style: TextStyle(
                          color: Color(0xFF0B5ED7),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Text(
                        '(506 Ratings)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: context.hp(1)),

                  const Text(
                    'Sharanam Greens Resort',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: context.hp(0.8)),

                  Text(
                    'Calangute, 7 minutes walk to Calangute Beach',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: context.wp(3)),

            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                'https://images.unsplash.com/photo-1566073771259-6a8506099945',
                width: context.wp(24),
                height: context.wp(24),
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),

        SizedBox(height: context.hp(1.4)),

        Container(
          padding: EdgeInsets.all(context.wp(3)),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Sharanam Green Resort is appreciated for its prime location near Calangute Beach.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),

        SizedBox(height: context.hp(1.3)),

        Row(
          children: [

            const Text(
              'Change Hotel',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1E88E5),
                fontWeight: FontWeight.w700,
              ),
            ),

            const Spacer(),

            const Text(
              'More Details',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1E88E5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        SizedBox(height: context.hp(1.5)),

        Divider(
          color: Colors.black12,
          thickness: 1,
        ),
      ],
    );
  }
}