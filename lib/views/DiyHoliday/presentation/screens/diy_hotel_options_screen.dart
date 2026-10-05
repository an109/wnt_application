import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_trip_day_card.dart';
import 'diy_hotel_detail_screen.dart';
import 'diy_hotel_filter_screen.dart';

/// "Change Hotel" for one stay of the trip.
///
/// **GET /trips/{trip_id}/stops/{stop_id}/hotels/** lists the properties,
/// each priced as the difference (`delta`) from the hotel on the package. The
/// customer picks one — optionally a particular room in it, through Change
/// Room — the current-selection card shows what the trip comes to, and
/// UPDATE pins it (**POST /hotels/**) and pops the repriced trip.
class DiyHotelOptionsScreen extends StatefulWidget {
  final DiyTrip trip;
  final DiyStop stop;
  final int rooms;

  const DiyHotelOptionsScreen({
    super.key,
    required this.trip,
    required this.stop,
    this.rooms = 1,
  });

  @override
  State<DiyHotelOptionsScreen> createState() => _DiyHotelOptionsScreenState();
}

/// A hotel the customer has picked but not yet applied.
class _Pending {
  final DiyHotelOption hotel;
  final String hotelRef;
  final DiyRoomOption? room;

  const _Pending(this.hotel, this.hotelRef, this.room);

  /// The room's own difference when one was chosen; the hotel's "from" one
  /// otherwise.
  double get delta => room?.delta ?? hotel.delta;
}

class _DiyHotelOptionsScreenState extends State<DiyHotelOptionsScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();
  final TextEditingController _search = TextEditingController();

  List<DiyHotelOption> _options = const [];
  bool _loading = true;
  String? _error;
  bool _updating = false;

  _Pending? _pending;

  /// Room names chosen through Change Room, by hotel, for the Room Type row.
  final Map<String, String> _roomNames = {};

  DiyHotelFilters _filters = const DiyHotelFilters();

  int get _adults => widget.trip.adults > 0 ? widget.trip.adults : 1;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await _api.getHotelOptions(
        tripId: widget.trip.tripId,
        stopId: widget.stop.stopId,
      );
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ------------------------------------------------------------ the stay

  /// The hotel row on the trip for this stay — its dates and the room on it.
  DiyRow? get _stayRow {
    for (final day in widget.trip.days) {
      for (final row in day.rows) {
        if (row.kind == 'HOTEL' &&
            row.destination.toLowerCase() ==
                widget.stop.destination.toLowerCase()) {
          return row;
        }
      }
    }
    return null;
  }

  String get _dates {
    final row = _stayRow;
    final a = diyParseDate(row?.checkIn ?? '');
    final b = diyParseDate(row?.checkOut ?? '');
    if (a == null || b == null) return '';
    final days = widget.stop.nights + 1;
    return '${DateFormat('EEE dd MMM').format(a)} - '
        '${DateFormat('EEE dd MMM').format(b)} (${days}D)';
  }

  DiyHotelOption? get _current => _options.where((o) => o.isSelected).firstOrNull;

  // -------------------------------------------------------------- actions

  Future<void> _update() async {
    final pending = _pending;
    if (pending == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _updating = true);
    try {
      final trip = await _api.changeHotel(
        tripId: widget.trip.tripId,
        stopId: widget.stop.stopId,
        hotelRef: pending.hotelRef,
        roomRef: pending.room?.roomRef,
        previous: widget.trip,
      );
      if (mounted) Navigator.of(context).pop(trip);
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _pick(DiyHotelOption hotel) {
    if (hotel.isSelected) {
      setState(() => _pending = null);
      return;
    }
    setState(() => _pending = _Pending(hotel, hotel.hotelRef, null));
  }

  Future<void> _changeRoom(DiyHotelOption hotel) async {
    final row = _stayRow;
    final pick = await Navigator.of(context).push<DiyRoomPick>(
      MaterialPageRoute(
        builder: (_) => DiyHotelDetailScreen(
          trip: widget.trip,
          stop: widget.stop,
          hotelRef: hotel.isSelected ? null : hotel.hotelRef,
          hotelName: hotel.name,
          previewImages: [
            if (hotel.heroImage.isNotEmpty) hotel.heroImage,
            ...hotel.images,
          ],
          checkIn: row?.checkIn ?? '',
          checkOut: row?.checkOut ?? '',
          rooms: widget.rooms,
        ),
      ),
    );
    if (pick == null || !mounted) return;
    // A room on the hotel already pinned is applied by the hotel page itself.
    if (pick.trip != null) {
      Navigator.of(context).pop(pick.trip);
      return;
    }
    final room = pick.room;
    if (room == null) return;
    setState(() {
      _roomNames[hotel.hotelRef] = room.name;
      _pending = _Pending(hotel, pick.hotelRef, room);
    });
  }

  Future<void> _openFilters() async {
    final deltas = _options.map((o) => o.delta / _adults).toList()..sort();
    final locations = _rank(_options.map(_locality));
    final amenities = _rank(_options.expand((o) => o.facilities));
    final result = await Navigator.of(context).push<DiyHotelFilters>(
      MaterialPageRoute(
        builder: (_) => DiyHotelFilterScreen(
          initial: _filters,
          priceMin: deltas.isEmpty ? 0 : deltas.first.floorToDouble(),
          priceMax: deltas.isEmpty ? 0 : deltas.last.ceilToDouble(),
          locations: locations,
          amenities: amenities,
        ),
      ),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  /// Distinct values, most common first.
  static List<String> _rank(Iterable<String> values) {
    final counts = <String, int>{};
    for (final v in values) {
      if (v.trim().isEmpty) continue;
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final keys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return keys;
  }

  /// "Vagator" out of "Vagator, North Goa, Goa".
  static String _locality(DiyHotelOption o) => o.location.split(',').first.trim();

  List<DiyHotelOption> get _visible {
    final query = _search.text.trim().toLowerCase();
    final f = _filters;
    final list = _options.where((o) {
      if (o.isSelected) return true;
      if (query.isNotEmpty &&
          !o.name.toLowerCase().contains(query) &&
          !o.location.toLowerCase().contains(query)) {
        return false;
      }
      if (f.maxPerPerson != null && o.delta / _adults > f.maxPerPerson!) {
        return false;
      }
      final stars = (double.tryParse(o.starRating) ?? 0).round();
      if (f.stars.isNotEmpty && !f.stars.contains(stars)) return false;
      if (f.locations.isNotEmpty && !f.locations.contains(_locality(o))) {
        return false;
      }
      if (f.amenities.isNotEmpty &&
          !f.amenities.every((a) => o.facilities.contains(a))) {
        return false;
      }
      return true;
    }).toList();

    double rating(DiyHotelOption o) => double.tryParse(o.reviewRating) ?? 0;
    list.sort(switch (f.sort) {
      DiyHotelSort.popularity => (a, b) {
          final byRating = rating(b).compareTo(rating(a));
          return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
        },
      DiyHotelSort.priceLow => (a, b) => a.delta.compareTo(b.delta),
      DiyHotelSort.priceHigh => (a, b) => b.delta.compareTo(a.delta),
    });
    // The hotel on the package leads — it is what everything is compared to.
    final current = _current;
    if (current != null && list.remove(current)) list.insert(0, current);
    return list;
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final date = diyParseDate(trip.departureDate);
    final party = [
      '${trip.adults} Adult${trip.adults == 1 ? '' : 's'}',
      if (trip.children > 0)
        '${trip.children} Child${trip.children == 1 ? '' : 'ren'}',
    ].join(', ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: context.w(24)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              [
                if (date != null) DateFormat('MMM dd').format(date),
                party,
              ].join(', '),
              style: TextStyle(fontSize: context.fs(10), color: DiyTripStyle.grey),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _options.isEmpty ? null : _sortFilterPill(),
      body: _loading
          ? const DiyLoading(message: 'Finding hotels for your dates…')
          : _error != null
              ? DiyErrorView(message: _error!, onRetry: _load)
              : _content(),
    );
  }

  Widget _content() {
    final hotels = _visible;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(24),
        context.w(16),
        context.h(96),
      ),
      children: [
        _currentCard(),
        SizedBox(height: context.h(18)),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search_rounded,
                size: context.w(20), color: DiyTripStyle.grey),
            hintText: 'Search by hotel name, landmark or beach…',
            hintStyle:
                TextStyle(fontSize: context.fs(11), color: DiyTripStyle.grey),
            contentPadding: EdgeInsets.symmetric(vertical: context.h(12)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(8)),
              borderSide: const BorderSide(color: DiyTripStyle.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(8)),
              borderSide: const BorderSide(color: DiyTripStyle.border),
            ),
          ),
        ),
        SizedBox(height: context.h(18)),
        if (hotels.length <= 1)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(12)),
            child: Text(
              'No other hotels match. Try clearing the search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.fs(12), color: DiyTripStyle.grey),
            ),
          ),
        for (final hotel in hotels)
          Padding(
            padding: EdgeInsets.only(bottom: context.h(18)),
            child: _hotelCard(hotel),
          ),
      ],
    );
  }

  // ------------------------------------------------------- current card

  Widget _currentCard() {
    final pending = _pending;
    final shown = pending?.hotel ?? _current;
    final row = _stayRow;
    final image = shown?.heroImage.isNotEmpty == true
        ? shown!.heroImage
        : (row?.heroImage ?? '');
    final name = shown?.name ?? row?.hotelName ?? '';
    final location = shown?.location ?? row?.location ?? '';
    final rating = shown?.reviewRating ?? row?.reviewRating ?? '';
    final perPerson =
        (widget.trip.grandTotal + (pending?.delta ?? 0)) / _adults;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(context.w(14)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(12)),
            gradient: const LinearGradient(
              colors: [Color(0xFFBFE6F8), Color(0xFFEFF9FE)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: context.w(6),
                    height: context.w(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5484D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: context.w(6)),
                  Text(
                    '${pending == null ? 'CURRENT SELECTION' : 'NEW SELECTION'}'
                    ' • ${widget.stop.nights} NIGHTS STAY',
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: DiyTokens.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(10)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      DiyImage(
                        url: image,
                        width: context.w(70),
                        height: context.w(70),
                        radius: BorderRadius.circular(context.r(8)),
                      ),
                      if (rating.isNotEmpty)
                        Positioned(
                          right: context.w(4),
                          bottom: context.w(4),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(4),
                              vertical: context.h(1),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(context.r(4)),
                            ),
                            child: Text(
                              '$rating ★',
                              style: TextStyle(
                                fontSize: context.fs(8),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(14),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        if (location.isNotEmpty)
                          _meta(Icons.location_on_rounded, location),
                        if (_dates.isNotEmpty)
                          _meta(Icons.calendar_month_rounded, _dates),
                        SizedBox(height: context.h(6)),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (pending == null)
                                    Text(
                                      'Package Base Cost:',
                                      style: TextStyle(
                                        fontSize: context.fs(9),
                                        color: DiyTripStyle.grey,
                                      ),
                                    ),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: diyMoney(perPerson,
                                              currency: widget.trip.currency),
                                          style: TextStyle(
                                            fontSize: context.fs(16),
                                            fontWeight: FontWeight.w700,
                                            color: DiyTokens.blue,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '/person',
                                          style: TextStyle(
                                            fontSize: context.fs(10),
                                            color: DiyTripStyle.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (pending != null)
                              SizedBox(
                                width: context.w(96),
                                height: context.h(36),
                                child: ElevatedButton(
                                  onPressed: _updating ? null : _update,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: DiyTripStyle.orange,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(context.r(6)),
                                    ),
                                  ),
                                  child: _updating
                                      ? SizedBox(
                                          width: context.w(16),
                                          height: context.w(16),
                                          child:
                                              const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'UPDATE',
                                          style: TextStyle(
                                            fontSize: context.fs(13),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (pending == null)
          Positioned(
            right: context.w(8),
            top: -context.h(10),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(3),
              ),
              decoration: BoxDecoration(
                color: DiyTokens.blue,
                borderRadius: BorderRadius.circular(context.r(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded,
                      size: context.w(11), color: Colors.white),
                  SizedBox(width: context.w(3)),
                  Text(
                    'SELECTED',
                    style: TextStyle(
                      fontSize: context.fs(9),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _meta(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(top: context.h(3)),
      child: Row(
        children: [
          Icon(icon, size: context.w(10), color: DiyTripStyle.grey),
          SizedBox(width: context.w(4)),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: context.fs(9), color: DiyTripStyle.grey),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- hotel card

  Widget _hotelCard(DiyHotelOption o) {
    final pickedHere = _pending?.hotel == o;
    final selected = pickedHere || (_pending == null && o.isSelected);
    final stars = (double.tryParse(o.starRating) ?? 0).round().clamp(0, 5);
    final image = o.heroImage.isNotEmpty
        ? o.heroImage
        : (o.images.isNotEmpty ? o.images.first : '');
    final locality = [
      _locality(o),
      if (o.distanceKm.isNotEmpty) '${o.distanceKm} km away',
    ].join(' • ');
    final room = _roomNames[o.hotelRef] ??
        (o.isSelected ? _stayRow?.roomName ?? '' : '');
    final delta = pickedHere && _pending?.room != null
        ? _pending!.delta
        : o.delta;

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: selected ? DiyTokens.blue : DiyTripStyle.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              DiyImage(
                url: image,
                width: double.infinity,
                height: context.h(150),
                radius: BorderRadius.circular(context.r(10)),
              ),
              if (o.freeBreakfast)
                Positioned(
                  left: context.w(8),
                  top: context.h(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(8),
                      vertical: context.h(4),
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE5484D), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(context.r(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_rounded,
                            size: context.w(11), color: Colors.white),
                        SizedBox(width: context.w(4)),
                        Text(
                          'Free Breakfast',
                          style: TextStyle(
                            fontSize: context.fs(9),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Text(
            o.name,
            style: TextStyle(
              fontSize: context.fs(15),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (locality.isNotEmpty) _meta(Icons.location_on_rounded, locality),
          if (_dates.isNotEmpty) _meta(Icons.calendar_month_rounded, _dates),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              for (var i = 0; i < stars; i++)
                Padding(
                  padding: EdgeInsets.only(right: context.w(2)),
                  child: SvgPicture.asset(DiyTripStyle.star,
                      width: context.w(16), height: context.w(16)),
                ),
              if (o.reviewRating.isNotEmpty)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: ' ${o.reviewRating}',
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      if (o.reviewCount > 0)
                        TextSpan(
                          text: '(${o.reviewCount})',
                          style: TextStyle(
                            fontSize: context.fs(8),
                            color: DiyTripStyle.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                '${widget.stop.nights}N ${widget.stop.destination}',
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(10),
              vertical: context.h(8),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Room Type: ',
                          style: TextStyle(
                            fontSize: context.fs(9),
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: room.isNotEmpty
                              ? room.toUpperCase()
                              : 'BEST AVAILABLE',
                          style: TextStyle(
                            fontSize: context.fs(9),
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _changeRoom(o),
                  child: Text(
                    'Change Room',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: DiyTokens.blue,
                      decoration: TextDecoration.underline,
                      decorationColor: DiyTokens.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(12)),
          if (selected && !pickedHere)
            SizedBox(
              width: double.infinity,
              height: context.h(40),
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: DiyTripStyle.orange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(6)),
                  ),
                ),
                child: Text(
                  'SELECTED',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(context.w(12)),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade Difference',
                          style: TextStyle(
                            fontSize: context.fs(9),
                            color: DiyTripStyle.grey,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: diyDelta(delta / _adults,
                                    currency: widget.trip.currency),
                                style: TextStyle(
                                  fontSize: context.fs(16),
                                  fontWeight: FontWeight.w700,
                                  color: DiyTokens.blue,
                                ),
                              ),
                              TextSpan(
                                text: '/person',
                                style: TextStyle(
                                  fontSize: context.fs(10),
                                  color: DiyTripStyle.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: context.w(100),
                    height: context.h(38),
                    child: pickedHere
                        ? ElevatedButton(
                            onPressed: () => _pick(_current ?? o),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DiyTripStyle.orange,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(context.r(6)),
                              ),
                            ),
                            child: Text(
                              'SELECTED',
                              style: TextStyle(
                                fontSize: context.fs(12),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () => _pick(o),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: DiyTripStyle.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(context.r(6)),
                              ),
                            ),
                            child: Text(
                              'SELECT',
                              style: TextStyle(
                                fontSize: context.fs(13),
                                fontWeight: FontWeight.w600,
                                color: DiyTripStyle.orange,
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

  // ---------------------------------------------------------- sort/filter

  Widget _sortFilterPill() {
    Widget half(IconData icon, String label, VoidCallback onTap, bool dot) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.r(30)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(26),
            vertical: context.h(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: context.w(17), color: Colors.black),
              SizedBox(width: context.w(8)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              if (dot) ...[
                SizedBox(width: context.w(5)),
                Container(
                  width: context.w(6),
                  height: context.w(6),
                  decoration: const BoxDecoration(
                    color: DiyTripStyle.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(context.r(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          half(Icons.swap_vert_rounded, 'Sort', _openFilters, false),
          Container(
              width: 1, height: context.h(22), color: DiyTripStyle.divider),
          half(Icons.tune_rounded, 'Filter', _openFilters, _filters.isActive),
        ],
      ),
    );
  }
}
