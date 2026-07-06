import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/entity/MyBooking_entity.dart';

/// Builds native, text-based PDF documents for the transport voucher and
/// invoice, mirroring [BookingTicketWidget]/[BookingInvoiceWidget].
///
/// Unlike a screenshot capture, the content here is drawn directly with pdf
/// widgets, so text stays crisp/selectable and pages break naturally instead
/// of being sliced out of a single captured image.
class TransportPdfBuilder {
  static const _navy = Color(0xff293241);
  static const _primary = Color(0xFF0054A0);
  static const _orange = Color(0xffF97316);
  static const _textSecondary = Color(0xFF666666);
  static const _textLight = Color(0xFF999999);
  static const _divider = Color(0xFFE0E0E0);

  static const _pending = Color(0xFFFFA726);
  static const _cancelled = Color(0xFFE53935);
  static const _confirmed = Color(0xFF4CAF50);

  static PdfColor _c(Color color) => PdfColor.fromInt(color.value);

  static PdfColor _tint(Color base, double opacity) {
    final c = _c(base);
    return PdfColor(
      1 - (1 - c.red) * opacity,
      1 - (1 - c.green) * opacity,
      1 - (1 - c.blue) * opacity,
    );
  }

  static pw.Document buildTicket(BookingEntity booking) {
    final status = booking.status.toLowerCase();
    final isPending = status.contains('pending');
    final isCancelled = status.contains('cancelled');
    final statusColor = isPending ? _pending : (isCancelled ? _cancelled : _confirmed);
    final isAirport = booking.category == 'Flight';

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          _header(booking.type.toUpperCase(), 'VOUCHER'),
          pw.SizedBox(height: 12),
          _confirmationCard(
            statusColor: statusColor,
            title: isPending ? 'Booking is Pending' : (isCancelled ? 'Booking Cancelled' : 'Booking Confirmed'),
            subtitle: isPending
                ? 'Your booking is being processed'
                : (isCancelled ? 'This booking has been cancelled' : 'Thank you for booking with us'),
            refLabel: 'Confirmation No',
            refValue: booking.confirmationNumber,
          ),
          pw.SizedBox(height: 12),
          _sectionCard('TRIP DETAILS', [
            _infoRow('Pickup', booking.startAddress),
            _infoRow('Drop-off', booking.endAddress),
            _infoRow('Pickup Time', _formatDateTime(booking.pickupDatetime)),
            if (isAirport)
              _infoRow('Flight Number', booking.flightNumber)
            else
              _infoRow('Vehicle', booking.vehicleName),
            _infoRow('Category', booking.category),
          ]),
          pw.SizedBox(height: 10),
          _sectionCard('PASSENGER INFORMATION', [
            _infoRow('Name', '${booking.firstName} ${booking.lastName}'),
            _infoRow('Email', booking.email),
            _infoRow('Phone', booking.phoneNumber),
            _infoRow('Applicants', booking.applicantCount.toString()),
          ]),
          pw.SizedBox(height: 10),
          _sectionCard('FARE SUMMARY', [
            _fareRow('Base Fare', '${booking.currency} ${_amount(booking)}'),
            _fareRow('Tax', '${booking.currency} 0'),
            pw.Divider(height: 16, color: _c(_divider)),
            _fareRow('Total Paid', _getConvertedAmountText(booking), big: true),
          ]),
          pw.SizedBox(height: 10),
          _sectionCard('BOOKING INFORMATION', [
            _infoRow('Confirmation No', booking.confirmationNumber),
            _infoRow('Payment Mode', booking.type),
            _infoRow('Status', booking.status),
            _infoRow('Booked Date', booking.bookedDate),
            _infoRow('Provider', booking.providerName),
          ]),
          pw.SizedBox(height: 10),
          _sectionCard('IMPORTANT INFORMATION', [
            _bulletPoint('Please present this voucher to the ${isAirport ? 'airline' : 'driver'} for check-in.'),
            _bulletPoint('Carry a valid government-issued ID proof for all travelers.'),
            if (isAirport) ...[
              _bulletPoint('Arrive at the airport at least 2 hours before departure.'),
              _bulletPoint('Check-in baggage allowance: As per airline policy.'),
            ] else ...[
              _bulletPoint('Please be ready at the pickup location 10 minutes before the scheduled time.'),
              _bulletPoint('Driver will wait for maximum 15 minutes after the scheduled pickup time.'),
            ],
            _bulletPoint('Cancellation policy applies as per booking terms.'),
          ]),
        ],
      ),
    );
    return pdf;
  }

  static pw.Document buildInvoice(BookingEntity booking) {
    final isFlight = booking.category == 'Flight';
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          _header('INVOICE', 'INVOICE ${booking.confirmationNumber}', isInvoice: true),
          pw.SizedBox(height: 16),
          pw.Text('${booking.firstName} ${booking.lastName}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _detailText('Date: ${booking.bookedDate}'),
          _detailText('Email: ${booking.email.isNotEmpty ? booking.email : 'N/A'}'),
          _detailText('Phone: ${booking.phoneNumber.isNotEmpty ? booking.phoneNumber : 'N/A'}'),
          pw.SizedBox(height: 12),
          pw.Divider(color: _c(_divider)),
          pw.SizedBox(height: 12),
          _invoiceTable(booking, isFlight),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _billingRow('Billed by:', '${booking.firstName} ${booking.lastName}'),
                    _billingRow('Issued by:', 'WANDER NOVA'),
                    _billingRow('Billing Cycle:', 'Immediate'),
                    _billingRow('Payment Basis:', 'Invoice Date'),
                    _billingRow('Invoice Status:', booking.status.toUpperCase()),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    _amountRow('SERVICE CHARGE', _getConvertedAmountText(booking)),
                    _amountRow('TAX & FEES', '${_currencySymbol(booking.currency)}0'),
                    pw.Divider(color: _c(_divider)),
                    pw.SizedBox(height: 8),
                    _amountRow('TOTAL', _getConvertedAmountText(booking), big: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: _c(_divider)),
          pw.SizedBox(height: 16),
          pw.Text('TERMS AND CONDITIONS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
          pw.SizedBox(height: 8),
          pw.Text(
            'Payment is due within 30 days of invoice date. Late payments may incur additional charges. '
            'All bookings are subject to our terms and conditions. Cancellations must be made at least 24 '
            'hours before departure for a full refund. For any queries or support, please contact us. This '
            'invoice is valid for the services listed above.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, lineSpacing: 2),
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

  static pw.Widget _invoiceTable(BookingEntity booking, bool isFlight) {
    pw.Widget row(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
            pw.Expanded(flex: 2, child: pw.Text(value.isEmpty ? 'N/A' : value, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
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
          row('Service Type', booking.type),
          row('Category', booking.category),
          row('Pickup', booking.startAddress),
          row('Drop-off', booking.endAddress),
          row('Pickup Time', _formatDateTime(booking.pickupDatetime)),
          if (isFlight) row('Flight Number', booking.flightNumber) else row('Vehicle', booking.vehicleName),
          row('Travelers', booking.applicantCount.toString()),
          row('Payment Mode', booking.type),
          row('Provider', booking.providerName),
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
                  child: pw.Text(_getConvertedAmountText(booking), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _amount(BookingEntity booking) {
    String amount = booking.totalPrice;
    if (amount.isEmpty) amount = booking.rawTotalPrice;
    return amount;
  }

  static String _getConvertedAmountText(BookingEntity booking) {
    return '${booking.currency} ${_amount(booking)}';
  }

  static String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      default:
        return currency;
    }
  }

  static String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $time';
    } catch (e) {
      return isoString;
    }
  }
}
