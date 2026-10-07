import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../Screen/trip_card.dart';
import '../domain/entities/FlightBookEntity.dart';
import '../domain/flight_trip_info.dart';
import 'flight_pdf_builder.dart';
import 'flight_trip_details_screen.dart' show saveAndOfferPdf;

// Figma "Booking Tickets" (412px wide): one boarding-pass card per leg with
// the booking reference and its barcode.

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF6B7280);

/// One leg as shown on a ticket card.
class _Leg {
  final String airline;
  final String airlineCode;
  final String flightNumber;
  final String fromCode, fromCity, toCode, toCity, terminal;
  final DateTime? dep, arr;
  final String duration;
  final String baggage;

  const _Leg({
    required this.airline,
    required this.airlineCode,
    required this.flightNumber,
    required this.fromCode,
    required this.fromCity,
    required this.toCode,
    required this.toCity,
    required this.terminal,
    required this.dep,
    required this.arr,
    required this.duration,
    required this.baggage,
  });
}

class FlightTicketScreen extends StatelessWidget {
  final FlightBookEntity booking;

  const FlightTicketScreen({super.key, required this.booking});

  List<_Leg> _legs() {
    final info = FlightTripInfo(booking);
    if (booking.tboSegments.isEmpty) {
      return [
        _Leg(
          airline: info.airline,
          airlineCode: info.airlineCode,
          flightNumber: info.flightNumber,
          fromCode: info.fromCode,
          fromCity: info.fromCity,
          toCode: info.toCode,
          toCity: info.toCity,
          terminal: '',
          dep: info.departure,
          arr: null,
          duration: '',
          baggage: '',
        ),
      ];
    }
    return [
      for (final s in booking.tboSegments)
        () {
          // Each leg on its own, so reuse the single-leg maths.
          final one = FlightTripInfo(_withSegments(booking, [s]));
          return _Leg(
            airline: one.airline,
            airlineCode: one.airlineCode,
            flightNumber: one.flightNumber,
            fromCode: one.fromCode,
            fromCity: one.fromCity,
            toCode: one.toCode,
            toCity: one.toCity,
            terminal: one.arrivalTerminal,
            dep: one.departure,
            arr: one.arrival,
            duration: one.durationLabel ?? '',
            baggage: one.checkInBaggage,
          );
        }(),
    ];
  }

  static FlightBookEntity _withSegments(FlightBookEntity b, List<Map<String, dynamic>> segs) => FlightBookEntity(
    id: b.id,
    flightType: b.flightType,
    flightNumber: b.flightNumber,
    fromCity: b.fromCity,
    toCity: b.toCity,
    departureDate: b.departureDate,
    returnDate: b.returnDate,
    passengers: b.passengers,
    flightClass: b.flightClass,
    guestReference: b.guestReference,
    bookingToken: b.bookingToken,
    segments: b.segments,
    email: b.email,
    phone: b.phone,
    passportNumber: b.passportNumber,
    bookingDate: b.bookingDate,
    pnr: b.pnr,
    tboBookingId: b.tboBookingId,
    totalAmount: b.totalAmount,
    currency: b.currency,
    ssrSelections: b.ssrSelections,
    passengersData: b.passengersData,
    created: b.created,
    updated: b.updated,
    tboSegments: segs,
  );

  @override
  Widget build(BuildContext context) {
    final info = FlightTripInfo(booking);
    final legs = _legs();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(12), context.fx(16), context.fx(12)),
              child: FilledButton.icon(
                onPressed: () => saveAndOfferPdf(
                  context,
                  filename: 'ticket_${booking.pnr.isEmpty ? booking.id : booking.pnr}.pdf',
                  build: (logo) async => FlightPdfBuilder.buildTicket(booking: booking, logo: logo),
                ),
                icon: Icon(Icons.download_rounded, size: context.fx(20)),
                label: Text(
                  'DOWNLOAD TICKETS',
                  style: TextStyle(fontSize: context.ffs(14), fontWeight: FontWeight.w600, letterSpacing: 0.2),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEE7330),
                  minimumSize: Size.fromHeight(context.fx(50)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.fx(10))),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Sky backdrop behind the top of the ticket.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: context.fx(360),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2F86D1), Color(0xFF8CC8F2), Color(0xFFF2F4F7)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: -context.fx(60),
                    right: -context.fx(60),
                    bottom: -context.fx(10),
                    child: Opacity(
                      opacity: 0.85,
                      child: Image.asset('assets/home/footer_clouds.png', height: context.fx(170), fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(context.fx(8), context.fx(6), context.fx(16), 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(Icons.arrow_back, color: Colors.white, size: context.fx(24)),
                        ),
                        Text(
                          legs.length > 1 ? 'Tickets' : 'Ticket',
                          style: TextStyle(fontSize: context.ffs(20), fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      physics: context.scrollPhysics,
                      padding: EdgeInsets.fromLTRB(context.fx(20), context.fx(16), context.fx(20), context.fx(24)),
                      itemCount: legs.length,
                      separatorBuilder: (_, __) => SizedBox(height: context.fx(20)),
                      itemBuilder: (context, i) => _TicketCard(
                        leg: legs[i],
                        info: info,
                        pnr: booking.pnr,
                        label: legs.length > 1 ? 'Flight ${i + 1} of ${legs.length}' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final _Leg leg;
  final FlightTripInfo info;
  final String pnr;
  final String? label;

  const _TicketCard({required this.leg, required this.info, required this.pnr, this.label});

  @override
  Widget build(BuildContext context) {
    final notch = context.fx(14);
    final corner = context.fx(16);
    final pad = EdgeInsets.symmetric(horizontal: context.fx(18));

    Widget side(DateTime? when, String kind, String code, String extra, CrossAxisAlignment align) {
      final ta = align == CrossAxisAlignment.end ? TextAlign.end : TextAlign.start;
      return Column(
        crossAxisAlignment: align,
        children: [
          Text.rich(
            TextSpan(
              text: when == null ? '--:--' : tripTime(when),
              children: [
                TextSpan(
                  text: ' ($kind)',
                  style: TextStyle(fontSize: context.ffs(11), fontWeight: FontWeight.w400, color: _kMuted),
                ),
              ],
            ),
            textAlign: ta,
            style: TextStyle(fontSize: context.ffs(18), fontWeight: FontWeight.w600, color: _kInk),
          ),
          if (when != null)
            Text(tripDayLabel(when), textAlign: ta, style: TextStyle(fontSize: context.ffs(11), color: _kInk)),
          Text(
            [code, if (extra.isNotEmpty) extra].join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: ta,
            style: TextStyle(fontSize: context.ffs(10), color: _kMuted),
          ),
        ],
      );
    }

    final top = Padding(
      padding: EdgeInsets.fromLTRB(context.fx(18), context.fx(18), context.fx(18), context.fx(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Text(label!, style: TextStyle(fontSize: context.ffs(11), fontWeight: FontWeight.w600, color: AppColors.AppBlue)),
            SizedBox(height: context.fx(8)),
          ],
          Row(
            children: [
              AirlineLogo(
                code: leg.airlineCode,
                name: leg.airline,
                size: context.fx(48),
                borderRadius: BorderRadius.circular(context.fx(10)),
              ),
              SizedBox(width: context.fx(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leg.airline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.ffs(16), fontWeight: FontWeight.w600, color: _kInk),
                    ),
                    Text(
                      '${leg.fromCity} to ${leg.toCity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.ffs(13), color: _kMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(18)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: side(leg.dep, 'Depart', leg.fromCode, '', CrossAxisAlignment.start)),
              SizedBox(
                width: context.fx(80),
                child: Padding(
                  padding: EdgeInsets.only(top: context.fx(2)),
                  child: Column(
                    children: [
                      Text(leg.duration, style: TextStyle(fontSize: context.ffs(10.5), color: _kInk)),
                      SizedBox(height: context.fx(3)),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const TripDashedLine(color: Color(0xFFB8C0CC)),
                          Container(
                            color: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: context.fx(2)),
                            child: Icon(Icons.flight_rounded, size: context.fx(13), color: AppColors.AppBlue),
                          ),
                        ],
                      ),
                      SizedBox(height: context.fx(3)),
                      Text('Non Stop', style: TextStyle(fontSize: context.ffs(10.5), color: _kMuted)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: side(
                  leg.arr,
                  'Arrive',
                  leg.toCode,
                  leg.terminal.isEmpty ? '' : 'Terminal ${leg.terminal.replaceFirst(RegExp(r'^[Tt]erminal\s*'), '')}',
                  CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.fx(14)),
            child: const TripDashedLine(color: Color(0xFFD5D9E0)),
          ),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.person_rounded,
                  tint: const Color(0xFFE91E63),
                  label: 'Passengers',
                  value: info.paxLabel,
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.airline_seat_recline_normal_rounded,
                  tint: const Color(0xFF4CAF50),
                  label: 'Cabin Class',
                  value: info.cabinClass.isEmpty ? '—' : info.cabinClass,
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(14)),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.flight_rounded,
                  tint: const Color(0xFF3B82F6),
                  label: 'Flight No.',
                  value: leg.flightNumber.isEmpty ? '—' : leg.flightNumber,
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.work_rounded,
                  tint: const Color(0xFFF07C35),
                  label: 'Baggage',
                  value: leg.baggage.isEmpty ? 'As per airline' : leg.baggage,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final bottom = Padding(
      padding: pad.copyWith(top: context.fx(10)),
      child: Column(
        children: [
          Text('Booking Reference', style: TextStyle(fontSize: context.ffs(13), color: _kMuted)),
          Text(
            pnr.isEmpty ? '—' : pnr,
            style: TextStyle(fontSize: context.ffs(22), fontWeight: FontWeight.w700, letterSpacing: 1.5, color: _kInk),
          ),
          if (pnr.isNotEmpty) ...[
            SizedBox(height: context.fx(8)),
            SizedBox(
              height: context.fx(46),
              width: context.fx(200),
              child: CustomPaint(painter: _BarcodePainter(pnr)),
            ),
          ],
        ],
      ),
    );

    final bottomHeight = context.fx(pnr.isEmpty ? 76 : 132);
    return PhysicalShape(
      clipper: _TicketClipper(corner: corner, notch: notch, stubHeight: bottomHeight),
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x40000000),
      child: Column(
        children: [
          top,
          SizedBox(
            height: bottomHeight,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: notch + context.fx(4)),
                  child: const TripDashedLine(color: Color(0xFFD5D9E0)),
                ),
                bottom,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String value;

  const _Fact({required this.icon, required this.tint, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: context.fx(40),
          height: context.fx(40),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.fx(10)),
          ),
          child: Icon(icon, size: context.fx(20), color: tint),
        ),
        SizedBox(width: context.fx(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: context.ffs(10.5), color: _kMuted)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.ffs(13.5), fontWeight: FontWeight.w500, color: _kInk),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Boarding-pass outline: rounded corners plus a semicircle bite on each
/// side where the stub (the bottom [stubHeight]) tears off.
class _TicketClipper extends CustomClipper<Path> {
  final double corner;
  final double notch;
  final double stubHeight;

  _TicketClipper({required this.corner, required this.notch, required this.stubHeight});

  @override
  Path getClip(Size s) {
    final y = s.height - stubHeight;
    final card = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(corner)));
    final bites = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(s.width, y), radius: notch));
    return Path.combine(PathOperation.difference, card, bites);
  }

  @override
  bool shouldReclip(_TicketClipper old) =>
      old.corner != corner || old.notch != notch || old.stubHeight != stubHeight;
}

/// Code 128 barcode of the booking reference.
class _BarcodePainter extends CustomPainter {
  final String data;

  _BarcodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kInk;
    try {
      for (final e in Barcode.code128().make(data, width: size.width, height: size.height, drawText: false)) {
        if (e is BarcodeBar && e.black) {
          canvas.drawRect(Rect.fromLTWH(e.left, e.top, e.width, e.height), paint);
        }
      }
    } catch (_) {
      // Unencodable reference: just leave the space empty.
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.data != data;
}
