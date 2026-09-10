import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/views/AKGetSPricer/domain/entity/AKGetSPricer_entity.dart';
import 'package:wander_nova/views/AKInsurance/domain/entity/AKInsurance_entity.dart';
import 'package:wander_nova/views/flight_payment/presentation/screen/ak_payment_screen.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/seat_addons_screen.dart';

// ---------------------------------------------------------------------------
// Figma tokens (Review trip details — node 496:2193)
// ---------------------------------------------------------------------------
const _pri = AppColors.AppBlue; // #00A1E4
const _sec = AppColors.OrangeColor; // #FF6600
const _muted = AppColors.subhead; // #757575
const _stroke = Color(0xFFE6E8EC);
const _ink = Color(0xFF0F172A);
const _danger = Color(0xFFFF383C);

/// Last stop before [AkFlightPaymentScreen]: a read-only recap of the flight,
/// travellers, contact details and add-ons so the traveller can catch a typo
/// before any money moves.
///
/// Purely presentational — CreateItinerary has already run by the time this
/// is pushed, so "Confirm & Continue" just forwards the same arguments on to
/// the payment screen.
class AkTripReviewScreen extends StatelessWidget {
  final FlightRouteSegment route;
  final List<FlightRouteSegment> additionalLegs;

  /// Lead passenger map from the traveller form (`title`, `firstName`,
  /// `lastName`, `gender`, `email`, `mobileNumber`, …).
  final Map<String, dynamic> leadPassenger;

  /// Every traveller on the booking, same shape as [leadPassenger].
  final List<Map<String, dynamic>> travellers;

  final List<String> travellerNames;
  final int travellerCount;

  /// CreateItinerary's netAmount — forwarded untouched to the payment screen.
  final double netAmount;

  /// Seats / meals / other extras chosen on [SeatAddonsScreen].
  final AddOnsSummary addOns;

  final TripSecureBookingContext? insuranceBookingContext;

  const AkTripReviewScreen({
    super.key,
    required this.route,
    required this.leadPassenger,
    required this.travellers,
    required this.netAmount,
    this.additionalLegs = const [],
    this.travellerNames = const [],
    this.travellerCount = 1,
    this.addOns = const AddOnsSummary(),
    this.insuranceBookingContext,
  });

  // -------------------------------------------------------------------------
  // Data helpers — everything here reads the real booking, never a literal
  // -------------------------------------------------------------------------

  AkGetSPricerFlightEntity? _flight({required bool last}) {
    final trips = route.akFareData?.trips;
    if (trips == null || trips.isEmpty) return null;
    final journeys = trips.first.journey;
    if (journeys.isEmpty) return null;
    final segments = journeys.first.segments;
    if (segments.isEmpty) return null;
    return last ? segments.last.flight : segments.first.flight;
  }

  /// `route.flightNo` arrives as "<IATA> • <number>" — this pulls the code
  /// back out so the real carrier logo is shown.
  String get _airlineCode {
    final flightNo = route.flightNo;
    final sep = flightNo.indexOf('•');
    return (sep > 0 ? flightNo.substring(0, sep) : flightNo).trim();
  }

  String get _fromCity =>
      (route.fromCity ?? '').trim().isNotEmpty ? route.fromCity!.trim() : route.from;

  String get _toCity =>
      (route.toCity ?? '').trim().isNotEmpty ? route.toCity!.trim() : route.to;

  DateTime? _parse(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim().replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  /// "Wed, 26 Aug" off the real departure timestamp, falling back to the
  /// pre-formatted date the route already carries.
  String get _departureDate {
    final dt = _parse(_flight(last: false)?.departureTime ?? '');
    if (dt != null) return DateFormat('EEE, dd MMM').format(dt);
    return route.departureDate ?? '';
  }

  /// Whether the flight lands on a later calendar day, which the design flags
  /// as "+1 DAY".
  int get _dayOffset {
    final dep = _parse(_flight(last: false)?.departureTime ?? '');
    final arr = _parse(_flight(last: true)?.arrivalTime ?? '');
    if (dep == null || arr == null) return 0;
    final d = DateTime(dep.year, dep.month, dep.day);
    final a = DateTime(arr.year, arr.month, arr.day);
    return a.difference(d).inDays;
  }

  String get _stops {
    final stops = route.stops;
    if (stops == null || stops <= 0) return 'Non Stop';
    return '$stops Stop${stops > 1 ? 's' : ''}';
  }

  /// "1 Adult" / "2 Adults, 1 Child" — built from the real traveller list so
  /// it always matches what was actually collected.
  String get _paxSummary {
    int adults = 0, children = 0, infants = 0;
    for (final t in travellers) {
      switch ((t['paxType'] ?? 'ADT').toString().toUpperCase()) {
        case 'CHD':
          children++;
          break;
        case 'INF':
          infants++;
          break;
        default:
          adults++;
      }
    }
    if (adults + children + infants == 0) {
      adults = travellerCount < 1 ? 1 : travellerCount;
    }
    final parts = <String>[
      if (adults > 0) '$adults Adult${adults > 1 ? 's' : ''}',
      if (children > 0) '$children Child${children > 1 ? 'ren' : ''}',
      if (infants > 0) '$infants Infant${infants > 1 ? 's' : ''}',
    ];
    return parts.join(', ');
  }

  String _s(Map<String, dynamic> m, String key) => (m[key] ?? '').toString().trim();

  String get _others {
    final extras = <String>[
      if (insuranceBookingContext != null) 'Trip Secure',
      ...addOns.others,
    ];
    return AddOnsSummary.display(extras);
  }

  void _continue(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkFlightPaymentScreen(
          route: route,
          leadPassenger: leadPassenger,
          netAmount: netAmount,
          additionalLegs: additionalLegs,
          travellerCount: travellerCount,
          travellerNames: travellerNames,
          travellers: travellers,
          addOns: addOns,
          insuranceBookingContext: insuranceBookingContext,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(
                    context.w(16), context.h(4), context.w(16), context.h(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _flightCard(context),
                    SizedBox(height: context.h(30)),
                    _sectionTitle(context, 'Traveller Details'),
                    SizedBox(height: context.h(12)),
                    _travellerCard(context),
                    SizedBox(height: context.h(22)),
                    _sectionTitle(context, 'Contact info'),
                    SizedBox(height: context.h(12)),
                    _contactCard(context),
                    SizedBox(height: context.h(24)),
                    _sectionTitle(context, 'Add-ons'),
                    SizedBox(height: context.h(12)),
                    _addOnsCard(context),
                    SizedBox(height: context.h(20)),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'NOTE: ',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: _muted),
                        ),
                        const TextSpan(
                          text:
                              'Please review your itinerary & traveller details carefully to avoid any cancellation penalties later.',
                        ),
                      ]),
                      style:
                          TextStyle(fontSize: context.fs(12), color: _muted, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(context.w(16), context.h(12), context.w(16), context.h(16)),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Image.asset(
              'assets/NewIcons/arrowBack.png',
              width: context.w(15),
              height: context.h(15),
              color: Colors.black,
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Text(
              'Review trip details',
              style: TextStyle(
                fontSize: context.fs(20),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FLIGHT CARD ====================
  Widget _flightCard(BuildContext context) {
    final dayOffset = _dayOffset;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFB8E8FF), Color(0xFFDDF3FF)],
        ),
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AirlineLogo(
                code: _airlineCode,
                name: route.airline,
                size: context.w(46),
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: context.h(5)),
                    Text(
                      '${route.from} - ${route.to}',
                      style: TextStyle(
                        fontSize: context.fs(18),
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: context.h(7)),
                    Wrap(
                      spacing: context.w(8),
                      runSpacing: context.h(6),
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_departureDate.isNotEmpty)
                          _metaChip(context, 'assets/NewIcons/calender.png', _departureDate),
                        _metaChip(context, 'assets/NewIcons/clock.png',
                            '${route.departureTime} - ${route.arrivalTime}'),
                        _metaChip(context, 'assets/NewIcons/no_stops.png', _stops),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(6)),
              Image.asset(
                'assets/Newimage/traveller.png',
                width: context.w(64),
                height: context.w(68),
                fit: BoxFit.contain,
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _fromCity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: _pri,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(8)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        route.duration,
                        style: TextStyle(fontSize: context.fs(10), color: _muted, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: context.h(2)),
                      Row(
                        children: [
                          const Expanded(child: _DashedLine()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.w(4)),
                            child: Transform.rotate(
                              angle: 1.5708,
                              child: Icon(Icons.flight, size: context.w(15), color: _pri),
                            ),
                          ),
                          const Expanded(child: _DashedLine()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _toCity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: _pri,
                      ),
                    ),
                    if (dayOffset > 0)
                      Text(
                        '+$dayOffset DAY${dayOffset > 1 ? 'S' : ''}',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w700,
                          color: _danger,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(BuildContext context, String assetPath, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: context.w(8),
          height: context.w(8),
          color: AppColors.subhead,
          fit: BoxFit.contain,
        ),
        SizedBox(width: context.w(4)),
        Text(label, style: TextStyle(fontSize: context.fs(8), fontWeight: FontWeight.w600, color: AppColors.subhead)),
      ],
    );
  }

  // ==================== CARDS ====================
  Widget _sectionTitle(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          fontSize: context.fs(16),
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      );

  Widget _card(BuildContext context, {required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.w(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(12)),
          border: Border.all(color: _stroke),
        ),
        child: child,
      );

  Widget _kvRow(BuildContext context, String label, String value) => Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(7)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: _muted)),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Text(
                value.isEmpty ? '--' : value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _travellerCard(BuildContext context) {
    final list = travellers.isNotEmpty ? travellers : [leadPassenger];
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.w(44),
                height: context.w(44),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.person, size: context.w(20), color: const Color(0xFF2F80ED)),
              ),
              SizedBox(width: context.w(14)),
              Expanded(
                child: Text(
                  _paxSummary,
                  style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          for (int i = 0; i < list.length; i++) ...[
            if (i > 0) ...[
              SizedBox(height: context.h(10)),
              Divider(height: 1, color: _stroke),
              SizedBox(height: context.h(6)),
            ],
            _kvRow(context, 'First & Middle Name', _s(list[i], 'firstName')),
            _kvRow(context, 'Last Name', _s(list[i], 'lastName')),
            _kvRow(context, 'Gender', _s(list[i], 'gender')),
          ],
        ],
      ),
    );
  }

  Widget _contactCard(BuildContext context) {
    final phone = _s(leadPassenger, 'mobileNumber');
    return _card(
      context,
      child: Column(
        children: [
          _kvRow(context, 'Mail', _s(leadPassenger, 'email')),
          _kvRow(context, 'Phone no.', phone.isEmpty ? '' : '+91 $phone'),
        ],
      ),
    );
  }

  Widget _addOnsCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        children: [
          _kvRow(context, 'Seats', AddOnsSummary.display(addOns.seatNumbers)),
          _kvRow(context, 'Meals', AddOnsSummary.display(addOns.meals)),
          _kvRow(context, 'Others', _others),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            EdgeInsets.fromLTRB(context.w(16), context.h(10), context.w(16), context.h(10)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: context.h(52),
          child: ElevatedButton(
            onPressed: () => _continue(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _sec,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
            ),
            child: Text(
              'CONFIRM & CONTINUE',
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The thin dashed rule either side of the plane glyph on the flight card.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const dash = 3.0;
        const gap = 3.0;
        final count = (c.maxWidth / (dash + gap)).floor().clamp(0, 200);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: dash,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF9FB3C8))),
            ),
          ),
        );
      },
    );
  }
}
