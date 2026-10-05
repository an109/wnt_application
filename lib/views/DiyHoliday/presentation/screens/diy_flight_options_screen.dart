import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_flight_parts.dart';
import '../widgets/diy_trip_day_card.dart';

/// "Change Flight" — both legs of the trip on one screen.
///
/// **API 7: GET /trips/{trip_id}/flights/{outbound|return}/** lists each
/// leg's options, priced as a difference (`delta`) from the flight already
/// pinned. The customer picks per tab; the summary card at the top shows the
/// per-person price those picks come to, and UPDATE applies them — **API 8:
/// POST** per changed leg — and pops the repriced trip.
class DiyFlightOptionsScreen extends StatefulWidget {
  /// The trip being edited. The POST answers with a partial trip, so this is
  /// passed back in as the base to merge onto.
  final DiyTrip trip;

  /// Which tab opens first.
  final bool outbound;

  const DiyFlightOptionsScreen({
    super.key,
    required this.trip,
    required this.outbound,
  });

  @override
  State<DiyFlightOptionsScreen> createState() => _DiyFlightOptionsScreenState();
}

enum _Sort { price, departure, duration }

class _Leg {
  final bool outbound;
  List<DiyFlightOption> options = const [];
  bool loading = true;
  String? error;

  /// The offer the customer has picked on this tab; starts on the pinned one.
  String? chosenRef;

  _Leg(this.outbound);

  DiyFlightOption? get pinned => options.where((o) => o.isSelected).firstOrNull;
  DiyFlightOption? get chosen =>
      options.where((o) => o.offerRef == chosenRef).firstOrNull ?? pinned;
  bool get changed => chosen != null && pinned != null && chosen != pinned;
}

class _DiyFlightOptionsScreenState extends State<DiyFlightOptionsScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();

  late final List<_Leg> _legs;
  late _Leg _tab;
  bool _updating = false;

  _Sort _sort = _Sort.price;
  bool _nonStopOnly = false;
  bool _refundableOnly = false;

  @override
  void initState() {
    super.initState();
    // Only the legs the trip still flies: a removed leg has nothing to change.
    final days = widget.trip.days;
    bool flies(DiyDay? d) => d != null && d.rows.any((r) => r.kind == 'FLIGHT');
    _legs = [
      if (flies(days.firstOrNull)) _Leg(true),
      if (days.length > 1 && flies(days.lastOrNull)) _Leg(false),
    ];
    if (_legs.isEmpty) _legs.add(_Leg(widget.outbound));
    _tab = _legs.firstWhere(
      (l) => l.outbound == widget.outbound,
      orElse: () => _legs.first,
    );
    for (final leg in _legs) {
      _load(leg);
    }
  }

  Future<void> _load(_Leg leg) async {
    setState(() {
      leg.loading = true;
      leg.error = null;
    });
    try {
      final options = await _api.getFlightOptions(
        tripId: widget.trip.tripId,
        outbound: leg.outbound,
      );
      if (!mounted) return;
      setState(() {
        leg.options = options;
        leg.chosenRef = leg.pinned?.offerRef;
        leg.loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        leg.error = e.toString();
        leg.loading = false;
      });
    }
  }

  bool get _anyChanged => _legs.any((l) => l.changed);

  /// What the picks come to per adult: today's total plus each leg's delta.
  double get _perPerson {
    final adults = widget.trip.adults > 0 ? widget.trip.adults : 1;
    final deltas = _legs.fold<double>(
      0,
      (sum, l) => sum + (l.changed ? l.chosen!.delta : 0),
    );
    return (widget.trip.grandTotal + deltas) / adults;
  }

  Future<void> _update() async {
    if (!_anyChanged) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _updating = true);
    var trip = widget.trip;
    try {
      for (final leg in _legs.where((l) => l.changed)) {
        trip = await _api.changeFlight(
          tripId: trip.tripId,
          outbound: leg.outbound,
          offerRef: leg.chosen!.offerRef,
          previous: trip,
        );
      }
      if (mounted) Navigator.of(context).pop(trip);
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  List<DiyFlightOption> _visible(_Leg leg) {
    final list = leg.options
        .where((o) => !_nonStopOnly || o.stops == 0)
        .where((o) => !_refundableOnly || o.refundable)
        .toList();
    int byDeparture(DiyFlightOption a, DiyFlightOption b) =>
        a.departureAt.compareTo(b.departureAt);
    list.sort(switch (_sort) {
      _Sort.price => (a, b) => a.delta.compareTo(b.delta),
      _Sort.departure => byDeparture,
      _Sort.duration => (a, b) => a.durationMinutes.compareTo(
        b.durationMinutes,
      ),
    });
    // The pinned flight stays at the top whatever the order.
    final pinned = leg.pinned;
    if (pinned != null && list.remove(pinned)) list.insert(0, pinned);
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
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: context.w(24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Flight',
              style: TextStyle(
                fontSize: context.fs(18),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              [
                if (date != null) DateFormat('MMM dd').format(date),
                party,
              ].join(', '),
              style: TextStyle(
                fontSize: context.fs(11),
                color: DiyTripStyle.grey,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _sortFilterPill(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(28),
              context.w(16),
              context.h(8),
            ),
            child: _summaryCard(),
          ),
          if (_legs.length > 1) _tabs(),
          Expanded(child: _list(_tab)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- summary

  Widget _summaryCard() {
    String times(DiyFlightOption? o) =>
        o == null ? '' : '${diyTime(o.departureAt)} - ${diyTime(o.arrivalAt)}';

    Widget legRow(_Leg leg) {
      final o = leg.chosen;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(5)),
        child: Row(
          children: [
            AirlineLogo(
              code: o?.carrier ?? '',
              name: o?.carrierName ?? '',
              size: context.w(30),
              borderRadius: BorderRadius.circular(context.r(4)),
            ),
            SizedBox(width: context.w(10)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leg.outbound ? 'Departure' : 'Return',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      size: context.w(9),
                      color: DiyTripStyle.grey,
                    ),
                    SizedBox(width: context.w(3)),
                    Text(
                      times(o),
                      style: TextStyle(
                        fontSize: context.fs(9),
                        color: DiyTripStyle.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(context.w(16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(12)),
            gradient: const LinearGradient(
              colors: [Color(0xFFBFE6F8), Color(0xFFEFF9FE)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: context.w(8),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final leg in _legs) legRow(leg)],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: diyMoney(
                            _perPerson,
                            currency: widget.trip.currency,
                          ),
                          style: TextStyle(
                            fontSize: context.fs(19),
                            fontWeight: FontWeight.w700,
                            color: DiyTokens.blue,
                          ),
                        ),
                        TextSpan(
                          text: '/person',
                          style: TextStyle(
                            fontSize: context.fs(12),
                            color: DiyTripStyle.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(8)),
                  SizedBox(
                    width: context.w(140),
                    height: context.h(42),
                    child: ElevatedButton(
                      onPressed: _updating ? null : _update,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DiyTripStyle.orange,
                        disabledBackgroundColor: const Color(0xFFFFC299),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                      ),
                      child: _updating
                          ? SizedBox(
                              width: context.w(18),
                              height: context.w(18),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'UPDATE',
                              style: TextStyle(
                                fontSize: context.fs(15),
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
        // Nothing changed yet: the card is what the trip already has.
        if (!_anyChanged)
          Positioned(
            right: context.w(8),
            top: -context.h(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(4),
              ),
              decoration: BoxDecoration(
                color: DiyTokens.blue,
                borderRadius: BorderRadius.circular(context.r(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: context.w(12),
                    color: Colors.white,
                  ),
                  SizedBox(width: context.w(4)),
                  Text(
                    'SELECTED',
                    style: TextStyle(
                      fontSize: context.fs(10),
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

  // ------------------------------------------------------------------ tabs

  Widget _tabs() {
    String subtitle(_Leg leg) {
      final o = leg.chosen;
      if (o == null) return '';
      final (from, to) = diyRouteCodes(o.title);
      final d = diyParseDate(o.departureAt);
      return '$from- $to${d == null ? '' : ', ${DateFormat('MMM dd').format(d)}'}';
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(16),
        context.w(16),
        0,
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: DiyTripStyle.divider)),
        ),
        child: Row(
          children: [
            for (final leg in _legs)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _tab = leg),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      context.w(16),
                      context.h(8),
                      context.w(8),
                      context.h(8),
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: leg == _tab
                              ? DiyTokens.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leg.outbound ? 'Departure' : 'Return',
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: FontWeight.w500,
                            color: leg == _tab
                                ? DiyTokens.blue
                                : DiyTripStyle.grey,
                          ),
                        ),
                        Text(
                          subtitle(leg),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: FontWeight.w500,
                            color: leg == _tab
                                ? DiyTokens.blue
                                : DiyTripStyle.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ list

  Widget _list(_Leg leg) {
    if (leg.loading) {
      return const DiyLoading(message: 'Searching flights…');
    }
    if (leg.error != null) {
      return DiyErrorView(message: leg.error!, onRetry: () => _load(leg));
    }
    final options = _visible(leg);
    if (options.isEmpty) {
      return const DiyErrorView(
        message: 'No flights match. Try clearing the filters.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(20),
        context.w(16),
        context.h(96),
      ),
      itemCount: options.length,
      separatorBuilder: (_, __) => SizedBox(height: context.h(18)),
      itemBuilder: (_, i) => _optionCard(leg, options[i]),
    );
  }

  Widget _optionCard(_Leg leg, DiyFlightOption o) {
    final selected = leg.chosen == o;
    final (from, to) = diyRouteCodes(o.title);
    final dep = diyParseDate(o.departureAt);
    final arr = diyParseDate(o.arrivalAt);
    String day(DateTime? d) =>
        d == null ? '' : DateFormat('EEE, dd MMM').format(d);

    Widget end(String time, String date, String city, CrossAxisAlignment a) {
      return SizedBox(
        width: context.w(92),
        child: Column(
          crossAxisAlignment: a,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: context.fs(22),
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            SizedBox(height: context.h(4)),
            Text(
              date,
              style: TextStyle(
                fontSize: context.fs(12),
                color: DiyTripStyle.grey,
              ),
            ),
            Text(
              city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(12),
                color: DiyTripStyle.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: DiyTripStyle.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AirlineLogo(
                code: o.carrier,
                name: o.carrierName,
                size: context.w(34),
                borderRadius: BorderRadius.circular(context.r(4)),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.carrierName.isNotEmpty ? o.carrierName : o.carrier,
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      o.flightNumber,
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: DiyTripStyle.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // What moving costs against the flight already pinned.
              Text(
                o.isSelected
                    ? 'Included'
                    : diyDelta(o.delta, currency: widget.trip.currency),
                style: TextStyle(
                  fontSize: context.fs(15),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          const Divider(height: 1, color: DiyTripStyle.border),
          SizedBox(height: context.h(12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              end(
                diyTime(o.departureAt),
                day(dep),
                diyAirportCity(from),
                CrossAxisAlignment.start,
              ),
              Expanded(
                child: Column(
                  children: [
                    const DiyFlightArc(),
                    Text(
                      diyDuration(o.durationMinutes),
                      style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w600,
                        color: DiyTripStyle.slate,
                      ),
                    ),
                    Text(
                      o.stops == 0
                          ? 'Non stop'
                          : '${o.stops} stop${o.stops == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: DiyTripStyle.grey,
                      ),
                    ),
                  ],
                ),
              ),
              end(
                diyTime(o.arrivalAt),
                day(arr),
                diyAirportCity(to),
                CrossAxisAlignment.end,
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          Row(
            children: [
              Tooltip(
                message: o.baggageCabin.isNotEmpty
                    ? 'Cabin ${o.baggageCabin}'
                    : 'Cabin bag',
                child: Icon(
                  Icons.work_rounded,
                  size: context.w(24),
                  color: DiyTripStyle.grey,
                ),
              ),
              SizedBox(width: context.w(14)),
              Tooltip(
                message: o.baggageChecked.isNotEmpty
                    ? 'Check-in ${o.baggageChecked}'
                    : 'Check-in bag',
                child: Icon(
                  Icons.luggage_rounded,
                  size: context.w(24),
                  color: DiyTripStyle.grey,
                ),
              ),
              if (o.baggageChecked.isNotEmpty) ...[
                SizedBox(width: context.w(6)),
                Text(
                  o.baggageChecked,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTripStyle.grey,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: context.w(150),
                height: context.h(42),
                child: selected
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: DiyTripStyle.orange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(8)),
                          ),
                        ),
                        child: Text(
                          'SELECTED',
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () =>
                            setState(() => leg.chosenRef = o.offerRef),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DiyTripStyle.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(8)),
                          ),
                        ),
                        child: Text(
                          'SELECT',
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: FontWeight.w600,
                            color: DiyTripStyle.orange,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- sort/filter

  Widget _sortFilterPill() {
    Widget half(IconData icon, String label, VoidCallback onTap, bool dot) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.r(30)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(28),
            vertical: context.h(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: context.w(18), color: Colors.black),
              SizedBox(width: context.w(10)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(14),
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
          half(Icons.swap_vert_rounded, 'Sort', _openSort, false),
          Container(
            width: 1,
            height: context.h(24),
            color: DiyTripStyle.divider,
          ),
          half(
            Icons.tune_rounded,
            'Filter',
            _openFilter,
            _nonStopOnly || _refundableOnly,
          ),
        ],
      ),
    );
  }

  void _openSort() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(18)),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (sort, label) in const [
              (_Sort.price, 'Price — Low to High'),
              (_Sort.departure, 'Departure — Earliest first'),
              (_Sort.duration, 'Duration — Shortest first'),
            ])
              ListTile(
                title: Text(label),
                trailing: _sort == sort
                    ? const Icon(Icons.check_rounded, color: DiyTokens.blue)
                    : null,
                onTap: () {
                  setState(() => _sort = sort);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openFilter() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(18)),
        ),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Non-stop only'),
                value: _nonStopOnly,
                activeThumbColor: DiyTokens.blue,
                onChanged: (v) {
                  setState(() => _nonStopOnly = v);
                  setSheet(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Refundable only'),
                value: _refundableOnly,
                activeThumbColor: DiyTokens.blue,
                onChanged: (v) {
                  setState(() => _refundableOnly = v);
                  setSheet(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
