import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../Insurance/domain/entity/InsuranceBookingEntity.dart';

class InsurancePdfBuilder {
  static const _primary = Color(0xFF0054A0);
  static const _orange = Color(0xffF97316);
  static const _textSecondary = Color(0xFF666666);
  static const _textLight = Color(0xFF999999);
  static const _divider = Color(0xFFE0E0E0);

  static PdfColor _c(Color color) => PdfColor.fromInt(color.toARGB32());

  static PdfColor _tint(Color base, double opacity) {
    final c = _c(base);
    return PdfColor(
      1 - (1 - c.red) * opacity,
      1 - (1 - c.green) * opacity,
      1 - (1 - c.blue) * opacity,
    );
  }

  static Future<pw.Document> buildTicket(InsuranceBookingEntity booking) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          // _header(booking),
          // pw.SizedBox(height: 14),
          _confirmationCard(booking),
          pw.SizedBox(height: 14),
          _policyDetailsCard(booking),
          pw.SizedBox(height: 12),
          _sectionCard('COVERAGE DETAILS', [
            _infoRow('Plan', booking.planName),
            _infoRow('Provider', booking.providerName),
            _infoRow('Destination', booking.destination),
            _infoRow('Coverage Period',
                '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}'),
            _infoRow('No. of Travellers', booking.travellers.toString()),
          ]),
          pw.SizedBox(height: 12),
          _paymentSummary(booking),
          pw.SizedBox(height: 12),
          _sectionCard('BOOKING INFORMATION', [
            if (booking.policyNumber.isNotEmpty) _infoRow('Policy Number', booking.policyNumber),
            _infoRow('Transaction ID', booking.transactionId),
            _infoRow('Payment Method', booking.paymentMethod),
            _infoRow('Status', booking.status),
            _infoRow('Booking Date', _formatDate(booking.created)),
          ]),
          pw.SizedBox(height: 12),
          _sectionCard('CONTACT INFORMATION', [
            _infoRow('Holder Name', booking.holderName),
            _infoRow('Email', booking.email),
            _infoRow('Phone', booking.phone),
          ]),
          pw.SizedBox(height: 12),
          _sectionCard('IMPORTANT INFORMATION', [
            _bulletPoint('Keep this policy document handy during your travel.'),
            _bulletPoint('Carry a valid government-issued ID proof.'),
            _bulletPoint('In case of emergency, contact the insurance provider directly.'),
            _bulletPoint('Claims must be filed within the policy coverage period.'),
            _bulletPoint('Cancellation policy applies as per booking terms.'),
          ]),
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

  // static pw.Widget _header(InsuranceBookingEntity booking) {
  //   return pw.Row(
  //     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //     children: [
  //       pw.Expanded(
  //         child: pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             pw.RichText(
  //               text: pw.TextSpan(
  //                 children: [
  //                   pw.TextSpan(
  //                     text: 'WANDER ',
  //                     style: pw.TextStyle(
  //                         color: _c(_primary), fontSize: 18, fontWeight: pw.FontWeight.bold),
  //                   ),
  //                   pw.TextSpan(
  //                     text: 'NOVA',
  //                     style: pw.TextStyle(
  //                         color: _c(const Color(0xFFFF7200)),
  //                         fontSize: 18,
  //                         fontWeight: pw.FontWeight.bold),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             pw.SizedBox(height: 2),
  //             pw.Text(
  //               'TRAVEL WITH US',
  //               style: pw.TextStyle(
  //                   color: _c(const Color(0xFF009999)), fontSize: 7, letterSpacing: 2),
  //             ),
  //           ],
  //         ),
  //       ),
  //       pw.Expanded(
  //         child: pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.end,
  //           children: [
  //             pw.Text('INSURANCE',
  //                 style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
  //             pw.Text('POLICY',
  //                 style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  static pw.Widget _confirmationCard(InsuranceBookingEntity booking) {
    final status = booking.status.toLowerCase();
    final isPending = status.contains('pending');
    final isCancelled = status.contains('cancel');

    final PdfColor bg;
    final PdfColor fg;
    final String title;
    final String subtitle;
    if (isPending) {
      bg = PdfColor.fromInt(0xFFFFF3E0);
      fg = PdfColors.orange800;
      title = 'Policy is Pending';
      subtitle = 'Your policy is being processed';
    } else if (isCancelled) {
      bg = PdfColor.fromInt(0xFFFFEBEE);
      fg = PdfColors.red800;
      title = 'Policy Cancelled';
      subtitle = 'This policy has been cancelled';
    } else {
      bg = PdfColor.fromInt(0xFFE8F5E9);
      fg = PdfColors.green800;
      title = 'Policy Confirmed';
      subtitle = 'Thank you for choosing us';
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
                pw.Text(title,
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: fg)),
                pw.SizedBox(height: 2),
                pw.Text(subtitle, style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
              ],
            ),
          ),
          if (booking.policyNumber.isNotEmpty)
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Policy No',
                      style: pw.TextStyle(fontSize: 7, color: _c(_textLight))),
                  pw.Text(
                    booking.policyNumber,
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold, color: _c(_primary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _policyDetailsCard(InsuranceBookingEntity booking) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration:
          pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 46,
                height: 46,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF5F7FA),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  booking.planName.isNotEmpty ? booking.planName[0].toUpperCase() : 'I',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold, color: _c(_primary)),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      booking.planName.isNotEmpty ? booking.planName : 'Insurance Policy',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                    if (booking.providerName.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(booking.providerName,
                          style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary))),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Expanded(
                  child: _dateBox('START DATE', _formatDate(booking.startDate), _primary)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _dateBox('END DATE', _formatDate(booking.endDate), _orange)),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Expanded(child: _infoBox('DESTINATION', booking.destination)),
              pw.Expanded(child: _infoBox('TRAVELLERS', booking.travellers.toString())),
            ],
          ),
        ],
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
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 7,
                  color: _c(_textLight),
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _c(color))),
        ],
      ),
    );
  }

  static pw.Widget _infoBox(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 7,
                color: _c(_textLight),
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1)),
        pw.SizedBox(height: 3),
        pw.Text(value.isNotEmpty ? value : 'N/A',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), maxLines: 1),
      ],
    );
  }

  static pw.Widget _sectionCard(String title, List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration:
          pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _c(_primary),
                  letterSpacing: 1)),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _paymentSummary(InsuranceBookingEntity booking) {
    final hasBase = booking.basePremium != null && booking.basePremium!.isNotEmpty;
    final taxVal = double.tryParse(booking.tax ?? '') ?? 0;
    final taxIsZero = booking.tax == null || taxVal == 0;

    return _sectionCard('PAYMENT SUMMARY', [
      if (hasBase) _fareRow('Base Premium', '${booking.currency} ${booking.basePremium}'),
      if (hasBase) pw.SizedBox(height: 4),
      _fareRow('Tax', taxIsZero ? 'Included' : '${booking.currency} ${booking.tax}'),
      pw.Divider(height: 16, color: _c(_divider)),
      _fareRow('Total Paid', '${booking.currency} ${booking.totalAmount}', big: true),
    ]);
  }

  static pw.Widget _fareRow(String title, String value, {bool big = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: big ? 13 : 10, fontWeight: pw.FontWeight.bold)),
        pw.Text(
          value,
          style: pw.TextStyle(
              fontSize: big ? 13 : 10,
              fontWeight: pw.FontWeight.bold,
              color: big ? _c(_orange) : PdfColors.black),
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
          pw.Text('$label: ',
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold, color: _c(_textSecondary))),
          pw.Expanded(
              child:
                  pw.Text(value.isEmpty ? 'N/A' : value, style: const pw.TextStyle(fontSize: 9))),
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
          pw.Text('•  ',
              style: pw.TextStyle(
                  fontSize: 9, color: _c(_primary), fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
              child: pw.Text(text,
                  style: pw.TextStyle(fontSize: 8, color: _c(_textSecondary), lineSpacing: 1.5))),
        ],
      ),
    );
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}
