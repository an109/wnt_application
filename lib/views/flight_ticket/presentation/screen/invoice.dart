import 'package:flutter/material.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../flight_search/presentation/screen/booking_screen.dart';
import '../../../flight_ssr/presentation/screen/ssr/ssr_price_formatter.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../data/services/booking_details_service.dart';
import 'e-ticket.dart';

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

class TicketVoucherInvoice extends StatefulWidget {
  final String pnr, invoiceNo, bookId;
  final String passengerName, email, mobile;
  final double baseFare, tax, total;
  final String currency;
  final String finalTotalStr;
  final List<BookingSegmentDetail> segs;
  final List<BookingPassengerDetail> dpax;
  final List<TicketPassengerEntity> tpax;
  final FlightRouteSegment route;
  final VoidCallback onDownload;
  final String Function(String?) dtFn, dateOnlyFn, timeOnlyFn;
  final String Function(int?) durFn;
  final int Function() totalDurFn;
  final String Function(double) fmtFn;
  final Map<String, dynamic> ssrSelections;
  final double promoDiscount;
  final String promoCode;
  final String preferredCurrency;

  const TicketVoucherInvoice({
    super.key,
    required this.pnr,
    required this.invoiceNo,
    required this.bookId,
    required this.passengerName,
    required this.email,
    required this.mobile,
    required this.baseFare,
    required this.tax,
    required this.total,
    required this.currency,
    this.finalTotalStr = '',
    required this.segs,
    required this.dpax,
    required this.tpax,
    required this.route,
    required this.onDownload,
    required this.dtFn,
    required this.dateOnlyFn,
    required this.timeOnlyFn,
    required this.durFn,
    required this.totalDurFn,
    required this.fmtFn,
    this.ssrSelections = const {},
    this.promoDiscount = 0.0,
    this.promoCode = '',
    this.preferredCurrency = 'INR',
  });

  @override
  State<TicketVoucherInvoice> createState() => _TicketVoucherInvoiceState();
}

class _TicketVoucherInvoiceState extends State<TicketVoucherInvoice>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── SSR helpers ─────────────────────────────────────────────────────────────
  double _ssrPrice(String key) {
    if (key == 'seat') {
      double total = 0;
      final seats = widget.ssrSelections['seat'];
      if (seats is List) {
        for (final s in seats) {
          if (s is Map) {
            final p = (s['Price'] as num?)?.toDouble() ?? 0;
            final c = (s['Currency'] as String?) ?? widget.currency;
            total += SsrPriceFormatter.convertAmount(p, c);
          }
        }
      }
      return total;
    }
    final item = widget.ssrSelections[key];
    if (item is Map) {
      final p = (item['Price'] as num?)?.toDouble() ?? 0;
      final c = (item['Currency'] as String?) ?? widget.currency;
      return SsrPriceFormatter.convertAmount(p, c);
    }
    return 0;
  }

  String _fmtPreferred(double amount) =>
      CurrencyConverter.format(amount, widget.preferredCurrency);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
        ),
        child: Column(children: [
          // drag handle
          Center(child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)
            ),
          )),
          // top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TabBar(
                controller: _tab,
                isScrollable: true,
                labelColor: _navy,
                unselectedLabelColor: _textMid,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                indicatorColor: _red,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: 'Invoice'),
                  Tab(text: 'E-Ticket')
                ],
              ),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDownload();
                  },
                  icon: const Icon(Icons.download_rounded, size: 15, color: Colors.white),
                  label: const Text('Download',
                      style: TextStyle(color: Colors.white, fontSize: 12)
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle
                    ),
                    child: const Icon(Icons.close, size: 18, color: _textMid),
                  ),
                ),
              ]),
            ]),
          ),
          Divider(color: Colors.grey.shade200, height: 1),
          Expanded(
            child: TabBarView(controller: _tab, children: [
              _buildInvoiceTab(sc),
              _buildETicketTab(sc),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── INVOICE TAB ──────────────────────────────────────────────────────────────
  Widget _buildInvoiceTab(ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // brand header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(text: const TextSpan(children: [
              TextSpan(text: 'WANDER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0668CC), letterSpacing: 2)),
              TextSpan(text: 'NOVA',   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFE6B02), letterSpacing: 2)),
            ])),
            const Text('TRAVEL SERVICES', style: TextStyle(fontSize: 9, letterSpacing: 4, color: Color(0xFF0EA3A3), fontWeight: FontWeight.w600)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('INVOICE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2, color: _textDark)),
            Text(widget.invoiceNo, style: const TextStyle(color: _textMid, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 12),
        // billed to
        Text(widget.passengerName.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
        const SizedBox(height: 2),
        if (widget.email.isNotEmpty)  Text(widget.email,  style: const TextStyle(fontSize: 12, color: _textMid)),
        if (widget.mobile.isNotEmpty) Text(widget.mobile, style: const TextStyle(fontSize: 12, color: _textMid)),
        const SizedBox(height: 14),
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 12),

        // service table
        _invFlightTable(),
        const SizedBox(height: 20),

        // billing + fare
        LayoutBuilder(builder: (_, box) {
          final wide = box.maxWidth > 480;
          final left = _invBillingInfo();
          final right = _invFareSummary();
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: left),
            const SizedBox(width: 20),
            SizedBox(width: 220, child: right)
          ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            left,
            const SizedBox(height: 16),
            right
          ]);
        }),
        const SizedBox(height: 20),
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 8),
        const Text('TERMS & CONDITIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _textDark)),
        const SizedBox(height: 4),
        const Text(
            'All bookings are subject to our terms and conditions. Cancellations must be made at least 24 hours '
                'before departure. For support, contact support@wandernova.com.',
            style: TextStyle(fontSize: 11, color: _textMid, height: 1.6)),
        const SizedBox(height: 20),
        // footer
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

  Widget _invFlightTable() {
    final fromCode = widget.segs.isNotEmpty
        ? (widget.segs.first.originCode ?? widget.route.from)
        : widget.route.from;
    final toCode   = widget.segs.isNotEmpty
        ? (widget.segs.last.destCode   ?? widget.route.to)
        : widget.route.to;
    final paxNames = widget.dpax.isNotEmpty
        ? widget.dpax.map((p) => p.fullName.isNotEmpty ? p.fullName : widget.passengerName).join(', ')
        : widget.tpax.isNotEmpty
        ? widget.tpax.map((p) => '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim()).join(', ')
        : widget.passengerName;
    final totalDur = widget.totalDurFn();
    final durStr   = totalDur > 0 ? widget.durFn(totalDur) : widget.route.duration;
    // Show final total (with SSR + promo) if available, otherwise fall back.
    final totalStr = widget.finalTotalStr.isNotEmpty
        ? widget.finalTotalStr
        : widget.fmtFn(widget.total);

    return Table(
      border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(2.5),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.4),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF005EB8)),
          children: ['TYPE', 'ROUTE', 'PASSENGER(S)', 'DURATION', 'TOTAL'].map((h) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              )).toList(),
        ),
        TableRow(children: [
          _tc('One Way'),
          _tc('$fromCode → $toCode'),
          _tc(paxNames),
          _tc(durStr),
          _tc(totalStr),
        ]),
      ],
    );
  }

  Widget _invBillingInfo() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('BILLING INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
    const SizedBox(height: 8),
    _infoRow('Billed by',        widget.passengerName.toUpperCase()),
    _infoRow('Issued by',        'WANDERNOVA TRAVEL'),
    _infoRow('PNR',              widget.pnr),
    _infoRow('Invoice Status',   'Raised'),
    _infoRow('Payment Basis',    'InvoiceDate'),
  ]);

  Widget _invFareSummary() {
    final baggageAmt = _ssrPrice('baggage');
    final mealAmt    = _ssrPrice('meal');
    final seatAmt    = _ssrPrice('seat');
    final hasPromo   = widget.promoDiscount > 0;
    final hasSSR     = baggageAmt > 0 || mealAmt > 0 || seatAmt > 0;

    return Column(children: [
      _fareLine('BASE FARE',  widget.fmtFn(widget.baseFare)),
      const SizedBox(height: 8),
      _fareLine('TAX & FEES', widget.fmtFn(widget.tax)),
      if (baggageAmt > 0) ...[
        const SizedBox(height: 8),
        _fareLine('BAGGAGE ADD-ON', _fmtPreferred(baggageAmt)),
      ],
      if (mealAmt > 0) ...[
        const SizedBox(height: 8),
        _fareLine('MEAL ADD-ON', _fmtPreferred(mealAmt)),
      ],
      if (seatAmt > 0) ...[
        const SizedBox(height: 8),
        _fareLine('SEAT ADD-ON', _fmtPreferred(seatAmt)),
      ],
      if (hasPromo) ...[
        const SizedBox(height: 8),
        _fareLine('PROMO (${widget.promoCode})', '- ${_fmtPreferred(widget.promoDiscount)}', discount: true),
      ],
      const SizedBox(height: 8),
      Divider(color: Colors.grey.shade300),
      const SizedBox(height: 4),
      _fareLine(
        'TOTAL',
        (hasSSR || hasPromo) && widget.finalTotalStr.isNotEmpty
            ? widget.finalTotalStr
            : widget.finalTotalStr.isNotEmpty ? widget.finalTotalStr : widget.fmtFn(widget.total),
        large: true,
      ),
    ]);
  }

  // ── E-TICKET TAB ─────────────────────────────────────────────────────────────
  Widget _buildETicketTab(ScrollController sc) {
    return TicketVoucherETicket(
      sc: sc,
      pnr: widget.pnr,
      passengerName: widget.passengerName,
      email: widget.email,
      segs: widget.segs,
      dpax: widget.dpax,
      tpax: widget.tpax,
      baseFare: widget.baseFare,
      tax: widget.tax,
      total: widget.total,
      finalTotalStr: widget.finalTotalStr,
      route: widget.route,
      fmtFn: widget.fmtFn,
      timeOnlyFn: widget.timeOnlyFn,
      dateOnlyFn: widget.dateOnlyFn,
      durFn: widget.durFn,
      ssrSelections: widget.ssrSelections,
      promoDiscount: widget.promoDiscount,
      promoCode: widget.promoCode,
      preferredCurrency: widget.preferredCurrency,
    );
  }

  // ── shared invoice helpers ──────────────────────────────────────────────────
  Widget _tc(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Text(text, style: const TextStyle(fontSize: 11, color: _textDark)),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: _textMid))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark))),
    ]),
  );

  Widget _fareLine(String label, String value, {bool large = false, bool discount = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.w600, color: large ? _textDark : _textMid)),
        Text(value,  style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.bold,
            color: discount ? _green : large ? _red : _textDark)),
      ]);
}
