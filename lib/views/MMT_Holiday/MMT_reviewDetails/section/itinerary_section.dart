import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

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

  // Only ONE collapse state per section
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
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
              children: [
                _buildTopTabs(),
                SizedBox(height: context.hp(1.4)),
                _buildDateSelector(dates),
                SizedBox(height: context.hp(1.6)),
                _buildDayContent(),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

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
          color: selected ? const Color(0xFF2196F3) : Colors.black12,
          width: selected ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? const Color(0xFF2196F3) : Colors.black87,
        ),
      ),
    );
  }

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
                  right: index == dates.length - 1 ? 0 : context.wp(2),
                ),
                padding: EdgeInsets.symmetric(vertical: context.hp(1)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2196F3) : Colors.black12,
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
                        color: isSelected ? const Color(0xFF2196F3) : Colors.black54,
                      ),
                    ),
                    SizedBox(height: context.hp(0.3)),
                    Text(
                      DateFormat('dd').format(date),
                      style: const TextStyle(
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

  Widget _buildDayContent() {
    return SingleChildScrollView(
      child: Column(
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

          /// FLIGHT SECTION
          _buildFlightSection(),

          /// DIVIDER
          _buildDivider(),

          /// TRANSFER SECTION
          _buildTransferSection(),

          /// DIVIDER
          _buildDivider(),

          /// HOTEL SECTION
          _buildHotelSection(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.hp(1.5)),
      child: Divider(
        color: Colors.grey.shade300,
        thickness: 1,
      ),
    );
  }

  /// FLIGHT SECTION - Only red note collapses
  Widget _buildFlightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header with collapse arrow
        InkWell(
          onTap: () {
            setState(() {
              _isFlightExpanded = !_isFlightExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.hp(0.5)),
            child: Row(
              children: [
                Icon(Icons.flight, size: 20, color: Colors.black54),
                SizedBox(width: context.wp(2)),
                Expanded(
                  child: Text(
                    'Flight',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isFlightExpanded ? 0 : 0.5,
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

        /// Always visible content (Arrival text)
        Padding(
          padding: EdgeInsets.only(left: context.wp(7.2)),
          child: Column(
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
              SizedBox(height: context.hp(0.4)),

              /// ONLY THIS RED NOTE COLLAPSES
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: _isFlightExpanded
                      ? Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13),
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
                    ],
                  )
                      : const SizedBox.shrink(),
                ),
              ),

              /// Always visible transport options (Blue container)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(4),
                  vertical: context.hp(1.5),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
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
          ),
        ),
      ],
    );
  }

  /// TRANSFER SECTION - Only details collapse, subtitle stays
  Widget _buildTransferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header with collapse arrow
        InkWell(
          onTap: () {
            setState(() {
              _isTransferExpanded = !_isTransferExpanded;
            });
          },
          child: Row(
            children: [
              Icon(Icons.directions_car, size: 20, color: Colors.black54),
              SizedBox(width: context.wp(2)),
              Expanded(
                child: Text(
                  'TRANSFER',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: _isTransferExpanded ? 0 : 0.5,
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

        /// Always visible subtitle
        Padding(
          padding: EdgeInsets.only(left: context.wp(7.4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfer From Airport to hotel in Goa',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              // SizedBox(height: context.hp(1.5)),

              /// Collapsible details
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: _isTransferExpanded
                      ? Column(
                    children: [
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
                            'assets/images/car.png',
                            width: context.wp(26),
                            height: context.wp(18),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.directions_car,
                                size: context.wp(18),
                                color: Colors.grey.shade400,
                              );
                            },
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
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// HOTEL SECTION - Only content collapses, subtitle stays
  Widget _buildHotelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header with collapse arrow
        InkWell(
          onTap: () {
            setState(() {
              _isHotelExpanded = !_isHotelExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.hp(0.5)),
            child: Row(
              children: [
                Icon(Icons.apartment, size: 20, color: Colors.black54),
                SizedBox(width: context.wp(2)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      children: const [
                        TextSpan(text: 'RESORT'),
                        TextSpan(
                          text: ' • 4 Nights • In Goa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isHotelExpanded ? 0 : 0.5,
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

        /// Collapsible hotel details
        Padding(
          padding: EdgeInsets.only(left: context.wp(6)),
          child: ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _isHotelExpanded
                  ? Column(
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: context.wp(24),
                              height: context.wp(24),
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.hotel, size: 40),
                            );
                          },
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
                ],
              )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}