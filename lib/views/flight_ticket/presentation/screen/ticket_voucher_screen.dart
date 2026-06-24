// // ignore_for_file: avoid_print
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import '../../../../UI_helper/currency_converter.dart';
// import '../../../../UI_helper/responsive_layout.dart';
// import '../../../../common_widgets/logo.dart';
// import '../../../../injection_container.dart' as di;
// import '../../domain/entities/ticket_entity.dart';
// import '../../data/services/booking_details_service.dart';
// import '../../../flight_search/presentation/screen/booking_screen.dart';
//
// // ── colour palette ─────────────────────────────────────────────────────────────
// const _red      = Color(0xFFE71D36);
// const _navyDark = Color(0xFF0A1931);
// const _navy     = Color(0xFF1A3461);
// const _indigoBg = Color(0xFFF0F4FF);
// const _surface  = Colors.white;
// const _textDark = Color(0xFF1A1F36);
// const _textMid  = Color(0xFF5A6174);
// const _green    = Color(0xFF27AE60);
// const _greenBg  = Color(0xFFE8F8F0);
// const _borderC  = Color(0xFFE4E9F2);
//
// class TicketVoucherScreen extends StatefulWidget {
//   final TicketEntity ticket;
//   final FlightRouteSegment route;
//   final Map<String, dynamic> passengerData;
//
//   const TicketVoucherScreen({
//     super.key,
//     required this.ticket,
//     required this.route,
//     required this.passengerData,
//   });
//
//   @override
//   State<TicketVoucherScreen> createState() => _TicketVoucherScreenState();
// }
//
// class _TicketVoucherScreenState extends State<TicketVoucherScreen> {
//   BookingDetailsModel? _details;
//   bool _loadingDetails = true;
//   String? _detailsError;
//
//   // ── getters ───────────────────────────────────────────────────────────────
//   String get _pnr    => widget.ticket.pnr ?? 'N/A';
//   String get _bookId => (_details?.bookingId ?? widget.ticket.bookingId)
//       ?.toString() ?? 'N/A';
//   String get _invoiceNo => 'WNT${_bookId.padLeft(4, '0')}';
//
//   String get _passengerName =>
//       '${widget.passengerData['firstName'] ?? ''} ${widget.passengerData['lastName'] ?? ''}'.trim();
//   String get _email  => widget.passengerData['email']        as String? ?? '';
//   String get _mobile => widget.passengerData['mobileNumber'] as String? ?? '';
//
//   FareQuoteData?     get _fare    => widget.route.fareQuoteData;
//   BookingDetailsModel? get _d     => _details;
//
//   double get _baseFare  => _fare?.baseFare  ?? _d?.baseFare  ?? 0;
//   double get _tax       => _fare?.tax       ?? _d?.tax       ?? 0;
//   double get _total     => _fare?.total     ?? _d?.offeredFare ?? _d?.publishedFare ?? (_baseFare + _tax);
//   String get _currency  => _fare?.currency  ?? _d?.currency  ?? 'INR';
//
//   // The currency the user sees in the app (their preferred currency).
//   // TBO fare is in _currency; we convert to preferredCurrency for display.
//   String get _preferredCurrency => CurrencyConverter.getPreferredCurrency();
//
//   /// Format a fare amount: convert from TBO fare currency → user's preferred
//   /// currency, then format with symbol (e.g. ₹12,345 or $150).
//   String _fmt(double amount) {
//     final converted = CurrencyConverter.convert(
//       amount: amount,
//       fromCurrency: _currency,
//       toCurrency: _preferredCurrency,
//     );
//     return CurrencyConverter.format(converted, _preferredCurrency);
//   }
//
//   List<BookingSegmentDetail>       get _segs => _d?.segments   ?? [];
//   List<BookingPassengerDetail>     get _dpax => _d?.passengers ?? [];
//   List<TicketPassengerEntity>      get _tpax => widget.ticket.passengers ?? [];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchDetails();
//   }
//
//   Future<void> _fetchDetails() async {
//     if (_pnr == 'N/A') { setState(() => _loadingDetails = false); return; }
//     try {
//       final svc = BookingDetailsService(di.sl<Dio>());
//       final d = await svc.fetch(_pnr);
//       setState(() {
//         _details = d;
//         _loadingDetails = false;
//         if (!d.isSuccess && d.errorMessage != null) _detailsError = d.errorMessage;
//       });
//     } catch (e) {
//       setState(() { _loadingDetails = false; _detailsError = e.toString(); });
//     }
//   }
//
//   // ── date helpers ──────────────────────────────────────────────────────────
//   String _dt(String? raw) {
//     if (raw == null || raw.isEmpty) return 'N/A';
//     try { return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(raw)); }
//     catch (_) { return raw; }
//   }
//   String _timeOnly(String? raw) {
//     if (raw == null || raw.isEmpty) return '';
//     try { return DateFormat('HH:mm').format(DateTime.parse(raw)); }
//     catch (_) { return raw; }
//   }
//   String _dateOnly(String? raw) {
//     if (raw == null || raw.isEmpty) return '';
//     try { return DateFormat('dd MMM yyyy').format(DateTime.parse(raw)); }
//     catch (_) { return raw; }
//   }
//   String _dur(int? m) {
//     if (m == null) return '';
//     final h = m ~/ 60; final mn = m % 60;
//     return h > 0 ? '${h}h ${mn}m' : '${mn}m';
//   }
//   int _totalDur() => _segs.fold<int>(0, (s, seg) => s + (seg.duration ?? 0));
//
//   // ── PDF ───────────────────────────────────────────────────────────────────
//   Future<void> _downloadPdf() async {
//     try {
//       final bytes = await _buildPdf();
//       await Printing.sharePdf(bytes: bytes, filename: 'WanderNova_${_pnr}.pdf');
//     } catch (e) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('PDF export failed: $e'), backgroundColor: _red));
//     }
//   }
//
//   Future<Uint8List> _buildPdf() async {
//     final doc = pw.Document();
//
//     doc.addPage(pw.MultiPage(
//       pageFormat: PdfPageFormat.a4,
//       margin: const pw.EdgeInsets.all(36),
//       header: (_) => _pdfHeader(),
//       build: (_) => [
//         pw.SizedBox(height: 14),
//         _pdfConfirmBanner(),
//         pw.SizedBox(height: 18),
//         _pdfSectionTitle('FLIGHT DETAILS'),
//         pw.SizedBox(height: 8),
//         if (_segs.isNotEmpty)
//           ..._segs.map(_pdfSegment)
//         else
//           _pdfFallbackRoute(),
//         pw.SizedBox(height: 18),
//         _pdfSectionTitle('PASSENGER INFORMATION'),
//         pw.SizedBox(height: 8),
//         _pdfPassengerTable(),
//         pw.SizedBox(height: 18),
//         _pdfSectionTitle('FARE SUMMARY'),
//         pw.SizedBox(height: 8),
//         _pdfFareBox(),
//         pw.SizedBox(height: 20),
//         _pdfTerms(),
//         pw.SizedBox(height: 14),
//         _pdfFooter(),
//       ],
//     ));
//     return doc.save();
//   }
//
//   pw.Widget _pdfHeader() => pw.Container(
//     padding: const pw.EdgeInsets.only(bottom: 10),
//     decoration: const pw.BoxDecoration(
//       border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
//     child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
//       pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
//         pw.Row(children: [
//           pw.Text('WANDER', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
//           pw.Text('NOVA',   style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
//         ]),
//         pw.Text('TRAVEL SERVICES', style: pw.TextStyle(fontSize: 7, color: PdfColors.teal700, letterSpacing: 2)),
//       ]),
//       pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
//         pw.Text('E-TICKET', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800, letterSpacing: 2)),
//         pw.SizedBox(height: 2),
//         pw.Text('Invoice: $_invoiceNo', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
//         pw.Text('PNR: $_pnr', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, letterSpacing: 1)),
//       ]),
//     ]),
//   );
//
//   pw.Widget _pdfConfirmBanner() => pw.Container(
//     padding: const pw.EdgeInsets.all(14),
//     decoration: pw.BoxDecoration(
//       color: PdfColors.green50,
//       borderRadius: pw.BorderRadius.circular(8),
//       border: pw.Border.all(color: PdfColors.green200),
//     ),
//     child: pw.Row(children: [
//       pw.Container(
//         width: 22, height: 22,
//         decoration: const pw.BoxDecoration(color: PdfColors.green, shape: pw.BoxShape.circle),
//         child: pw.Center(child: pw.Text('✓', style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold))),
//       ),
//       pw.SizedBox(width: 12),
//       pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
//         pw.Text('Booking Confirmed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.green800)),
//         pw.Text('Your e-ticket has been issued successfully.', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
//       ])),
//       pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
//         pw.Text('Billed To', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
//         pw.Text(_passengerName.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
//         if (_email.isNotEmpty) pw.Text(_email, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
//         if (_mobile.isNotEmpty) pw.Text(_mobile, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
//       ]),
//     ]),
//   );
//
//   pw.Widget _pdfSegment(BookingSegmentDetail seg) => pw.Container(
//     margin: const pw.EdgeInsets.only(bottom: 10),
//     padding: const pw.EdgeInsets.all(12),
//     decoration: pw.BoxDecoration(
//       border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
//       borderRadius: pw.BorderRadius.circular(6),
//     ),
//     child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
//       pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
//         pw.Text(
//           '${seg.airlineName ?? ''} (${seg.airlineCode ?? ''})  ·  Flt ${seg.flightNumber ?? ''}',
//           style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
//         pw.Text('Class: ${seg.fareClass ?? '—'}  |  Duration: ${_dur(seg.duration)}',
//             style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
//       ]),
//       pw.SizedBox(height: 10),
//       pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
//         pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
//           pw.Text(seg.originCode ?? '', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
//           pw.Text(seg.originName ?? '', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
//           pw.SizedBox(height: 3),
//           pw.Text(_timeOnly(seg.depTime), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
//           pw.Text(_dateOnly(seg.depTime), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
//           if (seg.originTerminal?.isNotEmpty ?? false)
//             pw.Text('Terminal ${seg.originTerminal}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
//         ]),
//         pw.Column(children: [
//           pw.Text('──── ✈ ────', style: pw.TextStyle(fontSize: 9, color: PdfColors.red700)),
//         ]),
//         pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
//           pw.Text(seg.destCode ?? '', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
//           pw.Text(seg.destName ?? '', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
//           pw.SizedBox(height: 3),
//           pw.Text(_timeOnly(seg.arrTime), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
//           pw.Text(_dateOnly(seg.arrTime), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
//           if (seg.destTerminal?.isNotEmpty ?? false)
//             pw.Text('Terminal ${seg.destTerminal}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
//         ]),
//       ]),
//       if ((seg.baggage?.isNotEmpty ?? false) || (seg.cabinBaggage?.isNotEmpty ?? false)) ...[
//         pw.SizedBox(height: 6),
//         pw.Row(children: [
//           if (seg.baggage?.isNotEmpty ?? false)
//             _pdfBadge('Check-in: ${seg.baggage!}'),
//           if (seg.cabinBaggage?.isNotEmpty ?? false) ...[
//             pw.SizedBox(width: 6),
//             _pdfBadge('Cabin: ${seg.cabinBaggage!}'),
//           ],
//         ]),
//       ],
//     ]),
//   );
//
//   pw.Widget _pdfFallbackRoute() => pw.Container(
//     padding: const pw.EdgeInsets.all(12),
//     decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5), borderRadius: pw.BorderRadius.circular(6)),
//     child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
//       pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
//         pw.Text(widget.route.from, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//         pw.Text(widget.route.departureTime, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
//       ]),
//       pw.Column(children: [
//         pw.Text(widget.route.duration, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
//         pw.Text('──── ✈ ────', style: pw.TextStyle(fontSize: 9, color: PdfColors.red700)),
//       ]),
//       pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
//         pw.Text(widget.route.to, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//         pw.Text(widget.route.arrivalTime, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
//       ]),
//     ]),
//   );
//
//   pw.Widget _pdfPassengerTable() {
//     // build rows
//     List<List<String>> rows;
//     if (_dpax.isNotEmpty) {
//       rows = _dpax.map((p) => [
//         p.fullName.isNotEmpty ? p.fullName : _passengerName,
//         _email,
//         _mobile,
//         // p.ticketNumber ?? 'Processing…',
//         p.ticketStatus ?? 'Confirmed',
//       ]).toList();
//     } else if (_tpax.isNotEmpty) {
//       rows = _tpax.map((p) => [
//         '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim().isEmpty ? _passengerName : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim(),
//         _email,
//         _mobile,
//         p.ticketNumber ?? 'N/A',
//         p.status ?? 'Confirmed',
//       ]).toList();
//     } else {
//       rows = [[_passengerName, _email, _mobile, 'Processing…', 'Confirmed']];
//     }
//
//     return pw.Table(
//       border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
//       columnWidths: {
//         0: const pw.FlexColumnWidth(2.2),
//         1: const pw.FlexColumnWidth(2.5),
//         2: const pw.FlexColumnWidth(1.8),
//         3: const pw.FlexColumnWidth(2.2),
//         4: const pw.FlexColumnWidth(1.3),
//       },
//       children: [
//         pw.TableRow(
//           decoration: const pw.BoxDecoration(color: PdfColors.blue900),
//           children: ['PASSENGER', 'EMAIL', 'MOBILE', 'TICKET NUMBER', 'STATUS']
//               .map((h) => pw.Padding(
//                     padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
//                     child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)),
//                   ))
//               .toList(),
//         ),
//         ...rows.map((row) => pw.TableRow(
//           children: row.map((cell) => pw.Padding(
//             padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
//             child: pw.Text(cell.isEmpty ? '—' : cell, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey900)),
//           )).toList(),
//         )),
//       ],
//     );
//   }
//
//   pw.Widget _pdfFareBox() => pw.Container(
//     padding: const pw.EdgeInsets.all(14),
//     decoration: pw.BoxDecoration(
//       color: PdfColors.grey50,
//       borderRadius: pw.BorderRadius.circular(6),
//       border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
//     ),
//     child: pw.Column(children: [
//       _pdfFareRow('Base Fare',   '$_currency ${_baseFare.toStringAsFixed(2)}'),
//       pw.Divider(color: PdfColors.grey200, height: 12),
//       _pdfFareRow('Taxes & Fees', '$_currency ${_tax.toStringAsFixed(2)}'),
//       pw.Divider(color: PdfColors.grey300, height: 16),
//       _pdfFareRow('Total Paid',  '$_currency ${_total.toStringAsFixed(2)}', bold: true),
//     ]),
//   );
//
//   pw.Widget _pdfFareRow(String l, String v, {bool bold = false}) =>
//     pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
//       pw.Text(l, style: pw.TextStyle(fontSize: bold ? 12 : 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: bold ? PdfColors.grey900 : PdfColors.grey700)),
//       pw.Text(v, style: pw.TextStyle(fontSize: bold ? 12 : 10, fontWeight: pw.FontWeight.bold, color: bold ? PdfColors.red700 : PdfColors.grey900)),
//     ]);
//
//   pw.Widget _pdfTerms() => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
//     pw.Divider(color: PdfColors.grey300, height: 1),
//     pw.SizedBox(height: 8),
//     pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, letterSpacing: 1)),
//     pw.SizedBox(height: 4),
//     pw.Text(
//       'All bookings are subject to our terms and conditions. Cancellations must be made at least 24 hours before departure. '
//       'For support, contact support@wandernova.com. This e-ticket is valid for the services listed above.',
//       style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, lineSpacing: 2)),
//   ]);
//
//   pw.Widget _pdfFooter() => pw.Container(
//     padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//     decoration: pw.BoxDecoration(color: const PdfColor(0, 0.37, 0.72), borderRadius: pw.BorderRadius.circular(6)),
//     child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
//       pw.Text('WanderNova Travel Services', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
//       pw.Text('support@wandernova.com',     style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
//     ]),
//   );
//
//   pw.Widget _pdfSectionTitle(String t) => pw.Text(
//     t, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, letterSpacing: 1));
//
//   pw.Widget _pdfBadge(String t) => pw.Container(
//     padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//     decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(10), border: pw.Border.all(color: PdfColors.blue200, width: 0.5)),
//     child: pw.Text(t, style: pw.TextStyle(fontSize: 8, color: PdfColors.blue800)),
//   );
//
//   // ── invoice bottom sheet ──────────────────────────────────────────────────
//   void _showInvoice() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _InvoiceSheet(
//         pnr: _pnr, invoiceNo: _invoiceNo, bookId: _bookId,
//         passengerName: _passengerName, email: _email, mobile: _mobile,
//         baseFare: _baseFare, tax: _tax, total: _total, currency: _currency,
//         segs: _segs, dpax: _dpax, tpax: _tpax,
//         route: widget.route,
//         onDownload: _downloadPdf,
//         dtFn: _dt, dateOnlyFn: _dateOnly, timeOnlyFn: _timeOnly, durFn: _dur, totalDurFn: _totalDur,
//       ),
//     );
//   }
//
//   // ── build ─────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _indigoBg,
//       appBar: AppBar(
//         title: const WanderNovaLogo(scaleFactor: 0.6),
//         backgroundColor: _navyDark,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download_rounded, color: Colors.white),
//             tooltip: 'Download PDF',
//             onPressed: _downloadPdf,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: context.responsivePadding,
//         child: Column(children: [
//           SizedBox(height: context.gapSmall),
//           _buildBanner(context),
//           SizedBox(height: context.gapSmall),
//           _buildPNRCard(context),
//           SizedBox(height: context.gapSmall),
//           _buildFlightCard(context),
//           SizedBox(height: context.gapSmall),
//           _buildPassengerCard(context),
//           SizedBox(height: context.gapSmall),
//           _buildFareCard(context),
//           if (_detailsError != null) ...[
//             SizedBox(height: context.gapSmall),
//             _buildErrorNote(context),
//           ],
//           SizedBox(height: context.gapSmall),
//           _buildActions(context),
//           SizedBox(height: context.gapLarge),
//         ]),
//       ),
//     );
//   }
//
//   // ── success banner ─────────────────────────────────────────────────────────
//   Widget _buildBanner(BuildContext context) => Container(
//     padding: EdgeInsets.all(context.w(16)),
//     decoration: BoxDecoration(
//       gradient: const LinearGradient(colors: [Color(0xFF27AE60), Color(0xFF1E8449)]),
//       borderRadius: BorderRadius.circular(context.borderRadius),
//       boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
//     ),
//     child: Row(children: [
//       const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 40),
//       SizedBox(width: context.gapSmall),
//       Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text('Booking Confirmed!', style: TextStyle(color: Colors.white, fontSize: context.titleLarge, fontWeight: FontWeight.bold)),
//         SizedBox(height: 2),
//         Text('Your e-ticket has been issued.', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: context.bodySmall)),
//       ])),
//       Icon(Icons.flight_takeoff_rounded, color: Colors.white.withValues(alpha: 0.45), size: 40),
//     ]),
//   );
//
//   // ── PNR card ───────────────────────────────────────────────────────────────
//   Widget _buildPNRCard(BuildContext context) => _card(context, child: Column(children: [
//     Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//       Text('PNR / Booking Reference', style: TextStyle(fontSize: context.bodySmall, color: _textMid, fontWeight: FontWeight.w600)),
//       GestureDetector(
//         onTap: () {
//           Clipboard.setData(ClipboardData(text: _pnr));
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PNR copied')));
//         },
//         child: Row(children: [
//           const Icon(Icons.copy_rounded, size: 14, color: _navy),
//           const SizedBox(width: 3),
//           Text('Copy', style: TextStyle(color: _navy, fontSize: context.labelSmall, fontWeight: FontWeight.w600)),
//         ]),
//       ),
//     ]),
//     SizedBox(height: context.gapSmall),
//     Text(_pnr, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5, color: _red)),
//     SizedBox(height: 2),
//     Text('Booking ID: $_bookId  ·  Invoice: $_invoiceNo',
//         style: TextStyle(color: _textMid, fontSize: context.labelSmall)),
//     if (_loadingDetails) ...[
//       SizedBox(height: context.gapSmall),
//       const LinearProgressIndicator(backgroundColor: _indigoBg, color: _navy, minHeight: 2),
//       SizedBox(height: 2),
//       Text('Loading booking details…', style: TextStyle(color: _textMid, fontSize: context.labelSmall)),
//     ],
//   ]));
//
//   // ── flight card ─────────────────────────────────────────────────────────────
//   Widget _buildFlightCard(BuildContext context) => _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//     _sectionHeader(context, 'FLIGHT DETAILS'),
//     SizedBox(height: context.gapSmall),
//     if (_segs.isNotEmpty)
//       ..._segs.asMap().entries.map((e) {
//         final i = e.key; final seg = e.value;
//         return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           if (i > 0) _stopoverDivider(context, seg.originCode ?? ''),
//           _segRow(context, seg),
//           SizedBox(height: context.gapSmall),
//           if ((seg.baggage?.isNotEmpty ?? false) || (seg.cabinBaggage?.isNotEmpty ?? false))
//             Wrap(spacing: 8, children: [
//               if (seg.baggage?.isNotEmpty ?? false) _badge('Check-in: ${seg.baggage!}'),
//               if (seg.cabinBaggage?.isNotEmpty ?? false) _badge('Cabin: ${seg.cabinBaggage!}'),
//             ]),
//           SizedBox(height: context.gapSmall),
//         ]);
//       })
//     else
//       _fallbackRoute(context),
//   ]));
//
//   Widget _segRow(BuildContext context, BookingSegmentDetail seg) => Row(children: [
//     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(seg.originCode ?? '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark)),
//       Text(_timeOnly(seg.depTime), style: TextStyle(fontSize: context.bodyLarge, fontWeight: FontWeight.w600, color: _textDark)),
//       Text(_dateOnly(seg.depTime), style: TextStyle(fontSize: context.bodySmall, color: _textMid)),
//       if (seg.originName?.isNotEmpty ?? false)
//         Text(seg.originName!, style: TextStyle(fontSize: context.labelSmall, color: _textMid), maxLines: 2, overflow: TextOverflow.ellipsis),
//       if (seg.originTerminal?.isNotEmpty ?? false)
//         _terminalBadge('T${seg.originTerminal}'),
//     ])),
//     Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Column(children: [
//         Text(_dur(seg.duration), style: TextStyle(fontSize: context.labelSmall, color: _textMid)),
//         const SizedBox(height: 2),
//         const Icon(Icons.flight, color: _red, size: 20),
//         const SizedBox(height: 2),
//         if ((seg.airlineCode?.isNotEmpty ?? false))
//           Text('${seg.airlineCode} ${seg.flightNumber ?? ''}',
//               style: TextStyle(fontSize: context.labelSmall, color: _textMid)),
//       ]),
//     ),
//     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//       Text(seg.destCode ?? '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark)),
//       Text(_timeOnly(seg.arrTime), style: TextStyle(fontSize: context.bodyLarge, fontWeight: FontWeight.w600, color: _textDark)),
//       Text(_dateOnly(seg.arrTime), style: TextStyle(fontSize: context.bodySmall, color: _textMid)),
//       if (seg.destName?.isNotEmpty ?? false)
//         Text(seg.destName!, style: TextStyle(fontSize: context.labelSmall, color: _textMid), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
//       if (seg.destTerminal?.isNotEmpty ?? false)
//         _terminalBadge('T${seg.destTerminal}'),
//     ])),
//   ]);
//
//   Widget _stopoverDivider(BuildContext context, String code) => Padding(
//     padding: EdgeInsets.symmetric(vertical: context.gapSmall),
//     child: Row(children: [
//       Expanded(child: Divider(color: Colors.grey.shade200)),
//       Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8),
//         child: Text('Stopover · $code', style: TextStyle(color: _textMid, fontSize: context.labelSmall)),
//       ),
//       Expanded(child: Divider(color: Colors.grey.shade200)),
//     ]),
//   );
//
//   Widget _fallbackRoute(BuildContext context) => Row(children: [
//     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(widget.route.from, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
//       Text(widget.route.departureTime, style: TextStyle(color: _textMid, fontSize: context.bodySmall)),
//     ])),
//     Column(children: [
//       Text(widget.route.duration, style: TextStyle(color: _textMid, fontSize: context.labelSmall)),
//       const Icon(Icons.flight, color: _red, size: 20),
//     ]),
//     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//       Text(widget.route.to, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
//       Text(widget.route.arrivalTime, style: TextStyle(color: _textMid, fontSize: context.bodySmall)),
//     ])),
//   ]);
//
//   // ── passenger card ─────────────────────────────────────────────────────────
//   Widget _buildPassengerCard(BuildContext context) => _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//     _sectionHeader(context, 'PASSENGER INFORMATION'),
//     SizedBox(height: context.gapSmall),
//     // Contact info row (from form data)
//     if (_email.isNotEmpty || _mobile.isNotEmpty)
//       Container(
//         margin: EdgeInsets.only(bottom: context.gapSmall),
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(8)),
//         child: Row(children: [
//           Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             if (_email.isNotEmpty) ...[
//               Text('Email', style: TextStyle(fontSize: context.labelSmall, color: _textMid, fontWeight: FontWeight.w500)),
//               Text(_email, style: TextStyle(fontSize: context.bodySmall, color: _textDark, fontWeight: FontWeight.w600)),
//             ],
//           ])),
//           if (_mobile.isNotEmpty)
//             Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//               Text('Mobile', style: TextStyle(fontSize: context.labelSmall, color: _textMid, fontWeight: FontWeight.w500)),
//               Text(_mobile, style: TextStyle(fontSize: context.bodySmall, color: _textDark, fontWeight: FontWeight.w600)),
//             ]),
//         ]),
//       ),
//     // Passenger rows
//     if (_dpax.isNotEmpty)
//       ..._dpax.map((p) => _paxRow(context, p.fullName.isNotEmpty ? p.fullName : _passengerName, p.ticketNumber, p.ticketStatus))
//     else if (_tpax.isNotEmpty)
//       ..._tpax.map((p) {
//         final n = '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();
//         return _paxRow(context, n.isEmpty ? _passengerName : n, p.ticketNumber, p.status);
//       })
//     else
//       _paxRow(context, _passengerName, null, 'Confirmed'),
//   ]));
//
//   Widget _paxRow(BuildContext context, String name, String? ticketNo, String? status) =>
//     Padding(
//       padding: EdgeInsets.only(bottom: context.gapSmall),
//       child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(name.isEmpty ? 'Passenger' : name,
//               style: TextStyle(fontWeight: FontWeight.w700, fontSize: context.bodyMedium, color: _textDark)),
//           SizedBox(height: 2),
//           Text('Ticket: ${ticketNo ?? 'Processing…'}',
//               style: TextStyle(color: _textMid, fontSize: context.bodySmall)),
//         ])),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
//           decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _green.withValues(alpha: 0.3))),
//           child: Text(status ?? 'Confirmed', style: TextStyle(color: _green, fontSize: context.labelSmall, fontWeight: FontWeight.w700)),
//         ),
//       ]),
//     );
//
//   // ── fare card ──────────────────────────────────────────────────────────────
//   Widget _buildFareCard(BuildContext context) => _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//     _sectionHeader(context, 'FARE SUMMARY'),
//     SizedBox(height: context.gapSmall),
//     _fareRow(context, 'Base Fare', '$_currency ${_baseFare.toStringAsFixed(2)}'),
//     SizedBox(height: context.gapSmall),
//     _fareRow(context, 'Taxes & Fees', '$_currency ${_tax.toStringAsFixed(2)}'),
//     Divider(height: context.gapLarge, color: _borderC),
//     _fareRow(context, 'Total Paid', '$_currency ${_total.toStringAsFixed(2)}', isTotal: true),
//   ]));
//
//   Widget _fareRow(BuildContext context, String l, String v, {bool isTotal = false}) =>
//     Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//       Text(l, style: TextStyle(fontSize: isTotal ? context.bodyLarge : context.bodyMedium, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? _textDark : _textMid)),
//       Text(v, style: TextStyle(fontSize: isTotal ? context.bodyLarge : context.bodyMedium, fontWeight: FontWeight.bold, color: isTotal ? _red : _textDark)),
//     ]);
//
//   // ── error note ─────────────────────────────────────────────────────────────
//   Widget _buildErrorNote(BuildContext context) => Container(
//     padding: const EdgeInsets.all(12),
//     decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
//     child: Row(children: [
//       Expanded(child: Text('Could not refresh booking details. Showing data from ticket issuance.',
//           style: TextStyle(color: Colors.orange.shade800, fontSize: context.bodySmall))),
//       TextButton(onPressed: _fetchDetails, child: const Text('Retry')),
//     ]),
//   );
//
//   // ── action buttons ──────────────────────────────────────────────────────────
//   Widget _buildActions(BuildContext context) => Column(children: [
//     Row(children: [
//       Expanded(child: _btn(context, label: 'Download PDF', icon: Icons.download_rounded, onTap: _downloadPdf, primary: true)),
//       SizedBox(width: context.gapSmall),
//       Expanded(child: _btn(context, label: 'View Invoice', icon: Icons.receipt_outlined, onTap: _showInvoice, primary: false)),
//     ]),
//     SizedBox(height: context.gapSmall),
//     SizedBox(
//       width: double.infinity,
//       height: context.buttonHeight + 4,
//       child: OutlinedButton(
//         onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
//         style: OutlinedButton.styleFrom(side: const BorderSide(color: _navy, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//         child: Text('Back to Home', style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: context.bodyMedium)),
//       ),
//     ),
//   ]);
//
//   Widget _btn(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap, required bool primary}) =>
//     SizedBox(
//       height: context.buttonHeight + 4,
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, color: primary ? Colors.white : _navy, size: 16),
//         label: Text(label, style: TextStyle(color: primary ? Colors.white : _navy, fontWeight: FontWeight.bold, fontSize: context.bodySmall)),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primary ? _red : _indigoBg,
//           elevation: primary ? 2 : 0,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//     );
//
//   // ── shared helpers ─────────────────────────────────────────────────────────
//   Widget _sectionHeader(BuildContext context, String title) =>
//     Text(title, style: TextStyle(fontSize: context.labelSmall, fontWeight: FontWeight.bold, color: _textMid, letterSpacing: 1));
//
//   Widget _terminalBadge(String t) => Container(
//     margin: const EdgeInsets.only(top: 2),
//     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
//     decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(4), border: Border.all(color: _navy.withValues(alpha: 0.2))),
//     child: Text(t, style: TextStyle(fontSize: 9, color: _navy, fontWeight: FontWeight.w600)),
//   );
//
//   Widget _badge(String t) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//     decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _navy.withValues(alpha: 0.2))),
//     child: Text(t, style: TextStyle(color: _navy, fontSize: 10, fontWeight: FontWeight.w500)),
//   );
//
//   Widget _card(BuildContext context, {required Widget child}) => Container(
//     width: double.infinity,
//     padding: EdgeInsets.all(context.w(16)),
//     decoration: BoxDecoration(
//       color: _surface,
//       borderRadius: BorderRadius.circular(context.borderRadius),
//       border: Border.all(color: _borderC),
//       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
//     ),
//     child: child,
//   );
// }
//
// // ═══════════════════════════════════════════════════════════════════════════════
// //  Invoice Bottom Sheet
// // ═══════════════════════════════════════════════════════════════════════════════
// class _InvoiceSheet extends StatefulWidget {
//   final String pnr, invoiceNo, bookId;
//   final String passengerName, email, mobile;
//   final double baseFare, tax, total;
//   final String currency;
//   final List<BookingSegmentDetail> segs;
//   final List<BookingPassengerDetail> dpax;
//   final List<TicketPassengerEntity> tpax;
//   final FlightRouteSegment route;
//   final VoidCallback onDownload;
//   final String Function(String?) dtFn, dateOnlyFn, timeOnlyFn;
//   final String Function(int?) durFn;
//   final int Function() totalDurFn;
//
//   const _InvoiceSheet({
//     required this.pnr, required this.invoiceNo, required this.bookId,
//     required this.passengerName, required this.email, required this.mobile,
//     required this.baseFare, required this.tax, required this.total, required this.currency,
//     required this.segs, required this.dpax, required this.tpax, required this.route,
//     required this.onDownload,
//     required this.dtFn, required this.dateOnlyFn, required this.timeOnlyFn,
//     required this.durFn, required this.totalDurFn,
//   });
//
//   @override
//   State<_InvoiceSheet> createState() => _InvoiceSheetState();
// }
//
// class _InvoiceSheetState extends State<_InvoiceSheet>
//     with SingleTickerProviderStateMixin {
//   late TabController _tab;
//
//   @override
//   void initState() {
//     super.initState();
//     _tab = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() { _tab.dispose(); super.dispose(); }
//
//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.94,
//       maxChildSize: 0.97,
//       minChildSize: 0.5,
//       builder: (_, sc) => Container(
//         decoration: const BoxDecoration(color: _surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//         child: Column(children: [
//           // drag handle
//           Center(child: Container(
//             margin: const EdgeInsets.symmetric(vertical: 10),
//             width: 40, height: 4,
//             decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
//           )),
//           // top bar
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//             child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//               TabBar(
//                 controller: _tab,
//                 isScrollable: true,
//                 labelColor: _navy,
//                 unselectedLabelColor: _textMid,
//                 labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//                 indicatorColor: _red,
//                 indicatorWeight: 2,
//                 tabs: const [Tab(text: 'Invoice'), Tab(text: 'E-Ticket')],
//               ),
//               Row(children: [
//                 ElevatedButton.icon(
//                   onPressed: () { Navigator.pop(context); widget.onDownload(); },
//                   icon: const Icon(Icons.download_rounded, size: 15, color: Colors.white),
//                   label: const Text('Download', style: TextStyle(color: Colors.white, fontSize: 12)),
//                   style: ElevatedButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
//                 ),
//                 const SizedBox(width: 6),
//                 InkWell(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
//                     child: const Icon(Icons.close, size: 18, color: _textMid),
//                   ),
//                 ),
//               ]),
//             ]),
//           ),
//           Divider(color: Colors.grey.shade200, height: 1),
//           Expanded(
//             child: TabBarView(controller: _tab, children: [
//               _buildInvoiceTab(sc),
//               _buildETicketTab(sc),
//             ]),
//           ),
//         ]),
//       ),
//     );
//   }
//
//   // ── INVOICE TAB ──────────────────────────────────────────────────────────────
//   Widget _buildInvoiceTab(ScrollController sc) {
//     return SingleChildScrollView(
//       controller: sc,
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         // brand header
//         Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             RichText(text: const TextSpan(children: [
//               TextSpan(text: 'WANDER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0668CC), letterSpacing: 2)),
//               TextSpan(text: 'NOVA',   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFE6B02), letterSpacing: 2)),
//             ])),
//             const Text('TRAVEL SERVICES', style: TextStyle(fontSize: 9, letterSpacing: 4, color: Color(0xFF0EA3A3), fontWeight: FontWeight.w600)),
//           ]),
//           Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//             const Text('INVOICE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2, color: _textDark)),
//             Text(widget.invoiceNo, style: const TextStyle(color: _textMid, fontSize: 11)),
//           ]),
//         ]),
//         const SizedBox(height: 12),
//         // billed to
//         Text(widget.passengerName.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
//         const SizedBox(height: 2),
//         if (widget.email.isNotEmpty)  Text(widget.email,  style: const TextStyle(fontSize: 12, color: _textMid)),
//         if (widget.mobile.isNotEmpty) Text(widget.mobile, style: const TextStyle(fontSize: 12, color: _textMid)),
//         const SizedBox(height: 14),
//         Divider(color: Colors.grey.shade300),
//         const SizedBox(height: 12),
//
//         // service table
//         _invFlightTable(),
//         const SizedBox(height: 20),
//
//         // billing + fare
//         LayoutBuilder(builder: (_, box) {
//           final wide = box.maxWidth > 480;
//           final left = _invBillingInfo();
//           final right = _invFareSummary();
//           return wide
//             ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 20), SizedBox(width: 220, child: right)])
//             : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 16), right]);
//         }),
//         const SizedBox(height: 20),
//         Divider(color: Colors.grey.shade300),
//         const SizedBox(height: 8),
//         const Text('TERMS & CONDITIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _textDark)),
//         const SizedBox(height: 4),
//         const Text(
//           'All bookings are subject to our terms and conditions. Cancellations must be made at least 24 hours '
//           'before departure. For support, contact support@wandernova.com.',
//           style: TextStyle(fontSize: 11, color: _textMid, height: 1.6)),
//         const SizedBox(height: 20),
//         // footer
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           decoration: BoxDecoration(color: const Color(0xFF005EB8), borderRadius: BorderRadius.circular(8)),
//           child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//             Text('WanderNova Travel Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
//             Text('support@wandernova.com', style: TextStyle(color: Colors.white70, fontSize: 11)),
//           ]),
//         ),
//       ]),
//     );
//   }
//
//   Widget _invFlightTable() {
//     final fromCode = widget.segs.isNotEmpty ? (widget.segs.first.originCode ?? widget.route.from) : widget.route.from;
//     final toCode   = widget.segs.isNotEmpty ? (widget.segs.last.destCode   ?? widget.route.to)   : widget.route.to;
//     final paxNames = widget.dpax.isNotEmpty
//         ? widget.dpax.map((p) => p.fullName.isNotEmpty ? p.fullName : widget.passengerName).join(', ')
//         : widget.tpax.isNotEmpty
//             ? widget.tpax.map((p) => '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim()).join(', ')
//             : widget.passengerName;
//     final totalDur = widget.totalDurFn();
//     final durStr = totalDur > 0 ? widget.durFn(totalDur) : widget.route.duration;
//     final totalStr = '${widget.currency} ${widget.total.toStringAsFixed(2)}';
//
//     return Table(
//       border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
//       columnWidths: const {
//         0: FlexColumnWidth(1.2),
//         1: FlexColumnWidth(1.4),
//         2: FlexColumnWidth(2.5),
//         3: FlexColumnWidth(1.2),
//         4: FlexColumnWidth(1.4),
//       },
//       children: [
//         TableRow(
//           decoration: const BoxDecoration(color: Color(0xFF005EB8)),
//           children: ['TYPE', 'ROUTE', 'PASSENGER(S)', 'DURATION', 'TOTAL'].map((h) =>
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//               child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
//             )).toList(),
//         ),
//         TableRow(children: [
//           _tc('One Way'),
//           _tc('$fromCode → $toCode'),
//           _tc(paxNames),
//           _tc(durStr),
//           _tc(totalStr),
//         ]),
//       ],
//     );
//   }
//
//   Widget _invBillingInfo() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//     const Text('BILLING INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
//     const SizedBox(height: 8),
//     _infoRow('Billed by',        widget.passengerName.toUpperCase()),
//     _infoRow('Issued by',        'WANDERNOVA TRAVEL'),
//     _infoRow('PNR',              widget.pnr),
//     _infoRow('Invoice Status',   'Raised'),
//     _infoRow('Payment Basis',    'InvoiceDate'),
//   ]);
//
//   Widget _invFareSummary() => Column(children: [
//     _fareLine('BASE FARE',  '${widget.currency} ${widget.baseFare.toStringAsFixed(2)}'),
//     const SizedBox(height: 8),
//     _fareLine('TAX & FEES', '${widget.currency} ${widget.tax.toStringAsFixed(2)}'),
//     const SizedBox(height: 8),
//     Divider(color: Colors.grey.shade300),
//     const SizedBox(height: 4),
//     _fareLine('TOTAL', '${widget.currency} ${widget.total.toStringAsFixed(2)}', large: true),
//   ]);
//
//   // ── E-TICKET TAB ─────────────────────────────────────────────────────────────
//   Widget _buildETicketTab(ScrollController sc) {
//     return SingleChildScrollView(
//       controller: sc,
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         // header
//         Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             RichText(text: const TextSpan(children: [
//               TextSpan(text: 'WANDER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0668CC), letterSpacing: 2)),
//               TextSpan(text: 'NOVA',   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFE6B02), letterSpacing: 2)),
//             ])),
//             const Text('TRAVEL SERVICES', style: TextStyle(fontSize: 9, letterSpacing: 4, color: Color(0xFF0EA3A3), fontWeight: FontWeight.w600)),
//           ]),
//           const Text('E-TICKET', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: _textDark)),
//         ]),
//         const SizedBox(height: 12),
//
//         // confirmed strip
//         Container(
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _green.withValues(alpha: 0.3))),
//           child: Row(children: [
//             const Icon(Icons.check_circle_outline_rounded, color: _green, size: 28),
//             const SizedBox(width: 12),
//             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               const Text('Your booking is confirmed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _green)),
//               Text('${widget.passengerName.toUpperCase()}  ·  ${widget.email}', style: const TextStyle(color: _textMid, fontSize: 11)),
//             ])),
//             Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//               const Text('PNR', style: TextStyle(fontSize: 9, color: _textMid)),
//               Text(widget.pnr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy, letterSpacing: 3)),
//             ]),
//           ]),
//         ),
//         const SizedBox(height: 16),
//
//         // segments
//         if (widget.segs.isNotEmpty) ...[
//           const Text('FLIGHT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
//           const SizedBox(height: 8),
//           ...widget.segs.asMap().entries.map((e) {
//             final i = e.key; final seg = e.value;
//             return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               if (i > 0) Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: Row(children: [
//                   Expanded(child: Divider(color: Colors.grey.shade200)),
//                   Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
//                       child: Text('Stopover · ${seg.originCode ?? ''}', style: const TextStyle(color: _textMid, fontSize: 11))),
//                   Expanded(child: Divider(color: Colors.grey.shade200)),
//                 ]),
//               ),
//               Container(
//                 margin: const EdgeInsets.only(bottom: 10),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(10)),
//                 child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                   Text('${seg.airlineName ?? ''} (${seg.airlineCode ?? ''}) · Flt ${seg.flightNumber ?? ''}  ·  Class: ${seg.fareClass ?? '—'}',
//                       style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _textDark)),
//                   const SizedBox(height: 10),
//                   Row(children: [
//                     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                       Text(seg.originCode ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
//                       Text(widget.timeOnlyFn(seg.depTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
//                       Text(widget.dateOnlyFn(seg.depTime), style: const TextStyle(fontSize: 11, color: _textMid)),
//                       Text(seg.originName ?? '', style: const TextStyle(fontSize: 10, color: _textMid), maxLines: 2),
//                     ])),
//                     Column(children: [
//                       Text(widget.durFn(seg.duration), style: const TextStyle(fontSize: 10, color: _textMid)),
//                       const Icon(Icons.flight, color: _red, size: 18),
//                     ]),
//                     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//                       Text(seg.destCode ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
//                       Text(widget.timeOnlyFn(seg.arrTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
//                       Text(widget.dateOnlyFn(seg.arrTime), style: const TextStyle(fontSize: 11, color: _textMid)),
//                       Text(seg.destName ?? '', style: const TextStyle(fontSize: 10, color: _textMid), maxLines: 2, textAlign: TextAlign.right),
//                     ])),
//                   ]),
//                   if ((seg.baggage?.isNotEmpty ?? false) || (seg.cabinBaggage?.isNotEmpty ?? false)) ...[
//                     const SizedBox(height: 8),
//                     Wrap(spacing: 8, children: [
//                       if (seg.baggage?.isNotEmpty ?? false) _tkBadge('Check-in: ${seg.baggage!}'),
//                       if (seg.cabinBaggage?.isNotEmpty ?? false) _tkBadge('Cabin: ${seg.cabinBaggage!}'),
//                     ]),
//                   ],
//                 ]),
//               ),
//             ]);
//           }),
//           const SizedBox(height: 8),
//         ],
//
//         // passengers
//         const Text('PASSENGERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(border: Border.all(color: _borderC), borderRadius: BorderRadius.circular(8)),
//           child: Column(children: [
//             // header
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: const BoxDecoration(color: Color(0xFF005EB8), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
//               child: const Row(children: [
//                 Expanded(flex: 3, child: Text('PASSENGER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
//                 Expanded(flex: 3, child: Text('TICKET NO.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
//                 Expanded(flex: 2, child: Text('STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.right)),
//               ]),
//             ),
//             ..._paxRows(),
//           ]),
//         ),
//         const SizedBox(height: 16),
//
//         // fare
//         const Text('FARE SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(8)),
//           child: Column(children: [
//             _fareLine('Base Fare',  '${widget.currency} ${widget.baseFare.toStringAsFixed(2)}'),
//             const SizedBox(height: 8),
//             _fareLine('Taxes & Fees','${widget.currency} ${widget.tax.toStringAsFixed(2)}'),
//             Divider(color: Colors.grey.shade300, height: 20),
//             _fareLine('Total Paid', '${widget.currency} ${widget.total.toStringAsFixed(2)}', large: true),
//           ]),
//         ),
//         const SizedBox(height: 20),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           decoration: BoxDecoration(color: const Color(0xFF005EB8), borderRadius: BorderRadius.circular(8)),
//           child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//             Text('WanderNova Travel Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
//             Text('support@wandernova.com', style: TextStyle(color: Colors.white70, fontSize: 11)),
//           ]),
//         ),
//       ]),
//     );
//   }
//
//   List<Widget> _paxRows() {
//     final rows = <Widget>[];
//     void add(String name, String? ticketNo, String? status) {
//       rows.add(Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
//         child: Row(children: [
//           Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text(name.isEmpty ? 'Passenger' : name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _textDark)),
//           ])),
//           Expanded(flex: 3, child: Text(ticketNo ?? 'Processing…', style: const TextStyle(fontSize: 11, color: _textMid))),
//           Expanded(flex: 2, child: Align(
//             alignment: Alignment.centerRight,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(12)),
//               child: Text(status ?? 'Confirmed', style: const TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w700)),
//             ),
//           )),
//         ]),
//       ));
//     }
//     if (widget.dpax.isNotEmpty) {
//       for (final p in widget.dpax) add(p.fullName.isNotEmpty ? p.fullName : widget.passengerName, p.ticketNumber, p.ticketStatus);
//     } else if (widget.tpax.isNotEmpty) {
//       for (final p in widget.tpax) add('${p.firstName ?? ''} ${p.lastName ?? ''}'.trim(), p.ticketNumber, p.status);
//     } else {
//       add(widget.passengerName, null, 'Confirmed');
//     }
//     return rows;
//   }
//
//   // ── shared invoice helpers ──────────────────────────────────────────────────
//   Widget _tc(String text) => Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//     child: Text(text, style: const TextStyle(fontSize: 11, color: _textDark)),
//   );
//
//   Widget _infoRow(String label, String value) => Padding(
//     padding: const EdgeInsets.only(bottom: 4),
//     child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: _textMid))),
//       Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark))),
//     ]),
//   );
//
//   Widget _fareLine(String label, String value, {bool large = false}) =>
//     Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//       Text(label, style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.w600, color: large ? _textDark : _textMid)),
//       Text(value,  style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.bold, color: large ? _red   : _textDark)),
//     ]);
//
//   Widget _tkBadge(String t) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//     decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _navy.withValues(alpha: 0.2))),
//     child: Text(t, style: const TextStyle(color: _navy, fontSize: 10, fontWeight: FontWeight.w500)),
//   );
// }


// ignore_for_file: avoid_print
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

// ── colour palette ─────────────────────────────────────────────────────────────
const _red      = Color(0xFFE71D36);
const _navyDark = Color(0xFF0A1931);
const _navy     = Color(0xFF1A3461);
const _indigoBg = Color(0xFFF0F4FF);
const _surface  = Colors.white;
const _textDark = Color(0xFF1A1F36);
const _textMid  = Color(0xFF5A6174);
const _green    = Color(0xFF27AE60);
const _greenBg  = Color(0xFFE8F8F0);
const _borderC  = Color(0xFFE4E9F2);

class TicketVoucherScreen extends StatefulWidget {
  final TicketEntity ticket;
  final FlightRouteSegment route;
  final Map<String, dynamic> passengerData;

  const TicketVoucherScreen({
    super.key,
    required this.ticket,
    required this.route,
    required this.passengerData,
  });

  @override
  State<TicketVoucherScreen> createState() => _TicketVoucherScreenState();
}

class _TicketVoucherScreenState extends State<TicketVoucherScreen> {
  BookingDetailsModel? _details;
  bool _loadingDetails = true;
  String? _detailsError;

  // ── getters ───────────────────────────────────────────────────────────────
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

  // The currency the user sees in the app (their preferred currency).
  // TBO fare is in _currency; we convert to preferredCurrency for display.
  String get _preferredCurrency => CurrencyConverter.getPreferredCurrency();

  /// Format a fare amount: convert from TBO fare currency → user's preferred
  /// currency, then format with symbol (e.g. ₹12,345 or $150).
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
        if (!d.isSuccess && d.errorMessage != null) _detailsError = d.errorMessage;
      });
    } catch (e) {
      setState(() { _loadingDetails = false; _detailsError = e.toString(); });
    }
  }

  // ── date helpers ──────────────────────────────────────────────────────────
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
  String _dur(int? m) {
    if (m == null) return '';
    final h = m ~/ 60; final mn = m % 60;
    return h > 0 ? '${h}h ${mn}m' : '${mn}m';
  }
  int _totalDur() => _segs.fold<int>(0, (s, seg) => s + (seg.duration ?? 0));

  // ── PDF ───────────────────────────────────────────────────────────────────
  Future<void> _downloadPdf() async {
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(bytes: bytes, filename: 'WanderNova_${_pnr}.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e'), backgroundColor: _red));
    }
  }

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (_) => _pdfHeader(),
      build: (_) => [
        pw.SizedBox(height: 14),
        _pdfConfirmBanner(),
        pw.SizedBox(height: 18),
        _pdfSectionTitle('FLIGHT DETAILS'),
        pw.SizedBox(height: 8),
        if (_segs.isNotEmpty)
          ..._segs.map(_pdfSegment)
        else
          _pdfFallbackRoute(),
        pw.SizedBox(height: 18),
        _pdfSectionTitle('PASSENGER INFORMATION'),
        pw.SizedBox(height: 8),
        _pdfPassengerTable(),
        pw.SizedBox(height: 18),
        _pdfSectionTitle('FARE SUMMARY'),
        pw.SizedBox(height: 8),
        _pdfFareBox(),
        pw.SizedBox(height: 20),
        _pdfTerms(),
        pw.SizedBox(height: 14),
        _pdfFooter(),
      ],
    ));
    return doc.save();
  }

  pw.Widget _pdfHeader() => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 10),
    decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          pw.Text('WANDER', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.Text('NOVA',   style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
        ]),
        pw.Text('TRAVEL SERVICES', style: pw.TextStyle(fontSize: 7, color: PdfColors.teal700, letterSpacing: 2)),
      ]),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text('E-TICKET', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800, letterSpacing: 2)),
        pw.SizedBox(height: 2),
        pw.Text('Invoice: $_invoiceNo', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
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
        pw.Text('Booking Confirmed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.green800)),
        pw.Text('Your e-ticket has been issued successfully.', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ])),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text('Billed To', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text(_passengerName.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        if (_email.isNotEmpty) pw.Text(_email, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        if (_mobile.isNotEmpty) pw.Text(_mobile, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ]),
    ]),
  );

  pw.Widget _pdfSegment(BookingSegmentDetail seg) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(
            '${seg.airlineName ?? ''} (${seg.airlineCode ?? ''})  ·  Flt ${seg.flightNumber ?? ''}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Text('Class: ${seg.fareClass ?? '—'}  |  Duration: ${_dur(seg.duration)}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ]),
      pw.SizedBox(height: 10),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(seg.originCode ?? '', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(seg.originName ?? '', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 3),
          pw.Text(_timeOnly(seg.depTime), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.Text(_dateOnly(seg.depTime), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          if (seg.originTerminal?.isNotEmpty ?? false)
            pw.Text('Terminal ${seg.originTerminal}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ]),
        pw.Column(children: [
          pw.Text('──── ✈ ────', style: pw.TextStyle(fontSize: 9, color: PdfColors.red700)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(seg.destCode ?? '', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(seg.destName ?? '', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 3),
          pw.Text(_timeOnly(seg.arrTime), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.Text(_dateOnly(seg.arrTime), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          if (seg.destTerminal?.isNotEmpty ?? false)
            pw.Text('Terminal ${seg.destTerminal}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ]),
      ]),
      if ((seg.baggage?.isNotEmpty ?? false) || (seg.cabinBaggage?.isNotEmpty ?? false)) ...[
        pw.SizedBox(height: 6),
        pw.Row(children: [
          if (seg.baggage?.isNotEmpty ?? false)
            _pdfBadge('Check-in: ${seg.baggage!}'),
          if (seg.cabinBaggage?.isNotEmpty ?? false) ...[
            pw.SizedBox(width: 6),
            _pdfBadge('Cabin: ${seg.cabinBaggage!}'),
          ],
        ]),
      ],
    ]),
  );

  pw.Widget _pdfFallbackRoute() => pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5), borderRadius: pw.BorderRadius.circular(6)),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(widget.route.from, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text(widget.route.departureTime, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ]),
      pw.Column(children: [
        pw.Text(widget.route.duration, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        pw.Text('──── ✈ ────', style: pw.TextStyle(fontSize: 9, color: PdfColors.red700)),
      ]),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text(widget.route.to, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text(widget.route.arrivalTime, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ]),
    ]),
  );

  pw.Widget _pdfPassengerTable() {
    // build rows
    List<List<String>> rows;
    if (_dpax.isNotEmpty) {
      rows = _dpax.map((p) => [
        p.fullName.isNotEmpty ? p.fullName : _passengerName,
        _email,
        _mobile,
        // p.ticketNumber ?? 'Processing…',
        p.ticketStatus ?? 'Confirmed',
      ]).toList();
    } else if (_tpax.isNotEmpty) {
      rows = _tpax.map((p) => [
        '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim().isEmpty ? _passengerName : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim(),
        _email,
        _mobile,
        p.ticketNumber ?? 'N/A',
        p.status ?? 'Confirmed',
      ]).toList();
    } else {
      rows = [[_passengerName, _email, _mobile, 'Processing…', 'Confirmed']];
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(2.2),
        4: const pw.FlexColumnWidth(1.3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: ['PASSENGER', 'EMAIL', 'MOBILE', 'TICKET NUMBER', 'STATUS']
              .map((h) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)),
          ))
              .toList(),
        ),
        ...rows.map((row) => pw.TableRow(
          children: row.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: pw.Text(cell.isEmpty ? '—' : cell, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey900)),
          )).toList(),
        )),
      ],
    );
  }

  pw.Widget _pdfFareBox() => pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey50,
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    ),
    child: pw.Column(children: [
      _pdfFareRow('Base Fare',   _fmt(_baseFare)),
      pw.Divider(color: PdfColors.grey200, height: 12),
      _pdfFareRow('Taxes & Fees', _fmt(_tax)),
      pw.Divider(color: PdfColors.grey300, height: 16),
      _pdfFareRow('Total Paid',  _fmt(_total), bold: true),
    ]),
  );

  pw.Widget _pdfFareRow(String l, String v, {bool bold = false}) =>
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(l, style: pw.TextStyle(fontSize: bold ? 12 : 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: bold ? PdfColors.grey900 : PdfColors.grey700)),
        pw.Text(v, style: pw.TextStyle(fontSize: bold ? 12 : 10, fontWeight: pw.FontWeight.bold, color: bold ? PdfColors.red700 : PdfColors.grey900)),
      ]);

  pw.Widget _pdfTerms() => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Divider(color: PdfColors.grey300, height: 1),
    pw.SizedBox(height: 8),
    pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, letterSpacing: 1)),
    pw.SizedBox(height: 4),
    pw.Text(
        'All bookings are subject to our terms and conditions. Cancellations must be made at least 24 hours before departure. '
            'For support, contact support@wandernova.com. This e-ticket is valid for the services listed above.',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, lineSpacing: 2)),
  ]);

  pw.Widget _pdfFooter() => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: pw.BoxDecoration(color: const PdfColor(0, 0.37, 0.72), borderRadius: pw.BorderRadius.circular(6)),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('WanderNova Travel Services', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
      pw.Text('support@wandernova.com',     style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
    ]),
  );

  pw.Widget _pdfSectionTitle(String t) => pw.Text(
      t, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, letterSpacing: 1));

  pw.Widget _pdfBadge(String t) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(10), border: pw.Border.all(color: PdfColors.blue200, width: 0.5)),
    child: pw.Text(t, style: pw.TextStyle(fontSize: 8, color: PdfColors.blue800)),
  );

  // ── invoice bottom sheet ──────────────────────────────────────────────────
  void _showInvoice() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceSheet(
        pnr: _pnr, invoiceNo: _invoiceNo, bookId: _bookId,
        passengerName: _passengerName, email: _email, mobile: _mobile,
        baseFare: _baseFare, tax: _tax, total: _total, currency: _currency,
        segs: _segs, dpax: _dpax, tpax: _tpax,
        route: widget.route,
        onDownload: _downloadPdf,
        dtFn: _dt, dateOnlyFn: _dateOnly, timeOnlyFn: _timeOnly, durFn: _dur, totalDurFn: _totalDur,
        fmtFn: _fmt,
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _indigoBg,
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: _navyDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download PDF',
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(children: [
          SizedBox(height: context.gapSmall),
          _buildBanner(context),
          SizedBox(height: context.gapSmall),
          _buildPNRCard(context),
          SizedBox(height: context.gapSmall),
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
        ]),
      ),
    );
  }

  // ── success banner ─────────────────────────────────────────────────────────
  Widget _buildBanner(BuildContext context) => Container(
    padding: EdgeInsets.all(context.w(16)),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF27AE60), Color(0xFF1E8449)]),
      borderRadius: BorderRadius.circular(context.borderRadius),
      boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: Row(children: [
      const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 40),
      SizedBox(width: context.gapSmall),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Booking Confirmed!', style: TextStyle(color: Colors.white, fontSize: context.titleLarge, fontWeight: FontWeight.bold)),
        SizedBox(height: 2),
        Text('Your e-ticket has been issued.', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: context.bodySmall)),
      ])),
      Icon(Icons.flight_takeoff_rounded, color: Colors.white.withValues(alpha: 0.45), size: 40),
    ]),
  );

  // ── PNR card ───────────────────────────────────────────────────────────────
  Widget _buildPNRCard(BuildContext context) => _card(context, child: Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('PNR / Booking Reference', style: TextStyle(fontSize: context.bodySmall, color: _textMid, fontWeight: FontWeight.w600)),
      GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: _pnr));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PNR copied')));
        },
        child: Row(children: [
          const Icon(Icons.copy_rounded, size: 14, color: _navy),
          const SizedBox(width: 3),
          Text('Copy', style: TextStyle(color: _navy, fontSize: context.labelSmall, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]),
    SizedBox(height: context.gapSmall),
    Text(_pnr, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5, color: _red)),
    SizedBox(height: 2),
    Text('Booking ID: $_bookId  ·  Invoice: $_invoiceNo',
        style: TextStyle(color: _textMid, fontSize: context.labelSmall)),
    if (_loadingDetails) ...[
      SizedBox(height: context.gapSmall),
      const LinearProgressIndicator(backgroundColor: _indigoBg, color: _navy, minHeight: 2),
      SizedBox(height: 2),
      Text('Loading booking details…', style: TextStyle(color: _textMid, fontSize: context.labelSmall)),
    ],
  ]));

  // ── flight card ─────────────────────────────────────────────────────────────
  Widget _buildFlightCard(BuildContext context) => _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeader(context, 'FLIGHT DETAILS'),
    SizedBox(height: context.gapSmall),
    if (_segs.isNotEmpty)
      ..._segs.asMap().entries.map((e) {
        final i = e.key; final seg = e.value;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (i > 0) _stopoverDivider(context, seg.originCode ?? ''),
          _segRow(context, seg),
          SizedBox(height: context.gapSmall),
          if ((seg.baggage?.isNotEmpty ?? false) || (seg.cabinBaggage?.isNotEmpty ?? false))
            Wrap(spacing: 8, children: [
              if (seg.baggage?.isNotEmpty ?? false) _badge('Check-in: ${seg.baggage!}'),
              if (seg.cabinBaggage?.isNotEmpty ?? false) _badge('Cabin: ${seg.cabinBaggage!}'),
            ]),
          SizedBox(height: context.gapSmall),
        ]);
      })
    else
      _fallbackRoute(context),
  ]));

  Widget _segRow(BuildContext context, BookingSegmentDetail seg) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(seg.originCode ?? '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark)),
      Text(_timeOnly(seg.depTime), style: TextStyle(fontSize: context.bodyLarge, fontWeight: FontWeight.w600, color: _textDark)),
      Text(_dateOnly(seg.depTime), style: TextStyle(fontSize: context.bodySmall, color: _textMid)),
      if (seg.originName?.isNotEmpty ?? false)
        Text(seg.originName!, style: TextStyle(fontSize: context.labelSmall, color: _textMid), maxLines: 2, overflow: TextOverflow.ellipsis),
      if (seg.originTerminal?.isNotEmpty ?? false)
        _terminalBadge('T${seg.originTerminal}'),
    ])),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        Text(_dur(seg.duration), style: TextStyle(fontSize: context.labelSmall, color: _textMid)),
        const SizedBox(height: 2),
        const Icon(Icons.flight, color: _red, size: 20),
        const SizedBox(height: 2),
        if ((seg.airlineCode?.isNotEmpty ?? false))
          Text('${seg.airlineCode} ${seg.flightNumber ?? ''}',
              style: TextStyle(fontSize: context.labelSmall, color: _textMid)),
      ]),
    ),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(seg.destCode ?? '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark)),
      Text(_timeOnly(seg.arrTime), style: TextStyle(fontSize: context.bodyLarge, fontWeight: FontWeight.w600, color: _textDark)),
      Text(_dateOnly(seg.arrTime), style: TextStyle(fontSize: context.bodySmall, color: _textMid)),
      if (seg.destName?.isNotEmpty ?? false)
        Text(seg.destName!, style: TextStyle(fontSize: context.labelSmall, color: _textMid), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
      if (seg.destTerminal?.isNotEmpty ?? false)
        _terminalBadge('T${seg.destTerminal}'),
    ])),
  ]);

  Widget _stopoverDivider(BuildContext context, String code) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.gapSmall),
    child: Row(children: [
      Expanded(child: Divider(color: Colors.grey.shade200)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('Stopover · $code', style: TextStyle(color: _textMid, fontSize: context.labelSmall)),
      ),
      Expanded(child: Divider(color: Colors.grey.shade200)),
    ]),
  );

  Widget _fallbackRoute(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.route.from, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
      Text(widget.route.departureTime, style: TextStyle(color: _textMid, fontSize: context.bodySmall)),
    ])),
    Column(children: [
      Text(widget.route.duration, style: TextStyle(color: _textMid, fontSize: context.labelSmall)),
      const Icon(Icons.flight, color: _red, size: 20),
    ]),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(widget.route.to, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
      Text(widget.route.arrivalTime, style: TextStyle(color: _textMid, fontSize: context.bodySmall)),
    ])),
  ]);

  // ── passenger card ─────────────────────────────────────────────────────────
  Widget _buildPassengerCard(BuildContext context) => _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeader(context, 'PASSENGER INFORMATION'),
    SizedBox(height: context.gapSmall),
    // Contact info row (from form data)
    if (_email.isNotEmpty || _mobile.isNotEmpty)
      Container(
        margin: EdgeInsets.only(bottom: context.gapSmall),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_email.isNotEmpty) ...[
              Text('Email', style: TextStyle(fontSize: context.labelSmall, color: _textMid, fontWeight: FontWeight.w500)),
              Text(_email, style: TextStyle(fontSize: context.bodySmall, color: _textDark, fontWeight: FontWeight.w600)),
            ],
          ])),
          if (_mobile.isNotEmpty)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Mobile', style: TextStyle(fontSize: context.labelSmall, color: _textMid, fontWeight: FontWeight.w500)),
              Text(_mobile, style: TextStyle(fontSize: context.bodySmall, color: _textDark, fontWeight: FontWeight.w600)),
            ]),
        ]),
      ),
    // Passenger rows
    if (_dpax.isNotEmpty)
      ..._dpax.map((p) => _paxRow(context, p.fullName.isNotEmpty ? p.fullName : _passengerName, p.ticketNumber, p.ticketStatus))
    else if (_tpax.isNotEmpty)
      ..._tpax.map((p) {
        final n = '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();
        return _paxRow(context, n.isEmpty ? _passengerName : n, p.ticketNumber, p.status);
      })
    else
      _paxRow(context, _passengerName, null, 'Confirmed'),
  ]));

  Widget _paxRow(BuildContext context, String name, String? ticketNo, String? status) =>
      Padding(
        padding: EdgeInsets.only(bottom: context.gapSmall),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty ? 'Passenger' : name,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: context.bodyMedium, color: _textDark)),
            SizedBox(height: 2),
            Text('Ticket: ${ticketNo ?? 'Processing…'}',
                style: TextStyle(color: _textMid, fontSize: context.bodySmall)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _green.withValues(alpha: 0.3))),
            child: Text(status ?? 'Confirmed', style: TextStyle(color: _green, fontSize: context.labelSmall, fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  // ── fare card ──────────────────────────────────────────────────────────────
  Widget _buildFareCard(BuildContext context) => _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeader(context, 'FARE SUMMARY'),
    SizedBox(height: context.gapSmall),
    _fareRow(context, 'Base Fare', _fmt(_baseFare)),
    SizedBox(height: context.gapSmall),
    _fareRow(context, 'Taxes & Fees', _fmt(_tax)),
    Divider(height: context.gapLarge, color: _borderC),
    _fareRow(context, 'Total Paid', _fmt(_total), isTotal: true),
  ]));

  Widget _fareRow(BuildContext context, String l, String v, {bool isTotal = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: TextStyle(fontSize: isTotal ? context.bodyLarge : context.bodyMedium, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? _textDark : _textMid)),
        Text(v, style: TextStyle(fontSize: isTotal ? context.bodyLarge : context.bodyMedium, fontWeight: FontWeight.bold, color: isTotal ? _red : _textDark)),
      ]);

  // ── error note ─────────────────────────────────────────────────────────────
  Widget _buildErrorNote(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
    child: Row(children: [
      Expanded(child: Text('Could not refresh booking details. Showing data from ticket issuance.',
          style: TextStyle(color: Colors.orange.shade800, fontSize: context.bodySmall))),
      TextButton(onPressed: _fetchDetails, child: const Text('Retry')),
    ]),
  );

  // ── action buttons ──────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context) => Column(children: [
    Row(children: [
      Expanded(child: _btn(context, label: 'Download PDF', icon: Icons.download_rounded, onTap: _downloadPdf, primary: true)),
      SizedBox(width: context.gapSmall),
      Expanded(child: _btn(context, label: 'View Invoice', icon: Icons.receipt_outlined, onTap: _showInvoice, primary: false)),
    ]),
    SizedBox(height: context.gapSmall),
    SizedBox(
      width: double.infinity,
      height: context.buttonHeight + 4,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: _navy, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text('Back to Home', style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: context.bodyMedium)),
      ),
    ),
  ]);

  Widget _btn(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap, required bool primary}) =>
      SizedBox(
        height: context.buttonHeight + 4,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: primary ? Colors.white : _navy, size: 16),
          label: Text(label, style: TextStyle(color: primary ? Colors.white : _navy, fontWeight: FontWeight.bold, fontSize: context.bodySmall)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary ? _red : _indigoBg,
            elevation: primary ? 2 : 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  // ── shared helpers ─────────────────────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, String title) =>
      Text(title, style: TextStyle(fontSize: context.labelSmall, fontWeight: FontWeight.bold, color: _textMid, letterSpacing: 1));

  Widget _terminalBadge(String t) => Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(4), border: Border.all(color: _navy.withValues(alpha: 0.2))),
    child: Text(t, style: TextStyle(fontSize: 9, color: _navy, fontWeight: FontWeight.w600)),
  );

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _navy.withValues(alpha: 0.2))),
    child: Text(t, style: TextStyle(color: _navy, fontSize: 10, fontWeight: FontWeight.w500)),
  );

  Widget _card(BuildContext context, {required Widget child}) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(context.w(16)),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(context.borderRadius),
      border: Border.all(color: _borderC),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: child,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Invoice Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════
class _InvoiceSheet extends StatefulWidget {
  final String pnr, invoiceNo, bookId;
  final String passengerName, email, mobile;
  final double baseFare, tax, total;
  final String currency;
  final List<BookingSegmentDetail> segs;
  final List<BookingPassengerDetail> dpax;
  final List<TicketPassengerEntity> tpax;
  final FlightRouteSegment route;
  final VoidCallback onDownload;
  final String Function(String?) dtFn, dateOnlyFn, timeOnlyFn;
  final String Function(int?) durFn;
  final int Function() totalDurFn;
  final String Function(double) fmtFn;

  const _InvoiceSheet({
    required this.pnr, required this.invoiceNo, required this.bookId,
    required this.passengerName, required this.email, required this.mobile,
    required this.baseFare, required this.tax, required this.total, required this.currency,
    required this.segs, required this.dpax, required this.tpax, required this.route,
    required this.onDownload,
    required this.dtFn, required this.dateOnlyFn, required this.timeOnlyFn,
    required this.durFn, required this.totalDurFn,
    required this.fmtFn,
  });

  @override
  State<_InvoiceSheet> createState() => _InvoiceSheetState();
}

class _InvoiceSheetState extends State<_InvoiceSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(color: _surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          // drag handle
          Center(child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
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
                tabs: const [Tab(text: 'Invoice'), Tab(text: 'E-Ticket')],
              ),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); widget.onDownload(); },
                  icon: const Icon(Icons.download_rounded, size: 15, color: Colors.white),
                  label: const Text('Download', style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
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
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 20), SizedBox(width: 220, child: right)])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 16), right]);
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
    final fromCode = widget.segs.isNotEmpty ? (widget.segs.first.originCode ?? widget.route.from) : widget.route.from;
    final toCode   = widget.segs.isNotEmpty ? (widget.segs.last.destCode   ?? widget.route.to)   : widget.route.to;
    final paxNames = widget.dpax.isNotEmpty
        ? widget.dpax.map((p) => p.fullName.isNotEmpty ? p.fullName : widget.passengerName).join(', ')
        : widget.tpax.isNotEmpty
        ? widget.tpax.map((p) => '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim()).join(', ')
        : widget.passengerName;
    final totalDur = widget.totalDurFn();
    final durStr = totalDur > 0 ? widget.durFn(totalDur) : widget.route.duration;
    final totalStr = widget.fmtFn(widget.total);

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

  Widget _invFareSummary() => Column(children: [
    _fareLine('BASE FARE',  widget.fmtFn(widget.baseFare)),
    const SizedBox(height: 8),
    _fareLine('TAX & FEES', widget.fmtFn(widget.tax)),
    const SizedBox(height: 8),
    Divider(color: Colors.grey.shade300),
    const SizedBox(height: 4),
    _fareLine('TOTAL', widget.fmtFn(widget.total), large: true),
  ]);

  // ── E-TICKET TAB ─────────────────────────────────────────────────────────────
  Widget _buildETicketTab(ScrollController sc) {
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
          decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _green.withValues(alpha: 0.3))),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded, color: _green, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your booking is confirmed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _green)),
              Text('${widget.passengerName.toUpperCase()}  ·  ${widget.email}', style: const TextStyle(color: _textMid, fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('PNR', style: TextStyle(fontSize: 9, color: _textMid)),
              Text(widget.pnr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy, letterSpacing: 3)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // segments
        if (widget.segs.isNotEmpty) ...[
          const Text('FLIGHT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
          const SizedBox(height: 8),
          ...widget.segs.asMap().entries.map((e) {
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
                      Text(widget.timeOnlyFn(seg.depTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                      Text(widget.dateOnlyFn(seg.depTime), style: const TextStyle(fontSize: 11, color: _textMid)),
                      Text(seg.originName ?? '', style: const TextStyle(fontSize: 10, color: _textMid), maxLines: 2),
                    ])),
                    Column(children: [
                      Text(widget.durFn(seg.duration), style: const TextStyle(fontSize: 10, color: _textMid)),
                      const Icon(Icons.flight, color: _red, size: 18),
                    ]),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(seg.destCode ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
                      Text(widget.timeOnlyFn(seg.arrTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                      Text(widget.dateOnlyFn(seg.arrTime), style: const TextStyle(fontSize: 11, color: _textMid)),
                      Text(seg.destName ?? '', style: const TextStyle(fontSize: 10, color: _textMid), maxLines: 2, textAlign: TextAlign.right),
                    ])),
                  ]),
                  if ((seg.baggage?.isNotEmpty ?? false) || (seg.cabinBaggage?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      if (seg.baggage?.isNotEmpty ?? false) _tkBadge('Check-in: ${seg.baggage!}'),
                      if (seg.cabinBaggage?.isNotEmpty ?? false) _tkBadge('Cabin: ${seg.cabinBaggage!}'),
                    ]),
                  ],
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
            // header
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

        // fare
        const Text('FARE SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: _textMid)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _indigoBg, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            _fareLine('Base Fare',  widget.fmtFn(widget.baseFare)),
            const SizedBox(height: 8),
            _fareLine('Taxes & Fees', widget.fmtFn(widget.tax)),
            Divider(color: Colors.grey.shade300, height: 20),
            _fareLine('Total Paid', widget.fmtFn(widget.total), large: true),
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
    if (widget.dpax.isNotEmpty) {
      for (final p in widget.dpax) add(p.fullName.isNotEmpty ? p.fullName : widget.passengerName, p.ticketNumber, p.ticketStatus);
    } else if (widget.tpax.isNotEmpty) {
      for (final p in widget.tpax) add('${p.firstName ?? ''} ${p.lastName ?? ''}'.trim(), p.ticketNumber, p.status);
    } else {
      add(widget.passengerName, null, 'Confirmed');
    }
    return rows;
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

  Widget _fareLine(String label, String value, {bool large = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.w600, color: large ? _textDark : _textMid)),
        Text(value,  style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.bold, color: large ? _red   : _textDark)),
      ]);

  Widget _tkBadge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _navy.withValues(alpha: 0.2))),
    child: Text(t, style: const TextStyle(color: _navy, fontSize: 10, fontWeight: FontWeight.w500)),
  );
}