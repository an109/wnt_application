import 'package:flutter/material.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../flight_search/presentation/screen/booking_screen.dart';
import '../../../flight_ssr/presentation/screen/ssr/ssr_price_formatter.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../data/services/booking_details_service.dart';

// ── colour palette (copied from main) ─────────────────────────────────────
const _red      = Color(0xFFE71D36);
const _navy     = Color(0xFF1A3461);
const _navyDark = Color(0xFF0A1931);
const _indigoBg = Color(0xFFF0F4FF);
const _surface  = Colors.white;
const _textDark = Color(0xFF1A1F36);
const _textMid  = Color(0xFF5A6174);
const _green    = Color(0xFF27AE60);
const _greenBg  = Color(0xFFE8F8F0);
const _borderC  = Color(0xFFE4E9F2);

class TicketVoucherETicket extends StatelessWidget {
  final ScrollController sc;
  final String pnr;
  final String passengerName;
  final String email;
  final List<BookingSegmentDetail> segs;
  final List<BookingPassengerDetail> dpax;
  final List<TicketPassengerEntity> tpax;
  final double baseFare;
  final double tax;
  final double total;
  final String finalTotalStr;
  final FlightRouteSegment route;
  final String Function(double) fmtFn;
  final String Function(String?) timeOnlyFn;
  final String Function(String?) dateOnlyFn;
  final String Function(int?) durFn;
  final Map<String, dynamic> ssrSelections;
  final double promoDiscount;
  final String promoCode;
  final String preferredCurrency;

  const TicketVoucherETicket({
    super.key,
    required this.sc,
    required this.pnr,
    required this.passengerName,
    required this.email,
    required this.segs,
    required this.dpax,
    required this.tpax,
    required this.baseFare,
    required this.tax,
    required this.total,
    this.finalTotalStr = '',
    required this.route,
    required this.fmtFn,
    required this.timeOnlyFn,
    required this.dateOnlyFn,
    required this.durFn,
    this.ssrSelections = const {},
    this.promoDiscount = 0.0,
    this.promoCode = '',
    this.preferredCurrency = 'INR',
  });

  // ── SSR helpers ────────────────────────────────────────────────────────────
  String get _currency => route.fareQuoteData?.currency ?? 'INR';

  double _ssrPrice(String key) {
    if (key == 'seat') {
      double total = 0;
      final seats = ssrSelections['seat'];
      if (seats is List) {
        for (final s in seats) {
          if (s is Map) {
            final p = (s['Price'] as num?)?.toDouble() ?? 0;
            final c = (s['Currency'] as String?) ?? _currency;
            total += SsrPriceFormatter.convertAmount(p, c);
          }
        }
      }
      return total;
    }
    final item = ssrSelections[key];
    if (item is Map) {
      final p = (item['Price'] as num?)?.toDouble() ?? 0;
      final c = (item['Currency'] as String?) ?? _currency;
      return SsrPriceFormatter.convertAmount(p, c);
    }
    return 0;
  }

  String _fmtPreferred(double amount) =>
      CurrencyConverter.format(amount, preferredCurrency);

  @override
  Widget build(BuildContext context) {
    final baggageAmt = _ssrPrice('baggage');
    final mealAmt    = _ssrPrice('meal');
    final seatAmt    = _ssrPrice('seat');
    final hasSSR     = baggageAmt > 0 || mealAmt > 0 || seatAmt > 0;
    final hasPromo   = promoDiscount > 0;

    return SingleChildScrollView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(text: const TextSpan(children: [
              TextSpan(text: 'WANDER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0668CC), letterSpacing: 2)),
              TextSpan(text: 'NOVA',   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFE6B02), letterSpacing: 2)),
            ])),
            const Text('TRAVEL SERVICES', style: TextStyle(fontSize: 9, letterSpacing: 4, color: Color(0xFF0EA3A3), fontWeight: FontWeight.w600)),
          ]),
          const Text('E-TICKET', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: _textDark)),
        ]),
        const SizedBox(height: 12),

        // confirmed strip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _greenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withValues(alpha: 0.3))
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded, color: _green, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your booking is confirmed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _green)),
              Text('${passengerName.toUpperCase()}  ·  $email', style: const TextStyle(color: _textMid, fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('PNR', style: TextStyle(fontSize: 9, color: _textMid)),
              Text(pnr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy, letterSpacing: 3)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // segments
        if (segs.isNotEmpty) ...[
          const Text('FLIGHT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
          const SizedBox(height: 8),
          ...segs.asMap().entries.map((e) {
            final i = e.key; final seg = e.value;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (i > 0) Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Stopover · ${seg.originCode ?? ''}', style: const TextStyle(color: _textMid, fontSize: 11))),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                ]),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${seg.airlineName ?? ''} (${seg.airlineCode ?? ''}) · Flt ${seg.flightNumber ?? ''}  ·  Class: ${seg.fareClass ?? '—'}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _textDark)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(seg.originCode ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
                      Text(timeOnlyFn(seg.depTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                      Text(dateOnlyFn(seg.depTime), style: const TextStyle(fontSize: 11, color: _textMid)),
                      Text(seg.originName ?? '', style: const TextStyle(fontSize: 10, color: _textMid), maxLines: 2),
                    ])),
                    Column(children: [
                      Text(durFn(seg.duration), style: const TextStyle(fontSize: 10, color: _textMid)),
                      const Icon(Icons.flight, color: _red, size: 18),
                    ]),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(seg.destCode ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
                      Text(timeOnlyFn(seg.arrTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                      Text(dateOnlyFn(seg.arrTime), style: const TextStyle(fontSize: 11, color: _textMid)),
                      Text(seg.destName ?? '', style: const TextStyle(fontSize: 10, color: _textMid), maxLines: 2, textAlign: TextAlign.right),
                    ])),
                  ]),
                ]),
              ),
            ]);
          }),
          const SizedBox(height: 8),
        ],

        // passengers
        const Text('PASSENGERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border.all(color: _borderC), borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(color: Color(0xFF005EB8), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
              child: const Row(children: [
                Expanded(flex: 3, child: Text('PASSENGER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                Expanded(flex: 3, child: Text('TICKET NO.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.right)),
              ]),
            ),
            ..._paxRows(),
          ]),
        ),
        const SizedBox(height: 16),

        // fare summary
        const Text('FARE SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            _fareLine('Base Fare',    fmtFn(baseFare)),
            const SizedBox(height: 8),
            _fareLine('Taxes & Fees', fmtFn(tax)),
            if (baggageAmt > 0) ...[
              const SizedBox(height: 8),
              _fareLine('Baggage Add-on', _fmtPreferred(baggageAmt)),
            ],
            if (mealAmt > 0) ...[
              const SizedBox(height: 8),
              _fareLine('Meal Add-on', _fmtPreferred(mealAmt)),
            ],
            if (seatAmt > 0) ...[
              const SizedBox(height: 8),
              _fareLine('Seat Add-on', _fmtPreferred(seatAmt)),
            ],
            if (hasPromo) ...[
              const SizedBox(height: 8),
              _fareLine('Promo Discount ($promoCode)', '- ${_fmtPreferred(promoDiscount)}', discount: true),
            ],
            Divider(color: Colors.grey.shade300, height: 20),
            _fareLine(
              'Total Paid',
              (hasSSR || hasPromo) && finalTotalStr.isNotEmpty
                  ? finalTotalStr
                  : finalTotalStr.isNotEmpty ? finalTotalStr : fmtFn(total),
              large: true,
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF005EB8), borderRadius: BorderRadius.circular(8)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('WanderNova Travel Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            Text('support@wandernova.com', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _paxRows() {
    final rows = <Widget>[];
    void add(String name, String? ticketNo, String? status) {
      rows.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
        child: Row(children: [
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty ? 'Passenger' : name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _textDark)),
          ])),
          Expanded(flex: 3, child: Text(ticketNo ?? 'Processing…', style: const TextStyle(fontSize: 11, color: _textMid))),
          Expanded(flex: 2, child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(12)),
              child: Text(status ?? 'Confirmed', style: const TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          )),
        ]),
      ));
    }
    if (dpax.isNotEmpty) {
      for (final p in dpax) add(p.fullName.isNotEmpty ? p.fullName : passengerName, p.ticketNumber, p.ticketStatus);
    } else if (tpax.isNotEmpty) {
      for (final p in tpax) add('${p.firstName ?? ''} ${p.lastName ?? ''}'.trim(), p.ticketNumber, p.status);
    } else {
      add(passengerName, null, 'Confirmed');
    }
    return rows;
  }

  Widget _fareLine(String label, String value, {bool large = false, bool discount = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.w600, color: large ? _textDark : _textMid)),
        Text(value,  style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.bold,
            color: discount ? _green : large ? _red : _textDark)),
      ]);
}
