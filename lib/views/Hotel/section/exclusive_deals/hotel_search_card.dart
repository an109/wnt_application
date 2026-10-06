import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/app_surface.dart';
import 'package:wander_nova/common_widgets/currency_chip.dart';
import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../injection_container.dart';
import '../../../../newUIWidgets/shine.dart';
import '../../../Hotel_Details/presentation/screens/widgets/room_config.dart';
// Old tbo-hotel-backed integration (cityCode search + HotelListingScreen) —
// commented out in favour of the Akbar Hotels Autosuggest + Search Init flow
// below. Left in place rather than deleted so it's easy to compare/restore.
// import '../../../Hotel_api/presentation/bloc/hotel_bloc.dart';
// import '../../../flight_destination/domain/entities/destination_entity.dart';
// import '../../../flight_destination/presentation/widget/destination_search_field.dart';
// import '../../../Hotel_api/presentation/screen/hotel_listing.dart';
import 'package:http/http.dart' as http;
import '../../../AKHotelAutosuggest/domain/entity/AKHotelAutosuggest_entity.dart';
import '../../../AKHotelAutosuggest/presentation/screen/hotel_destination_search_screen.dart';
import '../../../AKHotelSearchInit/domain/entity/AKHotelSearchInit_entity.dart';
import '../../../AKHotelSearchInit/domain/usecase/AKHotelSearchInit_usecase.dart';
import '../../../AKHotelBooking/presentation/screen/ak_hotel_results_screen.dart';
import '../../screen/hotel_calendar_screen.dart';


class HotelSearchCard extends StatefulWidget {
  const HotelSearchCard({super.key});

  @override
  State<HotelSearchCard> createState() => _HotelSearchCardState();
}

class _HotelSearchCardState extends State<HotelSearchCard> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  AkHotelLocationEntity? _selectedLocation;
  bool _isSearching = false;
  bool _locatingNearMe = false;

  /// Guest nationality is resolved internally (defaults to India / 'IN').
  /// It is not shown in the UI and will later be set based on the user's IP.
  String _guestNationalityCode = 'IN';

  List<RoomConfig> _rooms = [RoomConfig()];

  // Cosmetic only — the Figma shows a By Night / Nearby toggle but there is no
  // "nearby" backend flow yet, so this only drives the segment's selected
  // state and never changes the search request.
  String _searchMode = 'byNight';

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
        'location': _locationToJson(_selectedLocation),
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
        'location': _locationToJson(_selectedLocation),
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

      final savedLocation = _locationFromJson(lastSearch['location']);
      final savedRooms = _roomsFromJson(lastSearch['rooms']);
      final today = DateUtils.dateOnly(DateTime.now());

      setState(() {
        if (savedLocation != null) _selectedLocation = savedLocation;

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

  Map<String, dynamic>? _locationToJson(AkHotelLocationEntity? l) {
    if (l == null) return null;
    return {
      'id': l.id,
      'name': l.name,
      'fullName': l.fullName,
      'type': l.type,
      'state': l.state,
      'country': l.country,
      'referenceId': l.referenceId,
      'lat': l.lat,
      'long': l.long,
    };
  }

  AkHotelLocationEntity? _locationFromJson(dynamic json) {
    if (json == null || json['id'] == null) return null;
    return AkHotelLocationEntity(
      id: json['id'],
      name: json['name'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      type: json['type'] ?? 'city',
      state: json['state'],
      country: json['country'],
      referenceId: json['referenceId'],
      lat: (json['lat'] as num?)?.toDouble(),
      long: (json['long'] as num?)?.toDouble(),
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

  /// Rooms & guests picker — Figma "Select Rooms and Guests" bottom sheet
  /// (node 167:2266). A drawer with a Rooms / Adults / Children stepper per
  /// room, a per-child age panel, and a floating close button just above the
  /// top-right corner. `_rooms` and the search request shape are unchanged —
  /// only the UI is new.
  void _showRoomSelectionModal() {
    final tempRooms = _rooms.map((room) => room.copy()).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close — floating just above the sheet, top right.
                Padding(
                  padding: EdgeInsets.only(
                      right: context.w(20), bottom: context.h(10)),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _roomSheetClose(sheetContext),
                  ),
                ),
                // Flexible so the sheet's inner scroll area gets a bounded
                // height — with 3 rooms the content is taller than the screen.
                Flexible(
                  child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(context.r(24))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.w(20),
                        context.h(10),
                        context.w(20),
                        context.h(16) +
                            MediaQuery.of(sheetContext).viewInsets.bottom,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: _roomSheetHandle()),
                          SizedBox(height: context.h(18)),
                          Text(
                            'Select Rooms and Guests',
                            style: TextStyle(
                              fontSize: context.fs(16),
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(height: context.h(16)),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _roomCounterRow(
                                    title: 'Rooms',
                                    value: tempRooms.length,
                                    min: 1,
                                    max: 5,
                                    onDec: () =>
                                        setSheet(() => tempRooms.removeLast()),
                                    onInc: () => setSheet(
                                        () => tempRooms.add(RoomConfig())),
                                  ),
                                  for (int i = 0; i < tempRooms.length; i++) ...[
                                    if (tempRooms.length > 1) ...[
                                      SizedBox(height: context.h(16)),
                                      Row(
                                        children: [
                                          Text(
                                            'Room ${i + 1}',
                                            style: TextStyle(
                                              fontSize: context.fs(13),
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.subhead,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (i > 0)
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => setSheet(
                                                  () => tempRooms.removeAt(i)),
                                              child: Icon(
                                                Icons.remove_circle_outline,
                                                size: context.w(18),
                                                color: const Color(0xFFEF4444),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                    SizedBox(height: context.h(10)),
                                    _roomCounterRow(
                                      title: 'Adults',
                                      badge: '12y+',
                                      value: tempRooms[i].adults,
                                      min: 1,
                                      max: 9,
                                      onDec: () => setSheet(
                                          () => tempRooms[i].adults--),
                                      onInc: () => setSheet(
                                          () => tempRooms[i].adults++),
                                    ),
                                    SizedBox(height: context.h(10)),
                                    _roomCounterRow(
                                      title: 'Children',
                                      badge: '0-17y',
                                      value: tempRooms[i].children,
                                      min: 0,
                                      max: 4,
                                      onDec: () => setSheet(
                                          () => tempRooms[i].removeChild()),
                                      onInc: () => setSheet(
                                          () => tempRooms[i].addChild(8)),
                                    ),
                                    if (tempRooms[i].children > 0) ...[
                                      SizedBox(height: context.h(10)),
                                      _childAgesCard(tempRooms[i], setSheet),
                                    ],
                                  ],
                                  SizedBox(height: context.h(18)),
                                ],
                              ),
                            ),
                          ),
                          _roomDoneButton(() {
                            setState(() => _rooms = tempRooms);
                            Navigator.pop(sheetContext);
                          }),
                          SizedBox(height: context.h(6)),
                        ],
                      ),
                    ),
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

  Widget _roomSheetClose(BuildContext ctx) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(ctx).maybePop(),
      child: Container(
        width: context.w(34),
        height: context.w(34),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.close_rounded,
            size: context.w(19), color: AppColors.black),
      ),
    );
  }

  Widget _roomSheetHandle() {
    return Container(
      width: context.w(103),
      height: context.h(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(context.r(24)),
      ),
    );
  }

  Widget _roomDoneButton(VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: context.h(44),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.OrangeColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
        ),
        child: Text(
          'DONE',
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// One "Rooms / Adults / Children" stepper row — bordered card, label
  /// (+ optional age badge) on the left, a − N + control on the right.
  Widget _roomCounterRow({
    required String title,
    String? badge,
    required int value,
    required int min,
    required int max,
    required VoidCallback onDec,
    required VoidCallback onInc,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(16), vertical: context.h(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  SizedBox(width: context.w(8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.w(8), vertical: context.h(2)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(context.r(12)),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w600,
                        color: AppColors.subhead,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.w(8)),
          Container(
            padding: EdgeInsets.all(context.w(4)),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(context.r(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _roomStepBtn(
                    icon: Icons.remove, enabled: value > min, onTap: onDec),
                SizedBox(
                  width: context.w(34),
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                _roomStepBtn(
                    icon: Icons.add, enabled: value < max, onTap: onInc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomStepBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(36),
        height: context.w(36),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        child: Icon(
          icon,
          size: context.w(14),
          color: enabled ? AppColors.AppBlue : Colors.grey.shade300,
        ),
      ),
    );
  }

  /// "Age of children" panel — a light card with a compact − Ny + stepper
  /// per child (ages 1–17).
  Widget _childAgesCard(RoomConfig room, StateSetter setSheet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: context.w(14), vertical: context.h(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Age of children',
            style: TextStyle(
              fontSize: context.fs(11),
              fontWeight: FontWeight.w600,
              color: AppColors.subhead,
            ),
          ),
          for (int j = 0; j < room.children; j++) ...[
            SizedBox(height: context.h(10)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Child ${j + 1}',
                    style: TextStyle(
                      fontSize: context.fs(13),
                      color: AppColors.black,
                    ),
                  ),
                ),
                _roomStepBtn(
                  icon: Icons.remove,
                  enabled: room.childAges[j] > 1,
                  onTap: () => setSheet(
                      () => room.updateChildAge(j, room.childAges[j] - 1)),
                ),
                SizedBox(
                  width: context.w(34),
                  child: Text(
                    '${room.childAges[j]}y',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                _roomStepBtn(
                  icon: Icons.add,
                  enabled: room.childAges[j] < 17,
                  onTap: () => setSheet(
                      () => room.updateChildAge(j, room.childAges[j] + 1)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCalendar(
    BuildContext context, {
    required bool startWithCheckOut,
  }) async {
    final today = DateUtils.dateOnly(DateTime.now());

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => HotelCalendarScreen(
          checkIn: _checkInDate,
          checkOut: _checkOutDate,
          startWithCheckOut: startWithCheckOut,
          firstDate: today,
          lastDate: today.add(const Duration(days: 365)),
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      final ci = result['departure'] as DateTime? ?? _checkInDate;
      var co = result['return'] as DateTime?;
      _checkInDate = ci;
      if (ci != null && (co == null || !co.isAfter(ci))) {
        co = ci.add(const Duration(days: 1));
      }
      _checkOutDate = co ?? _checkOutDate;
    });
  }

  int? get _nights {
    final ci = _checkInDate, co = _checkOutDate;
    if (ci == null || co == null) return null;
    final n =
        DateUtils.dateOnly(co).difference(DateUtils.dateOnly(ci)).inDays;
    return n > 0 ? n : null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat("d MMM, yy").format(date);
  }

  String _formatDay(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('EEEE').format(date);
  }

  /// New Akbar Hotels flow: Search Init needs the Autosuggest-picked
  /// locationId (not free text), MM/DD/YYYY dates (not ISO), and rooms
  /// shaped as {adults, children, childAges}.
  Future<void> _onSearchPressed() async {
    if (_selectedLocation == null) {
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
    if (_isSearching) return;

    // Persist this search so the form is prefilled next time.
    _saveLastSearch();
    _addToSearchHistory();

    final checkInFormatted = DateFormat('MM/dd/yyyy').format(_checkInDate!);
    final checkOutFormatted = DateFormat('MM/dd/yyyy').format(_checkOutDate!);

    final rooms = _rooms
        .map((r) => AkHotelSearchInitRoomEntity(
              adults: r.adults,
              children: r.children,
              childAges: r.childAges,
            ))
        .toList();

    setState(() => _isSearching = true);

    final result = await sl<AkHotelSearchInitUseCase>().call(
      AkHotelSearchInitRequestEntity(
        locationId: _selectedLocation!.id,
        checkIn: checkInFormatted,
        checkOut: checkOutFormatted,
        rooms: rooms,
        nationality: _guestNationalityCode,
        countryOfResidence: _guestNationalityCode,
        destinationCountryCode:
            _selectedLocation!.country ?? _guestNationalityCode,
      ),
    );

    if (!mounted) return;
    setState(() => _isSearching = false);

    if (result is DataSuccess<AkHotelSearchInitEntity>) {
      final data = result.data!;
      final totalAdults = _rooms.fold(0, (sum, room) => sum + room.adults);
      final totalChildren = _rooms.fold(0, (sum, room) => sum + room.children);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AkHotelResultsScreen(
            searchId: data.searchId,
            searchTracingKey: data.searchTracingKey,
            locationName: _selectedLocation!.fullName,
            location: _selectedLocation!,
            checkIn: checkInFormatted,
            checkOut: checkOutFormatted,
            adults: totalAdults,
            children: totalChildren,
            nationality: _guestNationalityCode,
            rooms: rooms,
            searchedByHotelName: _selectedLocation!.type.toLowerCase() == 'hotel',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start hotel search. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(10))),
      content: Text(msg),
    ));
  }

  // ---------------------------------------------------------------- BUILD
  // Same look as the flight form: white page, dark top bar, light toggle
  // track and white cards with the shared raised shadow (412px Figma frame,
  // hence `context.fx`).

  static const Color _kMuted = Color(0xFF757575);
  static const Color _kTrackBg = Color(0xFFEEF3FA);

  @override
  Widget build(BuildContext context) {
    final gutter = EdgeInsets.symmetric(horizontal: context.fx(16));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: context.statusBarHeight + context.fx(16)),
        Padding(padding: gutter, child: _buildTopBar(context)),
        SizedBox(height: context.fx(24)),
        Padding(padding: gutter, child: _buildModeToggle(context)),
        SizedBox(height: context.fx(24)),
        Padding(
          padding: gutter,
          child: Column(
            children: [
              _buildDestinationCard(context),
              SizedBox(height: context.fx(12)),
              _buildDateCard(context),
              SizedBox(height: context.fx(12)),
              _buildRoomCard(context),
            ],
          ),
        ),
        SizedBox(height: context.fx(24)),
        _buildSearchButton(context),
        SizedBox(height: context.fx(8)),
      ],
    );
  }

  // --------------------------------------------------------------- TOP BAR

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: context.fx(36),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: context.fx(6)),
                child: Icon(Icons.arrow_back, size: context.fx(24), color: Colors.black),
              ),
            ),
          ),
          SizedBox(width: context.fx(16)),
          Text(
            'Hotel',
            style: TextStyle(
              fontSize: context.ffs(20),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          const CurrencyChip(),
          SizedBox(width: context.fx(16)),
          SvgPicture.asset(
            'assets/home/notification.svg',
            width: context.fx(24),
            height: context.fx(24),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(8)),
      decoration: BoxDecoration(
        color: _kTrackBg,
        borderRadius: BorderRadius.circular(context.fx(26)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeSegment(
              context,
              id: 'byNight',
              label: 'By Night',
              iconPath: 'assets/NewIcons/night_icon.png',
            ),
          ),
          Expanded(
            child: _modeSegment(
              context,
              id: 'nearby',
              label: 'Nearby',
              iconPath: 'assets/NewIcons/location_icon.png',
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSegment(
    BuildContext context, {
    required String id,
    required String label,
    required String iconPath,
  }) {
    final selected = _searchMode == id;
    final color = selected ? AppColors.AppBlue : _kMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => setState(() => _searchMode = id),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: context.fx(34),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(context.fx(17)),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                width: context.fx(16),
                height: context.fx(16),
                color: color,
              ),
              SizedBox(width: context.fx(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.ffs(14),
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------ CARD BUILDING BLOCKS

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        boxShadow: kRaisedCardShadow,
      );

  Widget _cardLabel(String text, {bool showChevron = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: context.ffs(9),
            fontWeight: FontWeight.w600,
            color: _kMuted,
            letterSpacing: 0.6,
          ),
        ),
        if (showChevron) ...[
          SizedBox(width: context.fx(4)),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.fx(14),
            color: _kMuted,
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------ DESTINATION

  /// Full-screen destination picker — same pattern the flight SearchCard uses
  /// for From / To. Returns the picked [AkHotelLocationEntity].
  Future<void> _openDestinationSearch({String? initialQuery}) async {
    final result = await Navigator.of(context).push<AkHotelLocationEntity>(
      MaterialPageRoute(
        builder: (_) => HotelDestinationSearchScreen(
          initialLocation: _selectedLocation,
          initialQuery: initialQuery,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _selectedLocation = result);
  }

  /// "Near me" — reverse-geocodes the device's current position to a
  /// city/locality name and opens the destination picker already searching
  /// for it, so the user still confirms and taps Search themselves (the
  /// Autosuggest API only takes a text term, so there's no true "search
  /// hotels near these coordinates" to run automatically). Same
  /// permission/service-check flow as `TLocationSearchScreen._useCurrentLocation`.
  Future<void> _useNearMe() async {
    if (_locatingNearMe) return;
    setState(() => _locatingNearMe = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are turned off.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'Location permission was denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      String? place;
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          place = [p.locality, p.subAdministrativeArea, p.administrativeArea]
              .firstWhere((s) => (s ?? '').trim().isNotEmpty, orElse: () => null);
        }
      } catch (_) {
        // Handled below via the null check — reverse geocoding failing just
        // means there's nothing to prefill the search with.
      }

      if (!mounted) return;
      if (place == null || place.trim().isEmpty) {
        throw 'Could not determine your current city.';
      }
      await _openDestinationSearch(initialQuery: place);
    } catch (e) {
      if (!mounted) return;
      _snack(e is String ? e : 'Could not detect your location.');
    } finally {
      if (mounted) setState(() => _locatingNearMe = false);
    }
  }

  Widget _buildDestinationCard(BuildContext context) {
    final loc = _selectedLocation;
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _cardLabel('DESTINATION'),
          SizedBox(height: context.fx(6)),
          Row(
            children: [
              Icon(Icons.search, size: context.fx(24), color: AppColors.AppBlue),
              SizedBox(width: context.fx(8)),
              Expanded(
                child: GestureDetector(
                  onTap: _openDestinationSearch,
                  behavior: HitTestBehavior.opaque,
                  child: loc == null
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: context.fx(4)),
                          child: Text(
                            'Select Destination...',
                            style: TextStyle(
                              fontSize: context.ffs(14),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.ffs(14),
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            if (loc.fullName.trim().isNotEmpty &&
                                loc.fullName.trim() != loc.name.trim())
                              Text(
                                loc.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.ffs(10),
                                  color: _kMuted,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              SizedBox(width: context.fx(8)),
              _nearMeButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nearMeButton(BuildContext context) {
    return GestureDetector(
      onTap: _locatingNearMe ? null : _useNearMe,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(6)),
          border: Border.all(color: AppColors.OrangeColor, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _locatingNearMe
                ? SizedBox(
                    width: context.w(14),
                    height: context.w(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.OrangeColor),
                    ),
                  )
                : Icon(Icons.my_location,
                    size: context.w(14), color: AppColors.OrangeColor),
            SizedBox(width: context.w(8)),
            Text(
              'Near me',
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: AppColors.OrangeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ DATE CARD

  Widget _buildDateCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Image.asset(
            'assets/NewIcons/departureCalendar.png',
            width: context.fx(26),
            height: context.fx(26),
            color: AppColors.AppBlue,
          ),
          SizedBox(width: context.fx(8)),
          Expanded(
            child: GestureDetector(
              onTap: () => _openCalendar(context, startWithCheckOut: false),
              behavior: HitTestBehavior.opaque,
              child: _dateColumn(context, _checkInDate),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.w(32), // Width of the divider line
                height: 1, // Thickness of the line
                color: AppColors.OrangeColor,
                margin: EdgeInsets.only(bottom: context.h(4)), // Space below divider
              ),
              _nightPill(context),
            ],
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openCalendar(context, startWithCheckOut: true),
              behavior: HitTestBehavior.opaque,
              child: _dateColumn(context, _checkOutDate,
                  alignEnd: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateColumn(
    BuildContext context,
    DateTime? date, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatDate(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: context.ffs(12),
            fontWeight: FontWeight.w600,
            color: date != null ? Colors.black : Colors.grey.shade400,
          ),
        ),
        SizedBox(height: context.fx(2)),
        Text(
          _formatDay(date),
          style: TextStyle(fontSize: context.ffs(10), color: _kMuted),
        ),
      ],
    );
  }

  Widget _nightPill(BuildContext context) {
    final n = _nights;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(8)),
      padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
      decoration: BoxDecoration(
        // color: Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(context.r(50)),
        border: Border.all(color: Color(0xFFE2E8F0), width: 1),
      ),
      child: Text(
        n == null ? '—' : '$n NIGHT${n > 1 ? 'S' : ''}',
        style: TextStyle(
          fontSize: context.fs(12),
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ ROOM CARD

  Widget _buildRoomCard(BuildContext context) {
    final totalAdults = _rooms.fold<int>(0, (s, r) => s + r.adults);
    final totalChildren = _rooms.fold<int>(0, (s, r) => s + r.children);

    return GestureDetector(
      onTap: _showRoomSelectionModal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(context.fx(12)),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _cardLabel('ROOM'),
                const Spacer(),
                // Text(
                //   _getRoomSummary(),
                //   style: TextStyle(
                //     fontSize: context.fs(10.5),
                //     fontWeight: FontWeight.w600,
                //     color: _kSubGrey,
                //   ),
                // ),
              ],
            ),
            SizedBox(height: context.fx(10)),
            Row(
              children: [
                _roomStat(context, Icons.hotel, _rooms.length),
                SizedBox(width: context.fx(24)),
                _roomDivider(context),
                SizedBox(width: context.fx(24)),
                _roomStat(
                    context,
                    'assets/NewIcons/TravellerAdult.png',
                    totalAdults,
                    isAsset: true
                ),
                SizedBox(width: context.fx(24)),
                _roomDivider(context),
                SizedBox(width: context.fx(24)),
                _roomStat(
                    context,
                    'assets/NewIcons/TravellerBaby.png',
                    totalChildren,
                    isAsset: true
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomStat(BuildContext context, dynamic icon, int count, {bool isAsset = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isAsset
            ? Image.asset(
          icon, // icon will be a String path
          width: context.fx(16),
          height: context.fx(16),
          color: AppColors.AppBlue,
        )
            : Icon(icon, size: context.fx(16), color: AppColors.AppBlue),
        SizedBox(width: context.fx(8)),
        Text(
          '$count',
          style: TextStyle(
            fontSize: context.ffs(12),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _roomDivider(BuildContext context) {
    return Container(
      width: 0.5,
      height: context.fx(20),
      color: const Color(0xFFCCCCCC),
    );
  }

  // ------------------------------------------------------- SEARCH BUTTON

  Widget _buildSearchButton(BuildContext context) {
    return Center(
      child: ShineBorderButton(
        // Match the button's own radius so the shine hugs it.
        borderRadius: context.fx(21),
        borderWidth: 1.4,
        shineColor: const Color(0xFFFFE0B5), // warm glow on orange
        duration: const Duration(seconds: 2, milliseconds: 500),
        // Turn the shine OFF while searching, so the disabled state is clean.
        enabled: !_isSearching,
        child: SizedBox(
          width: context.fx(210),
          height: context.fx(42),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.85),
              elevation: 6,
              shadowColor: AppColors.orange.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.fx(21)),
              ),
              padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            ),
            onPressed: _isSearching ? null : _onSearchPressed,
            child: _isSearching
                ? SizedBox(
              width: context.w(22),
              height: context.w(22),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Search Hotel',
                    style: TextStyle(
                      fontSize: context.ffs(14),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: context.fx(10)),
                  Icon(Icons.arrow_forward, size: context.fx(18), color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
