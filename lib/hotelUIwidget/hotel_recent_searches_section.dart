import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../core/error/data_state.dart';
import '../core/resources/app_colours.dart';
import '../core/utils/storage/shared_preference.dart';
import '../injection_container.dart';
import '../views/AKHotelAutosuggest/domain/entity/AKHotelAutosuggest_entity.dart';
import '../views/AKHotelBooking/presentation/screen/ak_hotel_results_screen.dart';
import '../views/AKHotelSearchInit/domain/entity/AKHotelSearchInit_entity.dart';
import '../views/AKHotelSearchInit/domain/usecase/AKHotelSearchInit_usecase.dart';


class HotelRecentSearchesSection extends StatefulWidget {
  const HotelRecentSearchesSection({super.key});

  @override
  State<HotelRecentSearchesSection> createState() =>
      _HotelRecentSearchesSectionState();
}

class _HotelRecentSearchesSectionState
    extends State<HotelRecentSearchesSection> {
  List<Map<String, dynamic>> _history = [];
  bool _loaded = false;
  int? _searchingIndex;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefsManager = await PreferencesManager.create(
        await SharedPreferences.getInstance(),
      );
      final history = prefsManager.getSearchHistory();
      final hotelOnly = history.where((entry) {
        if (entry['type'] != 'hotel') return false;
        final loc = entry['location'];
        return loc is Map && loc['id'] != null;
      }).toList();

      if (!mounted) return;
      setState(() {
        _history = hotelOnly.take(6).toList();
        _loaded = true;
      });
    } catch (e) {
      debugPrint('Error loading hotel recent searches: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  AkHotelLocationEntity _locationFromJson(Map json) {
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

  Future<void> _repeatSearch(int index) async {
    if (_searchingIndex != null) return;
    final entry = _history[index];

    setState(() => _searchingIndex = index);
    try {
      final location = _locationFromJson(entry['location'] as Map);
      final checkIn = entry['checkInDate'] != null
          ? DateTime.parse(entry['checkInDate'] as String)
          : DateTime.now();
      var checkOut = entry['checkOutDate'] != null
          ? DateTime.parse(entry['checkOutDate'] as String)
          : checkIn.add(const Duration(days: 1));
      if (!checkOut.isAfter(checkIn)) {
        checkOut = checkIn.add(const Duration(days: 1));
      }

      final roomsRaw = (entry['rooms'] as List?) ?? const [];
      final rooms = roomsRaw.isEmpty
          ? [const AkHotelSearchInitRoomEntity(adults: 1, children: 0, childAges: [])]
          : roomsRaw
              .map((r) => AkHotelSearchInitRoomEntity(
                    adults: (r['adults'] as int?) ?? 1,
                    children: (r['children'] as int?) ?? 0,
                    childAges: const [],
                  ))
              .toList();

      final checkInFormatted = DateFormat('MM/dd/yyyy').format(checkIn);
      final checkOutFormatted = DateFormat('MM/dd/yyyy').format(checkOut);

      final result = await sl<AkHotelSearchInitUseCase>().call(
        AkHotelSearchInitRequestEntity(
          locationId: location.id,
          checkIn: checkInFormatted,
          checkOut: checkOutFormatted,
          rooms: rooms,
          nationality: 'IN',
          countryOfResidence: 'IN',
          destinationCountryCode: location.country ?? 'IN',
        ),
      );

      if (!mounted) return;

      if (result is DataSuccess<AkHotelSearchInitEntity>) {
        final data = result.data!;
        final totalAdults = rooms.fold<int>(0, (s, r) => s + r.adults);
        final totalChildren = rooms.fold<int>(0, (s, r) => s + r.children);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AkHotelResultsScreen(
              searchId: data.searchId,
              searchTracingKey: data.searchTracingKey,
              locationName: location.fullName,
              checkIn: checkInFormatted,
              checkOut: checkOutFormatted,
              adults: totalAdults,
              children: totalChildren,
              nationality: 'IN',
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _searchingIndex = null);
    }
  }

  String _guestSummary(Map<String, dynamic> entry) {
    final roomsRaw = (entry['rooms'] as List?) ?? const [];
    final roomCount = roomsRaw.isEmpty ? 1 : roomsRaw.length;
    final guests = roomsRaw.fold<int>(
      0,
      (s, r) => s + ((r['adults'] as int?) ?? 0) + ((r['children'] as int?) ?? 0),
    );
    final totalGuests = guests == 0 ? 1 : guests;
    return '$roomCount room${roomCount > 1 ? 's' : ''}, $totalGuests Guest${totalGuests > 1 ? 's' : ''}';
  }

  String _dateRangeSummary(Map<String, dynamic> entry) {
    final ci = entry['checkInDate'] != null
        ? DateTime.tryParse(entry['checkInDate'] as String)
        : null;
    final co = entry['checkOutDate'] != null
        ? DateTime.tryParse(entry['checkOutDate'] as String)
        : null;
    if (ci == null || co == null) return '-';
    final sameMonth = ci.month == co.month && ci.year == co.year;
    final start = sameMonth ? DateFormat('d').format(ci) : DateFormat('d MMM').format(ci);
    final end = DateFormat('d MMM yy').format(co);
    return '$start-$end';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: context.fs(24),
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ),
        SizedBox(height: context.h(14)),
        SizedBox(
          // A bit more than the card's natural content height — this app
          // doesn't clamp text scale, so real devices with a larger system
          // font need the slack to avoid a RenderFlex overflow here.
          height: context.h(90),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
            itemCount: _history.length,
            separatorBuilder: (_, __) => SizedBox(width: context.w(12)),
            itemBuilder: (_, index) => _recentSearchCard(index),
          ),
        ),
      ],
    );
  }

  Widget _recentSearchCard(int index) {
    final entry = _history[index];
    final location = entry['location'] as Map;
    final cityName = (location['name'] as String?)?.trim().isNotEmpty == true
        ? location['name'] as String
        : (location['fullName'] as String? ?? '-');
    final isSearching = _searchingIndex == index;

    return GestureDetector(
      onTap: () => _repeatSearch(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(220),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // Keep it subtle
              blurRadius: context.w(12), // Slightly increased for a softer, more modern look
              offset: Offset(
                context.w(2), // Positive X = shadow to the right
                context.h(4), // Positive Y = shadow to the bottom
              ),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'City',
                    style: TextStyle(
                      fontSize: context.fs(8),
                      fontWeight: FontWeight.w700,
                      color: AppColors.AppBlue,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    cityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: context.h(8)),
                  Row(
                    children: [
                      Icon(Icons.hotel, color: AppColors.subhead, size: 12),
                      SizedBox(width: context.w(4)),
                      Flexible(
                        child: Text(
                          _guestSummary(entry),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(9.5),
                            fontWeight: FontWeight.w600,
                            color: AppColors.subhead,
                          ),
                        ),
                      ),
                      SizedBox(width: context.w(7)),
                      Image.asset(
                        'assets/NewIcons/calender.png',
                        width: context.w(11),
                        height: context.w(7.5),
                        color: AppColors.subhead,
                      ),
                      SizedBox(width: context.w(4)),
                      Text(
                        _dateRangeSummary(entry),
                        style: TextStyle(
                          fontSize: context.fs(9.5),
                          fontWeight: FontWeight.w600,
                          color: AppColors.subhead,
                        ),
                      ),
                      SizedBox(width: context.w(24)),
                      if (isSearching)
                        SizedBox(
                          width: context.w(22),
                          height: context.w(22),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.orange),
                          ),
                        )
                      else
                        Container(
                          width: context.w(22),
                          height: context.w(22),
                          decoration: const BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            size: context.w(12),
                            color: AppColors.white,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: context.h(4)),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
