import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class HolidaysSearchCard extends StatefulWidget {
  const HolidaysSearchCard({super.key});

  @override
  State<HolidaysSearchCard> createState() => _HolidaysSearchCardState();
}

class _HolidaysSearchCardState extends State<HolidaysSearchCard> {
  String _fromCity = "Mumbai";
  String _fromCountry = "India";
  String _destination = "Goa";

  DateTime? _departureDate;

  int _rooms = 1;
  int _adults = 2;
  int _children = 0;

  String _selectedPackageType = "With Flight";
  final List<String> _packageTypes = [
    "With Flight",
    "Without Flight",
    "Group Tour",
    "Honeymoon",
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                  Icon(
                    Icons.person_outline,
                    color: const Color(0xffFF3B3B),
                    size: context.iconMedium,
                  ),
                  SizedBox(width: context.w(8)),
                  Text(
                    "Rooms & Guests",
                    style: TextStyle(
                      fontSize: context.fs(18),
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
                    Divider(height: context.h(16), thickness: 0.5),
                    _buildCounterRow(
                      title: "Children",
                      value: tempChildren,
                      icon: Icons.child_care,
                      onChanged: (val) {
                        setDialogState(() => tempChildren = val);
                      },
                    ),
                    Divider(height: context.h(16), thickness: 0.5),
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
                      fontSize: context.fs(12),
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
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(20),
                      vertical: context.h(10),
                    ),
                  ),
                  child: Text(
                    "APPLY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.fs(12),
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
            Icon(icon, size: context.iconMedium, color: const Color(0xffFF3B3B)),
            SizedBox(width: context.w(12)),
            Text(
              title,
              style: TextStyle(
                fontSize: context.fs(14),
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
                width: context.w(32),
                height: context.w(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.remove,
                  size: context.iconSmall,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            SizedBox(width: context.w(16)),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: context.w(16)),
            GestureDetector(
              onTap: () {
                onChanged(value + 1);
              },
              child: Container(
                width: context.w(32),
                height: context.w(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.add,
                  size: context.iconSmall,
                  color: Colors.grey.shade700,
                ),
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
                  Icon(
                    Icons.filter_list,
                    color: const Color(0xffFF3B3B),
                    size: context.iconMedium,
                  ),
                  SizedBox(width: context.w(8)),
                  Text(
                    "Filters",
                    style: TextStyle(
                      fontSize: context.fs(18),
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
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: context.h(12)),
                    ..._packageTypes.map((packageType) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: context.h(12)),
                        child: Row(
                          children: [
                            SizedBox(
                              width: context.w(20),
                              height: context.w(20),
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
                                  borderRadius: BorderRadius.circular(context.r(4)),
                                ),
                              ),
                            ),
                            SizedBox(width: context.w(12)),
                            Text(
                              packageType,
                              style: TextStyle(
                                fontSize: context.fs(14),
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
                      fontSize: context.fs(12),
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
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(20),
                      vertical: context.h(10),
                    ),
                  ),
                  child: Text(
                    "APPLY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.fs(12),
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
      SnackBar(
        content: Text('Search functionality will be implemented'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(8)),
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
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.w(20),
            spreadRadius: context.w(1),
            offset: Offset(0, context.h(8)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.w(14)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// FROM & TO SECTION
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(8),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(context.r(12)),
                  ),
                  child: Column(
                    children: [
                      _buildLocationRow(
                        label: "FROM",
                        city: _fromCity,
                        country: _fromCountry,
                      ),
                      SizedBox(height: context.h(12)),
                      _buildLocationRow(
                        label: "DESTINATION",
                        city: _destination,
                        country: "Select destination",
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          final temp = _fromCity;
                          _fromCity = _destination;
                          _destination = temp;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(context.w(6)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: context.w(4),
                              offset: Offset(0, context.h(2)),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.swap_vert,
                          color: const Color(0xffFF3B3B),
                          size: context.iconSmall,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: context.h(14)),

            /// DEPARTURE DATE
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(10),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: context.iconSmall,
                      color: const Color(0xffFF3B3B),
                    ),
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DEPARTURE DATE",
                            style: TextStyle(
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                              letterSpacing: context.letterSpacingWider,
                            ),
                          ),
                          SizedBox(height: context.h(2)),
                          Text(
                            _formatDate(_departureDate),
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (_departureDate != null)
                            Text(
                              _formatDay(_departureDate),
                              style: TextStyle(
                                fontSize: context.fs(11),
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: context.iconSmall,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.h(12)),

            /// ROOMS & GUESTS & FILTER
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(6),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
              child: Row(
                children: [
                  /// GUESTS
                  Expanded(
                    child: GestureDetector(
                      onTap: _showGuestSelector,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: context.h(6)),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: context.iconSmall,
                              color: const Color(0xffFF3B3B),
                            ),
                            SizedBox(width: context.w(10)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "GUESTS",
                                    style: TextStyle(
                                      fontSize: context.fs(10),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade600,
                                      letterSpacing: context.letterSpacingWider,
                                    ),
                                  ),
                                  SizedBox(height: context.h(2)),
                                  Text(
                                    "$_adults Adult${_adults > 1 ? 's' : ''}",
                                    style: TextStyle(
                                      fontSize: context.fs(13),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "$_rooms Room${_rooms > 1 ? 's' : ''}",
                                    style: TextStyle(
                                      fontSize: context.fs(11),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: context.iconSmall,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// Vertical Divider
                  Container(
                    width: context.w(1),
                    height: context.h(40),
                    color: Colors.grey.shade300,
                  ),

                  SizedBox(width: context.w(12)),

                  /// FILTER
                  Expanded(
                    child: GestureDetector(
                      onTap: _showFilterSheet,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: context.h(6)),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list_outlined,
                              size: context.iconSmall,
                              color: const Color(0xffFF3B3B),
                            ),
                            SizedBox(width: context.w(10)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "PACKAGE",
                                    style: TextStyle(
                                      fontSize: context.fs(10),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade600,
                                      letterSpacing: context.letterSpacingWider,
                                    ),
                                  ),
                                  SizedBox(height: context.h(2)),
                                  Text(
                                    _selectedPackageType,
                                    style: TextStyle(
                                      fontSize: context.fs(13),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "Package Type",
                                    style: TextStyle(
                                      fontSize: context.fs(11),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: context.iconSmall,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.h(16)),

            /// SEARCH Button
            SizedBox(
              width: double.infinity,
              height: context.h(44),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFF3B3B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
                ),
                onPressed: _onSearchPressed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: context.iconSmall),
                    SizedBox(width: context.w(8)),
                    Text(
                      "Search Holidays",
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        letterSpacing: context.letterSpacingWide,
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

  Widget _buildLocationRow({
    required String label,
    required String city,
    required String country,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: context.letterSpacingWider,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                city,
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              if (country.isNotEmpty)
                Text(
                  country,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
