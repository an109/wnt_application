import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_cab_sheet.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_itinerary.dart';
import 'diy_addons_screen.dart';
import 'diy_enquiry_screen.dart';
import 'diy_flight_options_screen.dart';
import 'diy_hotel_options_screen.dart';

/// The customer's live trip — **API 6: GET /trips/{trip_id}/** — and the hub
/// for every customisation:
///
///  * flight   → API 7/8  ([DiyFlightOptionsScreen])
///  * hotel    → API 9/10 ([DiyHotelOptionsScreen], one per `stops[].stop_id`)
///  * add-ons  → API 12/13 ([DiyTripAddonsScreen])
///  * cab      → GET/POST /cab/ ([showDiyCabSheet]) — which is also how
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

  const DiyTripScreen({
    super.key,
    required this.trip,
    required this.query,
    required this.shareId,
    this.addons = const [],
    this.preselectedAddonIds = const [],
  });

  @override
  State<DiyTripScreen> createState() => _DiyTripScreenState();
}

class _DiyTripScreenState extends State<DiyTripScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();

  late DiyTrip _trip = widget.trip;
  late List<DiyAddon> _addons = widget.addons;

  /// addon id → trip-activity id, filled as add-ons are added in this
  /// session. The trip's own ACTIVITY rows carry no id, so only add-ons
  /// added here can be removed again (API 13 needs that id).
  final Map<String, String> _addedActivityIds = {};

  bool _busy = false;

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
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _applyPreselectedAddons());
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
        builder: (_) => DiyFlightOptionsScreen(
          trip: _trip,
          outbound: outbound,
        ),
      ),
    );
    if (trip != null && mounted) {
      setState(() => _trip = trip);
      diySnack(context, 'Flight updated${_totalSuffix(trip)}');
    }
  }

  Future<void> _changeHotel(DiyStop stop) async {
    final trip = await Navigator.of(context).push<DiyTrip>(
      MaterialPageRoute(
        builder: (_) => DiyHotelOptionsScreen(
          trip: _trip,
          stop: stop,
        ),
      ),
    );
    if (trip != null && mounted) {
      setState(() => _trip = trip);
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

  Future<void> _openAddons() async {
    if (_addons.isEmpty) {
      diySnack(context, 'No add-ons available for this package');
      return;
    }
    final result = await Navigator.of(context).push<DiyTripAddonsResult>(
      MaterialPageRoute(
        builder: (_) => DiyTripAddonsScreen(
          trip: _trip,
          addons: _addons,
          addedIds: _addedActivityIds,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _addedActivityIds
        ..clear()
        ..addAll(result.addedIds);
      if (result.trip != null) _trip = result.trip!;
    });
    if (result.trip == null) _refresh();
  }

  Future<void> _openCab() async {
    final trip = await showDiyCabSheet(context, trip: _trip);
    if (trip != null && mounted) {
      setState(() => _trip = trip);
      diySnack(context, 'Cab and transfers updated${_totalSuffix(trip)}');
    }
  }

  Future<void> _removeActivityRow(DiyRow row) async {
    // API 13 needs the trip-activity id, which only exists for add-ons this
    // session added; anything that shipped with the package has no handle.
    final entry = _addedActivityIds.entries
        .where((e) =>
            e.value.isNotEmpty &&
            _addons
                .where((a) => a.id == e.key)
                .any((a) => a.name.toLowerCase() == row.title.toLowerCase()))
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
      await _refresh();
      if (mounted) diySnack(context, 'Activity removed');
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _proceed() {
    final date = widget.query.departureDate ??
        DateTime.tryParse(_trip.departureDate) ??
        DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyEnquiryScreen(
          shareId: _trip.shareId.isNotEmpty ? _trip.shareId : widget.shareId,
          query: widget.query.copyWith(departureDate: date),
          withFlight: _trip.flightIncluded,
          addOnIds: _addedActivityIds.keys.toList(),
          quotedTotal: _trip.grandTotal,
          currency: _trip.currency,
          packageTitle: _trip.title,
          tripId: _trip.tripId,
        ),
      ),
    );
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: DiyTokens.navy, size: context.w(22)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Customise your trip',
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w700,
                color: DiyTokens.navy,
              ),
            ),
            Text(
              '${_trip.origin} · ${_trip.departureDate} · '
              '${_trip.adults} adult${_trip.adults == 1 ? '' : 's'}'
              '${_trip.children > 0 ? ', ${_trip.children} child' : ''}',
              style: TextStyle(
                fontSize: context.fs(10.5),
                color: DiyTokens.subGrey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded,
                color: DiyTokens.navy, size: context.w(20)),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(12),
              context.w(14),
              context.h(24),
            ),
            children: [
              _actionsRow(),
              SizedBox(height: context.h(12)),
              _cabCard(),
              if (_trip.incomplete.isNotEmpty) ...[
                SizedBox(height: context.h(12)),
                _incompleteBanner(),
              ],
              SizedBox(height: context.h(4)),
              Text(
                'Your itinerary',
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w800,
                  color: DiyTokens.navy,
                ),
              ),
              DiyItinerary(
                days: _trip.days,
                onChangeFlight: _changeFlight,
                onChangeHotel: _changeHotelByDestination,
                onRemoveActivity: _removeActivityRow,
              ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withOpacity(0.06),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _actionsRow() {
    Widget action({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.w(3)),
            padding: EdgeInsets.symmetric(vertical: context.h(12)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(12)),
              border: Border.all(color: DiyTokens.line),
            ),
            child: Column(
              children: [
                Icon(icon, size: context.w(19), color: DiyTokens.blue),
                SizedBox(height: context.h(5)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(10.5),
                    fontWeight: FontWeight.w600,
                    color: DiyTokens.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (_trip.flightIncluded)
          action(
            icon: Icons.flight_rounded,
            label: 'Flights',
            onTap: () => _changeFlight(true),
          ),
        action(
          icon: Icons.hotel_rounded,
          label: 'Hotels',
          onTap: () {
            if (_trip.stops.isEmpty) {
              diySnack(context, 'No hotel stops in this trip');
              return;
            }
            if (_trip.stops.length == 1) {
              _changeHotel(_trip.stops.first);
            } else {
              _pickStop();
            }
          },
        ),
        action(
          icon: Icons.local_activity_rounded,
          label: 'Add-ons',
          onTap: _openAddons,
        ),
        action(
          icon: Icons.local_taxi_rounded,
          label: 'Cab',
          onTap: _openCab,
        ),
      ],
    );
  }

  void _pickStop() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(18))),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(20),
                context.h(16),
                context.w(20),
                context.h(4),
              ),
              child: Text(
                'Which stay?',
                style: TextStyle(
                  fontSize: context.fs(17),
                  fontWeight: FontWeight.w700,
                  color: DiyTokens.navy,
                ),
              ),
            ),
            for (final stop in _trip.stops)
              ListTile(
                leading: Icon(Icons.hotel_rounded,
                    color: DiyTokens.blue, size: context.w(20)),
                title: Text(
                  stop.destination,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: DiyTokens.navy,
                  ),
                ),
                subtitle: Text(
                  '${stop.nights} night${stop.nights == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTokens.subGrey,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _changeHotel(stop);
                },
              ),
            SizedBox(height: context.h(8)),
          ],
        ),
      ),
    );
  }

  Widget _cabCard() {
    final cab = _trip.cab;
    if (!cab.isIncluded) return const SizedBox.shrink();
    return DiyCard(
      onTap: _openCab,
      child: Row(
        children: [
          Icon(Icons.local_taxi_rounded,
              size: context.w(20), color: DiyTokens.blue),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cab · ${cab.selected}',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
                Text(
                  '${cab.label} · ${cab.seats} seats · ${cab.luggage} bags. '
                  'Transfers follow the cab.',
                  style: TextStyle(
                    fontSize: context.fs(10.5),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: DiyTokens.labelGrey, size: context.w(20)),
        ],
      ),
    );
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
          Icon(Icons.warning_amber_rounded,
              size: context.w(18), color: DiyTokens.orange),
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

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(10),
        context.w(14),
        context.h(10) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: DiyTokens.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Trip total',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: DiyTokens.labelGrey,
                  ),
                ),
                Text(
                  _isPriced
                      ? diyMoney(_trip.grandTotal, currency: _trip.currency)
                      : 'Not priced yet',
                  style: TextStyle(
                    fontSize: context.fs(_isPriced ? 20 : 14),
                    fontWeight: FontWeight.w800,
                    color: _isPriced ? DiyTokens.navy : DiyTokens.orange,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: context.w(170),
            child: DiyPrimaryButton(
              label: 'PROCEED',
              onPressed: _isPriced ? _proceed : null,
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
