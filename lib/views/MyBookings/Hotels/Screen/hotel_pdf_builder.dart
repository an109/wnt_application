import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/entity/HotelBookingEntity.dart';

/// Builds native, text-based PDF documents for the hotel voucher and invoice.
///
/// Unlike a screenshot capture, the content here is drawn directly with pdf
/// widgets, so text stays crisp/selectable and pages break naturally instead
/// of being sliced out of a single captured image.
class HotelPdfBuilder {
  static const _navy = Color(0xff293241);
  static const _primary = Color(0xFF0054A0);
  static const _orange = Color(0xffF97316);
  static const _textSecondary = Color(0xFF666666);
  static const _textLight = Color(0xFF999999);
  static const _divider = Color(0xFFE0E0E0);

  static PdfColor _c(Color color) => PdfColor.fromInt(color.value);

  /// Blends [base] with the (white) page background at [opacity], mirroring
  /// how `Color.withOpacity` reads visually in the on-screen widgets.
  static PdfColor _tint(Color base, double opacity) {
    final c = _c(base);
    return PdfColor(
      1 - (1 - c.red) * opacity,
      1 - (1 - c.green) * opacity,
      1 - (1 - c.blue) * opacity,
    );
  }

  static Future<pw.Document> buildTicket(HotelBookingListEntity booking) async {
    final hotelImageBytes = await _tryFetchImage(booking.hotelImage);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          _header(isInvoice: false, booking: booking),
          pw.SizedBox(height: 14),
          _confirmationCard(booking),
          pw.SizedBox(height: 14),
          _hotelDetailsCard(booking, hotelImageBytes),
          pw.SizedBox(height: 12),
          _sectionCard('FARE SUMMARY', [
            _fareRow('Tax', '${booking.currency} ${booking.tax}'),
            pw.Divider(height: 16, color: _c(_divider)),
            _fareRow('Total Paid', '${booking.currency} ${booking.totalFare}', big: true),
          ]),
          pw.SizedBox(height: 12),
          _sectionCard('BOOKING INFORMATION', [
            _infoRow('Booking Reference', booking.bookingReferenceId),
            _infoRow('Guest Reference', booking.guestReference),
            _infoRow('Payment Mode', 'Online'),
            _infoRow('Status', booking.status),
            _infoRow('Booking Date', booking.bookingDate ?? booking.created),
          ]),
          pw.SizedBox(height: 12),
          _sectionCard('GUEST INFORMATION', [
            _infoRow('Guest Name', booking.guestName),
            _infoRow('Email', booking.email),
            _infoRow('Phone', booking.phone),
            _infoRow('Adults', booking.adults.toString()),
            _infoRow('Children', booking.children.toString()),
          ]),
          pw.SizedBox(height: 12),
          _sectionCard('IMPORTANT INFORMATION', [
            _bulletPoint('Please present this voucher at hotel reception for check-in.'),
            _bulletPoint('Carry a valid government-issued ID proof for all guests.'),
            _bulletPoint('Check-in time: 2:00 PM | Check-out time: 11:00 AM'),
            _bulletPoint('Early check-in is subject to availability.'),
            _bulletPoint('Cancellation policy applies as per booking terms.'),
          ]),
        ],
      ),
    );

    return pdf;
  }

  static Future<pw.Document> buildInvoice(HotelBookingListEntity booking) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          _header(isInvoice: true, booking: booking),
          pw.SizedBox(height: 18),
          pw.Text(
            booking.guestName.isNotEmpty ? booking.guestName : 'Guest',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _detailText('Date: ${_todayDate()}'),
          _detailText('Email: ${booking.email.isNotEmpty ? booking.email : 'N/A'}'),
          _detailText('Phone: ${booking.phone.isNotEmpty ? booking.phone : 'N/A'}'),
          pw.SizedBox(height: 12),
          pw.Divider(color: _c(_divider)),
          pw.SizedBox(height: 12),
          _invoiceTable(booking),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _billingRow('Billed by:', booking.guestName.isNotEmpty ? booking.guestName : 'Guest'),
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
                    _amountRow('ROOM CHARGE', '${booking.currency} ${booking.totalFare}'),
                    _amountRow('TAX & FEES', '${booking.currency} ${booking.tax}'),
                    pw.Divider(color: _c(_divider)),
                    pw.SizedBox(height: 8),
                    _amountRow('TOTAL', '${booking.currency} ${booking.totalFare}', big: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: _c(_divider)),
          pw.SizedBox(height: 16),
          pw.Text(
            'TERMS AND CONDITIONS',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _c(_navy)),
          ),
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
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 8, color: _c(_textLight)),
      ),
    );
  }

  static pw.Widget _header({required bool isInvoice, required HotelBookingListEntity booking}) {
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
                    pw.TextSpan(
                      text: 'WANDER ',
                      style: pw.TextStyle(color: _c(_primary), fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(
                      text: 'NOVA',
                      style: pw.TextStyle(color: _c(const Color(0xFFFF7200)), fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'TRAVEL WITH US',
                style: pw.TextStyle(color: _c(const Color(0xFF009999)), fontSize: 7, letterSpacing: 2),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: isInvoice
                ? [
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _c(_navy))),
                    pw.SizedBox(height: 4),
                    pw.Text('INVOICE ${booking.confirmationNumber}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ]
                : [
                    pw.Text('HOTEL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('VOUCHER', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _confirmationCard(HotelBookingListEntity booking) {
    final status = booking.status.toLowerCase();
    final isPending = status.contains('pending');
    final isCancelled = status.contains('cancelled');

    final PdfColor bg;
    final PdfColor fg;
    final String title;
    final String subtitle;
    if (isPending) {
      bg = PdfColor.fromInt(0xFFFFF3E0);
      fg = PdfColors.orange800;
      title = 'Booking is Pending';
      subtitle = 'Your booking is being processed';
    } else if (isCancelled) {
      bg = PdfColor.fromInt(0xFFFFEBEE);
      fg = PdfColors.red800;
      title = 'Booking Cancelled';
      subtitle = 'This booking has been cancelled';
    } else {
      bg = PdfColor.fromInt(0xFFE8F5E9);
      fg = PdfColors.green800;
      title = 'Booking Confirmed';
      subtitle = 'Thank you for booking with us';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: fg)),
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
                pw.Text('Confirmation No', style: pw.TextStyle(fontSize: 7, color: _c(_textLight))),
                pw.Text(
                  booking.confirmationNumber,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _c(_primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _hotelDetailsCard(HotelBookingListEntity booking, Uint8List? imageBytes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _hotelThumbnail(booking, imageBytes),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      booking.hotelName,
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${booking.hotelAddress}${booking.hotelCity.isNotEmpty ? ', ${booking.hotelCity}' : ''}'
                      '${booking.hotelCountry.isNotEmpty ? ', ${booking.hotelCountry}' : ''}',
                      style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary)),
                    ),
                    if (booking.hotelStars > 0) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '★' * (booking.hotelStars > 5 ? 5 : booking.hotelStars),
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.amber),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Expanded(child: _dateBox('CHECK-IN', _formatDate(booking.checkIn), _primary)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _dateBox('CHECK-OUT', _formatDate(booking.checkOut), _orange)),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Expanded(child: _infoBox('ROOM TYPE', booking.roomType)),
              pw.Expanded(child: _infoBox('ROOMS', booking.rooms.toString())),
              pw.Expanded(child: _infoBox('GUESTS', booking.guests.toString())),
              pw.Expanded(child: _infoBox('NIGHTS', booking.nights.toString())),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _hotelThumbnail(HotelBookingListEntity booking, Uint8List? imageBytes) {
    const size = 46.0;
    if (imageBytes != null) {
      return pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: pw.Image(pw.MemoryImage(imageBytes), width: size, height: size, fit: pw.BoxFit.cover),
      );
    }
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F7FA), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Text(
        booking.hotelName.isNotEmpty ? booking.hotelName[0].toUpperCase() : 'H',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
      ),
    );
  }

  static pw.Widget _dateBox(String title, String value, Color color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _tint(color, 0.06),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _tint(color, 0.2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 7, color: _c(_textLight), fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _c(color))),
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
        pw.Text(value, style:  pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), maxLines: 1),
      ],
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
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: big ? 13 : 10, fontWeight: pw.FontWeight.bold, color: big ? _c(_orange) : PdfColors.black),
        ),
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
          pw.Expanded(child: pw.Text(value.isEmpty ? 'N/A' : value, style: const pw.TextStyle(fontSize: 9))),
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
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 14 : 10, color: big ? _c(_navy) : PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 14 : 10, color: big ? _c(_navy) : PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  static pw.Widget _invoiceTable(HotelBookingListEntity booking) {
    pw.Widget row(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
            pw.Expanded(
              flex: 2,
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
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
                pw.Expanded(
                  flex: 3,
                  child: pw.Text('Description', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Details',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          row('Hotel Name', booking.hotelName),
          row('Room Type', booking.roomType),
          row('Check-in', _formatDate(booking.checkIn)),
          row('Check-out', _formatDate(booking.checkOut)),
          row('Nights', booking.nights.toString()),
          row('Rooms', booking.rooms.toString()),
          row('Guests', booking.guests.toString()),
          row('Children', booking.children.toString()),
          row('Payment Mode', 'Online'),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _c(_primary),
              borderRadius: const pw.BorderRadius.only(bottomLeft: pw.Radius.circular(6), bottomRight: pw.Radius.circular(6)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text('Total Amount', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '${booking.currency} ${booking.totalFare}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<Uint8List?> _tryFetchImage(String url) async {
    if (url.trim().isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {
      // Fall back to the placeholder thumbnail below.
    }
    return null;
  }

  static String _todayDate() {
    final d = DateTime.now();
    return '${d.day}/${d.month}/${d.year}';
  }

  static String _formatDate(String date) {
    if (date.isEmpty) return '-';
    try {
      final dt = DateTime.parse(date);
      return "${dt.day} ${_month(dt.month)}'${dt.year.toString().substring(2)}";
    } catch (_) {
      return date;
    }
  }

  static String _month(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
