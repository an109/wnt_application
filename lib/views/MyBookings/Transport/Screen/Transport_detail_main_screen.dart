import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/services/pdf_generator.dart';
import '../domain/entity/MyBooking_entity.dart';
import 'Transport_Invoice_widget.dart';
import 'Transport_ticket_widget.dart';
import 'transport_pdf_builder.dart';


class BookingDetailsScreen extends StatefulWidget {
  final BookingEntity booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  String _displayCurrency = 'USD';
  bool _currencyInitialized = false;
  String _selectedView = 'ticket';
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _displayCurrency = CurrencyConverter.getPreferredCurrency();
    _currencyInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    bool isPending = booking.status.toLowerCase().contains('pending');
    bool isCancelled = booking.status.toLowerCase().contains('cancelled');
    Color statusColor = isPending
        ? const Color(0xFFFFA726)
        : (isCancelled ? const Color(0xFFE53935) : const Color(0xFF4CAF50));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildToggleBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                child: _selectedView == 'ticket'
                    ? BookingTicketWidget(booking: widget.booking)
                    : BookingInvoiceWidget(booking: widget.booking),
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
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: context.w(18),
            color: Colors.white
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Booking Details',
        style: TextStyle(
          fontSize: context.fs(16),
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
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

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);

    try {
      final type = _selectedView;
      final filename = '${type}_${widget.booking.confirmationNumber}.pdf';

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

      // Build a native, text-based PDF that mirrors the on-screen layout
      // instead of capturing a screenshot of the widget.
      final pdf = type == 'ticket'
          ? TransportPdfBuilder.buildTicket(widget.booking)
          : TransportPdfBuilder.buildInvoice(widget.booking);

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
          _buildToggleOption('ticket', 'Ticket', Icons.confirmation_number_rounded, context),
          _buildToggleOption('invoice', 'Invoice', Icons.receipt_long_rounded, context),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String value, String label, IconData icon, BuildContext context) {
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

  // --- HELPERS ---
  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(isoString);
      List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      String time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $time';
    } catch (e) {
      return isoString;
    }
  }

  String _getConvertedAmountText(BookingEntity booking) {
    if (!_currencyInitialized) {
      return '${CurrencyConverter.getSymbol(booking.currency)} ${booking.totalPrice}';
    }

    try {
      final originalAmount = double.tryParse(booking.totalPrice) ?? 0.0;
      final originalCurrency = booking.currency.toUpperCase();
      final targetCurrency = _displayCurrency;

      if (originalAmount == 0 && double.tryParse(booking.rawTotalPrice) != null) {
        final fallbackAmount = double.tryParse(booking.rawTotalPrice) ?? 0.0;
        final fallbackCurrency = booking.rawCurrency.toUpperCase();

        if (fallbackAmount > 0) {
          if (fallbackCurrency == targetCurrency) {
            return '${CurrencyConverter.getSymbol(targetCurrency)} ${fallbackAmount.toStringAsFixed(0)}';
          }
          final convertedAmount = CurrencyConverter.convert(
            amount: fallbackAmount,
            fromCurrency: fallbackCurrency,
            toCurrency: targetCurrency,
          );
          return '${CurrencyConverter.getSymbol(targetCurrency)} ${convertedAmount.toStringAsFixed(0)}';
        }
      }

      if (originalCurrency == targetCurrency) {
        return '${CurrencyConverter.getSymbol(originalCurrency)} ${originalAmount.toStringAsFixed(0)}';
      }

      final convertedAmount = CurrencyConverter.convert(
        amount: originalAmount,
        fromCurrency: originalCurrency,
        toCurrency: targetCurrency,
      );
      return '${CurrencyConverter.getSymbol(targetCurrency)} ${convertedAmount.toStringAsFixed(0)}';
    } catch (e) {
      print('Currency conversion error: $e');
      final fallbackAmount = double.tryParse(booking.rawTotalPrice) ?? double.tryParse(booking.totalPrice) ?? 0.0;
      final fallbackCurrency = booking.rawCurrency.isNotEmpty ? booking.rawCurrency : booking.currency;
      return '${CurrencyConverter.getSymbol(fallbackCurrency)} ${fallbackAmount.toStringAsFixed(0)}';
    }
  }
}