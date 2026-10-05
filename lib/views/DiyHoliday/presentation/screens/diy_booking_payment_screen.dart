import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import 'diy_booking_confirmed_screen.dart';

/// Paying one instalment of a DIY booking on Razorpay's hosted page.
///
/// The page is Razorpay's own — UPI, cards, net banking, wallets — opened from
/// the link **POST /bookings/{id}/pay/** returned. Whether the money arrived
/// is never taken from the page: the screen asks the booking (**POST
/// /bookings/{id}/sync/**) every few seconds, which records anything Razorpay
/// has captured, and moves on to the confirmation only once the booking says
/// it has been paid.
class DiyBookingPaymentScreen extends StatefulWidget {
  final DiyBooking booking;
  final DiyPaymentLink link;
  final String packageTitle;
  final String destination;
  final DateTime? departureDate;
  final int nights;
  final int travellers;

  const DiyBookingPaymentScreen({
    super.key,
    required this.booking,
    required this.link,
    required this.packageTitle,
    required this.destination,
    required this.departureDate,
    required this.nights,
    required this.travellers,
  });

  @override
  State<DiyBookingPaymentScreen> createState() =>
      _DiyBookingPaymentScreenState();
}

class _DiyBookingPaymentScreenState extends State<DiyBookingPaymentScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();
  late final WebViewController _web;
  Timer? _poll;
  bool _loadingPage = true;
  bool _checking = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loadingPage = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.link.shortUrl));
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Asks the booking whether this payment has landed.
  Future<bool> _check() async {
    if (_checking || _done) return _done;
    _checking = true;
    try {
      final now = await _api.syncBooking(widget.booking.bookingId);
      if (now.amountPaid > widget.booking.amountPaid && mounted) {
        _finish(now);
        return true;
      }
    } catch (_) {
      // A missed poll is nothing; the next one asks again.
    } finally {
      _checking = false;
    }
    return false;
  }

  void _finish(DiyBooking paid) {
    if (_done) return;
    _done = true;
    _poll?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DiyBookingConfirmedScreen(
          packageTitle: widget.packageTitle,
          destination: widget.destination,
          departureDate: widget.departureDate,
          nights: widget.nights,
          travellers: widget.travellers,
          amount: paid.amountPaid - widget.booking.amountPaid,
          currency: paid.currency,
          paymentReference: paid.reference,
          paymentId: '',
          enquiryReference: paid.balance > 0
              ? 'Balance ${diyMoney(paid.balance, currency: paid.currency)}'
                  '${paid.balanceDueOn.isEmpty ? '' : ' due by ${diyDayDate(paid.balanceDueOn)}'}'
              : null,
        ),
      ),
    );
  }

  /// Closing the page checks once more — a customer who paid and tapped back
  /// straight away still gets their confirmation.
  Future<void> _close() async {
    setState(() => _checking = false);
    final paid = await _check();
    if (!paid && mounted) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Leave payment?'),
          content: const Text(
            'We have not received this payment yet. If you have just paid, wait '
            'a few seconds — it will show up here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (leave == true && mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.black, size: context.w(22)),
            onPressed: _close,
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay ${diyMoney(widget.link.amount, currency: widget.link.currency)}',
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                'Booking ${widget.booking.reference} · secured by Razorpay',
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: DiyTokens.subGrey,
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _web),
            if (_loadingPage)
              const DiyLoading(message: 'Opening secure payment…'),
          ],
        ),
      ),
    );
  }
}
