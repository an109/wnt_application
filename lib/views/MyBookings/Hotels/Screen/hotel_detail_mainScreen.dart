import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/services/pdf_generator.dart';
import '../domain/entity/HotelBookingEntity.dart';
import 'HotelTicket_widget.dart';
import 'hotel_pdf_builder.dart';


class HotelBookingDetailsScreen extends StatefulWidget {
  final HotelBookingListEntity booking;

  const HotelBookingDetailsScreen({super.key, required this.booking});

  @override
  State<HotelBookingDetailsScreen> createState() => _HotelBookingDetailsScreenState();
}

class _HotelBookingDetailsScreenState extends State<HotelBookingDetailsScreen> {
  static const _kInk = Color(0xFF111527);
  static const _kMuted = Color(0xFF757575);
  static const _kOrange = Color(0xFFEE7330);

  bool _isDownloading = false;

  String get _statusLabel {
    final s = widget.booking.status.toLowerCase();
    if (s.contains('cancelled')) return 'Cancelled';
    if (s.contains('confirmed')) return 'Confirmed';
    if (s.contains('pending')) return 'Pending';
    return widget.booking.status.isNotEmpty ? widget.booking.status : 'Pending';
  }

  Color get _statusColor {
    final s = widget.booking.status.toLowerCase();
    if (s.contains('cancelled')) return const Color(0xFF7CC7EE);
    if (s.contains('pending')) return const Color(0xFFFF9800);
    return AppColors.AppBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(8)),
                  child: HotelTicketWidget(booking: widget.booking),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(8), context.h(6), context.w(4), context.h(10)),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, size: context.w(24), color: _kInk),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hotel Details',
                      style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w600, color: _kInk),
                    ),
                    SizedBox(width: context.w(8)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(2)),
                      decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(context.r(20))),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(fontSize: context.fs(10.5), fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Booking ID: ${widget.booking.confirmationNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.fs(11), color: _kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.w(16), context.h(12), context.w(16), context.h(12)),
          child: FilledButton(
            onPressed: _isDownloading ? null : _handleDownload,
            style: FilledButton.styleFrom(
              backgroundColor: _kOrange,
              disabledBackgroundColor: const Color(0xFFF5C3A6),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
              minimumSize: Size.fromHeight(context.h(50)),
            ),
            child: _isDownloading
                ? SizedBox(
                    width: context.w(20),
                    height: context.w(20),
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded, size: context.w(18)),
                      SizedBox(width: context.w(8)),
                      Text(
                        'DOWNLOAD TICKET',
                        style: TextStyle(fontSize: context.fs(13.5), fontWeight: FontWeight.w600, letterSpacing: 0.2),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);

    try {
      final filename = 'ticket_${widget.booking.confirmationNumber}.pdf';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: context.w(20),
                height: context.w(20),
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              SizedBox(width: context.w(12)),
              const Text('Generating PDF...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );

      final pdf = await HotelPdfBuilder.buildTicket(widget.booking);

      final file = await PDFService.savePDF(pdf, filename);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showDownloadSuccessDialog(context, file);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
          insetPadding: EdgeInsets.symmetric(
            horizontal: context.w(24),
          ),
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
                    color: Colors.green.withValues(alpha: 0.1),
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
                        icon: Icon(
                          Icons.print,
                          size: context.w(18),
                        ),
                        label: const Text('Print'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: context.h(12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(context.r(10)),
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
                          padding: EdgeInsets.symmetric(
                            vertical: context.h(12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(context.r(10)),
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
}
