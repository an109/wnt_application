import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_remove_flight_dialog.dart';
import '../widgets/diy_share_sheet.dart';
import '../widgets/diy_trip_day_card.dart';
import '../widgets/diy_trip_summary.dart';
import 'diy_addons_screen.dart';
import 'diy_review_screen.dart';
import 'diy_flight_details_screen.dart';
import 'diy_add_activity_screen.dart';
import 'diy_flight_options_screen.dart';
import 'diy_modify_booking_screen.dart';
import 'diy_policies_screen.dart';
import 'diy_hotel_detail_screen.dart';
import 'diy_transfer_screen.dart';
import 'diy_hotel_options_screen.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

/// The customer's live trip — **API 6: GET /trips/{trip_id}/** — and the hub
/// for every customisation:
///
///  * flight   → API 7/8  ([DiyFlightOptionsScreen])
///  * hotel    → API 9/10 ([DiyHotelOptionsScreen], one per `stops[].stop_id`)
///  * add-ons  → API 12/13 ([DiyTripAddonsScreen])
///  * cab      → GET/POST /cab/ ([DiyTransferScreen]) — which is also how
///               transfers change, since they are derived from the cab.
///
/// Every one of those calls answers with the whole trip and a fresh
/// `grand_total`, so this screen simply swaps in whatever came back instead
/// of re-pricing.
class DiyTripScreen extends StatefulWidget {
  final DiyTrip trip;
  final DiySearchQuery query;
  final String shareId;
  final List<DiyAddon> addons;
  final List<String> preselectedAddonIds;

  /// The package was saved with flights but this trip was priced without
  /// them — VIEW TRANSPORT OPTION can put them back.
  final bool canAddFlights;

  const DiyTripScreen({
    super.key,
    required this.trip,
    required this.query,
    required this.shareId,
    this.addons = const [],
    this.preselectedAddonIds = const [],
    this.canAddFlights = false,
  });

  @override
  State<DiyTripScreen> createState() => _DiyTripScreenState();
}

class _DiyTripScreenState extends State<DiyTripScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();

  late DiyTrip _trip = widget.trip;

  /// The search the trip was priced on. MODIFY can change it, so the screen
  /// keeps its own copy rather than reading [_query].
  late DiySearchQuery _query = widget.query;

  /// What the customer changed on this trip, newest last — the "View N
  /// Customization" pill and its sheet.
  final List<_Change> _changes = [];

  void _record(
    String label,
    IconData icon, {
    String? addonId,
    double? perPerson,
    bool? flightOutbound,
    String? cabCode,
  }) => _changes.add(
    _Change(
      label,
      icon,
      addonId: addonId,
      perPerson: perPerson,
      flightOutbound: flightOutbound,
      cabCode: cabCode,
    ),
  );

  /// Swaps in a repriced trip and records the change with what it did to the
  /// per-person price — unknown when either side could not be priced. A
  /// removal carries what it takes to restore it.
  void _applyChange(
    DiyTrip trip,
    String label,
    IconData icon, {
    bool? flightOutbound,
    String? cabCode,
  }) {
    final adults = trip.adults > 0 ? trip.adults : 1;
    final before = _trip.grandTotal;
    final after = trip.grandTotal;
    setState(() {
      _trip = trip;
      _record(
        label,
        icon,
        perPerson: before > 0 && after > 0 ? (after - before) / adults : null,
        flightOutbound: flightOutbound,
        cabCode: cabCode,
      );
    });
  }

  /// ↻ on a customization — puts back what it took off, and drops it from
  /// the list.
  Future<void> _restore(_Change change) async {
    setState(() => _busy = true);
    try {
      DiyTrip? trip;
      if (change.addonId != null) {
        await _removeAddon(change.addonId!);
        return;
      } else if (change.flightOutbound != null) {
        trip = await _api.restoreFlight(
          tripId: _trip.tripId,
          outbound: change.flightOutbound!,
          previous: _trip,
        );
      } else if (change.cabCode != null) {
        trip = await _api.changeCab(
          tripId: _trip.tripId,
          code: change.cabCode!,
          previous: _trip,
        );
      }
      if (trip == null || !mounted) return;
      setState(() {
        _trip = trip!;
        _changes.remove(change);
      });
      diySnack(context, 'Restored${_totalSuffix(trip)}');
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  late List<DiyAddon> _addons = widget.addons;

  /// addon id → trip-activity id, filled as add-ons are added in this
  /// session. The trip's own ACTIVITY rows carry no id, so only add-ons
  /// added here can be removed again (API 13 needs that id).
  final Map<String, String> _addedActivityIds = {};

  bool _busy = false;

  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _dayKeys = {};
  DiyDayFilter _filter = DiyDayFilter.all;
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    // POST /price/ (API 5) answers without `stops[]`; the stop ids needed to
    // browse or change a hotel only come from GET /trips/{id}/ (API 6), so
    // hydrate once before the hotel actions are used.
    if (widget.trip.stops.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
    if (_addons.isEmpty) _loadAddons();
    // Add-ons ticked on the package screen were only ever a price probe
    // (API 14); apply them to the real trip now that one exists.
    if (widget.preselectedAddonIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyPreselectedAddons(),
      );
    }
  }

  Future<void> _loadAddons() async {
    try {
      final addons = await _api.getAddons(widget.shareId);
      if (mounted) setState(() => _addons = addons);
    } catch (_) {
      // Non-fatal: the trip is still fully usable without the add-on list.
    }
  }

  Future<void> _applyPreselectedAddons() async {
    setState(() => _busy = true);
    for (final addonId in widget.preselectedAddonIds) {
      if (_addedActivityIds.containsKey(addonId)) continue;
      final day = _dayForAddon(addonId);
      try {
        final result = await _api.addActivity(
          tripId: _trip.tripId,
          activityId: addonId,
          day: day,
          previous: _trip,
        );
        if (!mounted) return;
        setState(() {
          _addedActivityIds[addonId] = result.id;
          _trip = result.trip;
        });
      } catch (e) {
        if (mounted) diySnack(context, e.toString(), isError: true);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  /// Best day for an add-on: the first day in the add-on's own destination,
  /// otherwise day 1.
  int _dayForAddon(String addonId) {
    final addon = _addons.where((a) => a.id == addonId).firstOrNull;
    if (addon == null || addon.destination.isEmpty) return 1;
    for (final day in _trip.days) {
      if (day.destination.toLowerCase() == addon.destination.toLowerCase()) {
        return day.day;
      }
    }
    return 1;
  }

  /// A change can leave the trip unpriceable — e.g. picking a cab class with
  /// no vendor rate for those dates comes back with `incomplete` set and no
  /// `grand_total`. Showing ₹0 would read as "free", so the total and the
  /// PROCEED button both go quiet until it prices again.
  bool get _isPriced => _trip.grandTotal > 0;

  String _totalSuffix(DiyTrip trip) => trip.grandTotal > 0
      ? ' · new total ${diyMoney(trip.grandTotal, currency: trip.currency)}'
      : '';

  Future<void> _refresh() async {
    try {
      final trip = await _api.getTrip(_trip.tripId);
      if (mounted) setState(() => _trip = trip);
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    }
  }

  // --------------------------------------------------------- navigation

  Future<void> _changeFlight(bool outbound) async {
    final trip = await Navigator.of(context).push<DiyTrip>(
      MaterialPageRoute(
        builder: (_) => DiyFlightOptionsScreen(trip: _trip, outbound: outbound),
      ),
    );
    if (trip != null && mounted) {
      _applyChange(trip, 'Flight Changed', Icons.flight_rounded);
      diySnack(context, 'Flight updated${_totalSuffix(trip)}');
    }
  }

  /// Remove — drops the leg after asking, and swaps in the repriced trip.
  /// The customer then makes their own way for that leg.
  Future<void> _removeFlight(bool outbound) async {
    final ok = await showDiyRemoveFlightDialog(context, outbound: outbound);
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final trip = await _api.removeFlight(
        tripId: _trip.tripId,
        outbound: outbound,
        previous: _trip,
      );
      if (!mounted) return;
      _applyChange(
        trip,
        'Flight Removed',
        Icons.airplanemode_inactive_rounded,
        flightOutbound: outbound,
      );
      diySnack(context, 'Flight removed${_totalSuffix(trip)}');
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeHotel(DiyStop stop) async {
    final trip = await Navigator.of(context).push<DiyTrip>(
      MaterialPageRoute(
        builder: (_) =>
            DiyHotelOptionsScreen(trip: _trip, stop: stop, rooms: _query.rooms),
      ),
    );
    if (trip != null && mounted) {
      _applyChange(trip, 'Hotel Changed', Icons.hotel_rounded);
      diySnack(context, 'Hotel updated${_totalSuffix(trip)}');
    }
  }

  /// Itinerary hotel rows only know their destination name — map it back to
  /// the matching `stop_id`.
  void _changeHotelByDestination(String destination) {
    final stop = _trip.stops
        .where((s) => s.destination.toLowerCase() == destination.toLowerCase())
        .firstOrNull;
    if (stop == null) {
      diySnack(context, 'No hotel stop found for $destination', isError: true);
      return;
    }
    _changeHotel(stop);
  }

  /// VIEW TRANSPORT OPTION — price the trip again with flights, live from the
  /// customer's own city on their date, then open Change Flight on it.
  Future<void> _addFlights() async {
    final date = _query.departureDate ?? diyParseDate(_trip.departureDate);
    if (date == null) {
      diySnack(context, 'Pick a starting date first', isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final trip = await _api.priceForDates(
        shareId: _trip.shareId.isNotEmpty ? _trip.shareId : widget.shareId,
        departureDate: date,
        adults: _query.adults,
        children: _query.children,
        rooms: _query.roomsPayload,
        origin: _query.origin.slug,
        withFlight: true,
      );
      if (!mounted) return;
      _addedActivityIds.clear();
      _applyChange(trip, 'Flights Added', Icons.flight_takeoff_rounded);
      diySnack(context, 'Flights added${_totalSuffix(trip)}');
      if (trip.stops.isEmpty) await _refresh();
      if (mounted && _trip.flightIncluded) await _changeFlight(true);
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// MODIFY — "Select Booking Details": city, start date, rooms and guests.
  /// The package is priced again on them and the new trip replaces this one;
  /// add-ons picked on the old trip do not carry over.
  Future<void> _modify() async {
    final result = await Navigator.of(context).push<DiyModifiedBooking>(
      MaterialPageRoute(
        builder: (_) => DiyModifyBookingScreen(
          query: _query,
          shareId: _trip.shareId.isNotEmpty ? _trip.shareId : widget.shareId,
          withFlight: _trip.flightIncluded,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _query = result.query;
      _trip = result.trip;
      _addedActivityIds.clear();
      _changes.clear();
      _selectedDay = 1;
      _filter = DiyDayFilter.all;
    });
    diySnack(context, 'Trip updated${_totalSuffix(result.trip)}');
    // POST /price/ answers without the stops the hotel actions need.
    if (result.trip.stops.isEmpty) await _refresh();
  }

  /// ADD TO DAY — activities and transfer add-ons for that one day.
  Future<void> _addToDay(int dayNumber) async {
    final day = _trip.days.firstWhere(
      (d) => d.day == dayNumber,
      orElse: () => _trip.days.first,
    );
    final result = await Navigator.of(context).push<DiyTripAddonsResult>(
      MaterialPageRoute(
        builder: (_) => DiyAddActivityScreen(
          trip: _trip,
          day: day,
          shareId: _trip.shareId.isNotEmpty ? _trip.shareId : widget.shareId,
          addons: _addons,
          addedIds: _addedActivityIds,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final before = Set<String>.from(_addedActivityIds.keys);
    setState(() {
      _addedActivityIds
        ..clear()
        ..addAll(result.addedIds);
      if (result.trip != null) _trip = result.trip!;
      for (final id in result.addedIds.keys.where((k) => !before.contains(k))) {
        final addon = _addons.where((a) => a.id == id).firstOrNull;
        final adults = _trip.adults > 0 ? _trip.adults : 1;
        final pax = _trip.adults + _trip.children;
        _record(
          addon == null ? 'Activity Added' : 'Activity Added · ${addon.name}',
          Icons.hiking_rounded,
          addonId: id,
          perPerson: addon == null ? null : addon.pricePerPerson * pax / adults,
        );
      }
    });
    if (result.trip != null) {
      diySnack(context, 'Added to Day $dayNumber${_totalSuffix(_trip)}');
    }
  }

  Future<void> _removeActivityRow(DiyRow row) async {
    // API 13 needs the trip-activity id, which only exists for add-ons this
    // session added; anything that shipped with the package has no handle.
    final entry = _addedActivityIds.entries
        .where(
          (e) =>
              e.value.isNotEmpty &&
              _addons
                  .where((a) => a.id == e.key)
                  .any((a) => a.name.toLowerCase() == row.title.toLowerCase()),
        )
        .firstOrNull;
    if (entry == null) {
      // Either it shipped with the package, or it was added through API 12
      // and the backend returned no trip-activity id to delete it with.
      diySnack(
        context,
        'This activity cannot be removed from the app — a consultant can '
        'take it off for you.',
        isError: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _api.removeActivity(
        tripId: _trip.tripId,
        tripActivityId: entry.value,
      );
      _addedActivityIds.remove(entry.key);
      _changes.removeWhere((c) => c.addonId == entry.key);
      await _refresh();
      if (mounted) diySnack(context, 'Activity removed');
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// BOOK NOW — hands the finished trip to the Figma review screen, which
  /// collects travellers and then takes payment. The enquiry-only path is
  /// still reachable from there via "Talk to a consultant instead".
  void _proceed() {
    final date =
        _query.departureDate ??
        DateTime.tryParse(_trip.departureDate) ??
        DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyReviewScreen(
          shareId: _trip.shareId.isNotEmpty ? _trip.shareId : widget.shareId,
          query: _query.copyWith(departureDate: date),
          withFlight: _trip.flightIncluded,
          addOnIds: _addedActivityIds.keys.toList(),
          quotedTotal: _trip.grandTotal,
          currency: _trip.currency,
          packageTitle: _trip.title,
          tripId: _trip.tripId,
          counts: _trip.counts,
          // The trip reports days; the Figma header talks in nights.
          nights: _trip.counts.days > 0 ? _trip.counts.days - 1 : 0,
          destination: _query.destination?.name ?? '',
          subTotal: _trip.subTotal,
          tax: _trip.tax,
          taxPercent: _trip.taxPercent,
        ),
      ),
    );
  }

  // -------------------------------------------------------------- build
  //
  // Laid out as the Figma "Holiday card view": header, photo gallery, the
  // nights/customisable tags, the travellers strip, then the itinerary — day
  // pills and date selector over one card per day — the summary timeline,
  // and the per-person price with BOOK NOW.

  int get _nights {
    final fromStops = _trip.stops.fold<int>(0, (sum, s) => sum + s.nights);
    if (fromStops > 0) return fromStops;
    return _trip.days.length > 1 ? _trip.days.length - 1 : 0;
  }

  /// "Super Saver Goa (3N Goa)" — the stay in brackets when there is one.
  String get _headerTitle {
    final places = _trip.stops.map((s) => s.destination).toSet();
    final stay = places.length == 1 ? ' ${places.first}' : '';
    return _nights > 0 ? '${_trip.title} (${_nights}N$stay)' : _trip.title;
  }

  /// Every photo the trip has, hotels first — the gallery and its viewer.
  List<String> get _photos {
    final out = <String>[];
    void add(String url) {
      if (url.isNotEmpty && !out.contains(url)) out.add(url);
    }

    for (final day in _trip.days) {
      for (final row in day.rows) {
        if (row.kind == 'HOTEL') {
          add(row.heroImage);
          row.images.forEach(add);
        }
      }
    }
    for (final day in _trip.days) {
      for (final row in day.rows) {
        for (final poi in row.pois) {
          add(poi.image);
        }
        if (row.kind == 'ACTIVITY') row.images.forEach(add);
      }
    }
    return out;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToDay(int day) {
    setState(() => _selectedDay = day);
    final target = _dayKeys[day]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    }
  }

  void _share() {
    final perAdult = _trip.adults > 0 ? _trip.grandTotal / _trip.adults : 0;
    showDiyShareSheet(
      context,
      text:
          '${_trip.title} — '
          '${_isPriced ? '${diyMoney(perAdult, currency: _trip.currency)} per person' : 'price on request'}'
          '${_trip.flightIncluded ? ' with flights from ${_trip.origin}' : ''}. '
          'Check it out on Wander Nova!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _trip.days;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: DiyTokens.blue,
                    child: ListView(
                      controller: _scroll,
                      padding: EdgeInsets.only(bottom: context.h(24)),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: context.h(12)),
                              _gallery(),
                              SizedBox(height: context.h(24)),
                              _tags(),
                              SizedBox(height: context.h(16)),
                              _travellersStrip(),
                              if (_trip.incomplete.isNotEmpty) ...[
                                SizedBox(height: context.h(12)),
                                _incompleteBanner(),
                              ],
                              if (_trip.notes.isNotEmpty) ...[
                                SizedBox(height: context.h(12)),
                                _hotelNotesBanner(),
                              ],
                              SizedBox(height: context.h(24)),
                              _itineraryHeading(),
                            ],
                          ),
                        ),
                        SizedBox(height: context.h(12)),
                        _dayNavigator(),
                        SizedBox(height: context.h(22)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < days.length; i++)
                                KeyedSubtree(
                                  key: _dayKeys.putIfAbsent(
                                    days[i].day,
                                    () => GlobalKey(),
                                  ),
                                  child: DiyTripDayCard(
                                    day: days[i],
                                    isFirstDay: i == 0,
                                    isLastDay: i == days.length - 1,
                                    filter: _filter,
                                    cab: _trip.cab,
                                    adults: _trip.adults,
                                    children: _trip.children,
                                    rooms: _query.rooms,
                                    flightIncluded: _trip.flightIncluded,
                                    onChangeFlight: _changeFlight,
                                    onRemoveFlight: _removeFlight,
                                    onViewTransport:
                                        widget.canAddFlights &&
                                            !_trip.flightIncluded
                                        ? _addFlights
                                        : null,
                                    onFlightDetails: _flightDetails,
                                    onModifyTransfer: (row) =>
                                        _openTransfer(row, modify: true),
                                    onTransferDetails: _openTransfer,
                                    onRemoveTransfer: _removeTransfer,
                                    onChangeHotel: _changeHotelByDestination,
                                    onHotelDetails: _hotelDetails,
                                    onRemoveActivity: _removeActivityRow,
                                    onAddActivity: _addToDay,
                                  ),
                                ),
                              DiyTripSummary(days: days, stops: _trip.stops),
                              SizedBox(height: context.h(12)),
                              _policyLink(
                                'Terms & Conditions',
                                DiyPolicyPage.terms,
                              ),
                              _policyLink('Policies', DiyPolicyPage.policies),
                              SizedBox(height: context.h(48)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_changes.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: context.h(12),
              child: Center(child: _customizationPill()),
            ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.06),
                child: const Center(child: AppLoadingCard(message: 'Updating your trip…')),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(14),
        context.w(16),
        context.h(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            // The design's arrow is drawn pointing up and turned to face back.
            child: Transform.rotate(
              angle: -1.5708,
              child: SvgPicture.asset(
                DiyTripStyle.back,
                width: context.w(24),
                height: context.w(24),
              ),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Text(
              _headerTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(width: context.w(12)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _share,
            child: SvgPicture.asset(
              DiyTripStyle.share,
              width: context.w(20),
              height: context.w(20),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- gallery

  Widget _gallery() {
    final photos = _photos;
    String at(int i) => i < photos.length ? photos[i] : '';
    final radius = BorderRadius.circular(context.r(10));

    Widget tile(int index, double height, {bool label = false}) {
      return GestureDetector(
        onTap: photos.isEmpty ? null : () => _openPhotos(index),
        child: Stack(
          children: [
            DiyImage(
              url: at(index),
              width: double.infinity,
              height: height,
              radius: radius,
            ),
            if (label)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        DiyTripStyle.photo,
                        width: context.w(18),
                        height: context.w(18),
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        'Property photos',
                        style: TextStyle(
                          fontSize: context.fs(11),
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
      );
    }

    return SizedBox(
      height: context.h(209),
      child: Row(
        children: [
          Expanded(flex: 180, child: tile(0, context.h(209))),
          SizedBox(width: context.w(12)),
          Expanded(
            flex: 188,
            child: Column(
              children: [
                tile(1, context.h(99)),
                SizedBox(height: context.h(11)),
                tile(2, context.h(99), label: photos.length > 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPhotos(int initial) {
    final photos = _photos;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: initial),
            itemCount: photos.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: DiyImage(url: photos[i], fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(dialogContext).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ tags/strip

  Widget _tags() {
    Widget chip(String text, Color color) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.r(4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(12),
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    return Row(
      children: [
        if (_nights > 0) ...[
          chip('${_nights}N/${_nights + 1}D', DiyTripStyle.orange),
          SizedBox(width: context.w(8)),
        ],
        chip('Customizable', DiyTripStyle.green),
      ],
    );
  }

  /// "New Delhi • 3 Travellers / 9 Oct - 12 Oct (4 Days)" with MODIFY, which
  /// opens "Select Booking Details" and prices the trip again.
  Widget _travellersStrip() {
    final travellers = _trip.adults + _trip.children;
    final start = diyParseDate(_trip.departureDate) ?? _query.departureDate;
    final days = _trip.days.isNotEmpty ? _trip.days.length : _nights + 1;
    final end = start?.add(Duration(days: days > 0 ? days - 1 : 0));
    String fmt(DateTime d) => DateFormat('d MMM').format(d);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12.5),
        vertical: context.h(8.5),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: DiyTripStyle.border, width: 0.5),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            DiyTripStyle.people,
            width: context.w(16),
            height: context.w(16),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_trip.origin} • $travellers Traveller${travellers == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (start != null && end != null)
                  Text(
                    '${fmt(start)} - ${fmt(end)} ($days Day${days == 1 ? '' : 's'})',
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w500,
                      color: DiyTripStyle.grey,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _modify,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(4),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.r(4)),
                border: Border.all(color: DiyTokens.blue),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MODIFY',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: DiyTokens.blue,
                    ),
                  ),
                  SizedBox(width: context.w(4)),
                  Icon(
                    Icons.edit_rounded,
                    size: context.w(14),
                    color: DiyTokens.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- itinerary

  Widget _itineraryHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Itinerary',
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        Text(
          'Day Wise Details of your package',
          style: TextStyle(
            fontSize: context.fs(11),
            fontWeight: FontWeight.w500,
            color: DiyTripStyle.grey,
          ),
        ),
      ],
    );
  }

  /// The light-blue band: "Day Plan / 2 Transfers / 1 Hotels / 3 Meals"
  /// filter pills, and a date button per day that scrolls to it.
  Widget _dayNavigator() {
    final counts = _trip.counts;
    Widget pill(String label, DiyDayFilter filter) {
      final selected = _filter == filter;
      return Padding(
        padding: EdgeInsets.only(right: context.w(6)),
        child: GestureDetector(
          onTap: () => setState(() => _filter = filter),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(5),
            ),
            decoration: BoxDecoration(
              color: selected ? DiyTokens.blue : Colors.white,
              borderRadius: BorderRadius.circular(context.r(20)),
              border: Border.all(
                color: selected ? DiyTokens.blue : DiyTripStyle.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : DiyTripStyle.grey,
              ),
            ),
          ),
        ),
      );
    }

    Widget dateButton(DiyDay day) {
      final selected = _selectedDay == day.day;
      final d = diyParseDate(day.date);
      final fg = selected ? Colors.white : Colors.black;
      return Padding(
        padding: EdgeInsets.only(right: context.w(8)),
        child: GestureDetector(
          onTap: () => _jumpToDay(day.day),
          child: Container(
            width: context.w(62),
            padding: EdgeInsets.symmetric(vertical: context.h(9)),
            decoration: BoxDecoration(
              color: selected ? DiyTripStyle.orange : Colors.white,
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(
                color: selected ? DiyTripStyle.orange : DiyTripStyle.border,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  d == null ? '' : DateFormat('EEE, MMM').format(d),
                  style: TextStyle(fontSize: context.fs(10), color: fg),
                ),
                Text(
                  d == null ? '${day.day}' : '${d.day}',
                  style: TextStyle(
                    fontSize: context.fs(18),
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                Text(
                  'DAY ${day.day}',
                  style: TextStyle(
                    fontSize: context.fs(8),
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : DiyTripStyle.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFE6F6FD),
      padding: EdgeInsets.symmetric(vertical: context.h(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            child: Row(
              children: [
                pill('Day Plan', DiyDayFilter.all),
                if (counts.transfers > 0)
                  pill(
                    '${counts.transfers} Transfer${counts.transfers == 1 ? '' : 's'}',
                    DiyDayFilter.transfers,
                  ),
                if (counts.hotels > 0)
                  pill(
                    '${counts.hotels} Hotel${counts.hotels == 1 ? '' : 's'}',
                    DiyDayFilter.hotels,
                  ),
                if (counts.meals > 0)
                  pill(
                    '${counts.meals} Meal${counts.meals == 1 ? '' : 's'}',
                    DiyDayFilter.meals,
                  ),
              ],
            ),
          ),
          SizedBox(height: context.h(12)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            child: Row(
              children: [for (final day in _trip.days) dateButton(day)],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- detail sheets

  /// View Details — the leg in full, with Remove | Change on top.
  Future<void> _flightDetails(DiyRow f) async {
    final days = _trip.days;
    final dayIndex = days.indexWhere((d) => d.rows.contains(f));
    final outbound = dayIndex <= 0;
    final flights = dayIndex < 0
        ? [f]
        : days[dayIndex].rows.where((r) => r.kind == 'FLIGHT').toList();

    final action = await Navigator.of(context).push<DiyFlightAction>(
      MaterialPageRoute(
        builder: (_) => DiyFlightDetailsScreen(
          flights: flights,
          outbound: outbound,
          adults: _trip.adults,
          children: _trip.children,
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case DiyFlightAction.remove:
        await _removeFlight(outbound);
      case DiyFlightAction.change:
        await _changeFlight(outbound);
    }
  }

  /// More Details — the hotel's own page: photos, amenities and its rooms.
  /// A room picked there is pinned straight away; Change Hotel opens the
  /// hotel list for the stay.
  Future<void> _hotelDetails(DiyRow h) async {
    final destination = h.destination.isNotEmpty
        ? h.destination
        : _trip.days
              .firstWhere(
                (d) => d.rows.contains(h),
                orElse: () => _trip.days.first,
              )
              .destination;
    final stop = _trip.stops
        .where((s) => s.destination.toLowerCase() == destination.toLowerCase())
        .firstOrNull;
    if (stop == null) {
      diySnack(context, 'No hotel stop found for $destination', isError: true);
      return;
    }
    final pick = await Navigator.of(context).push<DiyRoomPick>(
      MaterialPageRoute(
        builder: (pageContext) => DiyHotelDetailScreen(
          trip: _trip,
          stop: stop,
          hotelName: h.hotelName.isNotEmpty ? h.hotelName : h.title,
          previewImages: [if (h.heroImage.isNotEmpty) h.heroImage, ...h.images],
          checkIn: h.checkIn,
          checkOut: h.checkOut,
          rooms: _query.rooms,
          onChangeHotel: () async {
            final trip = await Navigator.of(pageContext).push<DiyTrip>(
              MaterialPageRoute(
                builder: (_) => DiyHotelOptionsScreen(
                  trip: _trip,
                  stop: stop,
                  rooms: _query.rooms,
                ),
              ),
            );
            if (trip != null && pageContext.mounted) {
              Navigator.of(pageContext).pop(DiyRoomPick(trip: trip));
            }
          },
        ),
      ),
    );
    final trip = pick?.trip;
    if (trip != null && mounted) {
      _applyChange(trip, 'Hotel Changed', Icons.hotel_rounded);
      diySnack(context, 'Hotel updated${_totalSuffix(trip)}');
    }
  }

  /// Remove on the transfer — the cab goes, and every transfer and
  /// sightseeing drive with it.
  Future<void> _removeTransfer() async {
    final ok = await showDiyRemoveTransferDialog(context);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final previousCar = _trip.cab.selected;
      final trip = await _api.removeCab(tripId: _trip.tripId, previous: _trip);
      if (!mounted) return;
      _applyChange(
        trip,
        'Transfer Removed',
        Icons.no_crash_rounded,
        cabCode: previousCar,
      );
      diySnack(context, 'Transfers removed${_totalSuffix(trip)}');
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// View Details and Modify both open the transfer screen; Modify lands on
  /// the car options. Its UPDATE answers with the repriced trip.
  Future<void> _openTransfer(DiyRow transfer, {bool modify = false}) async {
    final day = _trip.days.firstWhere(
      (d) => d.rows.contains(transfer),
      orElse: () => _trip.days.first,
    );
    final trip = await Navigator.of(context).push<DiyTrip>(
      MaterialPageRoute(
        builder: (_) => DiyTransferScreen(
          trip: _trip,
          day: day,
          transfer: transfer,
          openOnOptions: modify,
        ),
      ),
    );
    if (trip != null && mounted) {
      _applyChange(
        trip,
        'Transfer Changed',
        Icons.directions_car_filled_rounded,
      );
      diySnack(context, 'Cab and transfers updated${_totalSuffix(trip)}');
    }
  }

  Widget _policyLink(String label, DiyPolicyPage page) {
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => DiyPoliciesScreen(page: page))),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.h(10)),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: DiyTripStyle.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.blue,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              size: context.w(18),
              color: DiyTokens.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _customizationPill() {
    final n = _changes.length;
    return Material(
      color: DiyTokens.blue,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(context.r(20)),
      child: InkWell(
        onTap: _showCustomizations,
        borderRadius: BorderRadius.circular(context.r(20)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: context.w(14),
                color: Colors.white,
              ),
              SizedBox(width: context.w(6)),
              Text(
                'View $n Customization${n == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "View your N Customization" — Figma `View costomization holiday`: what
  /// changed and what it did to the per-person price. An added activity can
  /// be undone from here (↻); other changes are undone on their own screens.
  void _showCustomizations() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final radius = Radius.circular(context.r(24));
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    right: context.w(18),
                    bottom: context.h(10),
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: Container(
                      width: context.w(34),
                      height: context.w(34),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: context.w(19),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    context.w(16),
                    context.h(12),
                    context.w(16),
                    context.h(24),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: radius,
                      topRight: radius,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: context.w(64),
                          height: context.h(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9DDE4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(height: context.h(22)),
                      Text(
                        'View your ${_changes.length} Customization'
                        '${_changes.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: context.fs(18),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: context.h(16)),
                      for (final change in List<_Change>.from(_changes))
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: context.h(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                change.icon,
                                size: context.w(26),
                                color: Colors.black,
                              ),
                              SizedBox(width: context.w(14)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      change.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: context.fs(14),
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (change.perPerson != null)
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: diyDelta(
                                                change.perPerson!,
                                                currency: _trip.currency,
                                              ),
                                              style: TextStyle(
                                                fontSize: context.fs(13),
                                                color: change.perPerson! <= 0
                                                    ? DiyTripStyle.green
                                                    : DiyTripStyle.orange,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' /person',
                                              style: TextStyle(
                                                fontSize: context.fs(13),
                                                color: DiyTripStyle.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (change.canRestore(_addedActivityIds))
                                IconButton(
                                  tooltip: 'Restore',
                                  icon: Icon(
                                    Icons.refresh_rounded,
                                    size: context.w(24),
                                    color: DiyTokens.blue,
                                  ),
                                  onPressed: () async {
                                    await _restore(change);
                                    setSheet(() {});
                                    if (_changes.isEmpty &&
                                        sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Takes an add-on this session added back off the trip.
  Future<void> _removeAddon(String addonId) async {
    final tripActivityId = _addedActivityIds[addonId];
    if (tripActivityId == null || tripActivityId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _api.removeActivity(
        tripId: _trip.tripId,
        tripActivityId: tripActivityId,
      );
      _addedActivityIds.remove(addonId);
      _changes.removeWhere((c) => c.addonId == addonId);
      await _refresh();
      if (mounted) diySnack(context, 'Activity removed');
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _incompleteBanner() {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xFFFFD9A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: context.w(18),
            color: DiyTokens.orange,
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              'Still to confirm: ${_trip.incomplete.join(', ')}',
              style: TextStyle(
                fontSize: context.fs(11.5),
                color: DiyTokens.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The package's own hotel could not be had on these dates and a similar
  /// one stands in — said plainly, so the swap is never a surprise.
  Widget _hotelNotesBanner() {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FD),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xFFBBDCF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hotel_rounded, size: context.w(18), color: DiyTokens.blue),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              _trip.notes.join('\n'),
              style: TextStyle(
                fontSize: context.fs(11.5),
                color: DiyTokens.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "₹ 7,890/person" and BOOK NOW, on the rounded white bar of the design.
  /// Per adult first, the way every price in the app reads; children ride
  /// inside the total underneath.
  Widget _bottomBar() {
    final perAdult = _trip.adults > 0
        ? _trip.grandTotal / _trip.adults
        : _trip.grandTotal;
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(19),
        context.h(17),
        context.w(19),
        context.h(17) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(24)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: context.w(12),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _trip.flightIncluded
                      ? 'Live price with flights'
                      : 'Package price',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: DiyTripStyle.grey,
                  ),
                ),
                if (_isPriced) ...[
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: diyMoney(
                            perAdult,
                            currency: _trip.currency,
                          ).replaceFirst('₹', '₹ '),
                          style: TextStyle(
                            fontSize: context.fs(24),
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: '/person',
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w500,
                            color: DiyTripStyle.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Total ${diyMoney(_trip.grandTotal, currency: _trip.currency)}',
                    style: TextStyle(
                      fontSize: context.fs(10),
                      color: DiyTripStyle.grey,
                    ),
                  ),
                ] else
                  Text(
                    'Not priced yet',
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w700,
                      color: DiyTokens.orange,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: context.w(149),
            height: context.h(44),
            child: ElevatedButton(
              onPressed: _isPriced ? _proceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DiyTripStyle.orange,
                disabledBackgroundColor: const Color(0xFFFFC299),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: Text(
                'BOOK NOW',
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// One thing the customer changed on the trip.
class _Change {
  final String label;
  final IconData icon;

  /// Set for an add-on, so the sheet can take it back off.
  final String? addonId;

  /// What the change did to the per-person price; null when unknown.
  final double? perPerson;

  /// Set on a removed flight: which leg to put back.
  final bool? flightOutbound;

  /// Set on removed transfers: the car to bring back.
  final String? cabCode;

  const _Change(
    this.label,
    this.icon, {
    this.addonId,
    this.perPerson,
    this.flightOutbound,
    this.cabCode,
  });

  /// Whether ↻ can undo it: an added activity the trip still holds an id
  /// for, a removed flight leg, or removed transfers.
  bool canRestore(Map<String, String> addedIds) =>
      (addonId != null && (addedIds[addonId] ?? '').isNotEmpty) ||
      flightOutbound != null ||
      cabCode != null;
}
