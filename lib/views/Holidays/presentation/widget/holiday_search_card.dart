import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class HolidaysSearchCard extends StatefulWidget {
  const HolidaysSearchCard({super.key});

  @override
  State<HolidaysSearchCard> createState() => _HolidaysSearchCardState();
}

class _HolidaysSearchCardState extends State<HolidaysSearchCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Form fields
  String _fromCity = "Mumbai";
  String _fromCountry = "India";
  String _destination = "";
  DateTime? _departureDate;
  int _rooms = 1;
  int _adults = 2;
  int _children = 0;

  // Filters
  String _budgetRange = "Any";
  String _duration = "Any";
  List<String> _selectedAmenities = [];

  final List<TabItem> _tabs = [
    TabItem(icon: Icons.search, label: "Search", color: Color(0xffFF3B3B)),
    TabItem(icon: Icons.favorite, label: "Honeymoon", color: Color(0xffFF6B6B)),
    TabItem(icon: Icons.flight_takeoff, label: "Visa Free", color: Color(0xff4ECDC4)),
    TabItem(icon: Icons.group, label: "Group Tour", color: Color(0xff45B7D1)),
    TabItem(icon: Icons.family_restroom, label: "Family", color: Color(0xff96CEB4)),
    TabItem(icon: Icons.landscape, label: "Adventure", color: Color(0xffFFEAA7)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xffFF3B3B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _departureDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat("d MMM'yy").format(date);
  }

  String _formatDay(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEEE').format(date);
  }

  void _showGuestSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottom) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(context.gapMedium),
                    child: Text(
                      'Select Rooms & Guests',
                      style: TextStyle(
                        fontSize: context.titleLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.all(context.gapMedium),
                    child: Column(
                      children: [
                        _buildGuestRow(
                          context,
                          "Adults",
                          _adults,
                              (value) {
                            setStateBottom(() => _adults = value);
                            setState(() {});
                          },
                          Icons.person,
                        ),
                        _buildGuestRow(
                          context,
                          "Children",
                          _children,
                              (value) {
                            setStateBottom(() => _children = value);
                            setState(() {});
                          },
                          Icons.child_care,
                        ),
                        _buildGuestRow(
                          context,
                          "Rooms",
                          _rooms,
                              (value) {
                            setStateBottom(() => _rooms = value);
                            setState(() {});
                          },
                          Icons.bed,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(context.gapMedium),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffFF3B3B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Apply",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGuestRow(BuildContext context, String label, int value,
      Function(int) onChanged, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.gapSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xffFF3B3B)),
              SizedBox(width: context.gapSmall),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => onChanged(value > 0 ? value - 1 : 0),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(width: context.gapMedium),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: context.gapMedium),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => onChanged(value + 1),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottom) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(context.gapMedium),
                      child: Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: context.titleLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.all(context.gapMedium),
                      child: Column(
                        children: [
                          _buildFilterSection(
                            context,
                            "Budget Range",
                            _budgetRange,
                            ["Any", "Budget", "Standard", "Premium", "Luxury"],
                                (value) {
                              setStateBottom(() => _budgetRange = value);
                              setState(() {});
                            },
                          ),
                          SizedBox(height: context.gapLarge),
                          _buildFilterSection(
                            context,
                            "Duration",
                            _duration,
                            ["Any", "3-5 Days", "6-8 Days", "9-12 Days", "13+ Days"],
                                (value) {
                              setStateBottom(() => _duration = value);
                              setState(() {});
                            },
                          ),
                          SizedBox(height: context.gapLarge),
                          _buildAmenitiesFilter(context, setStateBottom),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(BuildContext context, String title, String currentValue, List<String> options, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.titleSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.gapSmall),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option),
              selected: currentValue == option,
              onSelected: (selected) {
                if (selected) onChanged(option);
              },
              selectedColor: const Color(0xffFF3B3B).withOpacity(0.2),
              labelStyle: TextStyle(
                color: currentValue == option ? const Color(0xffFF3B3B) : Colors.grey.shade700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilter(BuildContext context, StateSetter setStateBottom) {
    List<String> amenities = ["Free WiFi", "Breakfast", "Pool", "Spa", "Airport Transfer"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: TextStyle(
            fontSize: context.titleSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.gapSmall),
        Wrap(
          spacing: 8,
          children: amenities.map((amenity) {
            return FilterChip(
              label: Text(amenity),
              selected: _selectedAmenities.contains(amenity),
              onSelected: (selected) {
                setStateBottom(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
                setState(() {});
              },
              selectedColor: const Color(0xffFF3B3B).withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedAmenities.contains(amenity) ? const Color(0xffFF3B3B) : Colors.grey.shade700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _onSearchPressed() {
    // Handle search with all selected filters
    print('SEARCH PRESSED');
    print('From: $_fromCity, $_fromCountry');
    print('Destination: $_destination');
    print('Departure Date: $_departureDate');
    print('Guests: $_adults adults, $_children children, $_rooms rooms');
    print('Budget Range: $_budgetRange');
    print('Duration: $_duration');
    print('Amenities: $_selectedAmenities');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search functionality will be implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          /// TABS SECTION
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1.5),
              ),
            ),
            child: SizedBox(
              height: 56,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xffFF3B3B),
                indicatorWeight: 3,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                labelColor: const Color(0xffFF3B3B),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w500,
                ),
                tabs: _tabs.map((tab) {
                  final isSelected = _tabs.indexOf(tab) == _selectedTabIndex;
                  return Tab(
                    icon: Icon(
                      tab.icon,
                      size: 20,
                      color: isSelected ? tab.color : Colors.grey.shade400,
                    ),
                    text: tab.label,
                  );
                }).toList(),
              ),
            ),
          ),

          /// MAIN CONTENT
          Padding(
            padding: EdgeInsets.all(context.gapLarge),
            child: Column(
              children: [
                /// FROM & DESTINATION IN A ROW
                if (context.isMobile)
                  Column(
                    children: [
                      _buildFromField(context),
                      SizedBox(height: context.gapMedium),
                      _buildDestinationField(context),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: _buildFromField(context)),
                      Container(
                        width: 1,
                        height: context.hp(10),
                        color: Colors.grey.shade300,
                      ),
                      Expanded(child: _buildDestinationField(context)),
                    ],
                  ),

                SizedBox(height: context.gapLarge),

                /// DEPARTURE DATE
                _buildDateField(context),

                SizedBox(height: context.gapLarge),

                /// ROOMS & GUESTS + FILTERS + SEARCH BUTTON
                if (context.isMobile)
                  Column(
                    children: [
                      _buildRoomsGuestsField(context),
                      SizedBox(height: context.gapMedium),
                      _buildFilterField(context),
                      SizedBox(height: context.gapMedium),
                      _buildSearchButton(context),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _buildRoomsGuestsField(context)),
                      Container(
                        width: 1,
                        height: context.hp(10),
                        color: Colors.grey.shade300,
                      ),
                      Expanded(child: _buildFilterField(context)),
                      SizedBox(width: context.gapLarge),
                      _buildSearchButton(context),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: context.iconSmall,
              color: const Color(0xffFF3B3B),
            ),
            SizedBox(width: context.gapSmall),
            Text(
              'FROM CITY',
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
          '$_fromCity, $_fromCountry',
          style: TextStyle(
            fontSize: context.titleLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tour,
              size: context.iconSmall,
              color: const Color(0xffFF3B3B),
            ),
            SizedBox(width: context.gapSmall),
            Text(
              'TO CITY / COUNTRY / CATEGORY',
              style: TextStyle(
                fontSize: context.labelMedium,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: context.gapSmall),
        GestureDetector(
          onTap: () {
            // Show destination picker
            showDialog(
              context: context,
              builder: (context) {
                String tempDestination = _destination;
                return AlertDialog(
                  title: const Text('Select Destination'),
                  content: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter destination...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      tempDestination = value;
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF3B3B),
                      ),
                      onPressed: () {
                        setState(() {
                          _destination = tempDestination;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
          child: Text(
            _destination.isEmpty ? 'Select Destination...' : _destination,
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.bold,
              color: _destination.isEmpty ? Colors.grey.shade400 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: context.iconSmall,
                color: const Color(0xffFF3B3B),
              ),
              SizedBox(width: context.gapSmall),
              Text(
                'DEPARTURE DATE',
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
            _formatDate(_departureDate),
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.bold,
              color: _departureDate == null ? Colors.grey.shade400 : Colors.black87,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            _formatDay(_departureDate),
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsGuestsField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people,
              size: context.iconSmall,
              color: const Color(0xffFF3B3B),
            ),
            SizedBox(width: context.gapSmall),
            Text(
              'ROOMS & GUESTS',
              style: TextStyle(
                fontSize: context.labelMedium,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: context.gapSmall),
        GestureDetector(
          onTap: _showGuestSelector,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_rooms Room, $_adults Adults${_children > 0 ? ', $_children Children' : ''}',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to modify',
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_list,
              size: context.iconSmall,
              color: const Color(0xffFF3B3B),
            ),
            SizedBox(width: context.gapSmall),
            Text(
              'FILTERS',
              style: TextStyle(
                fontSize: context.labelMedium,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: context.gapSmall),
        GestureDetector(
          onTap: _showFilterSheet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedAmenities.length + (_budgetRange != "Any" ? 1 : 0) + (_duration != "Any" ? 1 : 0)} Filters Applied',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Budget: $_budgetRange • Duration: $_duration',
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return SizedBox(
      width: context.isMobile ? double.infinity : 200,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffFF3B3B),
          padding: EdgeInsets.symmetric(
            vertical: context.buttonHeight * 0.3,
            horizontal: context.gapLarge,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        onPressed: _onSearchPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SEARCH',
              style: TextStyle(
                fontSize: context.labelLarge,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            SizedBox(width: context.gapSmall),
            const Icon(Icons.search, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class TabItem {
  final IconData icon;
  final String label;
  final Color color;

  TabItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}