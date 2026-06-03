import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../core/resources/app_colours.dart';
import '../screen/destination_package_screen.dart';
import '../sections/city_search_card.dart';
import 'search_field_tile.dart';
import 'filter_chips.dart';

class HolidaySearchCard extends StatefulWidget {
  final bool isCollapsed;
  final Function(String, String, DateTime, int, int)? onSearch;

  const HolidaySearchCard({
    super.key,
    this.isCollapsed = false,
    this.onSearch,
  });

  @override
  State<HolidaySearchCard> createState() => _HolidaySearchCardState();
}

class _HolidaySearchCardState extends State<HolidaySearchCard> {
  String _originCity = 'New Delhi';
  String _destinationCity = 'Goa';
  DateTime _startDate = DateTime(2026, 6, 22);
  int _adults = 2;
  int _rooms = 1;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _selectOrigin() async {
    final selectedCity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CitySearchScreen(
          title: 'Starting From',
        ),
      ),
    );

    if (selectedCity != null) {
      setState(() {
        _originCity = selectedCity;
      });
    }
  }

  String _getRoomGuestSummary() {
    if (_rooms == 1) {
      return '$_adults Adult${_adults > 1 ? 's' : ''}, $_rooms Room';
    }
    return '$_adults Adults, $_rooms Rooms';
  }

  void _selectDestination() async {
    final selectedCity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CitySearchScreen(
          title: 'Travelling To',
        ),
      ),
    );

    if (selectedCity != null) {
      setState(() {
        _destinationCity = selectedCity;
      });
    }
  }


  void _selectRoomAndGuests() {
    // Create local copies for editing
    int localAdults = _adults;
    int localRooms = _rooms;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.borderRadiusLarge)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            margin: EdgeInsets.all(context.gapMedium), // Add margin all around
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(context.borderRadiusLarge), // Make all corners rounded
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: EdgeInsets.only(top: context.gapMedium),
                  width: context.wp(10),
                  height: context.hp(0.5),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.gapMedium,
                    context.gapSmall,
                    context.gapMedium,
                    context.gapXSmall,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: context.bodyMedium,
                          ),
                        ),
                      ),
                      Text(
                        'Rooms & Guests',
                        style: TextStyle(
                          fontSize: context.titleMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _adults = localAdults;
                            _rooms = localRooms;
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: context.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: AppColors.divider, height: 1),

                // Content with padding all around
                Padding(
                  padding: EdgeInsets.all(context.w(12)), // Consistent padding all around
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rooms list
                      ...List.generate(localRooms, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < localRooms - 1 ? context.gapMedium : 0),
                          child: _buildCompactRoomCard(
                            roomNumber: index + 1,
                            isFirstRoom: index == 0,
                            adults: index == 0 ? localAdults : 1,
                            onAdultsChanged: (newAdults) {
                              setModalState(() {
                                if (index == 0) localAdults = newAdults;
                              });
                            },
                            onRemove: localRooms > 1 ? () {
                              setModalState(() {
                                localRooms--;
                              });
                            } : null,
                          ),
                        );
                      }),

                      // Add room button
                      if (localRooms < 5)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(top: context.gapSmall),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setModalState(() {
                                localRooms++;
                              });
                            },
                            icon: Icon(Icons.add, size: context.iconSmall, color: AppColors.primary),
                            label: Text(
                              'Add another room',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: context.bodyMedium,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                              ),
                              padding: EdgeInsets.symmetric(vertical: context.h(8)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: context.gapSmall), // Extra bottom padding
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactRoomCard({
    required int roomNumber,
    required bool isFirstRoom,
    required int adults,
    required Function(int) onAdultsChanged,
    VoidCallback? onRemove,
  }) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Room $roomNumber',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: EdgeInsets.all(context.gapXSmall),
                    child: Icon(
                      Icons.close,
                      size: context.iconSmall,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.gapMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adults',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircleButton(Icons.remove, () {
                    if (adults > 1) onAdultsChanged(adults - 1);
                  }),
                  SizedBox(width: context.gapMedium),
                  Text(
                    adults.toString(),
                    style: TextStyle(
                      fontSize: context.titleMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: context.gapMedium),
                  _buildCircleButton(Icons.add, () => onAdultsChanged(adults + 1), isPrimary: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.wp(7),
        height: context.wp(7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary ? AppColors.primary : Colors.transparent,
          border: isPrimary ? null : Border.all(color: AppColors.divider),
        ),
        child: Icon(
          icon,
          size: context.iconSmall,
          color: isPrimary ? AppColors.white : AppColors.primary,
        ),
      ),
    );
  }

  void _handleSearch() {
    // Navigate to DestinationPackagesScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationPackagesScreen(
          origin: _originCity,
          destination: _destinationCity,
          packageType: 'Holiday Package',
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return _buildCollapsedView();
    }
    return _buildExpandedView();
  }

  Widget _buildCollapsedView() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.gapSmall,
      ),
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_originCity - $_destinationCity',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.gapXXSmall),
          Text(
            '${DateFormat('dd MMM yyyy, EEEE').format(_startDate).toUpperCase()} | $_adults ADULTS',
            style: TextStyle(
              fontSize: context.labelMedium,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: context.gapMedium),
          ElevatedButton(
            onPressed: _handleSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size(double.infinity, context.buttonHeightMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadiusMedium),
              ),
            ),
            child: Text(
              'SEARCH',
              style: TextStyle(
                fontSize: context.bodyMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.gapMedium,
      ),
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Starting From
          SearchFieldTile(
            label: 'STARTING FROM',
            value: _originCity,
            icon: Icons.location_on_outlined,
            onTap: _selectOrigin,
            context: context,
          ),
          SizedBox(height: context.gapSmall),
          Divider(color: AppColors.divider, height: 1),
          SizedBox(height: context.gapSmall),

          // Travelling To
          SearchFieldTile(
            label: 'TRAVELLING TO',
            value: _destinationCity,
            icon: Icons.location_on_outlined,
            onTap: _selectDestination,
            showCameraIcon: true,
            context: context,
          ),
          SizedBox(height: context.gapSmall),
          Divider(color: AppColors.divider, height: 1),
          SizedBox(height: context.gapSmall),

          // Date & Rooms Row
          Row(
            children: [
              Expanded(
                child: SearchFieldTile(
                  label: 'STARTING DATE',
                  value: DateFormat('dd MMM yyyy, EEE').format(_startDate),
                  icon: Icons.calendar_today_outlined,
                  onTap: _selectDate,
                  context: context,
                ),
              ),
              SizedBox(width: context.gapSmall),
              Expanded(
                child: SearchFieldTile(
                  label: 'ROOM & GUESTS',
                  // value: '$_adults Adults, $_rooms Room',
                  value: _getRoomGuestSummary(),
                  icon: Icons.person_outline,
                  onTap: _selectRoomAndGuests,
                  context: context,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          // Filters Section
          Text(
            'CHOOSE FILTERS (OPTIONAL)',
            style: TextStyle(
              fontSize: context.labelSmall,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.gapSmall),
          FilterChips(onFilterSelected: (filter) {}),
          SizedBox(height: context.gapMedium),

          // Search Button
          Container(
            width: double.infinity,
            height: context.buttonHeightLarge,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4FC3F7),
                  AppColors.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            ),
            child: ElevatedButton(
              onPressed: _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                ),
              ),
              child: Text(
                'SEARCH',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}