import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'visa_form_data.dart';

class VisaPdfBuilder {
  static const _blue = Color(0xFF0088FF);
  static const _navy = Color(0xFF071638);
  static const _orange = Color(0xFFFF7200);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF555555);
  static const _textLight = Color(0xFF888888);
  static const _divider = Color(0xFFD0D5DD);
  static const _green = Color(0xFF16A34A);

  // ignore: deprecated_member_use
  static PdfColor _c(Color color) => PdfColor.fromInt(color.value);

  static String _ascii(String s) {
    const replacements = {
      '•': '-', '·': '-', '–': '-', '—': '-',
      '‘': "'", '’': "'", '“': '"', '”': '"',
      '₹': 'Rs.',
    };
    var out = s;
    replacements.forEach((from, to) => out = out.replaceAll(from, to));
    return out;
  }

  static pw.Document buildInvoice({
    required String destination,
    required String visaType,
    required String visaStay,
    required List<VisaTravellerForm> travellers,
    required VisaTripForm trip,
    required double visaFeeInr,
    required double insuranceInr,
    required int? insuranceDays,
    required double totalInr,
    required String bookingId,
    String? trackId,
    required String paymentMode,
    pw.ImageProvider? logo,
  }) {
    final count = travellers.length;
    final issuedDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    final issuedTime = DateFormat('hh:mm a').format(DateTime.now());
    final baseFare = visaFeeInr * count;
    final taxes = insuranceInr;
    final travelDate = trip.arrivalDate != null
        ? DateFormat('dd MMM yyyy').format(trip.arrivalDate!)
        : '--';
    final returnDate = trip.departureDate != null
        ? DateFormat('dd MMM yyyy').format(trip.departureDate!)
        : '--';
    final money = NumberFormat.decimalPattern('en_IN');

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      header: (context) => _header(logo, bookingId),
      footer: _footer,
      build: (context) {
        final W = PdfPageFormat.a4.width - 80;
        return [
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'VISA APPLICATION INVOICE',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: _c(_navy),
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Issued on $issuedDate at $issuedTime',
              style: pw.TextStyle(fontSize: 9, color: _c(_textLight)),
            ),
          ),
          pw.SizedBox(height: 18),

          // ── Booking reference banner ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: pw.BoxDecoration(
              color: _c(_blue),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(children: [
              pw.Text('Booking ID: ',
                  style: pw.TextStyle(
                      fontSize: 12, color: PdfColors.white)),
              pw.Text(_ascii(bookingId),
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
              pw.Spacer(),
              if (trackId != null && trackId.isNotEmpty)
                pw.Text('Track ID: ${_ascii(trackId)}',
                    style: pw.TextStyle(
                        fontSize: 11, color: PdfColors.white)),
            ]),
          ),
          pw.SizedBox(height: 16),

          // ── Visa Details ──
          _sectionTitle('VISA DETAILS'),
          pw.SizedBox(height: 6),
          _infoTable(W, [
            ['Destination', _ascii(destination)],
            ['Visa Type', _ascii(visaType)],
            ['Stay / Validity', _ascii(visaStay)],
            ['No. of Applicants', '$count'],
            ['Travel Date', travelDate],
            ['Return Date', returnDate],
          ]),
          pw.SizedBox(height: 16),

          // ── Trip Details ──
          _sectionTitle('TRIP DETAILS'),
          pw.SizedBox(height: 6),
          _infoTable(W, [
            ['Contact Email', _ascii(trip.email.trim())],
            ['Contact Phone', _ascii(trip.phone.trim())],
            if (trip.arrivalFlight.isNotEmpty)
              ['Arrival Flight', _ascii(trip.arrivalFlight)],
            if (trip.departureFlight.isNotEmpty)
              ['Departure Flight', _ascii(trip.departureFlight)],
            if (trip.hotel.isNotEmpty)
              ['Hotel', _ascii(trip.hotel)],
            if (trip.location.isNotEmpty)
              ['Location', _ascii(trip.location)],
          ]),
          pw.SizedBox(height: 16),

          // ── Traveller Details ──
          _sectionTitle('TRAVELLER DETAILS'),
          pw.SizedBox(height: 6),
          _travellersTable(travellers, W),
          pw.SizedBox(height: 20),

          // ── Payment Breakdown ──
          _sectionTitle('PAYMENT BREAKDOWN'),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _c(_divider), width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(children: [
              _payRow('Visa Fee (per applicant)', 'Rs.${money.format(visaFeeInr.round())}'),
              _payRow('No. of Applicants', 'x $count'),
              _payRow('Subtotal (Visa Fee)', 'Rs.${money.format(baseFare.round())}'),
              pw.Divider(color: _c(_divider), thickness: 0.5),
              if (insuranceDays != null && insuranceDays > 0)
                _payRow('Travel Insurance ($insuranceDays days)', 'Rs.${money.format(taxes.round())}')
              else
                _payRow('Taxes & Fees', 'Rs.${money.format(taxes.round())}'),
              pw.Divider(color: _c(_divider), thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL PAID',
                      style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: _c(_navy))),
                  pw.Text('Rs.${money.format(totalInr.round())}',
                      style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: _c(_green))),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(children: [
                pw.Text('Payment Method: ',
                    style: pw.TextStyle(
                        fontSize: 9, color: _c(_textLight))),
                pw.Text(_ascii(paymentMode),
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _c(_textPrimary))),
                pw.Spacer(),
                pw.Text('Status: ',
                    style: pw.TextStyle(
                        fontSize: 9, color: _c(_textLight))),
                pw.Text('PAID',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _c(_green))),
              ]),
            ]),
          ),
          pw.SizedBox(height: 20),

          // ── Terms ──
          pw.Divider(color: _c(_divider)),
          pw.SizedBox(height: 8),
          pw.Text('TERMS AND CONDITIONS',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _c(_navy))),
          pw.SizedBox(height: 6),
          _para('1. This invoice is a confirmation of your visa application submission and payment. '
              'It does not guarantee visa approval, which is at the sole discretion of the embassy/consulate.'),
          _para('2. Processing times are indicative and may vary based on embassy workload and completeness of documents.'),
          _para('3. Visa fees are non-refundable once the application has been submitted to the embassy/consulate.'),
          _para('4. Please ensure all travel documents (passport, photographs, supporting documents) are valid and meet the requirements.'),
          _para('5. For any queries, contact us at info@thewandernova.com.'),
        ];
      },
    ));
    return pdf;
  }

  // ── Header ──
  static pw.Widget _header(pw.ImageProvider? logo, String bookingId) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _c(_divider), width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Image(logo, width: 130, height: 46, fit: pw.BoxFit.contain)
          else
            pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(
                    text: 'WANDER ',
                    style: pw.TextStyle(
                        color: _c(_blue),
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.TextSpan(
                    text: 'NOVA',
                    style: pw.TextStyle(
                        color: _c(_orange),
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Visa Application Invoice',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _c(_navy))),
              pw.SizedBox(height: 2),
              pw.Text(_ascii(bookingId),
                  style: pw.TextStyle(fontSize: 9, color: _c(_textLight))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ──
  static pw.Widget _footer(pw.Context context) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(color: _c(_navy)),
      child: pw.Row(children: [
        pw.Expanded(
          child: pw.Text(
            'WanderNova | Email: info@thewandernova.com',
            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.white),
          ),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 7.5, color: PdfColors.white),
        ),
      ]),
    );
  }

  // ── Helpers ──
  static pw.Widget _sectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _c(_navy)));
  }

  static pw.Widget _infoTable(double W, List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _c(_divider), width: 0.5),
      columnWidths: {
        0: pw.FixedColumnWidth(W * 0.35),
        1: pw.FixedColumnWidth(W * 0.65),
      },
      children: [
        for (final row in rows)
          pw.TableRow(children: [
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(10, 7, 6, 7),
              child: pw.Text(row[0],
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _c(_textSecondary))),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(10, 7, 6, 7),
              child: pw.Text(row[1],
                  style: pw.TextStyle(
                      fontSize: 9.5, color: _c(_textPrimary))),
            ),
          ]),
      ],
    );
  }

  static pw.Widget _travellersTable(
      List<VisaTravellerForm> travellers, double W) {
    final hdrStyle = pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white);
    final cellStyle = pw.TextStyle(fontSize: 8.5, color: _c(_textPrimary));

    pw.Widget hCell(String t) => pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Text(t, style: hdrStyle));
    pw.Widget dCell(String t) => pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Text(_ascii(t), style: cellStyle));

    return pw.Table(
      border: pw.TableBorder.all(color: _c(_blue), width: 0.5),
      columnWidths: {
        0: pw.FixedColumnWidth(W * 0.06),
        1: pw.FixedColumnWidth(W * 0.28),
        2: pw.FixedColumnWidth(W * 0.20),
        3: pw.FixedColumnWidth(W * 0.16),
        4: pw.FixedColumnWidth(W * 0.14),
        5: pw.FixedColumnWidth(W * 0.16),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _c(_blue)),
          children: [
            hCell('#'),
            hCell('Name'),
            hCell('Passport No.'),
            hCell('Date of Birth'),
            hCell('Gender'),
            hCell('Nationality'),
          ],
        ),
        for (int i = 0; i < travellers.length; i++)
          pw.TableRow(
            decoration: i.isEven
                ? null
                : const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF8FAFC)),
            children: [
              dCell('${i + 1}'),
              dCell(
                  '${travellers[i].title} ${travellers[i].firstName} ${travellers[i].lastName}'
                      .trim()),
              dCell(travellers[i].passportNo.toUpperCase()),
              dCell(travellers[i].dob != null
                  ? DateFormat('dd/MM/yyyy').format(travellers[i].dob!)
                  : '--'),
              dCell(travellers[i].gender),
              dCell(travellers[i].passportFrom),
            ],
          ),
      ],
    );
  }

  static pw.Widget _payRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 10, color: _c(_textSecondary))),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 10, color: _c(_textPrimary))),
        ],
      ),
    );
  }

  static pw.Widget _para(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 8.5,
              color: _c(_textSecondary),
              lineSpacing: 1.4)),
    );
  }
}
