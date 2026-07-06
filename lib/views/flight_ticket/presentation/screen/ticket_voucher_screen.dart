import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/ticket_entity.dart';
import '../../data/services/booking_details_service.dart';
import '../../../flight_search/presentation/screen/booking_screen.dart';
import '../../../flight_ssr/presentation/screen/ssr/ssr_price_formatter.dart';
import 'invoice.dart';
import 'e-ticket.dart';

// ── Enhanced Colour Palette ──────────────────────────────────────────────────
const _primary      = Color(0xFF1A237E);      // Deep indigo
const _primaryLight = Color(0xFF3949AB);
const _accent       = Color(0xFFD32F2F);      // Rich red
const _accentLight  = Color(0xFFFFCDD2);
const _success      = Color(0xFF2E7D32);
const _successLight = Color(0xFFE8F5E9);
const _gold         = Color(0xFFFFA000);
const _goldLight    = Color(0xFFFFF3E0);
const _surface      = Colors.white;
const _background   = Color(0xFFF5F7FA);
const _textPrimary  = Color(0xFF1A1A2E);
const _textSecondary= Color(0xFF4A4A6A);
const _textTertiary = Color(0xFF7A7A9A);
const _borderLight  = Color(0xFFE8ECF2);
const _shadowLight  = Color(0x1A000000);
const _shadowMedium = Color(0x33000000);

class TicketVoucherScreen extends StatefulWidget {
  final TicketEntity ticket;
  final FlightRouteSegment route;
  final Map<String, dynamic> passengerData;
  final double promoDiscount;
  final String promoCode;
  final Map<String, dynamic> ssrSelections;

  const TicketVoucherScreen({
    super.key,
    required this.ticket,
    required this.route,
    required this.passengerData,
    this.promoDiscount = 0.0,
    this.promoCode = '',
    this.ssrSelections = const {},
  });

  @override
  State<TicketVoucherScreen> createState() => _TicketVoucherScreenState();
}

class _TicketVoucherScreenState extends State<TicketVoucherScreen> {
  BookingDetailsModel? _details;
  bool _loadingDetails = true;
  String? _detailsError;
  bool _isExpanded = false;

  // ── Getters ─────────────────────────────────────────────────────────────────

  /// Seat code for passenger 0: prefers GetBookingDetails PaxSeat, falls back
  /// to the ssrSelections the user chose on the SSR screen.
  String? get _resolvedSeatCode {
    final fromApi = _dpax.isNotEmpty ? _dpax.first.seatCode : null;
    if (fromApi?.isNotEmpty == true) return fromApi;
    final seats = widget.ssrSelections['seat'];
    if (seats is List && seats.isNotEmpty) {
      final first = seats.first;
      if (first is Map) return first['Code'] as String?;
    }
    return null;
  }

  /// Baggage label: prefers GetBookingDetails PaxBaggage, falls back to
  /// ssrSelections. Returns a human-readable string like "BG65 · 65 Kg".
  String? get _resolvedBaggageLabel {
    String? code;
    int? weight;

    if (_dpax.isNotEmpty && _dpax.first.baggageCode?.isNotEmpty == true) {
      code   = _dpax.first.baggageCode;
      weight = _dpax.first.baggageWeight;
    } else {
      final bag = widget.ssrSelections['baggage'];
      if (bag is Map) {
        code   = bag['Code'] as String?;
        weight = (bag['Weight'] as num?)?.toInt();
      }
    }

    if (code == null) return null;
    return weight != null ? '$code · ${weight} Kg' : code;
  }

  String get _pnr    => widget.ticket.pnr ?? 'N/A';
  String get _bookId => (_details?.bookingId ?? widget.ticket.bookingId)
      ?.toString() ?? 'N/A';
  String get _invoiceNo => 'WNT${_bookId.padLeft(4, '0')}';

  String get _passengerName =>
      '${widget.passengerData['firstName'] ?? ''} ${widget.passengerData['lastName'] ?? ''}'.trim();
  String get _email  => widget.passengerData['email']        as String? ?? '';
  String get _mobile => widget.passengerData['mobileNumber'] as String? ?? '';

  FareQuoteData?     get _fare    => widget.route.fareQuoteData;
  BookingDetailsModel? get _d     => _details;

  double get _baseFare  => _fare?.baseFare  ?? _d?.baseFare  ?? 0;
  double get _tax       => _fare?.tax       ?? _d?.tax       ?? 0;
  double get _total     => _fare?.total     ?? _d?.offeredFare ?? _d?.publishedFare ?? (_baseFare + _tax);
  String get _currency  => _fare?.currency  ?? _d?.currency  ?? 'INR';

  String get _preferredCurrency => CurrencyConverter.getPreferredCurrency();

  /// Total SSR add-on cost in preferred display currency.
  double get _ssrDisplayAmount {
    double total = 0;
    final sel = widget.ssrSelections;

    final baggage = sel['baggage'];
    if (baggage is Map) {
      final p = (baggage['Price'] as num?)?.toDouble() ?? 0;
      final c = (baggage['Currency'] as String?) ?? _currency;
      if (p > 0) total += SsrPriceFormatter.convertAmount(p, c);
    }

    final meal = sel['meal'];
    if (meal is Map) {
      final p = (meal['Price'] as num?)?.toDouble() ?? 0;
      final c = (meal['Currency'] as String?) ?? _currency;
      if (p > 0) total += SsrPriceFormatter.convertAmount(p, c);
    }

    final seats = sel['seat'];
    if (seats is List) {
      for (final seat in seats) {
        if (seat is Map) {
          final p = (seat['Price'] as num?)?.toDouble() ?? 0;
          final c = (seat['Currency'] as String?) ?? _currency;
          if (p > 0) total += SsrPriceFormatter.convertAmount(p, c);
        }
      }
    }

    return total;
  }

  /// Final amount actually paid: base fare (converted) + SSR − promo discount.
  double get _finalDisplayAmount {
    final base = SsrPriceFormatter.convertAmount(_total, _currency);
    final result = base + _ssrDisplayAmount - widget.promoDiscount;
    return result < 0 ? 0 : result;
  }

  String get _finalDisplayTotal =>
      CurrencyConverter.format(_finalDisplayAmount, _preferredCurrency);

  String _fmt(double amount) {
    return SsrPriceFormatter.format(amount, _currency);
  }

  List<BookingSegmentDetail>       get _segs => _d?.segments   ?? [];
  List<BookingPassengerDetail>     get _dpax => _d?.passengers ?? [];
  List<TicketPassengerEntity>      get _tpax => widget.ticket.passengers ?? [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (_pnr == 'N/A') { setState(() => _loadingDetails = false); return; }
    try {
      final svc = BookingDetailsService(di.sl<Dio>());
      final d = await svc.fetch(_pnr);
      setState(() {
        _details = d;
        _loadingDetails = false;
        if (d.segments.isNotEmpty) {
          _detailsError = null;
        } else if (!d.isSuccess && d.errorMessage != null) {
          _detailsError = d.errorMessage;
        }
      });
    } catch (e) {
      setState(() {
        _loadingDetails = false;
        if (_tpax.isEmpty) {
          _detailsError = e.toString();
        }
      });
    }
  }

  // ── Date Helpers ───────────────────────────────────────────────────────────
  String _dt(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try { return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(raw)); }
    catch (_) { return raw; }
  }
  String _timeOnly(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try { return DateFormat('HH:mm').format(DateTime.parse(raw)); }
    catch (_) { return raw; }
  }
  String _dateOnly(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(raw)); }
    catch (_) { return raw; }
  }
  String _dayOnly(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try { return DateFormat('EEE').format(DateTime.parse(raw)); }
    catch (_) { return raw; }
  }
  String _dur(int? m) {
    if (m == null) return '';
    final h = m ~/ 60; final mn = m % 60;
    return h > 0 ? '${h}h ${mn}m' : '${mn}m';
  }
  int _totalDur() => _segs.fold<int>(0, (s, seg) => s + (seg.duration ?? 0));

// ── PDF Generation ──────────────────────────────────────────────────────────
  Future<void> _downloadPdf() async {
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(bytes: bytes, filename: 'WanderNova_${_pnr}.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e'), backgroundColor: _accent));
    }
  }

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        // Header
        _pdfHeader(),
        pw.SizedBox(height: 14),
        // Confirmed banner
        _pdfConfirmBanner(),
        pw.SizedBox(height: 18),
        // Flight Details
        _pdfSectionTitle('FLIGHT DETAILS'),
        pw.SizedBox(height: 8),
        if (_segs.isNotEmpty)
          ..._segs.map(_pdfSegment)
        else
          _pdfFallbackRoute(),
        pw.SizedBox(height: 18),
        // Passengers
        _pdfSectionTitle('PASSENGERS'),
        pw.SizedBox(height: 8),
        _pdfPassengerTable(),
        pw.SizedBox(height: 18),
        // Fare
        _pdfSectionTitle('FARE SUMMARY'),
        pw.SizedBox(height: 8),
        _pdfFareBox(),
        pw.SizedBox(height: 20),
        _pdfFooter(),
      ],
    ));
    return doc.save();
  }

  pw.Widget _pdfHeader() => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 10),
    decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))
    ),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          pw.Text('WANDER', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.Text('NOVA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
        ]),
        pw.Text('TRAVEL SERVICES', style: pw.TextStyle(fontSize: 7, color: PdfColors.teal700, letterSpacing: 2)),
      ]),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text('E-TICKET', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800, letterSpacing: 2)),
        pw.Text('PNR: $_pnr', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, letterSpacing: 1)),
      ]),
    ]),
  );

  pw.Widget _pdfConfirmBanner() => pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: PdfColors.green50,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.green200),
    ),
    child: pw.Row(children: [
      pw.Container(
        width: 22, height: 22,
        decoration: const pw.BoxDecoration(color: PdfColors.green, shape: pw.BoxShape.circle),
        child: pw.Center(child: pw.Text('✓', style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold))),
      ),
      pw.SizedBox(width: 12),
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Your booking is confirmed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.green800)),
        pw.Text('${_passengerName.toUpperCase()}  ·  $_email', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ])),
    ]),
  );

  pw.Widget _pdfSegment(BookingSegmentDetail seg) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.blue50,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(
        '${seg.airlineName ?? ''} (${seg.airlineCode ?? ''}) · Flt ${seg.flightNumber ?? ''}  ·  Class: ${seg.fareClass ?? '—'}',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey800),
      ),
      pw.SizedBox(height: 10),
      pw.Row(children: [
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(seg.originCode ?? '', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          pw.Text(_timeOnly(seg.depTime), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          pw.Text(_dateOnly(seg.depTime), style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(seg.originName ?? '', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ])),
        pw.Column(children: [
          pw.Text(_dur(seg.duration), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Text('✈', style: pw.TextStyle(fontSize: 16, color: PdfColors.red700)),
        ]),
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(seg.destCode ?? '', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          pw.Text(_timeOnly(seg.arrTime), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          pw.Text(_dateOnly(seg.arrTime), style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(seg.destName ?? '', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ])),
      ]),
    ]),
  );

  pw.Widget _pdfFallbackRoute() => pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.blue50,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(children: [
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(widget.route.from, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
        pw.Text(widget.route.departureTime, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
      ])),
      pw.Column(children: [
        pw.Text(widget.route.duration, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.Text('✈', style: pw.TextStyle(fontSize: 16, color: PdfColors.red700)),
      ]),
      pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text(widget.route.to, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
        pw.Text(widget.route.arrivalTime, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
      ])),
    ]),
  );

  pw.Widget _pdfPassengerTable() {
    List<List<String>> rows;
    if (_dpax.isNotEmpty) {
      rows = _dpax.map((p) => [
        p.fullName.isNotEmpty ? p.fullName : _passengerName,
        p.ticketNumber ?? 'Processing…',
        p.ticketStatus ?? 'Confirmed',
      ]).toList();
    } else if (_tpax.isNotEmpty) {
      rows = _tpax.map((p) => [
        '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim().isEmpty ? _passengerName : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim(),
        p.ticketNumber ?? 'Processing…',
        p.status ?? 'Confirmed',
      ]).toList();
    } else {
      rows = [[_passengerName, 'Processing…', 'Confirmed']];
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8), // Use circular instead of vertical
      ),
      child: pw.Column(children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const pw.BoxDecoration(
            color: PdfColors.blue900,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ), // Use only with Radius
          ),
          child: pw.Row(children: [
            pw.Expanded(flex: 3, child: pw.Text('PASSENGER', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
            pw.Expanded(flex: 3, child: pw.Text('TICKET NO.', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
            pw.Expanded(flex: 2, child: pw.Text('STATUS', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
          ]),
        ),
        ...rows.map((row) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey100)),
          ),
          child: pw.Row(children: [
            pw.Expanded(flex: 3, child: pw.Text(row[0], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey900))),
            pw.Expanded(flex: 3, child: pw.Text(row[1], style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
            pw.Expanded(flex: 2, child: pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(row[2], style: pw.TextStyle(color: PdfColors.green700, fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
            )),
          ]),
        )),
      ]),
    );
  }

  pw.Widget _pdfFareBox() {
    final sel = widget.ssrSelections;
    final hasPromo = widget.promoDiscount > 0;

    double baggagePrice = 0;
    String baggageCurrency = _currency;
    final baggage = sel['baggage'];
    if (baggage is Map) {
      baggagePrice = (baggage['Price'] as num?)?.toDouble() ?? 0;
      baggageCurrency = (baggage['Currency'] as String?) ?? _currency;
    }

    double mealPrice = 0;
    String mealCurrency = _currency;
    final meal = sel['meal'];
    if (meal is Map) {
      mealPrice = (meal['Price'] as num?)?.toDouble() ?? 0;
      mealCurrency = (meal['Currency'] as String?) ?? _currency;
    }

    double seatPrice = 0;
    final seats = sel['seat'];
    if (seats is List) {
      for (final seat in seats) {
        if (seat is Map) {
          final p = (seat['Price'] as num?)?.toDouble() ?? 0;
          final c = (seat['Currency'] as String?) ?? _currency;
          seatPrice += SsrPriceFormatter.convertAmount(p, c);
        }
      }
    }

    final baggageDisplayPrice = SsrPriceFormatter.convertAmount(baggagePrice, baggageCurrency);
    final mealDisplayPrice = SsrPriceFormatter.convertAmount(mealPrice, mealCurrency);
    final hasSSR = baggagePrice > 0 || mealPrice > 0 || seatPrice > 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(children: [
        _pdfFareRow('Base Fare', _fmt(_baseFare)),
        pw.SizedBox(height: 8),
        _pdfFareRow('Taxes & Fees', _fmt(_tax)),
        if (baggagePrice > 0) ...[
          pw.SizedBox(height: 8),
          _pdfFareRow('Baggage Add-on',
              CurrencyConverter.format(baggageDisplayPrice, _preferredCurrency)),
        ],
        if (mealPrice > 0) ...[
          pw.SizedBox(height: 8),
          _pdfFareRow('Meal Add-on',
              CurrencyConverter.format(mealDisplayPrice, _preferredCurrency)),
        ],
        if (seatPrice > 0) ...[
          pw.SizedBox(height: 8),
          _pdfFareRow('Seat Add-on',
              CurrencyConverter.format(seatPrice, _preferredCurrency)),
        ],
        if (hasPromo) ...[
          pw.SizedBox(height: 8),
          _pdfFareRow(
            'Promo Discount (${widget.promoCode})',
            '- ${CurrencyConverter.format(widget.promoDiscount, _preferredCurrency)}',
          ),
        ],
        pw.Divider(color: PdfColors.grey300, height: 20),
        _pdfFareRow(
          'Total Paid',
          (hasSSR || hasPromo) ? _finalDisplayTotal : _fmt(_total),
          bold: true,
        ),
      ]),
    );
  }

  pw.Widget _pdfFareRow(String label, String value, {bool bold = false}) =>
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(
          fontSize: bold ? 14 : 12,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: bold ? PdfColors.grey900 : PdfColors.grey700,
        )),
        pw.Text(value, style: pw.TextStyle(
          fontSize: bold ? 14 : 12,
          fontWeight: pw.FontWeight.bold,
          color: bold ? PdfColors.red700 : PdfColors.grey900,
        )),
      ]);

  pw.Widget _pdfFooter() => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: pw.BoxDecoration(
      color: const PdfColor(0, 0.37, 0.72),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('WanderNova Travel Services', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11)),
      pw.Text('info@wandernova.com', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
    ]),
  );

  pw.Widget _pdfSectionTitle(String title) => pw.Text(
    title,
    style: pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 10,
      color: PdfColors.grey600,
      letterSpacing: 1,
    ),
  );

  pw.Widget _pdfTerms() => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Divider(color: PdfColors.grey300, height: 1),
    pw.SizedBox(height: 8),
    pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, letterSpacing: 1)),
    pw.SizedBox(height: 4),
    pw.Text(
        'All bookings are subject to our terms and conditions. Cancellations must be made at least 24 hours before departure. '
            'For support, contact info@wandernova.com. This e-ticket is valid for the services listed above.',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, lineSpacing: 2)),
  ]);


  // ── Invoice Bottom Sheet ────────────────────────────────────────────────────
  void _showInvoice() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketVoucherInvoice(
        pnr: _pnr,
        invoiceNo: _invoiceNo,
        bookId: _bookId,
        passengerName: _passengerName,
        email: _email,
        mobile: _mobile,
        baseFare: _baseFare,
        tax: _tax,
        total: _total,
        currency: _currency,
        finalTotalStr: _finalDisplayTotal,
        segs: _segs,
        dpax: _dpax,
        tpax: _tpax,
        route: widget.route,
        onDownload: _downloadPdf,
        dtFn: _dt,
        dateOnlyFn: _dateOnly,
        timeOnlyFn: _timeOnly,
        durFn: _dur,
        totalDurFn: _totalDur,
        fmtFn: _fmt,
        ssrSelections: widget.ssrSelections,
        promoDiscount: widget.promoDiscount,
        promoCode: widget.promoCode,
        preferredCurrency: _preferredCurrency,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(12),
        ),
        child: Column(
          children: [
            _buildStatusBanner(context),
            SizedBox(height: context.gapSmall),
            // _buildPNRCard(context),
            // SizedBox(height: context.gapSmall),
            _buildFlightCard(context),
            SizedBox(height: context.gapSmall),
            _buildPassengerCard(context),
            SizedBox(height: context.gapSmall),
            _buildFareCard(context),
            if (_detailsError != null) ...[
              SizedBox(height: context.gapSmall),
              _buildErrorNote(context),
            ],
            SizedBox(height: context.gapSmall),
            _buildActions(context),
            SizedBox(height: context.gapLarge),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const WanderNovaLogo(scaleFactor: 0.55),
      backgroundColor: _primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              _buildAppBarButton(
                icon: Icons.download_rounded,
                onTap: _downloadPdf,
                tooltip: 'Download PDF',
              ),
              const SizedBox(width: 4),
              _buildAppBarButton(
                icon: Icons.receipt_outlined,
                onTap: _showInvoice,
                tooltip: 'View Invoice',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // ── Status Banner ────────────────────────────────────────────────────────────
  Widget _buildStatusBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(20),
        vertical: context.h(16),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_success, Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(context.borderRadius + 4),
        boxShadow: [
          BoxShadow(
            color: _success.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: context.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Confirmed! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.titleLarge,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  'Your e-ticket has been issued successfully.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: context.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          // const Icon(
          //   Icons.flight_takeoff_rounded,
          //   color: Colors.white54,
          //   size: 36,
          // ),
        ],
      ),
    );
  }


  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: _textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Flight Card ─────────────────────────────────────────────────────────────
  Widget _buildFlightCard(BuildContext context) {
    return _card(context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'FLIGHT DETAILS'),
          SizedBox(height: context.gapSmall),
          if (_segs.isNotEmpty)
            ..._segs.asMap().entries.map((e) {
              final i = e.key;
              final seg = e.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) _stopoverDivider(context, seg.originCode ?? ''),
                  _buildSegmentRow(context, seg),
                  if (i < _segs.length - 1)
                    SizedBox(height: context.h(8)),
                ],
              );
            })
          else
            _fallbackRoute(context),
        ],
      ),
    );
  }

  Widget _buildSegmentRow(BuildContext context, BookingSegmentDetail seg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${seg.airlineCode ?? ''} ${seg.flightNumber ?? ''}',
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    seg.airlineName ?? '',
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _goldLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${seg.fareClass ?? '—'}',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    fontWeight: FontWeight.w600,
                    color: _gold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seg.originCode ?? '',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      _timeOnly(seg.depTime),
                      style: TextStyle(
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      _dateOnly(seg.depTime),
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: _textTertiary,
                      ),
                    ),
                    if (seg.originName?.isNotEmpty ?? false)
                      Text(
                        seg.originName!,
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: _textTertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // if (seg.originTerminal?.isNotEmpty ?? false)
                    //   _buildTerminalBadge('T${seg.originTerminal}'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _dur(seg.duration),
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 2,
                          width: double.infinity,
                          color: _borderLight,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flight,
                            color: _accent,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      seg.destCode ?? '',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      _timeOnly(seg.arrTime),
                      style: TextStyle(
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      _dateOnly(seg.arrTime),
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        color: _textTertiary,
                      ),
                    ),
                    if (seg.destName?.isNotEmpty ?? false)
                      Text(
                        seg.destName!,
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: _textTertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
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

  Widget _stopoverDivider(BuildContext context, String code) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Row(
        children: [
          Expanded(
            child: Container(height: 1, color: _borderLight),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _goldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🔄 Stopover · $code',
                style: TextStyle(
                  color: _gold,
                  fontSize: context.labelSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(height: 1, color: _borderLight),
          ),
        ],
      ),
    );
  }

  Widget _fallbackRoute(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.route.from,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  widget.route.departureTime,
                  style: TextStyle(
                    color: _textTertiary,
                    fontSize: context.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                widget.route.duration,
                style: TextStyle(
                  color: _textTertiary,
                  fontSize: context.labelSmall,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.flight, color: _accent, size: 24),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.route.to,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  widget.route.arrivalTime,
                  style: TextStyle(
                    color: _textTertiary,
                    fontSize: context.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Passenger Card ──────────────────────────────────────────────────────────
  // Widget _buildPassengerCard(BuildContext context) {
  //   return _card(context,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _sectionHeader(context, '👤 PASSENGER INFORMATION'),
  //         SizedBox(height: context.gapSmall),
  //         if (_email.isNotEmpty || _mobile.isNotEmpty)
  //           Container(
  //             margin: EdgeInsets.only(bottom: context.gapSmall),
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               color: _primary.withOpacity(0.04),
  //               borderRadius: BorderRadius.circular(10),
  //               border: Border.all(color: _primary.withOpacity(0.08)),
  //             ),
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       if (_email.isNotEmpty) ...[
  //                         Text(
  //                           'Email',
  //                           style: TextStyle(
  //                             fontSize: context.labelSmall,
  //                             color: _textTertiary,
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                         Text(
  //                           _email,
  //                           style: TextStyle(
  //                             fontSize: context.bodySmall,
  //                             color: _textPrimary,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                         ),
  //                       ],
  //                     ],
  //                   ),
  //                 ),
  //                 if (_mobile.isNotEmpty)
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.end,
  //                     children: [
  //                       Text(
  //                         'Mobile',
  //                         style: TextStyle(
  //                           fontSize: context.labelSmall,
  //                           color: _textTertiary,
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                       Text(
  //                         _mobile,
  //                         style: TextStyle(
  //                           fontSize: context.bodySmall,
  //                           color: _textPrimary,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //               ],
  //             ),
  //           ),
  //         if (_dpax.isNotEmpty)
  //           ..._dpax.map((p) => _buildPassengerRow(
  //             context,
  //             p.fullName.isNotEmpty ? p.fullName : _passengerName,
  //             p.ticketNumber,
  //             p.ticketStatus,
  //           ))
  //         else if (_tpax.isNotEmpty)
  //           ..._tpax.map((p) {
  //             final n = '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();
  //             return _buildPassengerRow(
  //               context,
  //               n.isEmpty ? _passengerName : n,
  //               p.ticketNumber,
  //               p.status,
  //             );
  //           })
  //         else
  //           _buildPassengerRow(context, _passengerName, null, 'Confirmed'),
  //       ],
  //     ),
  //   );
  // }
// ── Passenger Card ──────────────────────────────────────────────────────────
  Widget _buildPassengerCard(BuildContext context) {
    return _card(context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, '👤 PASSENGER INFORMATION'),
          SizedBox(height: context.gapSmall),
          // Passenger name
          _buildPassengerNameRow(context),
          SizedBox(height: context.gapSmall),
          // Email with icon
          if (_email.isNotEmpty)
            _buildInfoRowWithIcon(
              context,
              icon: Icons.email_outlined,
              label: _email,
            ),
          if (_email.isNotEmpty && _mobile.isNotEmpty)
            SizedBox(height: context.h(4)),
          // Mobile with icon
          if (_mobile.isNotEmpty)
            _buildInfoRowWithIcon(
              context,
              icon: Icons.phone_outlined,
              label: _mobile,
            ),
          SizedBox(height: context.gapSmall),
          // Ticket and status
          if (_dpax.isNotEmpty)
            ..._dpax.map((p) => _buildPassengerTicketRow(
              context,
              p.fullName.isNotEmpty ? p.fullName : _passengerName,
              p.ticketNumber,
              p.ticketStatus,
            ))
          else if (_tpax.isNotEmpty)
            ..._tpax.map((p) {
              final n = '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();
              return _buildPassengerTicketRow(
                context,
                n.isEmpty ? _passengerName : n,
                p.ticketNumber,
                p.status,
              );
            })
          else
            _buildPassengerTicketRow(context, _passengerName, null, 'Confirmed'),
          // ── SSR add-ons (seat / baggage) ──────────────────────────────────
          if (_resolvedSeatCode != null || _resolvedBaggageLabel != null) ...[
            SizedBox(height: context.h(10)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderLight),
              ),
              child: Row(
                children: [
                  if (_resolvedSeatCode != null) ...[
                    const Icon(Icons.event_seat_outlined, size: 15, color: _primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      'Seat $_resolvedSeatCode',
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                  if (_resolvedSeatCode != null && _resolvedBaggageLabel != null)
                    const SizedBox(width: 16),
                  if (_resolvedBaggageLabel != null) ...[
                    const Icon(Icons.luggage_outlined, size: 15, color: _primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      _resolvedBaggageLabel!,
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerNameRow(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Container(
          //   width: 36,
          //   height: 36,
          //   decoration: BoxDecoration(
          //     color: _primary.withOpacity(0.08),
          //     shape: BoxShape.circle,
          //   ),
          //   child: const Icon(
          //     Icons.person_outline,
          //     color: _primary,
          //     size: 20,
          //   ),
          // ),
          const SizedBox(width: 28),
          Expanded(
            child: Text(
              _passengerName.isEmpty ? 'Passenger' : _passengerName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.bodyLarge,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithIcon(BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Icon(
            icon,
            color: _textTertiary,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerTicketRow(
      BuildContext context,
      String name,
      String? ticketNo,
      String? status,
      ) {
    return Container(
      margin: EdgeInsets.only(top: context.gapSmall),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket Number',
                  style: TextStyle(
                    color: _textTertiary,
                    fontSize: context.labelSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  ticketNo ?? 'Processing…',
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _successLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status ?? 'Confirmed',
                  style: TextStyle(
                    color: _success,
                    fontSize: context.labelSmall,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerRow(
      BuildContext context,
      String name,
      String? ticketNo,
      String? status,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapSmall),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Container(
          //   width: 36,
          //   height: 36,
          //   decoration: BoxDecoration(
          //     color: _primary.withOpacity(0.08),
          //     shape: BoxShape.circle,
          //   ),
          //   child: const Icon(
          //     Icons.person_outline,
          //     color: _primary,
          //     size: 20,
          //   ),
          // ),
          // const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Passenger' : name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.bodyMedium,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  'Ticket: ${ticketNo ?? 'Processing…'}',
                  style: TextStyle(
                    color: _textTertiary,
                    fontSize: context.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _successLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status ?? 'Confirmed',
                  style: TextStyle(
                    color: _success,
                    fontSize: context.labelSmall,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Fare Card ───────────────────────────────────────────────────────────────
  Widget _buildFareCard(BuildContext context) {
    final sel = widget.ssrSelections;
    final hasPromo = widget.promoDiscount > 0;

    double baggagePrice = 0;
    String baggageCurrency = _currency;
    final baggage = sel['baggage'];
    if (baggage is Map) {
      baggagePrice = (baggage['Price'] as num?)?.toDouble() ?? 0;
      baggageCurrency = (baggage['Currency'] as String?) ?? _currency;
    }

    double mealPrice = 0;
    String mealCurrency = _currency;
    final meal = sel['meal'];
    if (meal is Map) {
      mealPrice = (meal['Price'] as num?)?.toDouble() ?? 0;
      mealCurrency = (meal['Currency'] as String?) ?? _currency;
    }

    double seatPrice = 0;
    final seats = sel['seat'];
    if (seats is List) {
      for (final seat in seats) {
        if (seat is Map) {
          final p = (seat['Price'] as num?)?.toDouble() ?? 0;
          final c = (seat['Currency'] as String?) ?? _currency;
          seatPrice += SsrPriceFormatter.convertAmount(p, c);
        }
      }
    }

    final baggageDisplayPrice = SsrPriceFormatter.convertAmount(baggagePrice, baggageCurrency);
    final mealDisplayPrice = SsrPriceFormatter.convertAmount(mealPrice, mealCurrency);
    final hasSSR = baggagePrice > 0 || mealPrice > 0 || seatPrice > 0;

    return _card(context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'FARE SUMMARY'),
          SizedBox(height: context.gapSmall),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderLight),
            ),
            child: Column(
              children: [
                _fareRow(context, 'Base Fare', _fmt(_baseFare)),
                SizedBox(height: context.gapSmall),
                _fareRow(context, 'Taxes & Fees', _fmt(_tax)),
                if (baggagePrice > 0) ...[
                  SizedBox(height: context.gapSmall),
                  _fareRow(context, 'Baggage Add-on',
                      CurrencyConverter.format(baggageDisplayPrice, _preferredCurrency)),
                ],
                if (mealPrice > 0) ...[
                  SizedBox(height: context.gapSmall),
                  _fareRow(context, 'Meal Add-on',
                      CurrencyConverter.format(mealDisplayPrice, _preferredCurrency)),
                ],
                if (seatPrice > 0) ...[
                  SizedBox(height: context.gapSmall),
                  _fareRow(context, 'Seat Add-on',
                      CurrencyConverter.format(seatPrice, _preferredCurrency)),
                ],
                if (hasPromo) ...[
                  SizedBox(height: context.gapSmall),
                  _fareRow(
                    context,
                    'Promo Discount (${widget.promoCode})',
                    '- ${CurrencyConverter.format(widget.promoDiscount, _preferredCurrency)}',
                    isDiscount: true,
                  ),
                ],
                Divider(height: context.gapMedium, color: _borderLight),
                _fareRow(
                  context,
                  'Total Paid',
                  (hasSSR || hasPromo) ? _finalDisplayTotal : _fmt(_total),
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRow(BuildContext context, String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    final labelColor = isDiscount
        ? Colors.green.shade700
        : (isTotal ? _textPrimary : _textSecondary);
    final valueColor = isDiscount
        ? Colors.green.shade700
        : (isTotal ? _accent : _textPrimary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: labelColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ── Error Note ──────────────────────────────────────────────────────────────
  Widget _buildErrorNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not refresh booking details. Showing data from ticket issuance.',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: context.bodySmall,
              ),
            ),
          ),
          TextButton(
            onPressed: _fetchDetails,
            style: TextButton.styleFrom(
              foregroundColor: _primary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ──────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Row(
        //   children: [
        //     Expanded(
        //       child: _buildActionButton(
        //         context,
        //         label: 'Download PDF',
        //         icon: Icons.download_rounded,
        //         onTap: _downloadPdf,
        //         primary: true,
        //       ),
        //     ),
        //     SizedBox(width: context.gapSmall),
        //     Expanded(
        //       child: _buildActionButton(
        //         context,
        //         label: 'View Invoice',
        //         icon: Icons.receipt_outlined,
        //         onTap: _showInvoice,
        //         primary: false,
        //       ),
        //     ),
        //   ],
        // ),
        // SizedBox(height: context.gapSmall),
        SizedBox(
          width: double.infinity,
          height: context.buttonHeight + 4,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
                  (route) => false,
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Back to Home',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.bold,
                fontSize: context.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required String label,
        required IconData icon,
        required VoidCallback onTap,
        required bool primary}) {
    return SizedBox(
      height: context.buttonHeight + 4,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: primary ? Colors.white : _primary,
          size: 18,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : _primary,
            fontWeight: FontWeight.bold,
            fontSize: context.bodySmall,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? _accent : _background,
          elevation: primary ? 2 : 0,
          shadowColor: primary ? _accent.withOpacity(0.3) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: primary ? null : BorderSide(color: _primary.withOpacity(0.2)),
        ),
      ),
    );
  }

  // ── Shared Helpers ──────────────────────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: context.labelSmall,
        fontWeight: FontWeight.bold,
        color: _textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }

  // Widget _buildTerminalBadge(String terminal) {
  //   return Container(
  //     margin: const EdgeInsets.only(top: 3),
  //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //     decoration: BoxDecoration(
  //       color: _primary.withOpacity(0.06),
  //       borderRadius: BorderRadius.circular(4),
  //       border: Border.all(color: _primary.withOpacity(0.12)),
  //     ),
  //     child: Text(
  //       terminal,
  //       style: TextStyle(
  //         fontSize: 10,
  //         color: _primary,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(context.borderRadius + 2),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: _shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}