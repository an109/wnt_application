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

  String _fromCity = "Mumbai";
  String _fromCountry = "India";
  String _destination = "Goa";

  DateTime? _departureDate;

  int _rooms = 1;
  int _adults = 2;
  int _children = 0;

  String _selectedPackageType = "With Flight";
  final List<String> _packageTypes = ["With Flight", "Without Flight", "Group Tour", "Honeymoon"];

  final List<TabItem> _tabs = [
    TabItem(
      icon: Icons.search,
      label: "Search",
      color: const Color(0xffFF3B3B),
    ),
    TabItem(
      icon: Icons.favorite,
      label: "Honeymoon",
      color: const Color(0xffFF6B6B),
    ),
    TabItem(
      icon: Icons.flight_takeoff,
      label: "Visa Free",
      color: const Color(0xff4ECDC4),
    ),
    TabItem(
      icon: Icons.group,
      label: "Group Tour",
      color: const Color(0xff45B7D1),
    ),
    TabItem(
      icon: Icons.family_restroom,
      label: "Family",
      color: const Color(0xff96CEB4),
    ),
    TabItem(
      icon: Icons.landscape,
      label: "Adventure",
      color: const Color(0xffFFEAA7),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );

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
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xffFF3B3B),
              onPrimary: Colors.white,
            ),
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
    return DateFormat("dd MMM").format(date);
  }

  String _formatDay(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEEE').format(date);
  }

  void _showGuestSelector() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        int tempRooms = _rooms;
        int tempAdults = _adults;
        int tempChildren = _children;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.person_outline, color: const Color(0xffFF3B3B), size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Rooms & Guests",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCounterRow(
                      title: "Adults",
                      value: tempAdults,
                      icon: Icons.person,
                      onChanged: (val) {
                        setDialogState(() => tempAdults = val);
                      },
                    ),
                    Divider(height: 16, thickness: 0.5),
                    _buildCounterRow(
                      title: "Children",
                      value: tempChildren,
                      icon: Icons.child_care,
                      onChanged: (val) {
                        setDialogState(() => tempChildren = val);
                      },
                    ),
                    Divider(height: 16, thickness: 0.5),
                    _buildCounterRow(
                      title: "Rooms",
                      value: tempRooms,
                      icon: Icons.bed,
                      onChanged: (val) {
                        setDialogState(() => tempRooms = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    "CANCEL",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _rooms = tempRooms;
                      _adults = tempAdults;
                      _children = tempChildren;
                    });
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF3B3B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    "APPLY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCounterRow({
    required String title,
    required int value,
    required IconData icon,
    required Function(int) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xffFF3B3B)),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (value > 0) {
                  onChanged(value - 1);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(Icons.remove, size: 18, color: Colors.grey.shade700),
              ),
            ),
            SizedBox(width: 16),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                onChanged(value + 1);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(Icons.add, size: 18, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        String tempPackageType = _selectedPackageType;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: const Color(0xffFF3B3B), size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Filters",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Package Type",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._packageTypes.map((packageType) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: tempPackageType == packageType,
                                onChanged: (bool? selected) {
                                  if (selected == true) {
                                    setDialogState(() {
                                      tempPackageType = packageType;
                                    });
                                  }
                                },
                                activeColor: const Color(0xffFF3B3B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              packageType,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    "CANCEL",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPackageType = tempPackageType;
                    });
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF3B3B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    "APPLY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onSearchPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Search functionality will be implemented',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.borderRadiusLarge,
        ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
          ],


      ),
      child: Column(
        children: [
          /// TABS
          Container(
            padding: EdgeInsets.only(left: context.wp(1)),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              height: 52,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                labelPadding: EdgeInsets.symmetric(horizontal: context.wp(2)),
                indicatorColor: const Color(0xffFF3B3B),
                indicatorWeight: 2.5,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: const Color(0xffFF3B3B),
                unselectedLabelColor: Colors.grey.shade600,
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                labelStyle: TextStyle(
                  fontSize: context.bodySmall,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: context.bodySmall,
                  fontWeight: FontWeight.w500,
                ),
                tabs: _tabs.map((tab) {
                  final isSelected = _tabs.indexOf(tab) == _selectedTabIndex;
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 16,
                          color: isSelected ? tab.color : Colors.grey.shade500,
                        ),
                        SizedBox(width: context.gapXSmall),
                        Text(tab.label),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          /// MAIN CONTENT
          Padding(
            padding: EdgeInsets.all(context.wp(3.5)),
            child: Column(
              children: [
                /// FROM LOCATION
                /// FROM & TO SECTION
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(2),
                        vertical: context.hp(0.5),
                      ),


                      child: Column(
                        children: [
                          _buildLocationRow(
                            label: "FROM",
                            city: _fromCity,
                            country: _fromCountry,
                            icon: Icons.location_on_outlined,
                          ),

                          SizedBox(height: context.gapSmall),

                          Divider(
                            color: Colors.grey.shade400,
                            height: 1,
                          ),

                          SizedBox(height: context.gapSmall),

                          _buildLocationRow(
                            label: "DESTINATION",
                            city: _destination,
                            country: "Select destination",
                            icon: Icons.flight_takeoff,
                          ),
                        ],
                      ),
                    ),

                    /// SWAP BUTTON
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            final temp = _fromCity;
                            _fromCity = _destination;
                            _destination = temp;
                          });
                        },

                        child: Container(
                          padding: EdgeInsets.all(context.gapXXSmall),

                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),

                          child: CircleAvatar(
                            radius: context.avatarRadius,
                            backgroundColor: const Color(0xffFF3B3B),

                            child: Icon(
                              Icons.swap_vert,
                              color: Colors.white,
                              size: context.iconSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.gapMedium),

                Divider(
                  color: Colors.grey.shade200,
                  height: context.gapMedium,
                  thickness: 0.5,
                ),

                /// DEPARTURE DATE
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: "DEPARTURE DATE",
                    value: _formatDate(_departureDate),
                    subtitle: _formatDay(_departureDate),
                  ),
                ),

                Divider(
                  color: Colors.grey.shade200,
                  height: context.gapMedium,
                  thickness: 0.5,
                ),

                /// ROOMS & GUESTS

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.wp(3),
                    vertical: context.hp(1.4),
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      context.borderRadiusMedium,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        /// GUESTS
                        Expanded(
                          child: GestureDetector(
                            onTap: _showGuestSelector,

                            child: _buildInfoRow(
                              icon: Icons.person_outline,
                              label: "GUESTS",
                              value:
                              "$_adults Adult${_adults > 1 ? 's' : ''}",
                              subtitle:
                              "$_rooms Room${_rooms > 1 ? 's' : ''}",
                            ),
                          ),
                        ),

                        /// VERTICAL DIVIDER
                        VerticalDivider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                          width: context.wp(6),
                        ),

                        /// FILTER
                        Expanded(
                          child: GestureDetector(
                            onTap: _showFilterSheet,

                            child: _buildInfoRow(
                              icon: Icons.filter_list_outlined,
                              label: "FILTER",
                              value: _selectedPackageType,
                              subtitle: "Package Type",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: context.gapLarge),

                /// SEARCH Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF3B3B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                      ),
                    ),
                    onPressed: _onSearchPressed,
                    icon: Icon(Icons.search, size: 18),
                    label: Text(
                      "Search Holidays",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required String label,
    required String city,
    required String country,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xffFF3B3B)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                city,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              if (country.isNotEmpty)
                Text(
                  country,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xffFF3B3B)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey.shade600),
      ],
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

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
//
// class HolidaysSearchCard extends StatefulWidget {
//   const HolidaysSearchCard({super.key});
//
//   @override
//   State<HolidaysSearchCard> createState() => _HolidaysSearchCardState();
// }
//
// class _HolidaysSearchCardState extends State<HolidaysSearchCard>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//
//   int _selectedTabIndex = 0;
//
//   String _fromCity = "Mumbai";
//   String _fromCountry = "India";
//   String _destination = "Goa";
//
//   DateTime? _departureDate;
//
//   int _rooms = 1;
//   int _adults = 2;
//   int _children = 0;
//
//   String _selectedPackageType = "With Flight";
//   final List<String> _packageTypes = ["With Flight", "Without Flight", "Group Tour", "Honeymoon"];
//
//   final List<TabItem> _tabs = [
//     TabItem(
//       icon: Icons.search,
//       label: "Search",
//       color: const Color(0xffFF3B3B),
//     ),
//     TabItem(
//       icon: Icons.favorite,
//       label: "Honeymoon",
//       color: const Color(0xffFF6B6B),
//     ),
//     TabItem(
//       icon: Icons.flight_takeoff,
//       label: "Visa Free",
//       color: const Color(0xff4ECDC4),
//     ),
//     TabItem(
//       icon: Icons.group,
//       label: "Group Tour",
//       color: const Color(0xff45B7D1),
//     ),
//     TabItem(
//       icon: Icons.family_restroom,
//       label: "Family",
//       color: const Color(0xff96CEB4),
//     ),
//     TabItem(
//       icon: Icons.landscape,
//       label: "Adventure",
//       color: const Color(0xffFFEAA7),
//     ),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//
//     _tabController = TabController(
//       length: _tabs.length,
//       vsync: this,
//     );
//
//     _tabController.addListener(() {
//       setState(() {
//         _selectedTabIndex = _tabController.index;
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _departureDate ?? DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(
//         const Duration(days: 365),
//       ),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xffFF3B3B),
//               onPrimary: Colors.white,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null && mounted) {
//       setState(() {
//         _departureDate = picked;
//       });
//     }
//   }
//
//   String _formatDate(DateTime? date) {
//     if (date == null) return 'Select Date';
//     return DateFormat("dd MMM").format(date);
//   }
//
//   String _formatDay(DateTime? date) {
//     if (date == null) return '';
//     return DateFormat('EEEE').format(date);
//   }
//
//   void _showGuestSelector() {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext dialogContext) {
//         int tempRooms = _rooms;
//         int tempAdults = _adults;
//         int tempChildren = _children;
//
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: Row(
//                 children: [
//                   Icon(Icons.person_outline, color: const Color(0xffFF3B3B), size: context.iconSmall),
//                   SizedBox(width: context.gapXSmall),
//                   Text(
//                     "Rooms & Guests",
//                     style: TextStyle(
//                       fontSize: context.titleMedium,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               content: Container(
//                 width: double.infinity,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     _buildCounterRow(
//                       title: "Adults",
//                       value: tempAdults,
//                       icon: Icons.person,
//                       onChanged: (val) {
//                         setDialogState(() => tempAdults = val);
//                       },
//                     ),
//                     Divider(height: context.gapSmall, thickness: context.dividerThin),
//                     _buildCounterRow(
//                       title: "Children",
//                       value: tempChildren,
//                       icon: Icons.child_care,
//                       onChanged: (val) {
//                         setDialogState(() => tempChildren = val);
//                       },
//                     ),
//                     Divider(height: context.gapSmall, thickness: context.dividerThin),
//                     _buildCounterRow(
//                       title: "Rooms",
//                       value: tempRooms,
//                       icon: Icons.bed,
//                       onChanged: (val) {
//                         setDialogState(() => tempRooms = val);
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(dialogContext);
//                   },
//                   child: Text(
//                     "CANCEL",
//                     style: TextStyle(
//                       fontSize: context.labelMedium,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey.shade600,
//                       letterSpacing: context.letterSpacingWider,
//                     ),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _rooms = tempRooms;
//                       _adults = tempAdults;
//                       _children = tempChildren;
//                     });
//                     Navigator.pop(dialogContext);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xffFF3B3B),
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(context.borderRadiusSmall),
//                     ),
//                     padding: EdgeInsets.symmetric(horizontal: context.wp(5), vertical: context.hp(1.2)),
//                   ),
//                   child: Text(
//                     "APPLY",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: context.labelMedium,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: context.letterSpacingWider,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildCounterRow({
//     required String title,
//     required int value,
//     required IconData icon,
//     required Function(int) onChanged,
//   }) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: context.iconSmall, color: const Color(0xffFF3B3B)),
//             SizedBox(width: context.gapXSmall),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: context.bodyMedium,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//         Row(
//           children: [
//             GestureDetector(
//               onTap: () {
//                 if (value > 0) {
//                   onChanged(value - 1);
//                 }
//               },
//               child: Container(
//                 width: context.iconLarge,
//                 height: context.iconLarge,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: Icon(Icons.remove, size: context.iconSmall, color: Colors.grey.shade700),
//               ),
//             ),
//             SizedBox(width: context.gapMedium),
//             Text(
//               value.toString(),
//               style: TextStyle(
//                 fontSize: context.bodyLarge,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(width: context.gapMedium),
//             GestureDetector(
//               onTap: () {
//                 onChanged(value + 1);
//               },
//               child: Container(
//                 width: context.iconLarge,
//                 height: context.iconLarge,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: Icon(Icons.add, size: context.iconSmall, color: Colors.grey.shade700),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   void _showFilterSheet() {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext dialogContext) {
//         String tempPackageType = _selectedPackageType;
//
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: Row(
//                 children: [
//                   Icon(Icons.filter_list, color: const Color(0xffFF3B3B), size: context.iconSmall),
//                   SizedBox(width: context.gapXSmall),
//                   Text(
//                     "Filters",
//                     style: TextStyle(
//                       fontSize: context.titleMedium,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               content: Container(
//                 width: double.infinity,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Package Type",
//                       style: TextStyle(
//                         fontSize: context.bodyMedium,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     SizedBox(height: context.gapXSmall),
//                     ..._packageTypes.map((packageType) {
//                       return Padding(
//                         padding: EdgeInsets.only(bottom: context.gapXSmall),
//                         child: Row(
//                           children: [
//                             SizedBox(
//                               width: context.radioSize,
//                               height: context.radioSize,
//                               child: Checkbox(
//                                 value: tempPackageType == packageType,
//                                 onChanged: (bool? selected) {
//                                   if (selected == true) {
//                                     setDialogState(() {
//                                       tempPackageType = packageType;
//                                     });
//                                   }
//                                 },
//                                 activeColor: const Color(0xffFF3B3B),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(context.borderRadiusSmall),
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: context.gapXSmall),
//                             Text(
//                               packageType,
//                               style: TextStyle(
//                                 fontSize: context.bodyMedium,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(dialogContext);
//                   },
//                   child: Text(
//                     "CANCEL",
//                     style: TextStyle(
//                       fontSize: context.labelMedium,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey.shade600,
//                       letterSpacing: context.letterSpacingWider,
//                     ),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _selectedPackageType = tempPackageType;
//                     });
//                     Navigator.pop(dialogContext);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xffFF3B3B),
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(context.borderRadiusSmall),
//                     ),
//                     padding: EdgeInsets.symmetric(horizontal: context.wp(5), vertical: context.hp(1.2)),
//                   ),
//                   child: Text(
//                     "APPLY",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: context.labelMedium,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: context.letterSpacingWider,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   void _onSearchPressed() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Search functionality will be implemented',
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(
//           context.borderRadiusLarge,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: context.hp(3.7), // ~30px on 800px
//             spreadRadius: context.hp(0.25), // ~2px on 800px
//             offset: context.shadowOffsetLarge,
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           /// TABS
//           Container(
//             padding: EdgeInsets.only(left: context.wp(1)),
//             decoration: BoxDecoration(
//               border: Border(
//                 bottom: BorderSide(
//                   color: Colors.grey.shade200,
//                   width: context.dividerThin,
//                 ),
//               ),
//             ),
//             child: SizedBox(
//               height: context.hp(6.5), // ~52px on 800px
//               child: TabBar(
//                 controller: _tabController,
//                 isScrollable: true,
//                 tabAlignment: TabAlignment.start,
//                 padding: EdgeInsets.zero,
//                 labelPadding: EdgeInsets.symmetric(horizontal: context.wp(2)),
//                 indicatorColor: const Color(0xffFF3B3B),
//                 indicatorWeight: context.dividerThick,
//                 dividerColor: Colors.transparent,
//                 indicatorSize: TabBarIndicatorSize.label,
//                 labelColor: const Color(0xffFF3B3B),
//                 unselectedLabelColor: Colors.grey.shade600,
//                 overlayColor: MaterialStateProperty.all(Colors.transparent),
//                 labelStyle: TextStyle(
//                   fontSize: context.bodySmall,
//                   fontWeight: FontWeight.w700,
//                 ),
//                 unselectedLabelStyle: TextStyle(
//                   fontSize: context.bodySmall,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 tabs: _tabs.map((tab) {
//                   final isSelected = _tabs.indexOf(tab) == _selectedTabIndex;
//                   return Tab(
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           tab.icon,
//                           size: context.iconSmall,
//                           color: isSelected ? tab.color : Colors.grey.shade500,
//                         ),
//                         SizedBox(width: context.gapXSmall),
//                         Text(tab.label),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//
//           /// MAIN CONTENT
//           Padding(
//             padding: EdgeInsets.all(context.wp(3.5)),
//             child: Column(
//               children: [
//                 /// FROM LOCATION
//                 /// FROM & TO SECTION
//                 Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: context.wp(2),
//                         vertical: context.hp(0.5),
//                       ),
//                       child: Column(
//                         children: [
//                           _buildLocationRow(
//                             label: "FROM",
//                             city: _fromCity,
//                             country: _fromCountry,
//                             icon: Icons.location_on_outlined,
//                           ),
//                           SizedBox(height: context.gapSmall),
//                           Divider(
//                             color: Colors.grey.shade400,
//                             height: context.gapXXSmall,
//                             thickness: context.dividerThin,
//                           ),
//                           SizedBox(height: context.gapSmall),
//                           _buildLocationRow(
//                             label: "DESTINATION",
//                             city: _destination,
//                             country: "Select destination",
//                             icon: Icons.flight_takeoff,
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     /// SWAP BUTTON
//                     Positioned(
//                       right: 0,
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             final temp = _fromCity;
//                             _fromCity = _destination;
//                             _destination = temp;
//                           });
//                         },
//                         child: Container(
//                           padding: EdgeInsets.all(context.gapXXSmall),
//                           decoration: const BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                           ),
//                           child: CircleAvatar(
//                             radius: context.avatarRadius,
//                             backgroundColor: const Color(0xffFF3B3B),
//                             child: Icon(
//                               Icons.swap_vert,
//                               color: Colors.white,
//                               size: context.iconSmall,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 SizedBox(height: context.gapMedium),
//
//                 Divider(
//                   color: Colors.grey.shade200,
//                   height: context.gapMedium,
//                   thickness: context.dividerThin,
//                 ),
//
//                 /// DEPARTURE DATE
//                 GestureDetector(
//                   onTap: () => _selectDate(context),
//                   child: _buildInfoRow(
//                     icon: Icons.calendar_today_outlined,
//                     label: "DEPARTURE DATE",
//                     value: _formatDate(_departureDate),
//                     subtitle: _formatDay(_departureDate),
//                   ),
//                 ),
//
//                 Divider(
//                   color: Colors.grey.shade200,
//                   height: context.gapMedium,
//                   thickness: context.dividerThin,
//                 ),
//
//                 /// ROOMS & GUESTS
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.wp(3),
//                     vertical: context.hp(1.4),
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(
//                       context.borderRadiusMedium,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.03),
//                         blurRadius: context.hp(1.2), // ~10px on 800px
//                         offset: context.shadowOffsetMedium,
//                       ),
//                     ],
//                   ),
//                   child: IntrinsicHeight(
//                     child: Row(
//                       children: [
//                         /// GUESTS
//                         Expanded(
//                           child: GestureDetector(
//                             onTap: _showGuestSelector,
//                             child: _buildInfoRow(
//                               icon: Icons.person_outline,
//                               label: "GUESTS",
//                               value: "$_adults Adult${_adults > 1 ? 's' : ''}",
//                               subtitle: "$_rooms Room${_rooms > 1 ? 's' : ''}",
//                             ),
//                           ),
//                         ),
//
//                         /// VERTICAL DIVIDER
//                         VerticalDivider(
//                           color: Colors.grey.shade400,
//                           thickness: context.dividerThin,
//                           width: context.wp(6),
//                         ),
//
//                         /// FILTER
//                         Expanded(
//                           child: GestureDetector(
//                             onTap: _showFilterSheet,
//                             child: _buildInfoRow(
//                               icon: Icons.filter_list_outlined,
//                               label: "FILTER",
//                               value: _selectedPackageType,
//                               subtitle: "Package Type",
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: context.gapLarge),
//
//                 /// SEARCH Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: context.buttonHeightMedium,
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xffFF3B3B),
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(context.borderRadiusMedium),
//                       ),
//                     ),
//                     onPressed: _onSearchPressed,
//                     icon: Icon(Icons.search, size: context.iconSmall),
//                     label: Text(
//                       "Search Holidays",
//                       style: TextStyle(
//                         fontSize: context.bodyMedium,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: context.letterSpacingWide,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLocationRow({
//     required String label,
//     required String city,
//     required String country,
//     required IconData icon,
//   }) {
//     return Row(
//       children: [
//         Icon(icon, size: context.iconSmall, color: const Color(0xffFF3B3B)),
//         SizedBox(width: context.gapXSmall),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: context.overline,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.grey.shade600,
//                   letterSpacing: context.letterSpacingWider,
//                 ),
//               ),
//               SizedBox(height: context.gapXXSmall),
//               Text(
//                 city,
//                 style: TextStyle(
//                   fontSize: context.bodyLarge,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black87,
//                 ),
//               ),
//               if (country.isNotEmpty)
//                 Text(
//                   country,
//                   style: TextStyle(
//                     fontSize: context.bodySmall,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildInfoRow({
//     required IconData icon,
//     required String label,
//     required String value,
//     required String subtitle,
//   }) {
//     return Row(
//       children: [
//         Icon(icon, size: context.iconSmall, color: const Color(0xffFF3B3B)),
//         SizedBox(width: context.gapXSmall),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: context.overline,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.grey.shade600,
//                   letterSpacing: context.letterSpacingWider,
//                 ),
//               ),
//               SizedBox(height: context.gapXXSmall),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: context.bodyLarge,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black87,
//                 ),
//               ),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: context.bodySmall,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Icon(Icons.keyboard_arrow_down, size: context.iconSmall, color: Colors.grey.shade600),
//       ],
//     );
//   }
// }
//
// class TabItem {
//   final IconData icon;
//   final String label;
//   final Color color;
//
//   TabItem({
//     required this.icon,
//     required this.label,
//     required this.color,
//   });
// }