import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/entities/FlightBookEntity.dart';

class AkTicketLeg {
  final String? label;
  final String airline;
  final String flightNo;
  final String from;
  final String to;
  final String departureTime;
  final String arrivalTime;
  final String? departureDate;
  final String duration;

  const AkTicketLeg({
    this.label,
    required this.airline,
    required this.flightNo,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.arrivalTime,
    this.departureDate,
    required this.duration,
  });
}

class FlightPdfBuilder {
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _cardBg = Color(0xFFE8EDF3);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF555555);
  static const _textLight = Color(0xFF888888);
  static const _divider = Color(0xFFD0D5DD);

  static PdfColor _c(Color color) => PdfColor.fromInt(color.value);

  static PdfColor _tint(Color base, double opacity) {
    final c = _c(base);
    return PdfColor(1 - (1 - c.red) * opacity, 1 - (1 - c.green) * opacity, 1 - (1 - c.blue) * opacity);
  }

  static bool _isConfirmed(FlightBookEntity booking) => booking.pnr.isNotEmpty && booking.pnr != 'null';

  // The base PDF font (Helvetica) has no Unicode support at all — any
  // character outside printable ASCII (bullets, em dashes, arrows, smart
  // quotes, accented letters) renders as a missing-glyph box or nothing.
  // Upstream data (e.g. flightNo formatted as "EK • 514") isn't
  // guaranteed to be plain ASCII, so every dynamic string is normalized
  // through here before it reaches a pw.Text.
  static const Map<String, String> _asciiReplacements = {
    '•': '-', // •
    '·': '-', // ·
    '–': '-', // – en dash
    '—': '-', // — em dash
    '‘': "'", '’': "'", // ‘ ’
    '“': '"', '”': '"', // “ ”
    '»': '>>', '«': '<<',
    '→': '->', '⇌': '<->', // → ⇌
  };

  static String _ascii(String s) {
    var out = s;
    _asciiReplacements.forEach((from, to) => out = out.replaceAll(from, to));
    return out.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  static AkTicketLeg _sanitizeLeg(AkTicketLeg leg) => AkTicketLeg(
        label: leg.label == null ? null : _ascii(leg.label!),
        airline: _ascii(leg.airline),
        flightNo: _ascii(leg.flightNo),
        from: _ascii(leg.from),
        to: _ascii(leg.to),
        departureTime: _ascii(leg.departureTime),
        arrivalTime: _ascii(leg.arrivalTime),
        departureDate: leg.departureDate == null ? null : _ascii(leg.departureDate!),
        duration: _ascii(leg.duration),
      );

  // =========================================================================
  // AKBAR FLOW
  // =========================================================================
  static pw.Document buildAkTicket({
    required List<AkTicketLeg> legs,
    required List<String> pnrs,
    required String passengerName,
    required String email,
    required String phone,
    String? transactionId,
    required String displayAmount,
    String? ticketNumber,
    pw.ImageProvider? logo,
    int travellerCount = 1,
  }) {
    final pnr = pnrs.isNotEmpty ? pnrs.join(', ') : 'N/A';
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
      header: (context) => _pageHeader(ticketNumber, logo),
      footer: _footer,
      build: (context) => _page1Content(
        passengerName: _ascii(passengerName),
        pnr: _ascii(pnr),
        legs: legs.map(_sanitizeLeg).toList(),
        displayAmount: _ascii(displayAmount),
        transactionId: transactionId == null ? null : _ascii(transactionId),
        email: _ascii(email),
        phone: _ascii(phone),
        travellerCount: travellerCount,
      ),
    ));
    return pdf;
  }

  // =========================================================================
  // MYBOOKINGS FLOW — 4-page exact match
  // =========================================================================
  static pw.Document buildTicket({required FlightBookEntity booking, pw.ImageProvider? logo}) {
    final ticketNumber = booking.passengersData.isNotEmpty ? booking.passengersData.first.ticketNumber : 'N/A';
    final passengerName = _allPassengerNames(booking);
    final lead = booking.passengersData.isNotEmpty
        ? booking.passengersData.firstWhere((p) => p.isLeadPax, orElse: () => booking.passengersData.first)
        : null;
    final email = lead?.email ?? 'N/A';
    final phone = lead?.phone ?? 'N/A';

    final legs = _buildLegsForBooking(booking).map(_sanitizeLeg).toList();

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
      header: (context) => _pageHeader(ticketNumber, logo),
      footer: _footer,
      build: (context) => [
        ..._page1Content(
          passengerName: _ascii(passengerName),
          pnr: _ascii(booking.pnr),
          legs: legs,
          displayAmount: _ascii('${booking.currency} ${booking.totalAmount}'),
          transactionId: booking.tboBookingId.isNotEmpty ? _ascii(booking.tboBookingId) : (booking.bookingToken.isNotEmpty ? _ascii(booking.bookingToken) : null),
          email: _ascii(email),
          phone: _ascii(phone),
          flightClass: _ascii(booking.flightClass),
          travellerCount: booking.passengers > 0 ? booking.passengers : (booking.passengersData.isNotEmpty ? booking.passengersData.length : 1),
        ),
        // Page 2 — Travel Information
        ..._travelInfoPage(legs: legs, flightClass: _ascii(booking.flightClass), isConfirmed: _isConfirmed(booking)),
        // Page 3 — Fare + Policies
        ..._fareAndPolicyPage(booking: booking),
        // Page 4 — Inflight Entertainment
        ..._inflightEntertainmentPage(),
      ],
    ));
    return pdf;
  }

  // =========================================================================
  // INVOICE
  // =========================================================================
  static pw.Document buildInvoice({required FlightBookEntity booking, pw.ImageProvider? logo}) {
    final isConfirmed = _isConfirmed(booking);
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
      header: (context) => _pageHeader('INVOICE ${booking.pnr}', logo),
      footer: _footer,
      build: (context) => [
        pw.Text('INVOICE', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
        pw.SizedBox(height: 16),
        pw.Text(_primaryPassengerName(booking), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _pdfParagraph('Date: ${_todayDate()}\nPNR: ${booking.pnr}\nTBO Booking ID: ${booking.tboBookingId}'),
        pw.SizedBox(height: 12),
        _buildInvoiceTable(booking, isConfirmed),
        pw.SizedBox(height: 16),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _billingRow('Billed by:', _primaryPassengerName(booking)),
            _billingRow('Issued by:', 'WANDER NOVA'),
            _billingRow('Billing Cycle:', 'Immediate'),
            _billingRow('Payment Basis:', 'Invoice Date'),
            _billingRow('Invoice Status:', isConfirmed ? 'CONFIRMED' : 'PROCESSING'),
            if (booking.paidVia != null && booking.paidVia!.isNotEmpty) _billingRow('Payment Method:', booking.paidVia!),
          ])),
          pw.SizedBox(width: 20),
          pw.Expanded(child: pw.Column(children: [
            _amountRow('BASE FARE', '${booking.currency} ${_baseFare(booking)}'),
            _amountRow('TAX & FEES', '${booking.currency} ${_tax(booking)}'),
            pw.Divider(color: _c(_divider)),
            pw.SizedBox(height: 8),
            _amountRow('TOTAL', '${booking.currency} ${booking.totalAmount}', big: true),
          ])),
        ]),
        pw.SizedBox(height: 16),
        pw.Divider(color: _c(_divider)),
        pw.SizedBox(height: 16),
        pw.Text('TERMS AND CONDITIONS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
        pw.SizedBox(height: 8),
        _pdfParagraph('Payment is due within 30 days of invoice date. Late payments may incur additional charges. All bookings are subject to our terms and conditions. Cancellations must be made at least 24 hours before departure for a full refund.'),
      ],
    ));
    return pdf;
  }

  // =========================================================================
  // PAGE 1 CONTENT
  // =========================================================================
  static List<pw.Widget> _page1Content({
    required String passengerName,
    required String pnr,
    required List<AkTicketLeg> legs,
    required String displayAmount,
    String? transactionId,
    required String email,
    required String phone,
    String flightClass = 'Economy',
    int travellerCount = 1,
  }) {
    return [
      // Title
      pw.Center(child: pw.Text('Ticket & Receipt', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: _c(_blue), fontStyle: pw.FontStyle.italic))),
      pw.SizedBox(height: 18),

      // Passenger info table
      pw.Table(
        border: pw.TableBorder.all(color: _c(_blue), width: 1),
        columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1), 3: pw.FlexColumnWidth(1)},
        children: [
          pw.TableRow(decoration: pw.BoxDecoration(color: _c(_blue)), children: [
            _headerCell('Passenger name'),
            _headerCell('WNT number'),
            _headerCell('Issued by / Date'),
            _headerCell('Membership Tier'),
          ]),
          pw.TableRow(children: [
            _dataCell(passengerName),
            _dataCell('N/A'),
            _dataCell('WANDER NOVA / ${_todayDate()}'),
            _dataCell('Standard'),
          ]),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Total Travellers: $travellerCount',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _c(_navy)),
      ),
      pw.SizedBox(height: 18),

      // Booking reference banner
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: pw.BoxDecoration(color: _c(_blue), borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Row(children: [
          pw.Text('Your booking reference: ', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.Text(pnr, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        ]),
      ),
      pw.SizedBox(height: 14),

      // Two-column notice text
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _pdfParagraph('Your ticket is stored in our booking system. This receipt is your record of your ticket and is part of your conditions of carriage. For more information you can read the notices and conditions of carriage.'),
          pw.SizedBox(height: 6),
          _pdfParagraph('You might need to show this receipt to enter the airport or to prove your return or onwards travel to immigration.'),
        ])),
        pw.SizedBox(width: 14),
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _pdfParagraph('Check with your departure airport for restrictions on the carriage of liquids, aerosols and gels in hand baggage and check your visa requirements.'),
          pw.SizedBox(height: 6),
          _pdfParagraph('Please check our Dangerous Goods information to find out what you can and can\'t bring on board. Some substances and certain items are restricted, like portable electronic devices, spare batteries or smart bags.'),
        ])),
      ]),
      pw.SizedBox(height: 18),

      // Check-in timeline banner
      _checkInTimeline(),
      pw.SizedBox(height: 10),

      // Check-in timeline descriptions
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _timelineColumn('Check in at the airport. At most airports you need to arrive 3 hours before departure, but it can be up to 4 hours to complete all the travel requirements. Please check the best time to arrive for your journey below.'),
        pw.SizedBox(width: 8),
        _timelineColumn('90 minutes before take-off go through passport control.'),
        pw.SizedBox(width: 8),
        _timelineColumn('60 minutes before take-off be ready at the gate (Premium Economy, Economy Class).'),
        pw.SizedBox(width: 8),
        _timelineColumn('45 minutes before take-off be ready at the gate (First Class, Business Class).'),
      ]),
      pw.SizedBox(height: 18),

      // Travel information heading
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: pw.BoxDecoration(color: _c(_cardBg), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text('Your travel information', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _c(_navy)))),
          pw.Text('All times shown are local for each city', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
        ]),
      ),
      pw.SizedBox(height: 8),

      // Flight legs
      for (int i = 0; i < legs.length; i++) ...[
        _legCard(leg: legs[i], index: i + 1, total: legs.length, flightClass: flightClass),
        pw.SizedBox(height: 12),
      ],

      // Fare information
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(color: _c(_cardBg), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('FARE INFORMATION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          pw.SizedBox(height: 8),
          pw.Table(border: pw.TableBorder.all(color: _c(_divider), width: 0.5), columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1.5), 3: pw.FlexColumnWidth(1), 4: pw.FlexColumnWidth(1)}, children: [
            pw.TableRow(decoration: pw.BoxDecoration(color: _c(_blue)), children: [
              _headerCell('Fare'), _headerCell('Equivalent fare'), _headerCell('Taxes / Fees / Charges (TFC)'), _headerCell('Total fare (Incl. TFC)'), _headerCell('Form of payment'),
            ]),
            pw.TableRow(children: [
              _dataCell(displayAmount), _dataCell('-'), _dataCell('TFC included'), _dataCell(displayAmount, bold: true), _dataCell(transactionId != null && transactionId.isNotEmpty ? 'RAZORPAY' : 'CREDIT CARD'),
            ]),
          ]),
          pw.SizedBox(height: 8),
          pw.Text('Fare calculation', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          _pdfParagraph('DXB EK DEL300.82XLXRFAE1/EOL4 EK DXB99.36LLXEPAE1/EOL4 NUC400.18END ROE3.673271'),
          pw.SizedBox(height: 6),
          pw.Text('Additional information', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          _pdfParagraph('FQEK215274651 NON-END/FLEX PLUS/NON-END/SAVER/REWARD UPGDS ALLOWED'),
        ]),
      ),
      pw.SizedBox(height: 14),

      // Hazardous materials
      _sectionTitle('HAZARDOUS MATERIALS AND SUBSTANCE CONTROL POLICY'),
      _pdfParagraph('The carriage of certain hazardous materials like aerosols, fireworks and inflammable liquids aboard the aircraft is forbidden. Personal motorised vehicles such as hoverboards, mini-Segways and smart or self-balancing wheels, are also forbidden on our flights as they contain large lithium batteries. For safety reasons, we can\'t accept these as part of checked-in baggage or as hand luggage. If you do not understand this restriction, further information may be obtained from your airline.'),
      pw.SizedBox(height: 6),
      _pdfParagraph('The United Arab Emirates (UAE) has a very strict, zero-tolerance, anti-drugs policy. All airports within the UAE conduct thorough searches using highly sensitive equipment. Possession of any amounts of illegal drugs by travellers entering or transiting the UAE will be subject to punishment.'),
      pw.SizedBox(height: 10),

      // Cabin baggage
      _sectionTitle('WNT CABIN BAGGAGE ALLOWANCES'),
      pw.Text('Economy Class:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
      _pdfParagraph('One piece of carry-on baggage is permitted with maximum dimensions: 55 x 38 x 22cm (22 x 15 x 8 inches) and maximum weight: 7kg (15lb). Note: If you\'re boarding in India, your carry-on baggage may not exceed 115cm or 45.3 inches (length + width + height). If your itinerary originates from Brazil, you\'re allowed a carry-on weighing 10kg (22lb).'),
      pw.SizedBox(height: 4),
      pw.Text('Premium Economy:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
      _pdfParagraph('One piece of carry-on baggage is permitted with maximum dimensions: 55 x 38 x 22cm (22 x 15 x 8 inches) and maximum weight: 10kg (22lb). Note: If you\'re boarding in India, your carry-on baggage may not exceed 115cm or 45.3 inches (length + width + height).'),
      pw.SizedBox(height: 4),
      pw.Text('First Class and Business Class:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
      _pdfParagraph('Two pieces of carry-on baggage permitted: one briefcase plus either one handbag or one garment bag. The briefcase may not exceed 45 x 35 x 20cm (18 x 14 x 8 inches); the handbag may not exceed 55 x 38 x 22cm (22 x 15 x 8 inches); the garment bag can be no more than 20cm (8 inches) thick when folded. The weight of each piece must not exceed 7kg (15lb). The total combined weight of both pieces may not be more than 14kg (30lb).'),
      pw.SizedBox(height: 4),
      _pdfParagraph('Infants in all cabin classes are permitted one checked-in bag that may not exceed 55 x 38 x 22 cm (22 x 15 x 8 inches) in size and 23kg (50lb) where the piece concept applies, or 10kg (22lb) where the weight concept applies. In addition, customers travelling with infants (and without a child seat) are permitted to bring one carry-cot or one fully collapsible stroller into the cabin if there is room. If there is no space for these items in the cabin, they will have to be checked. However, if checked, they will not count against your baggage allowance.'),
      pw.SizedBox(height: 10),

      // Checked baggage
      _sectionTitle('WNT CHECKED BAGGAGE NOTIFICATION'),
      _pdfParagraph('Checked baggage allowances vary by fare type and class of travel. Check your baggage allowance, however please note that any individual item weighing more than 32kg cannot be accepted, for health and safety reasons.'),
    ];
  }

  // =========================================================================
  // PAGE 2 — Travel Information
  // =========================================================================
  static List<pw.Widget> _travelInfoPage({
    required List<AkTicketLeg> legs,
    String flightClass = 'Economy',
    required bool isConfirmed,
  }) {
    return [
      pw.SizedBox(height: 8),
      for (int i = 0; i < legs.length; i++) ...[
        _largeTravelCard(leg: legs[i], index: i + 1, total: legs.length, flightClass: flightClass, isConfirmed: isConfirmed),
        pw.SizedBox(height: 16),
      ],
    ];
  }

  // =========================================================================
  // PAGE 3 — Fare + Policies
  // =========================================================================
  static List<pw.Widget> _fareAndPolicyPage({required FlightBookEntity booking}) {
    return [
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(color: _c(_cardBg), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('FARE INFORMATION', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          pw.SizedBox(height: 10),
          pw.Table(border: pw.TableBorder.all(color: _c(_divider), width: 0.5), columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1.5), 3: pw.FlexColumnWidth(1), 4: pw.FlexColumnWidth(1)}, children: [
            pw.TableRow(decoration: pw.BoxDecoration(color: _c(_blue)), children: [
              _headerCell('Fare'), _headerCell('Equivalent fare'), _headerCell('Taxes / Fees / Charges (TFC)'), _headerCell('Total fare (Incl. TFC)'), _headerCell('Form of payment'),
            ]),
            pw.TableRow(children: [
              _dataCell('${booking.currency} ${_baseFare(booking)}'),
              _dataCell('-'),
              _dataCell('INR1178-F6 INR130-TP INR1964-AE INR261-ZR INR1571-IN INR9954-YQ INR1571-P2'),
              _dataCell('${booking.currency} ${booking.totalAmount}', bold: true),
              _dataCell(booking.paidVia?.isNotEmpty == true ? booking.paidVia!.toUpperCase() : 'CREDIT CARD'),
            ]),
          ]),
          pw.SizedBox(height: 10),
          pw.Text('Fare calculation', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          _pdfParagraph('DXB EK DEL300.82XLXRFAE1/EOL4 EK DXB99.36LLXEPAE1/EOL4 NUC400.18END ROE3.673271'),
          pw.SizedBox(height: 8),
          pw.Text('Additional information', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          _pdfParagraph('FQEK215274651 NON-END/FLEX PLUS/NON-END/SAVER/REWARD UPGDS ALLOWED'),
        ]),
      ),
      pw.SizedBox(height: 16),
      _sectionTitle('HAZARDOUS MATERIALS AND SUBSTANCE CONTROL POLICY'),
      _pdfParagraph('The carriage of certain hazardous materials like aerosols, fireworks and inflammable liquids aboard the aircraft is forbidden. Personal motorised vehicles such as hoverboards, mini-Segways and smart or self-balancing wheels, are also forbidden on our flights as they contain large lithium batteries. For safety reasons, we can\'t accept these as part of checked-in baggage or as hand luggage. If you do not understand this restriction, further information may be obtained from your airline.'),
      pw.SizedBox(height: 6),
      _pdfParagraph('The United Arab Emirates (UAE) has a very strict, zero-tolerance, anti-drugs policy. All airports within the UAE conduct thorough searches using highly sensitive equipment. Possession of any amounts of illegal drugs by travellers entering or transiting the UAE will be subject to punishment.'),
      pw.SizedBox(height: 12),
      _sectionTitle('WNT CABIN BAGGAGE ALLOWANCES'),
      pw.Text('Economy Class:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
      _pdfParagraph('One piece of carry-on baggage is permitted with maximum dimensions: 55 x 38 x 22cm (22 x 15 x 8 inches) and maximum weight: 7kg (15lb). Note: If you\'re boarding in India, your carry-on baggage may not exceed 115cm or 45.3 inches (length + width + height). If your itinerary originates from Brazil, you\'re allowed a carry-on weighing 10kg (22lb).'),
      pw.SizedBox(height: 4),
      pw.Text('Premium Economy:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
      _pdfParagraph('One piece of carry-on baggage is permitted with maximum dimensions: 55 x 38 x 22cm (22 x 15 x 8 inches) and maximum weight: 10kg (22lb). Note: If you\'re boarding in India, your carry-on baggage may not exceed 115cm or 45.3 inches (length + width + height).'),
      pw.SizedBox(height: 4),
      pw.Text('First Class and Business Class:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
      _pdfParagraph('Two pieces of carry-on baggage permitted: one briefcase plus either one handbag or one garment bag. The briefcase may not exceed 45 x 35 x 20cm (18 x 14 x 8 inches); the handbag may not exceed 55 x 38 x 22cm (22 x 15 x 8 inches); the garment bag can be no more than 20cm (8 inches) thick when folded. The weight of each piece must not exceed 7kg (15lb). The total combined weight of both pieces may not be more than 14kg (30lb).'),
      pw.SizedBox(height: 4),
      _pdfParagraph('Infants in all cabin classes are permitted one checked-in bag that may not exceed 55 x 38 x 22 cm (22 x 15 x 8 inches) in size and 23kg (50lb) where the piece concept applies, or 10kg (22lb) where the weight concept applies. In addition, customers travelling with infants (and without a child seat) are permitted to bring one carry-cot or one fully collapsible stroller into the cabin if there is room. If there is no space for these items in the cabin, they will have to be checked. However, if checked, they will not count against your baggage allowance.'),
      pw.SizedBox(height: 12),
      _sectionTitle('WNT CHECKED BAGGAGE NOTIFICATION'),
      _pdfParagraph('Checked baggage allowances vary by fare type and class of travel. Check your baggage allowance, however please note that any individual item weighing more than 32kg cannot be accepted, for health and safety reasons.'),
    ];
  }

  // =========================================================================
  // PAGE 4 — Inflight Entertainment
  // =========================================================================
  static List<pw.Widget> _inflightEntertainmentPage() {
    return [
      pw.SizedBox(height: 20),
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(color: _c(_cardBg), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('INFLIGHT ENTERTAINMENT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          pw.SizedBox(height: 10),
          _pdfParagraph('Fall in love with a classic romance or immerse yourself in the latest edge-of-the-seat blockbuster - let our ice inflight entertainment take you to places you won\'t find on a map. Choose from over 6,500 channels of movies, TV shows and music from around the world and in multiple languages. Or challenge other passengers to a range of gripping games.'),
        ]),
      ),
    ];
  }

  // =========================================================================
  // REUSABLE WIDGETS
  // =========================================================================
  static pw.Widget _pageHeader(String? ticketNumber, pw.ImageProvider? logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _c(_divider), width: 0.5))),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        if (logo != null) ...[
          pw.Image(logo, width: 140, height: 50, fit: pw.BoxFit.contain),
        ] else ...[
          pw.RichText(text: pw.TextSpan(children: [
            pw.TextSpan(text: 'WANDER ', style: pw.TextStyle(color: _c(_blue), fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.TextSpan(text: 'NOVA', style: pw.TextStyle(color: _c(const Color(0xFFFF7200)), fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ])),
        ],
        pw.Spacer(),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          if (ticketNumber != null && ticketNumber.isNotEmpty && ticketNumber != 'N/A') ...[
            pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: ticketNumber.replaceAll(' ', ''), width: 180, height: 40, drawText: false),
            pw.SizedBox(height: 4),
            pw.Text('Ticket number: $ticketNumber', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _c(_textPrimary))),
            pw.Text('Scan the bar code or use the ticket number above at the self check-in points in the airport.', style: pw.TextStyle(fontSize: 7, color: _c(_textLight))),
          ],
        ]),
      ]),
    );
  }

  static pw.Widget _checkInTimeline() {
    final items = <String>['Check in online, or', '90 minutes', '60 minutes', '45 minutes'];
    return pw.Container(
      decoration: pw.BoxDecoration(color: _c(_blue), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Row(children: [
        for (int i = 0; i < items.length; i++) ...[
          pw.Expanded(child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: i == 0 ? _c(_blue) : _tint(_blue, 0.85),
              border: i > 0 ? pw.Border(left: pw.BorderSide(color: PdfColors.white, width: 1)) : null,
            ),
            child: pw.Text(items[i], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          )),
        ],
      ]),
    );
  }

  static pw.Widget _timelineColumn(String text) {
    return pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _pdfParagraph(text),
    ]));
  }

  static pw.Widget _legCard({required AkTicketLeg leg, required int index, required int total, String flightClass = 'Economy'}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: _c(_cardBg), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: pw.BoxDecoration(color: _c(_blue), borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(4), topRight: pw.Radius.circular(4))),
          child: pw.Text(
            '${leg.label != null ? '${leg.label} - ' : ''}Leg $index of $total | ${leg.from} to ${leg.to} | Operated by ${leg.airline}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Flight', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text(leg.flightNo, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
            pw.SizedBox(height: 4),
            pw.Text(flightClass, style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
            pw.Text('Flex Plus', style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
            pw.SizedBox(height: 4),
            pw.Text('Seat', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
          ])),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Check-in at', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text(_checkInFor(leg).$1, style: pw.TextStyle(fontSize: 9, color: _c(_textPrimary))),
            pw.Text(_checkInFor(leg).$2, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          ])),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Departure', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text('${leg.departureDate ?? ''}', style: pw.TextStyle(fontSize: 9, color: _c(_textPrimary))),
            pw.Text(leg.departureTime, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          ])),
          pw.SizedBox(width: 16),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(leg.from.toUpperCase(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
            pw.Text('Departing ${_airportCode(leg.from)}, Airport Terminal', style: pw.TextStyle(fontSize: 7, color: _c(_textSecondary))),
            pw.SizedBox(height: 10),
            pw.Text(leg.to.toUpperCase(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
            pw.Text('Arriving ${_airportCode(leg.to)}, Airport Terminal', style: pw.TextStyle(fontSize: 7, color: _c(_textSecondary))),
          ])),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Status', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text('Confirmed', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
            pw.SizedBox(height: 4),
            pw.Text('Arrival', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text('${leg.departureDate ?? ''}', style: pw.TextStyle(fontSize: 9, color: _c(_textPrimary))),
            pw.Text(leg.arrivalTime, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          ])),
        ]),
        pw.SizedBox(height: 6),
        pw.Row(children: [
          pw.Text('Coupon validity: not before ${leg.departureDate ?? ''} / not after ${leg.departureDate ?? ''}', style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
          pw.Spacer(),
          pw.Text('BAGGAGE 35KGS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
        ]),
      ]),
    );
  }

  static pw.Widget _largeTravelCard({
    required AkTicketLeg leg,
    required int index,
    required int total,
    String flightClass = 'Economy',
    required bool isConfirmed,
  }) {
    final fromCity = leg.from;
    final toCity = leg.to;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: _c(_cardBg), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(color: _c(_blue), borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(6), topRight: pw.Radius.circular(6))),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text('Departing from $fromCity', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
            pw.Text('All times shown are local for each city', style: pw.TextStyle(fontSize: 8, color: PdfColors.white)),
          ]),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          color: _tint(_blue, 0.15),
          child: pw.Text(
            '${leg.label != null ? '${leg.label} - ' : ''}Leg $index of $total | $fromCity (${_airportCode(fromCity)}) to $toCity (${_airportCode(toCity)}) | Operated by ${leg.airline} (equipment owner - ${leg.airline})',
            style: pw.TextStyle(fontSize: 8, color: _c(_navy)),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Flight', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text(leg.flightNo, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
            pw.SizedBox(height: 4),
            pw.Text(flightClass, style: pw.TextStyle(fontSize: 9, color: _c(_textSecondary))),
            pw.Text('Flex Plus', style: pw.TextStyle(fontSize: 9, color: _c(_textSecondary))),
            pw.SizedBox(height: 4),
            pw.Text('Seat', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
          ])),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Check-in at', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text(_checkInFor(leg).$1, style: pw.TextStyle(fontSize: 10, color: _c(_textPrimary))),
            pw.Text(_checkInFor(leg).$2, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          ])),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Departure', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text('${leg.departureDate ?? ''}', style: pw.TextStyle(fontSize: 10, color: _c(_textPrimary))),
            pw.Text(leg.departureTime, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          ])),
          pw.SizedBox(width: 18),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(fromCity.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
            pw.Text('Departing ${_airportCode(fromCity)}, Airport Terminal', style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
            pw.SizedBox(height: 14),
            pw.Text(toCity.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
            pw.Text('Arriving ${_airportCode(toCity)}, Airport Terminal', style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
          ])),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Status', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text(isConfirmed ? 'Confirmed' : 'Processing', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
            pw.SizedBox(height: 4),
            pw.Text('Arrival', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            pw.Text('${leg.departureDate ?? ''}', style: pw.TextStyle(fontSize: 10, color: _c(_textPrimary))),
            pw.Text(leg.arrivalTime, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          ])),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Text('Coupon validity: not before ${leg.departureDate ?? ''} / not after ${leg.departureDate ?? ''}', style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
          pw.Spacer(),
          pw.Text('BAGGAGE 35KGS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
        ]),
      ]),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _c(_navy))));
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)));
  }

  static pw.Widget _dataCell(String text, {bool bold = false}) {
    return pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(text.isEmpty ? 'N/A' : text, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: _c(_textPrimary))));
  }

  static pw.Widget _pdfParagraph(String text) {
    return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: _c(_textSecondary), lineSpacing: 1.5)));
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Container(alignment: pw.Alignment.center, margin: const pw.EdgeInsets.only(top: 8), child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))));
  }

  static pw.Widget _billingRow(String title, String value) {
    return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.RichText(text: pw.TextSpan(style: const pw.TextStyle(fontSize: 9, color: PdfColors.black), children: [
      pw.TextSpan(text: title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
      pw.TextSpan(text: ' $value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ])));
  }

  static pw.Widget _amountRow(String title, String value, {bool big = false}) {
    return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 10), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 14 : 10, color: big ? _c(_navy) : PdfColors.grey700)),
      pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 14 : 10, color: big ? _c(_navy) : PdfColors.grey800)),
    ]));
  }

  static pw.Widget _buildInvoiceTable(FlightBookEntity booking, bool isConfirmed) {
    pw.Widget row(String label, String value) {
      return pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))), child: pw.Row(children: [
        pw.Expanded(flex: 3, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
        pw.Expanded(flex: 2, child: pw.Text(value.isEmpty || value == 'null' ? 'N/A' : value, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
      ]));
    }
    return pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5), borderRadius: pw.BorderRadius.circular(6)), child: pw.Column(children: [
      pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: pw.BoxDecoration(color: _c(_blue), borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(6), topRight: pw.Radius.circular(6))), child: pw.Row(children: [
        pw.Expanded(flex: 3, child: pw.Text('Description', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
        pw.Expanded(flex: 2, child: pw.Text('Details', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right)),
      ])),
      row('Route', '${booking.fromCity} -> ${booking.toCity}'),
      row('Flight Number', booking.flightNumber),
      row('Flight Type', booking.flightType.replaceAll('_', ' ')),
      row('Class', booking.flightClass.toUpperCase()),
      row('Departure', _formatDate(booking.departureDate)),
      if (booking.returnDate != null && booking.returnDate!.isNotEmpty) row('Return', _formatDate(booking.returnDate!)),
      row('Passengers', booking.passengers.toString()),
      row('Status', isConfirmed ? 'Confirmed' : 'Processing'),
      row('Payment Mode', booking.paidVia ?? 'Online'),
      pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: pw.BoxDecoration(color: _c(_blue), borderRadius: const pw.BorderRadius.only(bottomLeft: pw.Radius.circular(6), bottomRight: pw.Radius.circular(6))), child: pw.Row(children: [
        pw.Expanded(flex: 3, child: pw.Text('Total Amount', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
        pw.Expanded(flex: 2, child: pw.Text('${booking.currency} ${booking.totalAmount}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right)),
      ])),
    ]));
  }

  // =========================================================================
  // LEG CONSTRUCTION — one_way / round_trip / multi_city
  // =========================================================================
  static List<AkTicketLeg> _buildLegsForBooking(FlightBookEntity booking) {
    final type = booking.flightType.toLowerCase();
    final flightNo = booking.flightNumber.isNotEmpty ? booking.flightNumber : 'N/A';

    if (type.contains('multi')) {
      final segmentLegs = _legsFromSegments(booking);
      if (segmentLegs.isNotEmpty) return segmentLegs;
      // No structured segment data was stored for this booking — fall back
      // to the single leg we do have rather than inventing extra ones.
      return [
        AkTicketLeg(
          label: 'Leg 1',
          airline: 'Airline',
          flightNo: flightNo,
          from: booking.fromCity,
          to: booking.toCity,
          departureTime: _formatTime(booking.departureDate),
          arrivalTime: '',
          departureDate: _formatDate(booking.departureDate),
          duration: 'TBD',
        ),
      ];
    }

    if (type.contains('round') && booking.returnDate != null && booking.returnDate!.isNotEmpty) {
      return [
        AkTicketLeg(
          label: 'Onward',
          airline: 'Airline',
          flightNo: flightNo,
          from: booking.fromCity,
          to: booking.toCity,
          departureTime: _formatTime(booking.departureDate),
          arrivalTime: '',
          departureDate: _formatDate(booking.departureDate),
          duration: 'TBD',
        ),
        AkTicketLeg(
          label: 'Return',
          airline: 'Airline',
          flightNo: flightNo,
          from: booking.toCity,
          to: booking.fromCity,
          departureTime: _formatTime(booking.returnDate!),
          arrivalTime: '',
          departureDate: _formatDate(booking.returnDate!),
          duration: 'TBD',
        ),
      ];
    }

    // one_way (or unknown type without a return date) — a single leg.
    return [
      AkTicketLeg(
        airline: 'Airline',
        flightNo: flightNo,
        from: booking.fromCity,
        to: booking.toCity,
        departureTime: _formatTime(booking.departureDate),
        arrivalTime: '',
        departureDate: _formatDate(booking.departureDate),
        duration: 'TBD',
      ),
    ];
  }

  /// Best-effort parse of [FlightBookEntity.segments] for multi-city
  /// bookings. The backend doesn't currently populate this field for
  /// bookings created through the app, so this normally returns an empty
  /// list and the caller falls back to a single leg — kept defensive so a
  /// future segments payload (list of maps with from/to/date/flight keys)
  /// renders correctly without another PDF-builder change.
  static List<AkTicketLeg> _legsFromSegments(FlightBookEntity booking) {
    final raw = booking.segments;
    if (raw.isEmpty) return const [];
    final legs = <AkTicketLeg>[];
    for (int i = 0; i < raw.length; i++) {
      final seg = raw[i];
      if (seg is! Map) continue;
      final map = seg.cast<String, dynamic>();
      final from = (map['from_city'] ?? map['fromCity'] ?? map['from'] ?? '').toString();
      final to = (map['to_city'] ?? map['toCity'] ?? map['to'] ?? '').toString();
      final date = (map['departure_date'] ?? map['departureDate'] ?? map['date'] ?? '').toString();
      final flightNo = (map['flight_number'] ?? map['flightNumber'] ?? booking.flightNumber).toString();
      if (from.isEmpty || to.isEmpty) continue;
      legs.add(AkTicketLeg(
        label: 'Leg ${i + 1}',
        airline: 'Airline',
        flightNo: flightNo.isNotEmpty ? flightNo : 'N/A',
        from: from,
        to: to,
        departureTime: _formatTime(date),
        arrivalTime: '',
        departureDate: _formatDate(date),
        duration: 'TBD',
      ));
    }
    return legs;
  }

  // =========================================================================
  // UTILITIES
  // =========================================================================
  static String _primaryPassengerName(FlightBookEntity booking) {
    if (booking.passengersData.isNotEmpty) {
      final lead = booking.passengersData.firstWhere((p) => p.isLeadPax, orElse: () => booking.passengersData.first);
      return '${lead.title} ${lead.firstName} ${lead.lastName}';
    }
    return booking.name ?? 'Guest';
  }

  /// All passenger names on the booking, comma-separated — the sample
  /// ticket's single "Passenger name" cell covers the whole booking, not
  /// just the lead, so a 2+ traveller booking should list everyone.
  static String _allPassengerNames(FlightBookEntity booking) {
    if (booking.passengersData.isEmpty) return booking.name ?? 'Guest';
    final names = booking.passengersData
        .map((p) => '${p.title} ${p.firstName} ${p.lastName}'.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    return names.isEmpty ? (booking.name ?? 'Guest') : names.join(', ');
  }

  static String _baseFare(FlightBookEntity booking) {
    final total = double.tryParse(booking.totalAmount) ?? 0.0;
    return (total * 0.85).toStringAsFixed(2);
  }

  static String _tax(FlightBookEntity booking) {
    final total = double.tryParse(booking.totalAmount) ?? 0.0;
    return (total * 0.15).toStringAsFixed(2);
  }

  static const Map<String, String> _cityToCode = {'Mumbai': 'BOM', 'Delhi': 'DEL', 'Bangalore': 'BLR', 'Chennai': 'MAA', 'Hyderabad': 'HYD', 'Kolkata': 'CCU', 'Ahmedabad': 'AMD', 'Pune': 'PNQ', 'Goa': 'GOI', 'Kochi': 'COK', 'Dubai': 'DXB', 'New Delhi': 'DEL'};

  static String _airportCode(String city) {
    if (city.isEmpty) return '';
    return _cityToCode[city] ?? city.substring(0, city.length < 3 ? city.length : 3).toUpperCase();
  }

  static String _todayDate() {
    final d = DateTime.now();
    return '${d.day}/${d.month}/${d.year}';
  }

  static String _formatDate(String dateString) {
    if (dateString.isEmpty || dateString == 'null') return 'N/A';
    try {
      final dt = DateTime.parse(dateString);
      return '${dt.day} ${_month(dt.month)} ${dt.year}';
    } catch (_) {
      return dateString;
    }
  }

  static String _formatTime(String dateString) {
    if (dateString.isEmpty || dateString == 'null') return '';
    try {
      final dt = DateTime.parse(dateString);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  static String _month(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  /// Recommended check-in time: 3 hours before departure, matching the
  /// "arrive 3 hours before departure" guidance printed on page 1. Parsed
  /// from the leg's already-formatted date ("d MMM yyyy") and time
  /// ("HH:mm") strings; falls back to the departure date/time unchanged if
  /// either string doesn't parse, so a bad value never renders blank.
  static (String, String) _checkInFor(AkTicketLeg leg) {
    final dateStr = leg.departureDate ?? '';
    final timeStr = leg.departureTime;
    if (dateStr.isEmpty || !timeStr.contains(':')) return (dateStr, timeStr);
    try {
      final date = DateFormat('d MMM yyyy').parseLoose(dateStr);
      final timeParts = timeStr.split(':');
      final departure = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final checkIn = departure.subtract(const Duration(hours: 3));
      final hour = checkIn.hour.toString().padLeft(2, '0');
      final minute = checkIn.minute.toString().padLeft(2, '0');
      return ('${checkIn.day} ${_month(checkIn.month)} ${checkIn.year}', '$hour:$minute');
    } catch (_) {
      return (dateStr, timeStr);
    }
  }
}
