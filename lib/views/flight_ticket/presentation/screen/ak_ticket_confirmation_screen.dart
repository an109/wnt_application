import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:lottie/lottie.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/services/pdf_generator.dart';
import 'package:wander_nova/core/services/push_notification_service.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/AKGetSPricer/domain/entity/AKGetSPricer_entity.dart';
import 'package:wander_nova/views/AKRetrieveBooking/domain/entity/AKRetrieveBooking_entity.dart';
import 'package:wander_nova/views/MyBookings/Flights/Screen/flight_pdf_builder.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/seat_addons_screen.dart';

/// Booking confirmation for the Akbar flow, built from RetrieveBooking's
/// response and the traveller / add-on data carried through the payment flow.
/// Deliberately a new, simple widget rather than a retrofit of
/// [TicketVoucherScreen] (whose props are TBO-shaped and reused by the TBO
/// booking flow).
///
/// UI — Figma "Payment successful flight" (node 604:5261).
class AkTicketConfirmationScreen extends StatefulWidget {
  final AkRetrieveBookingEntity booking;
  final FlightRouteSegment route;

  /// The return leg for RT/RS, or legs 2..N for Multi City. Empty for a
  /// plain one-way booking.
  final List<FlightRouteSegment> additionalLegs;
  final Map<String, dynamic> leadPassenger;

  /// Every traveller on the booking, same map shape the traveller form emits
  /// (`title`, `firstName`, `lastName`, `gender`, `paxType`, `dateOfBirth`,
  /// `email`, `mobileNumber`, …). Empty for older call sites, which then fall
  /// back to [travellerNames] / [leadPassenger].
  final List<Map<String, dynamic>> travellers;

  /// Seats / meals / other extras chosen on [SeatAddonsScreen]. Defaults to an
  /// empty summary, so a booking with no add-ons just shows "----".
  final AddOnsSummary addOns;

  /// The payment gateway's transaction reference (Razorpay payment id).
  /// Null for wallet payments, where there's no gateway transaction.
  final String? transactionId;

  /// Amount actually paid, in INR (Akbar's native currency) — converted to
  /// the user's preferred display currency for both the PDF and the
  /// on-screen total.
  final double netAmount;

  /// Total travellers on this booking (adults + children + infants), used
  /// to label the PDF/summary correctly for 1 vs 2+ passengers.
  final int travellerCount;

  /// Every traveller's full name (not just the lead's), used as a fallback
  /// when [travellers] wasn't supplied.
  final List<String> travellerNames;

  const AkTicketConfirmationScreen({
    super.key,
    required this.booking,
    required this.route,
    this.additionalLegs = const [],
    required this.leadPassenger,
    this.travellers = const [],
    this.addOns = const AddOnsSummary(),
    this.transactionId,
    required this.netAmount,
    this.travellerCount = 1,
    this.travellerNames = const [],
  });

  @override
  State<AkTicketConfirmationScreen> createState() => _AkTicketConfirmationScreenState();
}

class _AkTicketConfirmationScreenState extends State<AkTicketConfirmationScreen> {
  // ---- Figma tokens (node 604:5261) ----
  static const _pri = AppColors.AppBlue; // #00A1E4
  static const _sec = AppColors.OrangeColor; // #FF6600
  static const _muted = AppColors.subhead; // #757575
  static const _stroke = Color(0xFFCCCCCC);
  static const _ink = Color(0xFF111527);
  static const _headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00A1E4), Color(0xFF56B0FF)],
  );

  bool _downloading = false;
  bool _showAllPax = false;

  /// Payment happened moments ago — the API doesn't return a timestamp, so the
  /// confirmation time is the closest honest value.
  final DateTime _paidAt = DateTime.now();

  List<FlightRouteSegment> get _legs => [widget.route, ...widget.additionalLegs];

  bool get _isRoundTrip =>
      widget.additionalLegs.length == 1 &&
      widget.additionalLegs.first.to.trim().toLowerCase() == widget.route.from.trim().toLowerCase();

  /// "Onward"/"Return" for a round trip, "Leg N" for multi-city, null for a
  /// plain one-way booking. Kept for the PDF builder.
  String? _legLabel(int index) {
    if (widget.additionalLegs.isEmpty) return null;
    if (_isRoundTrip) return index == 0 ? 'Onward' : 'Return';
    return 'Leg ${index + 1}';
  }

  // -------------------------------------------------------------------------
  // Dynamic data helpers — every value here reads the real booking response
  // -------------------------------------------------------------------------

  String get _displayAmount {
    final prefs = sl<PreferencesManager>();
    final target = prefs.getPreferredCurrency() ?? 'INR';
    final converted = target.toUpperCase() == 'INR'
        ? widget.netAmount
        : CurrencyConverter.convert(amount: widget.netAmount, fromCurrency: 'INR', toCurrency: target);
    return CurrencyConverter.format(converted, target);
  }

  String get _paymentDate => DateFormat('dd MMM yyyy, hh:mm a').format(_paidAt);

  /// Gateway reference for a card/UPI payment; the PNR for a wallet payment
  /// (no gateway transaction there).
  String get _bookingId {
    if (widget.booking.bookingId != null) return 'WNT-${widget.booking.bookingId}';
    final txn = (widget.transactionId ?? '').trim();
    if (txn.isNotEmpty) return txn;
    if (widget.booking.pnrs.isNotEmpty) return widget.booking.pnrs.first;
    return '--';
  }

  /// The PNR for leg [legIndex]. Akbar returns one PNR per airline booking,
  /// in leg order, so a round trip across two carriers has two — the onward
  /// card must show its own and the return card its own. A single-carrier
  /// round trip comes back with one PNR covering both legs, so a missing
  /// entry falls back to the first rather than leaving the card blank.
  String _pnrFor(int legIndex) {
    final pnrs = widget.booking.pnrs;
    if (pnrs.isEmpty) return '--';
    return legIndex < pnrs.length ? pnrs[legIndex] : pnrs.first;
  }

  String get _statusLabel {
    if (widget.booking.success) return 'PAID';
    final s = widget.booking.status.trim();
    return s.isEmpty ? 'PAID' : s.toUpperCase();
  }

  /// Traveller maps to render — the real per-passenger list when it was passed
  /// through, otherwise a best effort from the names, and finally the lead.
  List<Map<String, dynamic>> get _pax {
    if (widget.travellers.isNotEmpty) return widget.travellers;
    if (widget.travellerNames.isNotEmpty) {
      return widget.travellerNames.map((n) {
        final parts = n.trim().split(RegExp(r'\s+'));
        return <String, dynamic>{
          'firstName': parts.isNotEmpty ? parts.first : n.trim(),
          'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'paxType': 'ADT',
        };
      }).toList();
    }
    return [widget.leadPassenger];
  }

  String _s(Map<String, dynamic> m, String key) => (m[key] ?? '').toString().trim();

  String _fullName(Map<String, dynamic> m, int index) {
    final name = '${_s(m, 'firstName')} ${_s(m, 'lastName')}'.trim();
    if (name.isNotEmpty) return name;
    if (index < widget.travellerNames.length) return widget.travellerNames[index].trim();
    return 'Guest';
  }

  String _ptcLabel(String ptc) => switch (ptc.trim().toUpperCase()) {
        'CHD' || 'CNN' || 'C' => 'Child',
        'INF' || 'INS' => 'Infant',
        _ => 'Adult',
      };

  /// "21y" / "Under 2y" from the collected DOB, or null when there's no DOB
  /// (adults on domestic fares aren't asked for one).
  String? _ageLabel(String rawDob) {
    final dob = _parseDate(rawDob);
    if (dob == null) return null;
    final now = DateTime.now();
    int years = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) years--;
    if (years < 0) return null;
    if (years < 2) return 'Under 2y';
    return '${years}y';
  }

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    for (final f in const ['dd MMM yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy']) {
      try {
        return DateFormat(f).parseStrict(value);
      } catch (_) {}
    }
    try {
      return DateTime.parse(value.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  /// The i-th entry of a flat add-on list ("8B", "Veg Meal", …), or "----"
  /// when the traveller has none — mirrors the placeholder in the design.
  String _addOnAt(List<String> values, int index) =>
      index < values.length && values[index].trim().isNotEmpty ? values[index].trim() : '----';

  /// Included check-in baggage for a passenger type, straight off GetSPricer's
  /// `includedBaggage` map. "----" when the fare didn't declare any.
  String _baggageFor(String ptc) {
    final map = widget.route.akFareData?.includedBaggage;
    if (map == null || map.isEmpty) return '----';
    final perPax = map.values.first;
    if (perPax.isEmpty) return '----';
    final entry = perPax[ptc.trim().toUpperCase()] ?? perPax['ADT'] ?? perPax.values.first;
    final checkin = entry.checkin.trim();
    return checkin.isEmpty ? '----' : checkin;
  }

  /// E-ticket number for the i-th traveller, falling back to the PNR and then
  /// a dash so the row never renders blank.
  String _ticketFor(int index) {
    final tickets = widget.booking.allTicketInfo;
    if (index < tickets.length && tickets[index].ticketNo.trim().isNotEmpty) {
      return tickets[index].ticketNo.trim();
    }
    if (widget.booking.pnrs.isNotEmpty) return widget.booking.pnrs.first;
    return '--';
  }

  // ---- per-leg flight detail off GetSPricer (terminals, airport names) ----

  AkGetSPricerFlightEntity? _flightAt(int legIndex, {required bool last}) {
    final leg = _legs[legIndex];
    final own = leg.akFareData?.trips;
    final hasOwn = own != null && own.isNotEmpty;
    final trips = hasOwn ? own : widget.route.akFareData?.trips;
    if (trips == null || trips.isEmpty) return null;
    // A leg's own akFareData often carries the WHOLE itinerary's trips, not
    // just that leg's, so reading trips[0] from it put the outbound flight's
    // airports, times and terminals inside the return card. Index by the
    // leg's own position and clamp, which also covers the case where the
    // response really does hold a single trip.
    final tripIdx = (hasOwn ? leg.legIndex : legIndex).clamp(0, trips.length - 1);
    final journeys = trips[tripIdx].journey;
    if (journeys.isEmpty) return null;
    final segments = journeys.first.segments;
    if (segments.isEmpty) return null;
    return last ? segments.last.flight : segments.first.flight;
  }

  String _airportCode(String raw, {String? preferred}) {
    if (preferred != null && preferred.trim().length == 3) return preferred.trim().toUpperCase();
    final match = RegExp(r'\(([A-Za-z]{3})\)').firstMatch(raw);
    if (match != null) return match.group(1)!.toUpperCase();
    final compact = raw.trim().toUpperCase();
    if (compact.length == 3) return compact;
    final head = compact.split(RegExp(r'[\s,/\-]+')).first;
    return head.isEmpty ? '--' : head;
  }

  String _cityOf(FlightRouteSegment leg, {required bool origin}) {
    final city = (origin ? leg.fromCity : leg.toCity)?.trim() ?? '';
    if (city.isNotEmpty) return city;
    return origin ? leg.from.trim() : leg.to.trim();
  }

  String _legDate(int legIndex) {
    // departureDate is set per-leg and is always correct — use it first.
    // _flightAt falls back to tripIdx=0 for any leg that has akFareData,
    // which would return the onward date for the return leg.
    final legDate = _legs[legIndex].departureDate?.trim() ?? '';
    if (legDate.isNotEmpty) return legDate;
    final raw = _flightAt(legIndex, last: false)?.departureTime ?? '';
    if (raw.trim().isNotEmpty) {
      try {
        return DateFormat('EEE, dd MMM').format(DateTime.parse(raw.trim().replaceFirst(' ', 'T')));
      } catch (_) {}
    }
    return '';
  }

  String _stopsLabel(FlightRouteSegment leg) {
    final stops = leg.stops;
    if (stops == null || stops <= 0) return 'Non Stop';
    return '$stops Stop${stops > 1 ? 's' : ''}';
  }

  String _airportLine(String name, String terminal) {
    final n = name.trim();
    final t = terminal.trim();
    if (n.isEmpty && t.isEmpty) return '';
    if (n.isEmpty) return 'Terminal $t';
    if (t.isEmpty) return n;
    return '$n, Terminal $t';
  }

  String _flightNumber(FlightRouteSegment leg) =>
      leg.flightNo.replaceAll('•', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  String _airlineCode(FlightRouteSegment leg) =>
      leg.flightNo.contains('•') ? leg.flightNo.split('•').first.trim() : '';

  // -------------------------------------------------------------------------
  // E-ticket PDF (unchanged behaviour)
  // -------------------------------------------------------------------------

  Future<void> _downloadTicket() async {
    setState(() => _downloading = true);
    try {
      final logoData = await rootBundle.load('assets/appLogo/wanderlogo2.png');
      final logoBytes = logoData.buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

      final leadName =
          '${widget.leadPassenger['firstName'] ?? ''} ${widget.leadPassenger['lastName'] ?? ''}'.trim();
      final passengerName = widget.travellerNames.isNotEmpty ? widget.travellerNames.join(', ') : leadName;
      final legs = [
        for (int i = 0; i < _legs.length; i++)
          AkTicketLeg(
            label: _legLabel(i),
            airline: _legs[i].airline,
            flightNo: _legs[i].flightNo,
            from: _legs[i].from,
            to: _legs[i].to,
            departureTime: _legs[i].departureTime,
            arrivalTime: _legs[i].arrivalTime,
            departureDate: _legs[i].departureDate,
            duration: _legs[i].duration,
            baggage: _legs[i].akFareData?.includedBaggage.values.firstOrNull?.values.firstOrNull?.checkin,
            cabinBaggage: _legs[i].akFareData?.includedBaggage.values.firstOrNull?.values.firstOrNull?.cabin,
            terminal: _flightAt(i, last: false)?.departureTerminal,
            arrivalTerminal: _flightAt(i, last: true)?.arrivalTerminal,
          ),
      ];
      final ticketInfo = widget.booking.allTicketInfo;
      final pdf = FlightPdfBuilder.buildAkTicket(
        legs: legs,
        pnrs: widget.booking.pnrs,
        passengerName: passengerName.isEmpty ? 'Guest' : passengerName,
        email: (widget.leadPassenger['email'] ?? '').toString(),
        phone: (widget.leadPassenger['mobileNumber'] ?? '').toString(),
        transactionId: widget.transactionId,
        displayAmount: _displayAmount,
        ticketNumber: ticketInfo.isNotEmpty ? ticketInfo.first.ticketNo : null,
        travellerCount: widget.travellerCount,
        flightClass: 'Economy',
        paidVia: widget.transactionId != null ? 'razorpay' : 'wallet',
        passengers: _pax,
        currency: 'INR',
        bookingId: widget.booking.bookingId,
        logo: logoImage,
      );

      final pnrLabel = widget.booking.pnrs.isNotEmpty ? widget.booking.pnrs.first : 'ticket';
      final file = await PDFService.savePDF(pdf, 'eticket_$pnrLabel.pdf');
      final fileName = file.path.split(Platform.pathSeparator).last;

      // The app sandbox copy above is what Share and the notification point
      // at; this is the one the traveller keeps. The system Save dialog lets
      // them drop it in Downloads (or Drive) without the app needing storage
      // permission, which Android 11+ would not grant for /Download anyway.
      final savedPath = await PDFService.saveToDevice(file, fileName: fileName);

      // A tray notification as well as the snackbar: the snackbar is gone in
      // seconds, while the saved ticket is something the traveller comes back
      // to. Local to this device — nothing about it goes to the server.
      await PushNotificationService.instance.showFileSaved(
        title: 'E-ticket downloaded',
        body: '$fileName — ${widget.route.from} to ${widget.route.to}',
        filePath: file.path,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          dismissDirection: DismissDirection.down,
          content: Text(savedPath == null
              ? 'E-ticket ready: $fileName'
              : 'E-ticket saved to your phone: $fileName'),
          action: SnackBarAction(label: 'Share', onPressed: () => PDFService.sharePDF(file)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate ticket: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _goHome() => Navigator.of(context).popUntil((r) => r.isFirst);

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(context.w(16), context.h(20), context.w(16), context.h(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _successHeader(context),
              SizedBox(height: context.h(28)),
              _paymentCard(context),
              SizedBox(height: context.h(24)),
              for (int i = 0; i < _legs.length; i++) ...[
                if (i > 0) SizedBox(height: context.h(16)),
                _flightCard(context, i),
              ],
              SizedBox(height: context.h(24)),
              _travellerSection(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  // ==================== SUCCESS HEADER ====================
  Widget _successHeader(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: context.h(180),
          // Confetti behind, the tick on top — the tick is drawn, not an
          // asset, so it still lands if `celebrate.json` ever fails to load.
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                // child: Lottie.asset(
                //   'assets/animation/success.json',
                //   repeat: false,
                //   fit: BoxFit.contain,
                child: Lottie.asset(
                  'assets/animation/celebrate.json',
                  repeat: true,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              // Success green, the same one the rest of this screen uses for
              // "paid" — it reads against the blue "Payment Successful!" title.
              _SuccessTick(size: context.w(96), color: const Color(0xFF16A34A)),
            ],
          ),
        ),
        SizedBox(height: context.h(4)),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFF00A1E4), Color(0xFF0088FF)],
          ).createShader(rect),
          child: Text(
            'Payment Successful!',
            textAlign: TextAlign.center,
            style: GoogleFonts.pottaOne(
              fontSize: context.fs(24),
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
        ),
        SizedBox(height: context.h(6)),
        Text(
          'Your booking is confirmed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
      ],
    );
  }

  // ==================== PAYMENT CARD ====================
  Widget _paymentCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke.withValues(alpha: 0.9), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _payCell(
                    context,
                    icon: Icons.payments_rounded,
                    label: 'AMOUNT PAID',
                    value: _displayAmount,
                    valueColor: _pri,
                    valueWeight: FontWeight.w700,
                  ),
                ),
                Container(width: 0.5, color: _stroke.withValues(alpha: 0.7)),
                Expanded(
                  child: _payCell(
                    context,
                    icon: Icons.calendar_month_rounded,
                    label: 'PAYMENT DATE',
                    value: _paymentDate,
                    valueColor: Colors.black,
                    valueWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
            decoration: BoxDecoration(
              color: const Color(0xFF56B0FF).withValues(alpha: 0.04),
              border: Border(top: BorderSide(color: _stroke.withValues(alpha: 0.9), width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Booking ID: '),
                      TextSpan(
                        text: _bookingId,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: _pri),
                      ),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w500,
                      color: _muted,
                    ),
                  ),
                ),
                SizedBox(width: context.w(8)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(2)),
                  decoration: BoxDecoration(
                    color: _pri.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(context.r(6)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: _pri,
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

  Widget _payCell(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required FontWeight valueWeight,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: context.w(16), color: _pri),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w600,
                    color: _muted,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(value.length > 16 ? 11 : 13),
                    fontWeight: valueWeight,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FLIGHT CARD ====================
  Widget _flightCard(BuildContext context, int legIndex) {
    final leg = _legs[legIndex];
    final first = _flightAt(legIndex, last: false);
    final last = _flightAt(legIndex, last: true);

    final fromCode = _airportCode(leg.from, preferred: first?.departureCode);
    final toCode = _airportCode(leg.to, preferred: last?.arrivalCode);
    final date = _legDate(legIndex);
    final depAirport = _airportLine(first?.depAirportName ?? '', first?.departureTerminal ?? '');
    final arrAirport = _airportLine(last?.arrAirportName ?? '', last?.arrivalTerminal ?? '');
    final flightNo = _flightNumber(leg);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ---- gradient header ----
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.w(16)),
            decoration: const BoxDecoration(gradient: _headerGradient),
            child: Stack(
              children: [
                Positioned(
                  right: -context.w(6),
                  top: -context.h(2),
                  child: Icon(
                    Icons.flight_rounded,
                    size: context.w(58),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.flight_takeoff_rounded, size: context.w(20), color: Colors.white),
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _cityOf(leg, origin: true),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.fs(18),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: context.w(6)),
                                child: Icon(Icons.arrow_forward_rounded,
                                    size: context.w(12), color: Colors.white),
                              ),
                              Flexible(
                                child: Text(
                                  _cityOf(leg, origin: false),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.fs(18),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.h(6)),
                          Wrap(
                            spacing: context.w(6),
                            runSpacing: context.h(4),
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (date.isNotEmpty)
                                _headerChip(context, 'assets/NewIcons/calender.png', date),
                              _headerChip(context, 'assets/NewIcons/clock.png',
                                  '${leg.departureTime} – ${leg.arrivalTime}'),
                              _headerChip(context, 'assets/NewIcons/no_stops.png', _stopsLabel(leg)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.w(10)),
                    _pnrTag(context, legIndex),
                  ],
                ),
              ],
            ),
          ),
          // ---- white body ----
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.w(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: _stroke.withValues(alpha: 0.6), width: 0.5),
                right: BorderSide(color: _stroke.withValues(alpha: 0.6), width: 0.5),
                bottom: BorderSide(color: _stroke.withValues(alpha: 0.6), width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // airline
                SizedBox(
                  width: context.w(58),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AirlineLogo(
                        code: _airlineCode(leg),
                        name: leg.airline,
                        size: context.w(42),
                        borderRadius: BorderRadius.circular(context.r(8)),
                      ),
                      SizedBox(height: context.h(6)),
                      Text(
                        leg.airline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      if (flightNo.isNotEmpty) ...[
                        SizedBox(height: context.h(3)),
                        Text(
                          flightNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: context.fs(10), color: _muted),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 0.5,
                  height: context.h(80),
                  margin: EdgeInsets.symmetric(horizontal: context.w(12)),
                  color: _stroke.withValues(alpha: 0.7),
                ),
                // route
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _endpoint(
                          context,
                          code: fromCode,
                          time: leg.departureTime,
                          airport: depAirport,
                          alignEnd: false,
                        ),
                      ),
                      SizedBox(
                        width: context.w(64),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(child: _DashedRule()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: context.w(2)),
                                  child: Transform.rotate(
                                    angle: math.pi / 2,
                                    child: Icon(Icons.flight, size: context.w(12), color: _pri),
                                  ),
                                ),
                                const Expanded(child: _DashedRule()),
                              ],
                            ),
                            SizedBox(height: context.h(5)),
                            Text(
                              leg.duration,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.fs(9),
                                fontWeight: FontWeight.w700,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _endpoint(
                          context,
                          code: toCode,
                          time: leg.arrivalTime,
                          airport: arrAirport,
                          alignEnd: true,
                        ),
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
  }

  Widget _pnrTag(BuildContext context, int legIndex) {
    return Container(
      constraints: BoxConstraints(maxWidth: context.w(112)),
      padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(6)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PNR:',
            style: TextStyle(
              fontSize: context.fs(10),
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(width: context.w(4)),
          Flexible(
            child: Text(
              _pnrFor(legIndex),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w700,
                color: _sec,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerChip(BuildContext context, String asset, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          asset,
          width: context.w(8),
          height: context.w(8),
          color: Colors.white,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        SizedBox(width: context.w(4)),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(8.5),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _endpoint(
    BuildContext context, {
    required String code,
    required String time,
    required String airport,
    required bool alignEnd,
  }) {
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final align = alignEnd ? TextAlign.right : TextAlign.left;
    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        if (time.trim().isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(10),
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
        if (airport.isNotEmpty) ...[
          SizedBox(height: context.h(6)),
          Text(
            airport,
            textAlign: align,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(10),
              fontWeight: FontWeight.w500,
              color: _muted,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  // ==================== TRAVELLER SECTION ====================
  Widget _travellerSection(BuildContext context) {
    final pax = _pax;
    final visible = _showAllPax ? pax : pax.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRAVELLER',
          style: TextStyle(
            fontSize: context.fs(10),
            fontWeight: FontWeight.w700,
            color: _muted,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: context.h(16)),
        for (int i = 0; i < visible.length; i++) ...[
          if (i > 0) SizedBox(height: context.h(18)),
          _travellerRow(context, visible[i], i),
        ],
        if (pax.length > 2) ...[
          SizedBox(height: context.h(14)),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showAllPax = !_showAllPax),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showAllPax ? 'View less' : 'View more',
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w600,
                      color: _pri,
                    ),
                  ),
                  Icon(
                    _showAllPax ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: context.w(14),
                    color: _pri,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _travellerRow(BuildContext context, Map<String, dynamic> m, int index) {
    final ptc = _s(m, 'paxType').isEmpty ? 'ADT' : _s(m, 'paxType');
    final typeLabel = _ptcLabel(ptc);
    final age = _ageLabel(_s(m, 'dateOfBirth'));

    final typeIcon = switch (typeLabel) {
      'Child' => Icons.child_friendly_rounded,
      'Infant' => Icons.child_care_rounded,
      _ => Icons.person_rounded,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.w(28),
          height: context.w(28),
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
          child: Icon(typeIcon, size: context.w(13), color: _pri),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _fullName(m, index),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (age != null) ...[
                    SizedBox(width: context.w(8)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(2)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(context.r(12)),
                      ),
                      child: Text(
                        age,
                        style: TextStyle(fontSize: context.fs(8.5), fontWeight: FontWeight.w500, color: _muted),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: context.h(6)),
              Wrap(
                spacing: context.w(10),
                runSpacing: context.h(5),
                children: [
                  _paxChip(context, typeIcon, typeLabel),
                  _paxChip(context, Icons.luggage_rounded, _baggageFor(ptc)),
                  _paxChip(context, Icons.airline_seat_recline_normal_rounded,
                      _addOnAt(widget.addOns.seatNumbers, index)),
                  _paxChip(context, Icons.restaurant_rounded, _addOnAt(widget.addOns.meals, index)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'E-TICKET NO',
              style: TextStyle(
                fontSize: context.fs(9.5),
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
            SizedBox(height: context.h(2)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.w(96)),
              child: Text(
                _ticketFor(index),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _paxChip(BuildContext context, IconData icon, String label) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: context.w(150)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.w(11), color: _muted),
          SizedBox(width: context.w(4)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(8.5),
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM BAR ====================
  Widget _bottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.r(24))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(19), vertical: context.h(12)),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: context.h(48),
                  child: OutlinedButton(
                    onPressed: _goHome,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _sec),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                    ),
                    child: FittedBox(
                      child: Text(
                        'GO TO HOME',
                        style: TextStyle(
                          color: _sec,
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: SizedBox(
                  height: context.h(48),
                  child: ElevatedButton(
                    onPressed: _downloading ? null : _downloadTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sec,
                      disabledBackgroundColor: _sec.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_downloading)
                          SizedBox(
                            width: context.w(16),
                            height: context.w(16),
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          Icon(Icons.download_rounded, size: context.w(18), color: Colors.white),
                        SizedBox(width: context.w(8)),
                        Flexible(
                          child: FittedBox(
                            child: Text(
                              _downloading ? 'PREPARING…' : 'DOWNLOAD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.fs(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ),
    );
  }
}

/// The thin dashed rule either side of the plane glyph on the flight card's
/// route connector.
class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const dash = 3.0;
        const gap = 3.0;
        final count = (c.maxWidth / (dash + gap)).floor().clamp(0, 40);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: dash,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFCCCCCC))),
            ),
          ),
        );
      },
    );
  }
}

/// The GPay-style confirmation tick: a disc that pops in, a check stroke that
/// draws itself, and a ring that ripples outward once and fades. Painted
/// rather than shipped as a Lottie file so it can't go missing, and so it
/// scales with [context.w] like everything else on this screen.
class _SuccessTick extends StatefulWidget {
  const _SuccessTick({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_SuccessTick> createState() => _SuccessTickState();
}

class _SuccessTickState extends State<_SuccessTick>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// The disc settling is the moment that gets the buzz — once per screen.
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addListener(_onTick);
    _controller.forward();
  }

  void _onTick() {
    if (_tapped || _controller.value < 0.42) return;
    _tapped = true;
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _SuccessTickPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _SuccessTickPainter extends CustomPainter {
  _SuccessTickPainter({required this.progress, required this.color});

  /// 0 -> 1 across the whole animation. The three beats overlap deliberately:
  /// the check starts drawing while the disc is still settling, which is what
  /// makes it read as one gesture instead of three separate steps.
  final double progress;
  final Color color;

  static double _phase(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // --- ring ripple: expands past the disc and fades out ---
    final ripple = _phase(progress, 0.40, 1.0);
    if (ripple > 0 && ripple < 1) {
      final eased = Curves.easeOutCubic.transform(ripple);
      canvas.drawCircle(
        center,
        radius * (1 + (0.35 * eased)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.03
          ..color = color.withValues(alpha: 0.35 * (1 - eased)),
      );
    }

    // --- disc: scales up with a slight overshoot ---
    final pop = _phase(progress, 0.0, 0.45);
    if (pop <= 0) return;
    final scale = Curves.easeOutBack.transform(pop);
    canvas.drawCircle(
      center,
      radius * scale,
      Paint()..color = color.withValues(alpha: Curves.easeOut.transform(pop)),
    );

    // --- check: stroked on, short arm first ---
    final draw = _phase(progress, 0.32, 0.78);
    if (draw <= 0) return;
    final eased = Curves.easeOutCubic.transform(draw);

    // Proportions of the box, so the tick keeps its shape at any size.
    final path = Path()
      ..moveTo(size.width * 0.29, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.37);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * eased),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_SuccessTickPainter old) =>
      old.progress != progress || old.color != color;
}
