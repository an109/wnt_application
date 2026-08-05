// flights/Screen/flight_booking_detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/services/pdf_generator.dart';
import '../domain/entities/FlightBookEntity.dart';
import 'Flight_Invoice_widget.dart';
import 'Flight_Ticket_widget.dart';
import 'flight_pdf_builder.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class FlightBookingDetailsScreen extends StatefulWidget {
  final FlightBookEntity booking;

  const FlightBookingDetailsScreen({super.key, required this.booking});

  @override
  State<FlightBookingDetailsScreen> createState() =>
      _FlightBookingDetailsScreenState();
}

class _FlightBookingDetailsScreenState
    extends State<FlightBookingDetailsScreen> {
  String _selectedView = 'ticket';
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildToggleBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(12), vertical: context.h(8)),
                child: _selectedView == 'ticket'
                    ? FlightTicketWidget(booking: widget.booking)
                    : FlightInvoiceWidget(booking: widget.booking),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Flight Details',
        style: TextStyle(
          fontSize: context.fs(18),
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: EdgeInsets.only(right: context.w(8)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: IconButton(
            icon: _isDownloading
                ? SizedBox(
              width: context.w(20),
              height: context.w(20),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _isDownloading ? null : _handleDownload,
          ),
        ),
      ],
    );
  }

  // Future<void> _handleDownload() async {
  //   setState(() => _isDownloading = true);
  //
  //   try {
  //     final type = _selectedView;
  //     final filename = '${type}_${widget.booking.pnr}.pdf';
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Row(
  //           children: [
  //             SizedBox(
  //               width: context.w(20),
  //               height: context.w(20),
  //               child: const CircularProgressIndicator(
  //                   color: Colors.white, strokeWidth: 2),
  //             ),
  //             SizedBox(width: context.w(12)),
  //             const Text('Generating PDF...'),
  //           ],
  //         ),
  //         backgroundColor: AppColors.primary,
  //         behavior: SnackBarBehavior.floating,
  //         duration: const Duration(seconds: 5),
  //       ),
  //     );
  //
  //     // Build a native, text-based PDF that mirrors the on-screen layout
  //     // instead of capturing a screenshot of the widget.
  //     final pdf = type == 'ticket'
  //         ? FlightPdfBuilder.buildTicket(widget.booking)
  //         : FlightPdfBuilder.buildInvoice(widget.booking);
  //
  //     final file = await PDFService.savePDF(pdf, filename);
  //
  //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //     _showDownloadSuccessDialog(context, file);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Download failed: $e'),
  //         backgroundColor: Colors.red,
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //   } finally {
  //     setState(() => _isDownloading = false);
  //   }
  // }
  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);

    try {
      final type = _selectedView;
      final filename = '${type}_${widget.booking.pnr}.pdf';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            SizedBox(width: context.w(20), height: context.w(20), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: context.w(12)),
            const Text('Generating PDF...'),
          ]),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );

      // Load Wander Nova logo for PDF
      pw.ImageProvider? logoImage;
      try {
        final ByteData data = await rootBundle.load('assets/images/wander_logo.png');
        logoImage = pw.MemoryImage(data.buffer.asUint8List());
      } catch (e) {
        debugPrint('Logo load failed, using fallback: $e');
      }

      final pdf = type == 'ticket'
          ? FlightPdfBuilder.buildTicket(booking: widget.booking, logo: logoImage)
          : FlightPdfBuilder.buildInvoice(booking: widget.booking, logo: logoImage);

      final file = await PDFService.savePDF(pdf, filename);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showDownloadSuccessDialog(context, file);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  void _showDownloadSuccessDialog(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: context.w(24)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(18)),
          ),
          child: Padding(
            padding: EdgeInsets.all(context.w(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: context.w(70),
                  width: context.w(70),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: context.w(42),
                  ),
                ),
                SizedBox(height: context.h(16)),
                Text(
                  'Download Complete',
                  style: TextStyle(
                    fontSize: context.fs(18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.h(10)),
                Text(
                  file.path.split('/').last,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: context.h(24)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await PDFService.printPDF(file);
                        },
                        icon: Icon(Icons.print, size: context.w(18)),
                        label: const Text('Print'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: context.h(12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(10)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await PDFService.sharePDF(file);
                        },
                        icon: Icon(
                          Icons.share,
                          size: context.w(18),
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Share',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: context.h(12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(6)),
      padding: EdgeInsets.all(context.w(3)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildToggleOption(
              'ticket', 'Ticket', Icons.confirmation_number_rounded, context),
          _buildToggleOption(
              'invoice', 'Invoice', Icons.receipt_long_rounded, context),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
      String value, String label, IconData icon, BuildContext context) {
    bool isSelected = _selectedView == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.h(8)),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [AppColors.primary, Color(0xFF0077CC)],
            )
                : null,
            borderRadius: BorderRadius.circular(context.r(8)),
            color: isSelected ? null : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: context.w(16),
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              SizedBox(width: context.w(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}