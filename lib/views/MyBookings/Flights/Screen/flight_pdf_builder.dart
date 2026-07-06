import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/entities/FlightBookEntity.dart';

/// Builds native, text-based PDF documents for the flight ticket and invoice,
/// mirroring [FlightTicketWidget]/[FlightInvoiceWidget].
///
/// Unlike a screenshot capture, the content here is drawn directly with pdf
/// widgets, so text stays crisp/selectable and pages break naturally instead
/// of being sliced out of a single captured image.
class FlightPdfBuilder {
  static const _navy = Color(0xff293241);
  static const _primary = Color(0xFF0054A0);
  static const _orange = Color(0xffF97316);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF666666);
  static const _textLight = Color(0xFF999999);
  static const _divider = Color(0xFFE0E0E0);
  static const _lightBg = Color(0xFFF7F9FC);

  static PdfColor _c(Color color) => PdfColor.fromInt(color.value);

  static PdfColor _tint(Color base, double opacity) {
    final c = _c(base);
    return PdfColor(
      1 - (1 - c.red) * opacity,
      1 - (1 - c.green) * opacity,
      1 - (1 - c.blue) * opacity,
    );
  }

  static bool _isConfirmed(FlightBookEntity booking) => booking.pnr.isNotEmpty && booking.pnr != 'null';

  static pw.Document buildTicket(FlightBookEntity booking) {
    final isConfirmed = _isConfirmed(booking);
    final statusColor = isConfirmed ? const Color(0xFF4CAF50) : const Color(0xFFFFA726);
    final passengerNames = booking.passengersData.isNotEmpty
        ? booking.passengersData.map((p) => '${p.firstName} ${p.lastName}').join(', ')
        : '';

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          _header('FLIGHT', 'TICKET'),
          pw.SizedBox(height: 12),
          _confirmationCard(
            statusColor: statusColor,
            title: isConfirmed ? 'Confirmed' : 'Processing',
            subtitle: isConfirmed ? 'Your flight has been confirmed' : 'Your flight booking is being processed',
            refLabel: 'PNR',
            refValue: booking.pnr,
          ),
          pw.SizedBox(height: 12),
          _flightDetailsCard(booking, passengerNames),
          pw.SizedBox(height: 10),
          _sectionCard('FARE SUMMARY', [
            _fareRow('Base Fare', '${booking.currency} ${_baseFare(booking)}'),
            _fareRow('Tax & Fees', '${booking.currency} ${_tax(booking)}'),
            pw.Divider(height: 16, color: _c(_divider)),
            _fareRow('Total Paid', '${booking.currency} ${booking.totalAmount}', big: true),
          ]),
          pw.SizedBox(height: 10),
          _passengerInformation(booking),
          pw.SizedBox(height: 10),
          _sectionCard('BOOKING INFORMATION', [
            _infoRow('PNR', booking.pnr),
            _infoRow('TBO Booking ID', booking.tboBookingId),
            _infoRow('Booking Token', booking.bookingToken),
            _infoRow('Booking Date', _formatDate(booking.bookingDate)),
            _infoRow('Status', isConfirmed ? 'Confirmed' : 'Processing'),
            if (booking.paidVia != null && booking.paidVia!.isNotEmpty) _infoRow('Payment Method', booking.paidVia!),
          ]),
          pw.SizedBox(height: 10),
          _sectionCard('IMPORTANT INFORMATION', [
            _bulletPoint('Please carry a valid government-issued ID proof for check-in.'),
            _bulletPoint('Report to the airport at least 2 hours before domestic departure.'),
            _bulletPoint('For international flights, report at least 3 hours before departure.'),
            _bulletPoint('Baggage allowance varies by airline and class.'),
            _bulletPoint('Web check-in is available 24 hours before departure.'),
            _bulletPoint('Keep your PNR and Booking ID handy for any queries.'),
          ]),
        ],
      ),
    );
    return pdf;
  }

  static pw.Document buildInvoice(FlightBookEntity booking) {
    final isConfirmed = _isConfirmed(booking);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          _header('INVOICE', 'INVOICE ${booking.pnr}', isInvoice: true),
          pw.SizedBox(height: 16),
          pw.Text(_primaryPassengerName(booking), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _detailText('Date: ${_todayDate()}'),
          _detailText('PNR: ${booking.pnr}'),
          _detailText('TBO Booking ID: ${booking.tboBookingId}'),
          if (booking.bookingToken.isNotEmpty) _detailText('Booking Token: ${booking.bookingToken}'),
          pw.SizedBox(height: 12),
          pw.Divider(color: _c(_divider)),
          pw.SizedBox(height: 12),
          _invoiceTable(booking, isConfirmed),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _billingRow('Billed by:', _primaryPassengerName(booking)),
                    _billingRow('Issued by:', 'WANDER NOVA'),
                    _billingRow('Billing Cycle:', 'Immediate'),
                    _billingRow('Payment Basis:', 'Invoice Date'),
                    _billingRow('Invoice Status:', isConfirmed ? 'CONFIRMED' : 'PROCESSING'),
                    if (booking.paidVia != null && booking.paidVia!.isNotEmpty) _billingRow('Payment Method:', booking.paidVia!),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    _amountRow('BASE FARE', '${booking.currency} ${_baseFare(booking)}'),
                    _amountRow('TAX & FEES', '${booking.currency} ${_tax(booking)}'),
                    pw.Divider(color: _c(_divider)),
                    pw.SizedBox(height: 8),
                    _amountRow('TOTAL', '${booking.currency} ${booking.totalAmount}', big: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: _c(_divider)),
          pw.SizedBox(height: 16),
          pw.Text('TERMS AND CONDITIONS', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          pw.SizedBox(height: 8),
          pw.Text(
            'Payment is due within 30 days of invoice date. Late payments may incur additional charges. '
            'All bookings are subject to our terms and conditions. Cancellations must be made at least 24 '
            'hours before departure for a full refund. For any queries or support, please contact us. This '
            'invoice is valid for the services listed above.',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, lineSpacing: 2),
          ),
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
    );
  }

  static pw.Widget _header(String line1, String line2, {bool isInvoice = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'WANDER ', style: pw.TextStyle(color: _c(_primary), fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(
                      text: 'NOVA',
                      style: pw.TextStyle(color: _c(const Color(0xFFFF7200)), fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text('TRAVEL WITH US', style: pw.TextStyle(color: _c(const Color(0xFF009999)), fontSize: 7, letterSpacing: 2)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: isInvoice
                ? [
                    pw.Text(line1, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
                    pw.SizedBox(height: 4),
                    pw.Text(line2, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ]
                : [
                    pw.Text(line1, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(line2, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _confirmationCard({
    required Color statusColor,
    required String title,
    required String subtitle,
    required String refLabel,
    required String refValue,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: _tint(statusColor, 0.08), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _c(statusColor))),
                pw.SizedBox(height: 2),
                pw.Text(subtitle, style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
              ],
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(refLabel, style: pw.TextStyle(fontSize: 7, color: _c(_textLight))),
                pw.Text(refValue, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _c(_primary))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _flightDetailsCard(FlightBookEntity booking, String passengerNames) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(booking.fromCity, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _c(_textPrimary))),
                    pw.SizedBox(height: 2),
                    pw.Text(_airportCode(booking.fromCity), style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
                    pw.SizedBox(height: 4),
                    pw.Text(_formatDate(booking.departureDate), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_textSecondary))),
                    pw.Text(_formatTime(booking.departureDate), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _c(_primary))),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(color: _tint(_primary, 0.1), borderRadius: pw.BorderRadius.circular(12)),
                      child: pw.Text(booking.flightNumber, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_primary))),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(booking.toCity, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _c(_textPrimary))),
                    pw.SizedBox(height: 2),
                    pw.Text(_airportCode(booking.toCity), style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
                    pw.SizedBox(height: 4),
                    if (booking.returnDate != null && booking.returnDate!.isNotEmpty) ...[
                      pw.Text('Return: ${_formatDate(booking.returnDate!)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_textSecondary))),
                      pw.Text(_formatTime(booking.returnDate!), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _c(_primary))),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(height: 16, color: _c(_divider)),
          pw.Row(
            children: [
              pw.Expanded(child: _infoBox('Flight Type', booking.flightType.replaceAll('_', ' ').toUpperCase())),
              pw.Expanded(child: _infoBox('Class', booking.flightClass.toUpperCase())),
              pw.Expanded(child: _infoBox('Passengers', booking.passengers.toString())),
            ],
          ),
          if (passengerNames.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(passengerNames, style: pw.TextStyle(fontSize: 9, color: _c(_textSecondary))),
            ),
          ],
          if (booking.tboBookingId.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text('Booking ID: ${booking.tboBookingId}', style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _infoBox(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 7, color: _c(_textLight), fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), maxLines: 1),
      ],
    );
  }

  static pw.Widget _passengerInformation(FlightBookEntity booking) {
    if (booking.passengersData.isEmpty) {
      return _sectionCard('PASSENGER INFORMATION', [
        _infoRow('Total Passengers', booking.passengers.toString()),
        if (booking.name != null && booking.name!.isNotEmpty) _infoRow('Lead Passenger', booking.name!),
      ]);
    }

    final cards = <pw.Widget>[];
    for (var i = 0; i < booking.passengersData.length; i++) {
      cards.add(_passengerCard(i + 1, booking.passengersData[i]));
      if (i < booking.passengersData.length - 1) cards.add(pw.SizedBox(height: 8));
    }
    return _sectionCard('PASSENGER INFORMATION', cards);
  }

  static pw.Widget _passengerCard(int index, PassengerDataEntity passenger) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _c(_lightBg),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _c(_divider)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(color: _tint(_primary, 0.1), borderRadius: pw.BorderRadius.circular(12)),
                child: pw.Text('Passenger $index', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _c(_primary))),
              ),
              pw.SizedBox(width: 8),
              if (passenger.isLeadPax)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F5E9), borderRadius: pw.BorderRadius.circular(12)),
                  child: pw.Text('Lead', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                ),
              pw.Spacer(),
              pw.Text(_paxType(passenger.paxType), style: pw.TextStyle(fontSize: 8, color: _c(_textLight))),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${passenger.title} ${passenger.firstName} ${passenger.lastName}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _c(_textPrimary)),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text(passenger.email, style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary)))),
              pw.SizedBox(width: 8),
              pw.Text(passenger.phone, style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Passport: ${passenger.passportNo}', style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary)))),
              pw.Text(_formatDate(passenger.dateOfBirth), style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
            ],
          ),
          if (passenger.ticketNumber.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Ticket: ${passenger.ticketNumber}', style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
          ],
        ],
      ),
    );
  }

  static pw.Widget _sectionCard(String title, List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _c(_primary), letterSpacing: 1)),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _fareRow(String title, String value, {bool big = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: big ? 13 : 10, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: pw.TextStyle(fontSize: big ? 13 : 10, fontWeight: pw.FontWeight.bold, color: big ? _c(_orange) : PdfColors.black)),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_textSecondary))),
          pw.Expanded(child: pw.Text(value.isEmpty || value == 'null' ? 'N/A' : value, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  static pw.Widget _bulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('•  ', style: pw.TextStyle(fontSize: 9, color: _c(_primary), fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary), lineSpacing: 1.5))),
        ],
      ),
    );
  }

  static pw.Widget _detailText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
    );
  }

  static pw.Widget _billingRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
          children: [
            pw.TextSpan(text: title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
            pw.TextSpan(text: ' $value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _amountRow(String title, String value, {bool big = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 14 : 10, color: big ? _c(_navy) : PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 14 : 10, color: big ? _c(_navy) : PdfColors.grey800)),
        ],
      ),
    );
  }

  static pw.Widget _invoiceTable(FlightBookEntity booking, bool isConfirmed) {
    pw.Widget row(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
            pw.Expanded(
              flex: 2,
              child: pw.Text(value.isEmpty || value == 'null' ? 'N/A' : value, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _c(_primary),
              borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(6), topRight: pw.Radius.circular(6)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('Description', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text('Details', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right),
                ),
              ],
            ),
          ),
          row('Route', '${booking.fromCity} -> ${booking.toCity}'),
          row('Flight Number', booking.flightNumber),
          row('Flight Type', booking.flightType.replaceAll('_', ' ')),
          row('Class', booking.flightClass.toUpperCase()),
          row('Departure', _formatDate(booking.departureDate)),
          if (booking.returnDate != null && booking.returnDate!.isNotEmpty) row('Return', _formatDate(booking.returnDate!)),
          row('Passengers', booking.passengers.toString()),
          row('Status', isConfirmed ? 'Confirmed' : 'Processing'),
          row('Payment Mode', booking.paidVia ?? 'Online'),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _c(_primary),
              borderRadius: const pw.BorderRadius.only(bottomLeft: pw.Radius.circular(6), bottomRight: pw.Radius.circular(6)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('Total Amount', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text('${booking.currency} ${booking.totalAmount}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _primaryPassengerName(FlightBookEntity booking) {
    if (booking.passengersData.isNotEmpty) {
      final lead = booking.passengersData.firstWhere(
        (p) => p.isLeadPax,
        orElse: () => booking.passengersData.first,
      );
      return '${lead.title} ${lead.firstName} ${lead.lastName}';
    }
    return booking.name ?? 'Guest';
  }

  static String _baseFare(FlightBookEntity booking) {
    final total = double.tryParse(booking.totalAmount) ?? 0.0;
    return (total * 0.85).toStringAsFixed(2);
  }

  static String _tax(FlightBookEntity booking) {
    final total = double.tryParse(booking.totalAmount) ?? 0.0;
    return (total * 0.15).toStringAsFixed(2);
  }

  static String _paxType(int type) {
    switch (type) {
      case 1:
        return 'Adult';
      case 2:
        return 'Child';
      case 3:
        return 'Infant';
      default:
        return 'Passenger';
    }
  }

  static const Map<String, String> _cityToCode = {
    'Mumbai': 'BOM',
    'Delhi': 'DEL',
    'Bangalore': 'BLR',
    'Chennai': 'MAA',
    'Hyderabad': 'HYD',
    'Kolkata': 'CCU',
    'Ahmedabad': 'AMD',
    'Pune': 'PNQ',
    'Goa': 'GOI',
    'Kochi': 'COK',
  };

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
}
