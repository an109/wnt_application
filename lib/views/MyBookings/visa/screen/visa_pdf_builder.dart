import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../UpcomingTrips/data/models/tripModel.dart';

/// Builds native, text-based PDF documents for the visa voucher and invoice,
/// mirroring [VisaTicketWidget]/[VisaInvoiceWidget].
///
/// Unlike a screenshot capture, the content here is drawn directly with pdf
/// widgets, so text stays crisp/selectable and pages break naturally instead
/// of being sliced out of a single captured image.
class VisaPdfBuilder {
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

  static pw.Document buildTicket(TripItem trip) {
    final status = trip.status.toLowerCase();
    final isPending = status.contains('pending');
    final isCancelled = status.contains('cancelled');
    final statusColor = isPending ? _pending : (isCancelled ? _cancelled : _confirmed);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          _header('VISA', 'VOUCHER'),
          pw.SizedBox(height: 12),
          _confirmationCard(
            statusColor: statusColor,
            title: isPending
                ? 'Visa Application is Pending'
                : (isCancelled ? 'Visa Application Cancelled' : 'Visa Application Approved'),
            subtitle: isPending
                ? 'Your visa application is being processed'
                : (isCancelled ? 'This visa application has been cancelled' : 'Your visa apploication is under processing'),
            refLabel: 'Reference No',
            refValue: trip.refId,
          ),
          pw.SizedBox(height: 12),
          _sectionCard('VISA DETAILS', [
            _infoRow('Country', trip.destination),
            _infoRow('Visa Type', trip.type),
            _infoRow('Category', trip.category),
            _infoRow('Processing Time', '5-10 Business Days'),
          ]),
          pw.SizedBox(height: 10),
          _sectionCard('APPLICANT INFORMATION', [
            _infoRow('Total Applicants', trip.applicantCount.toString()),
            _infoRow('Application Date', trip.bookedDate),
            _infoRow('Status', trip.status),
          ]),
          pw.SizedBox(height: 10),
          _sectionCard('FARE SUMMARY', [
            _fareRow('Visa Fee', trip.getFormattedPrice()),
            _fareRow('Service Fee', '0'),
            _fareRow('Tax & Charges', '0'),
            pw.Divider(height: 16, color: _c(_divider)),
            _fareRow('Total Paid', trip.getFormattedPrice(), big: true),
          ]),
          pw.SizedBox(height: 10),
          _sectionCard('BOOKING INFORMATION', [
            _infoRow('Reference No', trip.refId),
            _infoRow('Service Type', trip.type),
            _infoRow('Category', trip.category),
            _infoRow('Status', trip.status),
            _infoRow('Booked Date', trip.bookedDate),
            _infoRow('Destination', trip.destination),
          ]),
          pw.SizedBox(height: 10),
          _sectionCard('IMPORTANT INFORMATION', [
            _bulletPoint('Please carry a valid passport with at least 6 months validity from the date of travel.'),
            _bulletPoint('Carry a printout of this visa voucher for verification.'),
            _bulletPoint('Visa processing time may vary depending on the country and type of visa.'),
            _bulletPoint('Ensure all documents are submitted as per the requirements.'),
            _bulletPoint('Cancellation policy applies as per visa terms and conditions.'),
          ]),
        ],
      ),
    );
    return pdf;
  }

  static pw.Document buildInvoice(TripItem trip) {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          _header('INVOICE', 'INVOICE ${trip.refId}', isInvoice: true),
          pw.SizedBox(height: 16),
          pw.Text('Visa Application', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _detailText('Date: ${trip.bookedDate}'),
          _detailText('Destination: ${trip.destination}'),
          _detailText('Applicants: ${trip.applicantCount}'),
          _detailText('Status: ${trip.status}'),
          pw.SizedBox(height: 12),
          pw.Divider(color: _c(_divider)),
          pw.SizedBox(height: 12),
          _invoiceTable(trip),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _billingRow('Billed by:', '${trip.destination} Visa'),
                    _billingRow('Issued by:', 'WANDER NOVA'),
                    _billingRow('Billing Cycle:', 'Immediate'),
                    _billingRow('Payment Basis:', 'Invoice Date'),
                    _billingRow('Invoice Status:', trip.status.toUpperCase()),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    _amountRow('VISA FEE', trip.getFormattedPrice()),
                    _amountRow('TAX & FEES', '0'),
                    pw.Divider(color: _c(_divider)),
                    pw.SizedBox(height: 8),
                    _amountRow('TOTAL', trip.getFormattedPrice(), big: true),
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
            'Visa processing fees are non-refundable once the application is submitted. All visa applications '
            'are subject to approval by the respective embassy/consulate. We recommend applying well in advance '
            'of your travel date. For any queries or support, please contact our visa assistance team.',
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
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 14 : 10, color: big ? _c(_navy) : PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 14 : 10, color: big ? _c(_navy) : PdfColors.grey800)),
        ],
      ),
    );
  }

  static pw.Widget _invoiceTable(TripItem trip) {
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
          row('Service Type', 'Visa Application'),
          row('Category', trip.category),
          row('Country', trip.destination),
          row('Visa Type', trip.type),
          row('Applicants', trip.applicantCount.toString()),
          row('Status', trip.status),
          row('Booked Date', trip.bookedDate),
          row('Reference', trip.refId),
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
                  child: pw.Text(trip.getFormattedPrice(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
