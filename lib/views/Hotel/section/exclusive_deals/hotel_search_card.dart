import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/compact_date_picker_dialog.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../injection_container.dart';
import '../../../Hotel_Details/presentation/screens/widgets/room_config.dart';
import '../../../Hotel_api/presentation/bloc/hotel_bloc.dart';
import '../../../flight_destination/domain/entities/destination_entity.dart';
import '../../../flight_destination/presentation/widget/destination_search_field.dart';
import '../../../Hotel_api/presentation/screen/hotel_listing.dart';
import 'package:http/http.dart' as http;

class HotelSearchCard extends StatefulWidget {
  const HotelSearchCard({super.key});

  @override
  State<HotelSearchCard> createState() => _HotelSearchCardState();
}

class _HotelSearchCardState extends State<HotelSearchCard> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  DestinationEntity? _selectedDestination;
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _border = Color(0xFFE2E7F0);

  /// Guest nationality is resolved internally (defaults to India / 'IN').
  /// It is not shown in the UI and will later be set based on the user's IP.
  String _guestNationalityCode = 'IN';

  List<RoomConfig> _rooms = [RoomConfig()];

  static const String _lastHotelSearchKey = 'last_hotel_search_data';

  @override
  void initState() {
    super.initState();

    // Auto-select dates on initialization
    _checkInDate = DateTime.now();
    _checkOutDate = DateTime.now().add(const Duration(days: 1));

    _detectNationalityFromIP();
    // Prefill from the user's last hotel search (details are stored in prefs).
    _loadLastSearch();
  }

  Future<void> _saveLastSearch() async {
    try {
      final prefsManager =
          await PreferencesManager.create(await SharedPreferences.getInstance());

      final searchData = {
        'destination': _destinationToJson(_selectedDestination),
        'checkInDate': _checkInDate?.toIso8601String(),
        'checkOutDate': _checkOutDate?.toIso8601String(),
        'rooms': _rooms
            .map((r) => {
                  'adults': r.adults,
                  'children': r.children,
                  'childAges': r.childAges,
                })
            .toList(),
      };

      await prefsManager.setString(
          _lastHotelSearchKey, jsonEncode(searchData));
    } catch (e) {
      debugPrint('Error saving last hotel search: $e');
    }
  }

  Future<void> _addToSearchHistory() async {
    try {
      final prefsManager =
          await PreferencesManager.create(await SharedPreferences.getInstance());
      final searchData = {
        'type': 'hotel',
        'destination': _destinationToJson(_selectedDestination),
        'checkInDate': _checkInDate?.toIso8601String(),
        'checkOutDate': _checkOutDate?.toIso8601String(),
        'rooms': _rooms
            .map((r) => {'adults': r.adults, 'children': r.children})
            .toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefsManager.addToSearchHistory(searchData);
    } catch (e) {
      debugPrint('Error adding hotel search to history: $e');
    }
  }

  Future<void> _loadLastSearch() async {
    try {
      final prefsManager =
          await PreferencesManager.create(await SharedPreferences.getInstance());
      final raw = prefsManager.getString(_lastHotelSearchKey);
      if (raw == null || !mounted) return;

      final lastSearch = jsonDecode(raw) as Map<String, dynamic>;

      final savedDestination = _destinationFromJson(lastSearch['destination']);
      final savedRooms = _roomsFromJson(lastSearch['rooms']);
      final today = DateUtils.dateOnly(DateTime.now());

      setState(() {
        if (savedDestination != null) _selectedDestination = savedDestination;

        // Restore dates, but never prefill a date in the past.
        if (lastSearch['checkInDate'] != null) {
          final checkIn =
              DateUtils.dateOnly(DateTime.parse(lastSearch['checkInDate']));
          _checkInDate = checkIn.isBefore(today) ? today : checkIn;
        }
        if (lastSearch['checkOutDate'] != null) {
          final checkOut =
              DateUtils.dateOnly(DateTime.parse(lastSearch['checkOutDate']));
          _checkOutDate =
              (_checkInDate != null && !checkOut.isAfter(_checkInDate!))
                  ? _checkInDate!.add(const Duration(days: 1))
                  : checkOut;
        }

        if (savedRooms != null && savedRooms.isNotEmpty) _rooms = savedRooms;
      });
    } catch (e) {
      debugPrint('Error loading last hotel search: $e');
    }
  }

  Map<String, dynamic>? _destinationToJson(DestinationEntity? d) {
    if (d == null) return null;
    return {
      'id': d.id,
      'name': d.name,
      'type': d.type.name,
      'countryCode': d.countryCode,
      'countryName': d.countryName,
      'cityCode': d.cityCode,
      'additionalInfo': d.additionalInfo,
    };
  }

  DestinationEntity? _destinationFromJson(dynamic json) {
    if (json == null || json['id'] == null) return null;
    return DestinationEntity(
      id: json['id'],
      name: json['name'] ?? '',
      type: DestinationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DestinationType.city,
      ),
      countryCode: json['countryCode'],
      countryName: json['countryName'],
      cityCode: json['cityCode'],
      additionalInfo: json['additionalInfo'],
    );
  }

  List<RoomConfig>? _roomsFromJson(dynamic json) {
    if (json is! List) return null;
    return json
        .map((r) => RoomConfig(
              adults: r['adults'] ?? 1,
              children: r['children'] ?? 0,
              childAges: (r['childAges'] as List?)?.cast<int>() ?? [],
            ))
        .toList();
  }

  Future<void> _detectNationalityFromIP() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _guestNationalityCode = data['countryCode'] ?? 'IN';
        });

        print('Detected Country: $_guestNationalityCode');
      }
    } catch (e) {
      print('Failed to detect nationality: $e');
    }
  }

  String _getRoomSummary() {
    int totalAdults = _rooms.fold(0, (sum, room) => sum + room.adults);
    int totalChildren = _rooms.fold(0, (sum, room) => sum + room.children);
    int totalGuests = totalAdults + totalChildren;

    if (_rooms.length == 1) {
      return '${_rooms.length} Room, $totalGuests Guest${totalGuests > 1 ? 's' : ''}';
    }
    return '${_rooms.length} Rooms, $totalGuests Guests';
  }

  void _showRoomSelectionModal() {
    List<RoomConfig> tempRooms = _rooms.map((room) => room.copy()).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: context.w(20),
                vertical: context.h(16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadiusLarge),
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: context.h(480)),
                child: Column(
                  children: [
                    _buildModalHeader(() {
                      setState(() {
                        _rooms = tempRooms;
                      });
                      Navigator.pop(context);
                    }),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: tempRooms.length,
                        itemBuilder: (context, index) {
                          return _buildRoomConfigCard(
                            tempRooms,
                            index,
                            setModalState,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(context.w(12)),
                      child: TextButton.icon(
                        onPressed: tempRooms.length < 5
                            ? () {
                                setModalState(() {
                                  tempRooms.add(RoomConfig());
                                });
                              }
                            : null,
                        icon: Icon(Icons.add_circle_outline),
                        label: Text('Add another room'),
                        style: TextButton.styleFrom(foregroundColor: _blue),
                      ),
                    ),
                    SizedBox(height: context.gapMedium),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalHeader(VoidCallback onApply) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          Text(
            'Rooms & Guests',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
            ),
            child: Text('Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomConfigCard(
    List<RoomConfig> rooms,
    int index,
    StateSetter setModalState,
  ) {
    RoomConfig room = rooms[index];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.gapMedium,
        vertical: context.gapSmall,
      ),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Room ${index + 1}',
                style: TextStyle(
                  fontSize: context.titleSmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (rooms.length > 1)
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    setModalState(() {
                      rooms.removeAt(index);
                    });
                  },
                ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          _buildCounterRow(
            title: 'Adults',
            subtitle: 'Above 12 years',
            count: room.adults,
            onIncrement: () => setModalState(() => room.adults++),
            onDecrement: () {
              if (room.adults > 1) setModalState(() => room.adults--);
            },
          ),
          SizedBox(height: context.gapMedium),

          _buildCounterRow(
            title: 'Children',
            subtitle: 'Ages 1-12 years',
            count: room.children,
            onIncrement: () {
              if (room.children < 4) {
                setModalState(() {
                  room.addChild(8);
                });
              }
            },
            onDecrement: () {
              setModalState(() => room.removeChild());
            },
          ),

          if (room.children > 0) ...[
            SizedBox(height: context.gapMedium),
            Divider(color: Colors.grey.shade200),
            SizedBox(height: context.gapSmall),
            Text(
              'Children Ages',
              style: TextStyle(
                fontSize: context.labelMedium,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.gapSmall),
            ...List.generate(room.children, (childIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: context.gapSmall),
                child: Row(
                  children: [
                    Text(
                      'Child ${childIndex + 1}',
                      style: TextStyle(fontSize: context.bodySmall),
                    ),
                    SizedBox(width: context.gapMedium),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: room.childAges[childIndex],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.r(8)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.gapSmall,
                            vertical: context.gapXSmall,
                          ),
                        ),
                        items: List.generate(12, (i) => i + 1)
                            .map(
                              (age) => DropdownMenuItem(
                                value: age,
                                child: Text('$age years'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              room.updateChildAge(childIndex, value);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: context.bodyMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: context.labelSmall,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: context.w(32),
                height: context.w(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: Icon(Icons.remove, size: context.iconSmall),
              ),
            ),
            SizedBox(width: context.gapMedium),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: context.gapMedium),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: context.w(32),
                height: context.w(32),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: Icon(
                  Icons.add,
                  size: context.iconSmall,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final firstDate = isCheckIn
        ? DateUtils.dateOnly(DateTime.now())
        : DateUtils.dateOnly(_checkInDate ?? DateTime.now());
    final rawInitial = isCheckIn
        ? (_checkInDate ?? DateTime.now())
        : (_checkOutDate ??
              (_checkInDate ?? DateTime.now()).add(const Duration(days: 1)));
    final initialDate = DateUtils.dateOnly(rawInitial);

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CompactDatePickerDialog(
        initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
        firstDate: firstDate,
        lastDate: DateTime.now().add(const Duration(days: 365)),
        accentColor: _blue,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
            _checkOutDate = picked.add(const Duration(days: 1));
          }
        } else {
          if (_checkInDate != null && picked.isBefore(_checkInDate!)) {
            _checkOutDate = _checkInDate!.add(const Duration(days: 1));
          } else {
            _checkOutDate = picked;
          }
        }
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

  void _onSearchPressed() {
    // Validation
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select check-in and check-out dates'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('SEARCH CLICKED');
    print('Destination: ${_selectedDestination?.displayName}');
    print('Destination Type: ${_selectedDestination?.type}');
    print('Check-in: $_checkInDate');
    print('Check-out: $_checkOutDate');
    int totalAdults = _rooms.fold(0, (sum, room) => sum + room.adults);
    int totalChildren = _rooms.fold(0, (sum, room) => sum + room.children);
    print('Guests: $totalAdults adults, $totalChildren children');
    print('Rooms: ${_rooms.length}');
    print('Rooms: $_rooms');

    // Persist this search so the form is prefilled next time.
    _saveLastSearch();
    _addToSearchHistory();

    final checkInFormatted = DateFormat('yyyy-MM-dd').format(_checkInDate!);
    final checkOutFormatted = DateFormat('yyyy-MM-dd').format(_checkOutDate!);

    // Get the city code based on destination type
    String cityCode;
    if (_selectedDestination!.type == DestinationType.hotel) {
      cityCode = _selectedDestination!.cityCode ?? '';
      print('Hotel selected - using cityCode: $cityCode');
    } else {
      cityCode = _selectedDestination!.id;
      print('City selected - using id: $cityCode');
    }

    final paxRooms = List.generate(_rooms.length, (index) {
      final room = _rooms[index];
      return {
        'Adults': room.adults,
        'Children': room.children,
        'ChildrenAges': List.generate(
          room.children,
          (childIndex) => room.childAges[childIndex],
        ),
      };
    });

    // Navigate with BlocProvider
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => sl<HotelBloc>(),
          child: HotelListingScreen(
            cityCode: cityCode,
            checkIn: checkInFormatted,
            checkOut: checkOutFormatted,
            guestNationality: _guestNationalityCode,
            paxRooms: paxRooms,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// DESTINATION (full width — guest nationality is resolved internally)
          _buildDestinationField(context),

          _sectionDivider(context),

          /// DATE SECTION
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context,
                  title: 'Check-In',
                  date: _formatDate(_checkInDate),
                  day: _formatDay(_checkInDate),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              Container(
                width: context.w(1),
                height: context.h(46),
                margin: EdgeInsets.symmetric(horizontal: context.w(10)),
                color: _border,
              ),
              Expanded(
                child: _buildDateField(
                  context,
                  title: 'Check-Out',
                  date: _formatDate(_checkOutDate),
                  day: _formatDay(_checkOutDate),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),

          _sectionDivider(context),

          /// ROOM + SEARCH BUTTON
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: _buildRoomsField(context)),
              SizedBox(width: context.w(12)),
              Expanded(flex: 4, child: _buildSearchButton(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider(BuildContext context) {
    return Divider(height: context.h(18), thickness: 0.7, color: _border);
  }

  /// Small rounded square that holds a leading icon (Image #3 style).
  Widget _iconBox(BuildContext context, IconData icon) {
    return Container(
      width: 37,
      height: 37,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 17, color: _navy),
    );
  }

  TextStyle _labelStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      color: AppColors.muted,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );
  }

  Widget _buildDestinationField(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBox(context, Icons.location_on_outlined),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DESTINATION', style: _labelStyle(context)),
              SizedBox(height: context.h(2)),
              DestinationSearchField(
                label: 'Enter destination',
                hint: 'Select Destination...',
                initialDestination: _selectedDestination,
                onDestinationSelected: (destination) {
                  setState(() {
                    _selectedDestination = destination;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String title,
    required String date,
    required String day,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _iconBox(context, icon),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: _labelStyle(context)),
                SizedBox(height: context.h(2)),
                Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: date == 'Select Date'
                        ? const Color(0xFFB8BEC9)
                        : _navy,
                  ),
                ),
                if (day.isNotEmpty)
                  Text(
                    day,
                    style:  TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsField(BuildContext context) {
    return GestureDetector(
      onTap: _showRoomSelectionModal,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _iconBox(context, Icons.king_bed_outlined),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ROOMS & GUESTS', style: _labelStyle(context)),
                SizedBox(height: context.h(2)),
                Text(
                  _getRoomSummary(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                SizedBox(height: context.h(2)),
                 Text(
                  'Tap to configure',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.OrangeColor,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: context.w(10)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _onSearchPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SEARCH',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
            SizedBox(width: context.w(6)),
            const Icon(Icons.search, color: Colors.white, size: 17),
          ],
        ),
      ),
    );
  }
}
