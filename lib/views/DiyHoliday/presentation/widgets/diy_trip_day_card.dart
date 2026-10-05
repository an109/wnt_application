import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/airline_logo.dart';
import '../../data/models/diy_models.dart';
import 'diy_common.dart';
import 'diy_flight_parts.dart';

/// Colours and icons of the Figma "Holiday card view" — the package/trip
/// itinerary. Kept here rather than in [DiyTokens] because only this design
/// uses them.
class DiyTripStyle {
  const DiyTripStyle._();

  static const Color grey = Color(0xFF757575);
  static const Color border = Color(0xFFCCCCCC);
  static const Color divider = Color(0xFFE7E5E4);
  static const Color dayPill = Color(0xFFEC5B13);
  static const Color red = Color(0xFFFF383C);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF6600);
  static const Color slate = Color(0xFF475569);

  static const String _dir = 'assets/diy_holiday';
  static const String flight = '$_dir/flight.svg';
  static const String car = '$_dir/car.svg';
  static const String carWhite = '$_dir/car_white.svg';
  static const String building = '$_dir/building.svg';
  static const String buildingOutline = '$_dir/building_outline.svg';
  static const String dining = '$_dir/dining.svg';
  static const String bulb = '$_dir/bulb.svg';
  static const String star = '$_dir/star.svg';
  static const String location = '$_dir/location.svg';
  static const String people = '$_dir/people.svg';
  static const String peopleSmall = '$_dir/people_small.svg';
  static const String time = '$_dir/time.svg';
  static const String photo = '$_dir/photo.svg';
  static const String share = '$_dir/share.svg';
  static const String back = '$_dir/back.svg';
  static const String carPhoto = '$_dir/car_photo.png';
}

/// Which rows the itinerary shows — the "Day Plan / 2 Transfers / 1 Hotels /
/// 3 Meals" pills.
enum DiyDayFilter { all, transfers, hotels, meals }

/// The section kinds of a day card, in the order the design stacks them.
enum _Section { flight, transfer, sightseeing, hotel, meals, activity, checkout }

/// One "DAY n" card of the itinerary: the orange day pill and what the day
/// includes, then a collapsible section per kind of row — Flight, Transfer,
/// Resort, Meals — and the "Add Activity to your day" card.
///
/// Every action is optional: the trip screen wires them all, a read-only
/// view passes none and the links simply do not appear.
class DiyTripDayCard extends StatefulWidget {
  final DiyDay day;
  final bool isFirstDay;
  final bool isLastDay;
  final DiyDayFilter filter;
  final DiyCab cab;
  final int adults;
  final int children;
  final int rooms;

  /// For the land-package note: "You need to reach Goa on your own".
  final bool flightIncluded;

  final ValueChanged<bool>? onChangeFlight;
  final ValueChanged<bool>? onRemoveFlight;

  /// VIEW TRANSPORT OPTION on a trip priced without its flights: add them.
  final VoidCallback? onViewTransport;
  final ValueChanged<DiyRow>? onFlightDetails;
  final ValueChanged<DiyRow>? onModifyTransfer;
  final VoidCallback? onRemoveTransfer;
  final ValueChanged<DiyRow>? onTransferDetails;
  final ValueChanged<String>? onChangeHotel;
  final ValueChanged<DiyRow>? onHotelDetails;
  final ValueChanged<DiyRow>? onRemoveActivity;
  final ValueChanged<int>? onAddActivity;

  const DiyTripDayCard({
    super.key,
    required this.day,
    required this.isFirstDay,
    required this.isLastDay,
    required this.cab,
    required this.adults,
    required this.children,
    required this.rooms,
    required this.flightIncluded,
    this.filter = DiyDayFilter.all,
    this.onChangeFlight,
    this.onRemoveFlight,
    this.onViewTransport,
    this.onFlightDetails,
    this.onModifyTransfer,
    this.onRemoveTransfer,
    this.onTransferDetails,
    this.onChangeHotel,
    this.onHotelDetails,
    this.onRemoveActivity,
    this.onAddActivity,
  });

  @override
  State<DiyTripDayCard> createState() => _DiyTripDayCardState();
}

class _DiyTripDayCardState extends State<DiyTripDayCard> {
  final Set<_Section> _collapsed = {};

  DiyDay get _day => widget.day;

  List<DiyRow> _rows(String kind) =>
      _day.rows.where((r) => r.kind == kind).toList();

  bool _shows(_Section section) => switch (widget.filter) {
        DiyDayFilter.all => true,
        DiyDayFilter.transfers => section == _Section.transfer,
        DiyDayFilter.hotels =>
          section == _Section.hotel || section == _Section.checkout,
        DiyDayFilter.meals => section == _Section.meals,
      };

  /// "Transfer • Hotel" — what the day includes, in the design's words.
  List<String> get _includes {
    final kinds = _day.rows.map((r) => r.kind).toSet();
    return [
      if (kinds.contains('FLIGHT')) 'Flight',
      if (kinds.contains('TRANSFER')) 'Transfer',
      if (kinds.contains('SIGHTSEEING')) 'Sightseeing',
      if (kinds.contains('ACTIVITY')) 'Activity',
      if (kinds.contains('MEAL')) 'Meals',
      if (kinds.contains('HOTEL') || kinds.contains('HOTEL_CHECKOUT')) 'Hotel',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    void add(_Section section, Widget? child) {
      if (child == null || !_shows(section)) return;
      if (sections.isNotEmpty) {
        sections.add(const Divider(height: 1, color: DiyTripStyle.divider));
      }
      sections.add(child);
    }

    // A land package still tells the customer how the trip starts and ends.
    final flights = _rows('FLIGHT');
    if (flights.isNotEmpty) {
      add(_Section.flight, _flightSection(flights));
    } else if (!widget.flightIncluded &&
        (widget.isFirstDay || widget.isLastDay)) {
      add(_Section.flight, _ownFlightNote());
    }
    add(_Section.transfer, _transferSection());
    add(_Section.sightseeing, _sightseeingSection());
    add(_Section.hotel, _hotelSection());
    add(_Section.meals, _mealsSection());
    add(_Section.activity, _activitySection());
    add(_Section.checkout, _checkoutSection());

    final showAddActivity = widget.onAddActivity != null &&
        widget.filter == DiyDayFilter.all &&
        !widget.isLastDay;

    if (sections.isEmpty && !showAddActivity) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: context.h(24)),
      padding: EdgeInsets.fromLTRB(
        context.w(12.5),
        context.h(12.5),
        context.w(12.5),
        context.h(12.5),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: DiyTripStyle.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          SizedBox(height: context.h(12)),
          ...sections,
          if (showAddActivity) ...[
            SizedBox(height: context.h(12)),
            DiyAddActivityCard(
              onAdd: () => widget.onAddActivity!(_day.day),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _header() {
    final includes = _includes;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(4),
          ),
          decoration: BoxDecoration(
            color: DiyTripStyle.dayPill,
            borderRadius: BorderRadius.circular(context.r(20)),
          ),
          child: Text(
            'DAY ${_day.day}',
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: context.w(9)),
        if (includes.isNotEmpty)
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Includes : ',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: includes.join(' • '),
                    style: TextStyle(
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w500,
                      color: DiyTripStyle.grey,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------- section shell

  /// The blue bar, icon and label every section opens with, and the chevron
  /// that folds it.
  Widget _section({
    required _Section kind,
    required String icon,
    required List<String> labels,
    required Widget body,
    bool collapsible = true,
  }) {
    final open = !_collapsed.contains(kind);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: collapsible
                ? () => setState(() =>
                    open ? _collapsed.add(kind) : _collapsed.remove(kind))
                : null,
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: context.h(15),
                  color: DiyTokens.blue,
                ),
                SizedBox(width: context.w(10)),
                SvgPicture.asset(icon, width: context.w(12), height: context.w(12)),
                SizedBox(width: context.w(8)),
                Expanded(child: _labelLine(labels)),
                if (collapsible)
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: context.w(18),
                    color: DiyTokens.blue,
                  ),
              ],
            ),
          ),
          if (open) ...[
            SizedBox(height: context.h(12)),
            body,
          ],
        ],
      ),
    );
  }

  /// "Meals • Breakfast • In Goa" — the first word dark, the rest grey.
  Widget _labelLine(List<String> labels) {
    final parts = labels.where((l) => l.isNotEmpty).toList();
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0)
              TextSpan(
                text: '  •  ',
                style: TextStyle(
                  fontSize: context.fs(11),
                  color: DiyTripStyle.grey,
                ),
              ),
            TextSpan(
              text: parts[i],
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                color: i == 0 ? Colors.black : DiyTripStyle.grey,
              ),
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _link(String text, VoidCallback? onTap, {double size = 12}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(size),
          fontWeight: FontWeight.w600,
          color: DiyTokens.blue,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- flight

  Widget _flightSection(List<DiyRow> flights) {
    // Flights on the first day are the way out; any later day, the way home.
    final outbound = widget.isFirstDay;
    return _section(
      kind: _Section.flight,
      icon: DiyTripStyle.flight,
      labels: const ['Flight'],
      body: Column(
        children: [
          for (var i = 0; i < flights.length; i++) ...[
            if (i > 0)
              DiyLayoverBand.rows(
                  arriving: flights[i - 1], leaving: flights[i]),
            DiyFlightLegCard(
              flight: flights[i],
              outbound: outbound,
              onRemove: widget.onRemoveFlight == null
                  ? null
                  : () => widget.onRemoveFlight!(outbound),
              onChange: widget.onChangeFlight == null
                  ? null
                  : () => widget.onChangeFlight!(outbound),
              onDetails: widget.onFlightDetails == null
                  ? null
                  : () => widget.onFlightDetails!(flights[i]),
            ),
          ],
        ],
      ),
    );
  }

  /// A land package's first and last day: the customer makes their own way.
  Widget _ownFlightNote() {
    final place = _day.destination.isNotEmpty
        ? _day.destination
        : _day.fromDestination;
    final arriving = widget.isFirstDay;
    return _section(
      kind: _Section.flight,
      icon: DiyTripStyle.flight,
      labels: const ['Flight'],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arriving ? 'Arrival in $place' : 'Departure from $place',
            style: TextStyle(
              fontSize: context.fs(10),
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(4)),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Please Note: ',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w700,
                    color: DiyTripStyle.red,
                  ),
                ),
                TextSpan(
                  text: arriving
                      ? 'You need to reach $place on your own'
                      : 'You need to depart from $place on your own',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w500,
                    color: DiyTripStyle.red,
                  ),
                ),
              ],
            ),
          ),
          if (arriving && widget.onViewTransport != null) ...[
            SizedBox(height: context.h(12)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.w(12)),
              decoration: BoxDecoration(
                color: const Color(0xFFF2FAFE),
                borderRadius: BorderRadius.circular(context.r(10)),
                border: Border.all(color: const Color(0xFFD6EEF9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'There are multiple ways to reach your destination.',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: DiyTripStyle.slate,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  GestureDetector(
                    onTap: widget.onViewTransport,
                    child: Text(
                      'VIEW TRANSPORT OPTION',
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color: DiyTokens.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------- transfer

  Widget? _transferSection() {
    final transfers = _rows('TRANSFER');
    if (transfers.isEmpty) return null;
    final cab = widget.cab;
    final first = transfers.first;

    return _section(
      kind: _Section.transfer,
      icon: DiyTripStyle.car,
      labels: const ['Transfer'],
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.w(15)),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    cab.isIncluded ? 'Private Transfer' : 'Transfer',
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                _carImage(cab.image),
              ],
            ),
            SizedBox(height: context.h(12)),
            Row(
              children: [
                if (widget.onRemoveTransfer != null)
                  _link('Remove', widget.onRemoveTransfer, size: 14),
                if (widget.onRemoveTransfer != null &&
                    widget.onModifyTransfer != null)
                  Container(
                    width: 1,
                    height: context.h(20),
                    margin: EdgeInsets.symmetric(horizontal: context.w(10)),
                    color: DiyTripStyle.border,
                  ),
                if (widget.onModifyTransfer != null)
                  _link('Modify', () => widget.onModifyTransfer!(first),
                      size: 14),
                const Spacer(),
                if (widget.onTransferDetails != null)
                  _link('View Details',
                      () => widget.onTransferDetails!(first),
                      size: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The car on its soft shadow, as the design draws it.
  Widget _carImage(String url) {
    return SizedBox(
      width: context.w(130),
      height: context.h(62),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: context.w(130),
              height: context.h(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          url.isNotEmpty
              ? DiyImage(
                  url: url,
                  width: context.w(120),
                  height: context.h(54),
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  DiyTripStyle.carPhoto,
                  width: context.w(120),
                  height: context.h(54),
                  fit: BoxFit.contain,
                ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- sightseeing

  Widget? _sightseeingSection() {
    final rows = _rows('SIGHTSEEING');
    if (rows.isEmpty) return null;
    final pois = [for (final r in rows) ...r.pois];
    return _section(
      kind: _Section.sightseeing,
      icon: DiyTripStyle.car,
      labels: ['Sightseeing', _day.destination],
      body: pois.isEmpty
          ? Text(
              rows.map((r) => r.title).join('\n'),
              style: TextStyle(
                fontSize: context.fs(11),
                color: DiyTripStyle.grey,
              ),
            )
          : SizedBox(
              height: context.h(96),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pois.length,
                separatorBuilder: (_, __) => SizedBox(width: context.w(10)),
                itemBuilder: (_, i) => SizedBox(
                  width: context.w(110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DiyImage(
                        url: pois[i].image,
                        width: context.w(110),
                        height: context.h(70),
                        radius: BorderRadius.circular(context.r(8)),
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        pois[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(10),
                          color: DiyTripStyle.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ----------------------------------------------------------------- hotel

  Widget? _hotelSection() {
    final hotels = _rows('HOTEL');
    if (hotels.isEmpty) return null;
    return _section(
      kind: _Section.hotel,
      icon: DiyTripStyle.building,
      labels: const ['Resort'],
      body: Column(
        children: [
          for (final h in hotels)
            DiyHotelStayCard(
              hotel: h,
              rooms: widget.rooms,
              adults: widget.adults,
              children: widget.children,
              onChange: widget.onChangeHotel == null
                  ? null
                  : () => widget.onChangeHotel!(
                        h.destination.isNotEmpty
                            ? h.destination
                            : _day.destination,
                      ),
              onDetails: widget.onHotelDetails == null
                  ? null
                  : () => widget.onHotelDetails!(h),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- meals

  Widget? _mealsSection() {
    final meals = _rows('MEAL');
    if (meals.isEmpty) return null;
    // "Breakfast in Munnar" → "Breakfast".
    final first = meals.first.title;
    final meal = first.split(' in ').first;
    final hotel = _hotelOfTheNight();
    return _section(
      kind: _Section.meals,
      icon: DiyTripStyle.dining,
      labels: ['Meals', meal, if (_day.destination.isNotEmpty) 'In ${_day.destination}'],
      body: Padding(
        padding: EdgeInsets.only(left: context.w(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hotel.isNotEmpty)
              Text(
                'at $hotel',
                style: TextStyle(
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            SizedBox(height: context.h(2)),
            Text(
              'Include with Hotel',
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w500,
                color: DiyTripStyle.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The hotel the customer slept in the night before this day's breakfast:
  /// this day's hotel row, or the last one on an earlier day.
  String _hotelOfTheNight() {
    final today = _rows('HOTEL');
    if (today.isNotEmpty) return today.first.hotelName;
    return '';
  }

  // -------------------------------------------------------------- activity

  Widget? _activitySection() {
    final activities = _rows('ACTIVITY');
    if (activities.isEmpty) return null;
    return _section(
      kind: _Section.activity,
      icon: DiyTripStyle.bulb,
      labels: const ['Activity'],
      body: Column(
        children: [
          for (final a in activities)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DiyImage(
                    url: (a.detail['hero_image'] ?? '').toString().isNotEmpty
                        ? a.detail['hero_image'].toString()
                        : (a.images.isNotEmpty ? a.images.first : ''),
                    width: context.w(70),
                    height: context.w(56),
                    radius: BorderRadius.circular(context.r(8)),
                  ),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title.trim(),
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        if (a.shortDescription.isNotEmpty)
                          Text(
                            a.shortDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(10),
                              color: DiyTripStyle.grey,
                            ),
                          ),
                        if (widget.onRemoveActivity != null &&
                            !a.complimentary) ...[
                          SizedBox(height: context.h(4)),
                          _link('Remove', () => widget.onRemoveActivity!(a),
                              size: 11),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- checkout

  Widget? _checkoutSection() {
    final checkouts = _rows('HOTEL_CHECKOUT');
    if (checkouts.isEmpty) return null;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(12)),
      child: Row(
        children: [
          SizedBox(width: context.w(8)),
          SvgPicture.asset(
            DiyTripStyle.building,
            width: context.w(12),
            height: context.w(12),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: _labelLine([
              'Hotel Checkout',
              if (_day.fromDestination.isNotEmpty)
                'In ${_day.fromDestination}'
              else if (_day.destination.isNotEmpty)
                'In ${_day.destination}',
            ]),
          ),
        ],
      ),
    );
  }
}

/// One flight of the trip, as the with-flight design draws it: airline logo,
/// name and number with the journey time and route on the right; then the
/// DEPART/RETURN tag, the two times either side of the orange arc, and the
/// Remove | Change / View Details links.
class DiyFlightLegCard extends StatelessWidget {
  final DiyRow flight;
  final bool outbound;
  final VoidCallback? onRemove;
  final VoidCallback? onChange;
  final VoidCallback? onDetails;

  const DiyFlightLegCard({
    super.key,
    required this.flight,
    required this.outbound,
    this.onRemove,
    this.onChange,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final f = flight;
    final dep = diyParseDate(f.departureAt);
    final arr = diyParseDate(f.arrivalAt);
    // "DEL to COK" → the two codes either side of the arc.
    final codes = f.title.split(' to ');
    final from = codes.isNotEmpty ? codes.first.trim() : '';
    final to = codes.length > 1 ? codes.last.trim() : '';
    String day(DateTime? d) =>
        d == null ? '' : DateFormat('EEE, dd MMM').format(d);
    final duration =
        f.flightDurationMinutes > 0 ? diyDuration(f.flightDurationMinutes) : '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- airline and route
          Row(
            children: [
              AirlineLogo(
                code: f.carrier,
                name: f.carrierName,
                size: context.w(34),
                borderRadius: BorderRadius.circular(context.r(4)),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.carrierName.isNotEmpty ? f.carrierName : f.carrier,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      f.flightNumber,
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: DiyTripStyle.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (duration.isNotEmpty)
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w500,
                        color: DiyTokens.blue,
                      ),
                    ),
                  if (from.isNotEmpty && to.isNotEmpty)
                    Text(
                      '${diyAirportCity(from)} to ${diyAirportCity(to)}',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w500,
                        color: DiyTokens.blue,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          const Divider(height: 1, color: DiyTripStyle.border),
          SizedBox(height: context.h(8)),
          // ---- DEPART / RETURN
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(2),
              ),
              decoration: BoxDecoration(
                color: outbound
                    ? const Color(0xFFFDE7EA)
                    : const Color(0xFFE6F6EA),
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
              child: Text(
                outbound ? 'DEPART' : 'RETURN',
                style: TextStyle(
                  fontSize: context.fs(8),
                  fontWeight: FontWeight.w700,
                  color: outbound
                      ? const Color(0xFFE5484D)
                      : DiyTripStyle.green,
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(4)),
          // ---- times and the arc
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _end(context, diyTime(f.departureAt), day(dep), diyAirportCity(from),
                  CrossAxisAlignment.start),
              Expanded(
                child: Column(
                  children: [
                    const DiyFlightArc(),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w600,
                        color: DiyTripStyle.slate,
                      ),
                    ),
                    Text(
                      f.stops == 0
                          ? 'Non stop'
                          : '${f.stops} stop${f.stops == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: DiyTripStyle.grey,
                      ),
                    ),
                  ],
                ),
              ),
              _end(context, diyTime(f.arrivalAt), day(arr), diyAirportCity(to),
                  CrossAxisAlignment.end),
            ],
          ),
          // ---- links
          if (onRemove != null || onChange != null || onDetails != null) ...[
            SizedBox(height: context.h(14)),
            Row(
              children: [
                if (onRemove != null) _link(context, 'Remove', onRemove!),
                if (onRemove != null && onChange != null)
                  Container(
                    width: 1,
                    height: context.h(18),
                    margin: EdgeInsets.symmetric(horizontal: context.w(8)),
                    color: DiyTripStyle.border,
                  ),
                if (onChange != null) _link(context, 'Change', onChange!),
                const Spacer(),
                if (onDetails != null)
                  _link(context, 'View Details', onDetails!, size: 11),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _link(BuildContext context, String text, VoidCallback onTap,
      {double size = 14}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(size),
          fontWeight: FontWeight.w600,
          color: DiyTokens.blue,
        ),
      ),
    );
  }

  Widget _end(
    BuildContext context,
    String time,
    String date,
    String city,
    CrossAxisAlignment align,
  ) {
    return SizedBox(
      width: context.w(92),
      child: Column(
        crossAxisAlignment: align,
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
            style: TextStyle(fontSize: context.fs(12), color: DiyTripStyle.grey),
          ),
          Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align == CrossAxisAlignment.end
                ? TextAlign.right
                : TextAlign.left,
            style: TextStyle(fontSize: context.fs(12), color: DiyTripStyle.grey),
          ),
        ],
      ),
    );
  }
}

/// A stay: photo, stars and guest score, name, locality, the party and the
/// check-in/out window, then Change Hotel / More Details.
class DiyHotelStayCard extends StatelessWidget {
  final DiyRow hotel;
  final int rooms;
  final int adults;
  final int children;
  final VoidCallback? onChange;
  final VoidCallback? onDetails;

  const DiyHotelStayCard({
    super.key,
    required this.hotel,
    required this.rooms,
    required this.adults,
    required this.children,
    this.onChange,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final h = hotel;
    final stars = (double.tryParse(h.starRating) ?? 0).round().clamp(0, 5);
    final image = h.heroImage.isNotEmpty
        ? h.heroImage
        : (h.images.isNotEmpty ? h.images.first : '');
    final checkIn = diyParseDate(h.checkIn);
    final checkOut = diyParseDate(h.checkOut);
    String when(DateTime? d) =>
        d == null ? '' : DateFormat("d'${_ordinal(d.day)}' MMM").format(d);
    final party = [
      '$rooms Room${rooms == 1 ? '' : 's'}',
      '$adults Adult${adults == 1 ? '' : 's'}',
      if (children > 0) '$children Child${children == 1 ? '' : 'ren'}',
    ].join(' | ');

    return Padding(
      padding: EdgeInsets.only(bottom: context.h(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  DiyImage(
                    url: image,
                    width: context.w(91),
                    height: context.w(93),
                    radius: BorderRadius.circular(context.r(5)),
                  ),
                  if (h.images.length > 1)
                    Positioned(
                      right: context.w(4),
                      bottom: context.w(4),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(5),
                          vertical: context.h(2),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(context.r(4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              DiyTripStyle.photo,
                              width: context.w(9),
                              height: context.w(9),
                            ),
                            SizedBox(width: context.w(3)),
                            Text(
                              '${h.images.length}',
                              style: TextStyle(
                                fontSize: context.fs(8),
                                color: Colors.white,
                              ),
                            ),
                          ],
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
                    Row(
                      children: [
                        for (var i = 0; i < stars; i++)
                          Padding(
                            padding: EdgeInsets.only(right: context.w(2)),
                            child: SvgPicture.asset(
                              DiyTripStyle.star,
                              width: context.w(16),
                              height: context.w(16),
                            ),
                          ),
                        if (h.reviewRating.isNotEmpty) ...[
                          SizedBox(width: context.w(2)),
                          Text(
                            h.reviewRating,
                            style: TextStyle(
                              fontSize: context.fs(12),
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      h.hotelName.isNotEmpty ? h.hotelName : h.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (h.location.isNotEmpty)
                      _info(context, DiyTripStyle.location, h.location),
                    _info(context, DiyTripStyle.peopleSmall, party),
                    if (checkIn != null && checkOut != null)
                      _info(
                        context,
                        DiyTripStyle.time,
                        '${when(checkIn)} - ${when(checkOut)} | '
                            '${h.nights > 0 ? h.nights : checkOut.difference(checkIn).inDays} '
                            'Night${h.nights == 1 ? '' : 's'}',
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (onChange != null || onDetails != null) ...[
            SizedBox(height: context.h(12)),
            Row(
              children: [
                if (onChange != null)
                  GestureDetector(
                    onTap: onChange,
                    child: Text(
                      'Change Hotel',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                        color: DiyTokens.blue,
                      ),
                    ),
                  ),
                const Spacer(),
                if (onDetails != null)
                  GestureDetector(
                    onTap: onDetails,
                    child: Text(
                      'More Details',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w600,
                        color: DiyTokens.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    return switch (day % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
  }

  Widget _info(BuildContext context, String icon, String text) {
    return Padding(
      padding: EdgeInsets.only(top: context.h(3)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.h(2)),
            child: SvgPicture.asset(
              icon,
              width: context.w(10),
              height: context.w(10),
            ),
          ),
          SizedBox(width: context.w(4)),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w500,
                color: DiyTripStyle.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Add Activity to your day" — the light-blue suggestion card with the bulb
/// and the orange ADD TO DAY button.
class DiyAddActivityCard extends StatelessWidget {
  final VoidCallback onAdd;

  const DiyAddActivityCard({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(17)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xFFCFE9F7)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBFE6F8), Color(0xFFEAF7FD)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: context.w(6),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.w(50),
                height: context.w(50),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  DiyTripStyle.bulb,
                  width: context.w(30),
                  height: context.w(30),
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Activity to your day',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      'Spend the day at leisure or add an activity, cruise '
                      'tour, or water sports to your day.',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w500,
                        color: DiyTripStyle.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(17)),
          SizedBox(
            width: double.infinity,
            height: context.h(44),
            child: OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DiyTripStyle.orange),
                foregroundColor: DiyTripStyle.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: Text(
                'ADD TO DAY',
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  color: DiyTripStyle.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
