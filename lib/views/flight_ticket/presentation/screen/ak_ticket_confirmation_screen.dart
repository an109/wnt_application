import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';
import 'package:wander_nova/common_widgets/custom_bottom_nav.dart';
import 'package:wander_nova/common_widgets/logo.dart';
import 'package:wander_nova/core/services/pdf_generator.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/AKRetrieveBooking/domain/entity/AKRetrieveBooking_entity.dart';
import 'package:wander_nova/views/MyBookings/Flights/Screen/flight_pdf_builder.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';

/// Booking confirmation for the Akbar flow, built from RetrieveBooking's
/// response. Deliberately a new, simple widget rather than a retrofit of
/// [TicketVoucherScreen] (whose props are TBO-shaped and reused by the TBO
/// booking flow).
class AkTicketConfirmationScreen extends StatefulWidget {
  final AkRetrieveBookingEntity booking;
  final FlightRouteSegment route;

  /// The return leg for RT/RS, or legs 2..N for Multi City. Empty for a
  /// plain one-way booking.
  final List<FlightRouteSegment> additionalLegs;
  final Map<String, dynamic> leadPassenger;

  /// The payment gateway's transaction reference (Razorpay payment id).
  /// Null for wallet payments, where there's no gateway transaction.
  final String? transactionId;

  /// Amount actually paid, in INR (Akbar's native currency) — converted to
  /// the user's preferred display currency for both the PDF and any future
  /// on-screen total.
  final double netAmount;

  /// Total travellers on this booking (adults + children + infants), used
  /// to label the PDF/summary correctly for 1 vs 2+ passengers.
  final int travellerCount;

  /// Every traveller's full name (not just the lead's), so the ticket lists
  /// everyone on a 2+ passenger booking instead of only the lead.
  final List<String> travellerNames;

  const AkTicketConfirmationScreen({
    super.key,
    required this.booking,
    required this.route,
    this.additionalLegs = const [],
    required this.leadPassenger,
    this.transactionId,
    required this.netAmount,
    this.travellerCount = 1,
    this.travellerNames = const [],
  });

  @override
  State<AkTicketConfirmationScreen> createState() => _AkTicketConfirmationScreenState();
}

class _AkTicketConfirmationScreenState extends State<AkTicketConfirmationScreen> {
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _green = Color(0xFF16A34A);
  static const _pageBg = Color(0xFFF3F6FC);
  static const _border = Color(0xFFE2E7F0);

  bool _downloading = false;

  List<FlightRouteSegment> get _legs => [widget.route, ...widget.additionalLegs];

  /// True only for a genuine round trip: exactly one additional leg that
  /// flies back to the original origin. Anything else with additional legs
  /// (2+ distinct destinations) is multi-city, not a round trip.
  bool get _isRoundTrip =>
      widget.additionalLegs.length == 1 &&
      widget.additionalLegs.first.to.trim().toLowerCase() == widget.route.from.trim().toLowerCase();

  bool get _isMultiCity => widget.additionalLegs.isNotEmpty && !_isRoundTrip;

  /// "Onward"/"Return" for a round trip, "Leg N" for multi-city, null for a
  /// plain one-way booking (no label needed).
  String? _legLabel(int index) {
    if (widget.additionalLegs.isEmpty) return null;
    if (_isRoundTrip) return index == 0 ? 'Onward' : 'Return';
    return 'Leg ${index + 1}';
  }

  String get _displayAmount {
    final prefs = sl<PreferencesManager>();
    final target = prefs.getPreferredCurrency() ?? 'INR';
    final converted = target.toUpperCase() == 'INR'
        ? widget.netAmount
        : CurrencyConverter.convert(amount: widget.netAmount, fromCurrency: 'INR', toCurrency: target);
    return CurrencyConverter.format(converted, target);
  }

  Future<void> _downloadTicket() async {
    setState(() => _downloading = true);
    try {
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
      );

      final pnrLabel = widget.booking.pnrs.isNotEmpty ? widget.booking.pnrs.first : 'ticket';
      final file = await PDFService.savePDF(pdf, 'eticket_$pnrLabel.pdf');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-ticket saved: ${file.path.split(Platform.pathSeparator).last}'),
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

  @override
  Widget build(BuildContext context) {
    final pnr = widget.booking.pnrs.isNotEmpty ? widget.booking.pnrs.join(', ') : '—';
    final passengerName =
        '${widget.leadPassenger['firstName'] ?? ''} ${widget.leadPassenger['lastName'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: _pageBg,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: context.hp(2)),
              Center(
                child: Container(
                  width: context.w(64),
                  height: context.w(64),
                  decoration: const BoxDecoration(color: Color(0xffEAFBF1), shape: BoxShape.circle),
                  child: Icon(Icons.check_circle, color: _green, size: context.w(36)),
                ),
              ),
              SizedBox(height: context.h(14)),
              Center(
                child: Text(
                  'Booking Confirmed',
                  style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w900, color: _navy),
                ),
              ),
              SizedBox(height: context.h(6)),
              Center(
                child: Text(
                  _isRoundTrip
                      ? '${widget.route.from} ⇌ ${widget.additionalLegs.last.to} · Round Trip'
                      : _isMultiCity
                          ? '${[widget.route.from, ...widget.additionalLegs.map((l) => l.to)].join(' → ')} · Multi City'
                          : '${widget.route.from} → ${widget.route.to} · One Way',
                  style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600),
                ),
              ),
              SizedBox(height: context.h(4)),
              Center(
                child: Text(
                  '${widget.travellerCount} Traveller${widget.travellerCount == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: context.fs(11.5), color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: context.hp(3)),
              for (int i = 0; i < _legs.length; i++)
                _flightCard(context, _legs[i], _legLabel(i)),
              Container(
                padding: EdgeInsets.all(context.w(14)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(14)),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(context, 'PNR', pnr, emphasize: true),
                    SizedBox(height: context.h(8)),
                    _row(context, 'Passenger', passengerName),
                    SizedBox(height: context.h(8)),
                    _row(context, 'Amount Paid', _displayAmount),
                    if ((widget.transactionId ?? '').isNotEmpty) ...[
                      SizedBox(height: context.h(8)),
                      _row(context, 'Transaction ID', widget.transactionId!),
                    ],
                  ],
                ),
              ),
              SizedBox(height: context.hp(3)),
              SizedBox(
                height: context.buttonHeight + 10,
                child: OutlinedButton.icon(
                  onPressed: _downloading ? null : _downloadTicket,
                  icon: _downloading
                      ? SizedBox(
                          width: context.w(16),
                          height: context.w(16),
                          child: const CircularProgressIndicator(strokeWidth: 2, color: _blue),
                        )
                      : const Icon(Icons.download_rounded, color: _blue),
                  label: Text(
                    _downloading ? 'Preparing E-Ticket...' : 'Download E-Ticket',
                    style: TextStyle(color: _blue, fontWeight: FontWeight.bold, fontSize: context.bodyLarge),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(18))),
                  ),
                ),
              ),
              SizedBox(height: context.h(10)),
              SizedBox(
                height: context.buttonHeight + 10,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(18))),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: context.bodyLarge),
                  ),
                ),
              ),
              SizedBox(height: context.hp(2)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _flightCard(BuildContext context, FlightRouteSegment leg, String? label) {
    // flightNo is formatted as "<code> • <number>" upstream — split it back
    // apart so the logo can be looked up by the plain IATA code.
    final airlineCode = leg.flightNo.contains('•') ? leg.flightNo.split('•').first.trim() : '';

    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: _navy.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(context.r(20)),
              ),
              child: Text(
                label,
                style: TextStyle(color: _blue, fontSize: context.fs(10.5), fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(height: context.h(10)),
          ],
          Row(
            children: [
              AirlineLogo(code: airlineCode, name: leg.airline, size: context.w(26)),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  '${leg.airline} · ${leg.flightNo}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: _navy),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leg.departureTime,
                      style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w900, color: _navy),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      leg.from,
                      style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: _navy),
                    ),
                    if ((leg.departureDate ?? '').isNotEmpty)
                      Text(
                        leg.departureDate!,
                        style: TextStyle(fontSize: context.fs(10.5), color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(6)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flight_takeoff_rounded, size: context.w(16), color: _blue),
                    SizedBox(height: context.h(3)),
                    Text(
                      leg.duration,
                      style: TextStyle(fontSize: context.fs(9.5), color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      leg.arrivalTime,
                      style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w900, color: _navy),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      leg.to,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: _navy),
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

  Widget _row(BuildContext context, String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: context.fs(12)),
        ),
        Flexible(
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _navy,
              fontSize: context.fs(emphasize ? 15 : 12),
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
