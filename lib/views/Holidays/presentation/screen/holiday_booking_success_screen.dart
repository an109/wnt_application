import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../home/presentation/screens/home_screen.dart';

const Color _kAccent = Color(0xffFF3B3B);
const Color _kInk = Color(0xff1A1A2E);
const Color _kSuccessGreen = Color(0xff10B981);

/// Shown after a successful holiday package payment. There is no holiday
/// booking backend yet, so this simply confirms the payment and lets the
/// user head back home.
class HolidayBookingSuccessScreen extends StatelessWidget {
  final String packageTitle;
  final String packageLocation;
  final int travellersCount;
  final String amountPaidDisplay;
  final String bookingReference;

  const HolidayBookingSuccessScreen({
    super.key,
    required this.packageTitle,
    required this.packageLocation,
    required this.travellersCount,
    required this.amountPaidDisplay,
    required this.bookingReference,
  });

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: Padding(
            padding: context.responsivePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: context.w(80),
                  height: context.w(80),
                  decoration: BoxDecoration(
                    color: _kSuccessGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: _kSuccessGreen, size: context.w(56)),
                ),
                SizedBox(height: context.h(20)),
                Text(
                  'Payment Successful!',
                  style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.bold, color: _kInk),
                ),
                SizedBox(height: context.h(8)),
                Text(
                  'Your holiday package payment has been received.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade600),
                ),
                SizedBox(height: context.h(24)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.w(16)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.r(12)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(packageTitle,
                          style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w700, color: _kInk)),
                      if (packageLocation.isNotEmpty) ...[
                        SizedBox(height: context.h(4)),
                        Text(packageLocation, style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600)),
                      ],
                      Divider(height: context.h(24)),
                      _row(context, 'Travellers', '$travellersCount'),
                      SizedBox(height: context.h(8)),
                      _row(context, 'Amount Paid', amountPaidDisplay, bold: true),
                      SizedBox(height: context.h(8)),
                      _row(context, 'Reference ID', bookingReference),
                    ],
                  ),
                ),
                SizedBox(height: context.h(24)),
                Text(
                  'Our team will contact you shortly to confirm your itinerary details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600),
                ),
                SizedBox(height: context.h(28)),
                SizedBox(
                  width: double.infinity,
                  height: context.buttonHeight + 10,
                  child: ElevatedButton(
                    onPressed: () => _goHome(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
                    ),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(bold ? 13 : 12),
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: bold ? _kAccent : _kInk,
            ),
          ),
        ),
      ],
    );
  }
}
