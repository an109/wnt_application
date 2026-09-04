import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../injection_container.dart';
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
import '../../../AKHotelAutosuggest/presentation/widget/hotel_autosuggest_field.dart';
import '../../../AKHotelSearchInit/domain/entity/AKHotelSearchInit_entity.dart';
import '../../../AKHotelSearchInit/domain/usecase/AKHotelSearchInit_usecase.dart';
import '../../../AKHotelBooking/presentation/screen/ak_hotel_results_screen.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../../home/flight/flight_calendar_screen.dart';


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
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);

  /// Guest nationality is resolved internally (defaults to India / 'IN').
  /// It is not shown in the UI and will later be set based on the user's IP.
  String _guestNationalityCode = 'IN';

  List<RoomConfig> _rooms = [RoomConfig()];

  // Cosmetic only — the Figma shows a By Night / Nearby toggle but there is no
  // "nearby" backend flow yet, so this only drives the segment's selected
  // state and never changes the search request.
  String _searchMode = 'byNight';

  // `section_heroes.hotel` — the hero photo behind the card.
  String? _heroImage;

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

    // Same source the flight SearchCard reads its hero photo from.
    context.read<GeneralSettingsBloc>().add(
          const LoadSectionHeroes(domain: 'thewandernova.com'),
        );
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

  Future<void> _openCalendar(
    BuildContext context, {
    required bool startWithCheckOut,
  }) async {
    final today = DateUtils.dateOnly(DateTime.now());

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FlightCalendarScreen(
          initialDeparture: _checkInDate,
          initialReturn: _checkOutDate,
          isRoundTrip: true,
          startWithReturn: startWithCheckOut,
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
            checkIn: checkInFormatted,
            checkOut: checkOutFormatted,
            adults: totalAdults,
            children: totalChildren,
            nationality: _guestNationalityCode,
            rooms: rooms,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeneralSettingsBloc, GeneralSettingsState>(
      listener: (context, state) {
        if (state is SectionHeroesLoaded) {
          setState(() => _heroImage = state.sectionHeroes.hotel);
        }
      },
      child: _buildHeroForm(context),
    );
  }

  Widget _buildHeroForm(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _buildHeroBackdrop(context)),

        // ====== BOTTOM MELTING GRADIENT ======
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(100),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.90),
                  Colors.white.withOpacity(0.60),
                  Colors.white.withOpacity(0.35),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: context.h(170),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.white.withOpacity(0.0),
                  AppColors.white.withOpacity(0.45),
                  AppColors.white,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // Foreground content
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: context.statusBarHeight + context.h(10)),
            _buildTopBar(context),
            SizedBox(height: context.h(18)),
            _buildModeToggle(context),
            SizedBox(height: context.h(14)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(14)),
              child: Column(
                children: [
                  _buildDestinationCard(context),
                  SizedBox(height: context.h(10)),
                  _buildDateCard(context),
                  SizedBox(height: context.h(10)),
                  _buildRoomCard(context),
                ],
              ),
            ),
            SizedBox(height: context.h(24)),
            _buildSearchButton(context),
            SizedBox(height: context.h(26)),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------ HERO IMAGE

  Widget _buildHeroBackdrop(BuildContext context) {
    const fallbackGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4A90E2), Color(0xFF87CEEB)],
    );

    const fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: fallbackGradient),
    );

    final hero = _heroImage;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hero != null && hero.isNotEmpty)
          Image.network(
            hero,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (ctx, child, progress) =>
                progress == null ? child : fallback,
          )
        else
          fallback,

        // Soft white gradient near the bottom for the "cloudy" merge.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(154),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.92),
                  Colors.white.withOpacity(0.72),
                  Colors.white.withOpacity(0.38),
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.20, 0.40, 0.60, 0.80, 1.0],
              ),
            ),
          ),
        ),

        // Top scrim so the white "Hotel" title stays readable.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.22),
                Colors.black.withOpacity(0.0),
              ],
              stops: const [0.0, 0.3],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- TOP BAR

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            behavior: HitTestBehavior.opaque,
            child: Image.asset(
              'assets/NewIcons/arrowBack.png',
              width: context.w(17),
              height: context.w(17),
              color: const Color(0xFFFFFFFF),
            ),
          ),
          SizedBox(width: context.w(14)),
          Text(
            'Hotel',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context) {
    final radius = BorderRadius.circular(context.r(24));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(8)),
      child: SizedBox(
        width: context.w(380), // Fixed width
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 6,
              sigmaY: 6,
            ),
            child: Container(
              height: context.h(51), // Fixed height
              padding: EdgeInsets.all(context.w(4)),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: radius,
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
            ),
          ),
        ),
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
    return GestureDetector(
      onTap: () => setState(() => _searchMode = id),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: context.w(182),
        height: context.h(35),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(context.r(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: context.w(15),
              height: context.w(15),
              color: selected ? AppColors.AppBlue : Colors.white,
            ),
            SizedBox(width: context.w(6)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.AppBlue : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------ CARD BUILDING BLOCKS

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: context.w(14),
            offset: Offset(0, context.h(4)),
          ),
        ],
      );

  Widget _cardLabel(String text, {bool showChevron = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: context.fs(8),
            fontWeight: FontWeight.w800,
            color: AppColors.black.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
        if (showChevron) ...[
          SizedBox(width: context.w(4)),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.w(12),
            color: AppColors.black.withOpacity(0.5),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------ DESTINATION

  Widget _buildDestinationCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(10),
      ),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _cardLabel('DESTINATION'),
          SizedBox(height: context.h(2)),
          Row(
            children: [
              Icon(Icons.search, size: context.w(20), color: _navy),
              SizedBox(width: context.w(8)),
              Expanded(
                child: HotelAutosuggestField(
                  hint: 'Select Destination...',
                  initialLocation: _selectedLocation,
                  onLocationSelected: (location) {
                    setState(() {
                      _selectedLocation = location;
                    });
                  },
                ),
              ),
              SizedBox(width: context.w(8)),
              _nearMeButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nearMeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _snack('Nearby search coming soon'),
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
            Icon(Icons.my_location,
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
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Image.asset(
            'assets/NewIcons/departureCalendar.png',
            width: context.w(24),
            height: context.h(24),
            color: AppColors.AppBlue,
          ),
          SizedBox(width: context.w(8),),
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
            fontSize: context.fs(12),
            fontWeight: FontWeight.w600,
            color: date != null ? Color(0xFF191C1E) : const Color(0xFFB8BEC9),
          ),
        ),
        SizedBox(height: context.h(2)),
        Text(
          _formatDay(date),
          style: TextStyle(fontSize: context.fs(10), color: AppColors.subhead),
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
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(12),
        ),
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
            SizedBox(height: context.h(8)),
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _roomStat(context, Icons.hotel, _rooms.length),
                SizedBox(width: context.w(36)),
                _roomDivider(context),
                SizedBox(width: context.w(36)),
                _roomStat(
                    context,
                    'assets/NewIcons/TravellerAdult.png',
                    totalAdults,
                    isAsset: true
                ),
                SizedBox(width: context.w(36)),
                _roomDivider(context),
                SizedBox(width: context.w(36)),
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
          width: context.w(16),
          height: context.w(16),
          color: AppColors.AppBlue,
        )
            : Icon(icon, size: context.w(17), color: AppColors.AppBlue),
        SizedBox(width: context.w(5)),
        Text(
          '$count',
          style: TextStyle(
            fontSize: context.fs(13),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _roomDivider(BuildContext context) {
    return Container(
      width: 0.5,
      height: context.w(20),
      margin: EdgeInsets.symmetric(horizontal: context.w(12)),
      color: Colors.grey.shade300,
    );
  }

  // ------------------------------------------------------- SEARCH BUTTON

  Widget _buildSearchButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: context.w(170),
        height: context.h(44),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.OrangeColor,
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: AppColors.OrangeColor.withOpacity(0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(30)),
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
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: context.w(10)),
                      Image.asset(
                        'assets/NewIcons/arrowForward.png',
                        width: context.w(9.54),
                        height: context.w(13),
                        color: const Color(0xFFFFFFFF),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
