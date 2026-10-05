import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../flight_payment/data/razorpay_custom_checkout_service.dart';
import '../../../flight_payment/presentation/screen/ak_custom_checkout_args.dart';
import '../../../flight_payment/presentation/screen/ak_unified_checkout_screen.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/diy_traveller.dart';
import '../widgets/diy_common.dart';
import 'diy_booking_confirmed_screen.dart';

/// Payment for a holiday booking.
///
/// The DIY API stops at the enquiry, so the money side runs entirely on the
/// app's own stack — the same one flights, hotels and transport already use:
///
///   1. `Urls.razorpayCreateOrder` mints an order (`transaction_type: holiday`)
///   2. [AkUnifiedCheckoutScreen] collects the method and charges it — this is
///      the Figma's "Payment option" screen, with EMI / GooglePay / UPI /
///      cards / net banking / Pay Later already built
///   3. `Urls.razorpayVerify` checks the signature server-side
///   4. `Urls.holidayBookings` records the booking
///   5. **API 15** submits the DIY enquiry so the consultant picks the trip up
///      with the customer's real details and the price they actually paid
///
/// Step 5 is deliberately last and deliberately non-fatal: the customer has
/// already paid by then, so a failing enquiry must never read as a failed
/// booking. It is reported to the confirmation screen instead, which tells
/// them a consultant will still be in touch.
class DiyPaymentScreen extends StatefulWidget {
  final String shareId;
  final String? tripId;
  final DiySearchQuery query;
  final bool withFlight;
  final List<String> addOnIds;
  final double amount;
  final String currency;
  final String packageTitle;
  final List<DiyTraveller> travellers;
  final String contactEmail;
  final String contactPhone;
  final int nights;
  final String destination;

  const DiyPaymentScreen({
    super.key,
    required this.shareId,
    required this.query,
    required this.withFlight,
    required this.addOnIds,
    required this.amount,
    required this.packageTitle,
    required this.travellers,
    required this.contactEmail,
    required this.contactPhone,
    this.tripId,
    this.currency = 'INR',
    this.nights = 0,
    this.destination = '',
  });

  @override
  State<DiyPaymentScreen> createState() => _DiyPaymentScreenState();
}

class _DiyPaymentScreenState extends State<DiyPaymentScreen> {
  bool _busy = false;
  String _status = '';
  String? _error;

  String? _orderId;
  String? _keyId;

  String get _leadName =>
      widget.travellers.isEmpty ? '' : widget.travellers.first.fullName;

  /// A stable id for this attempt, so a retry reuses the same order rather
  /// than creating a second one Razorpay would refuse to settle.
  late final String _reference =
      'DIY-${widget.shareId.split('-').first}-'
      '${DateTime.now().millisecondsSinceEpoch}';

  // ------------------------------------------------------------- 1. order

  Future<bool> _ensureOrder() async {
    if (_orderId != null && _keyId != null) return true;

    setState(() {
      _busy = true;
      _error = null;
      _status = 'Preparing payment…';
    });

    try {
      final dio = sl<DioClient>().instance;
      final userId = sl<PreferencesManager>().getUserId();
      final res = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': widget.amount,
          'currency': widget.currency,
          'reference_id': _reference,
          // Tells the backend's webhook reconciliation what this is for,
          // the same way hotels send 'hotel'.
          'transaction_type': 'holiday',
          if (userId != null) 'user_id': userId,
        },
      );

      final orderId = res.data['order_id'] as String?;
      final keyId = res.data['key_id'] as String?;
      if (!mounted) return false;

      if (orderId == null || keyId == null) {
        setState(() {
          _busy = false;
          _error = 'Could not create the payment order. Please try again.';
        });
        return false;
      }

      setState(() {
        _busy = false;
        _orderId = orderId;
        _keyId = keyId;
      });
      return true;
    } on DioException catch (_) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _error = 'Could not create the payment order. Please try again.';
      });
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _error = 'Could not start payment: $e';
      });
      return false;
    }
  }

  // --------------------------------------------------------- 2. checkout

  Future<void> _pay() async {
    if (_busy) return;
    if (!await _ensureOrder() || !mounted) return;

    final result = await Navigator.of(context)
        .push<RazorpayCustomPaymentResult>(
          MaterialPageRoute(
            builder: (_) => AkUnifiedCheckoutScreen(
              args: AkCustomCheckoutArgs(
                keyId: _keyId!,
                orderId: _orderId!,
                amountInInr: widget.amount,
                name: _leadName,
                email: widget.contactEmail,
                contact: widget.contactPhone,
                description: widget.packageTitle,
              ),
            ),
          ),
        );

    // Customer backed out of the method screen — not an error.
    if (result == null || !mounted) return;
    await _verifyAndRecord(result);
  }

  // ------------------------------------------ 3/4/5. verify, record, enquire

  Future<void> _verifyAndRecord(RazorpayCustomPaymentResult payment) async {
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Verifying payment…';
    });

    final dio = sl<DioClient>().instance;

    try {
      final verify = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': payment.orderId ?? _orderId,
          'razorpay_payment_id': payment.paymentId,
          'razorpay_signature': payment.signature,
          'reference_id': _reference,
        },
      );

      if (!mounted) return;
      if (verify.data is Map && verify.data['success'] != true) {
        setState(() {
          _busy = false;
          _error =
              'We could not verify this payment. Please contact support with '
              'reference $_reference.';
        });
        return;
      }
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'We could not verify this payment. Please contact support with '
            'reference $_reference.';
      });
      return;
    }

    // ---- record the booking (non-fatal: the charge already succeeded) ----
    setState(() => _status = 'Confirming your booking…');
    try {
      await dio.post(
        Urls.holidayBookings,
        data: {
          'package_share_id': widget.shareId,
          if (widget.tripId != null) 'trip_id': widget.tripId,
          'package_title': widget.packageTitle,
          'destination': widget.destination,
          'departure_date': _ymd(widget.query.departureDate),
          'nights': widget.nights,
          'adults': widget.query.adults,
          'children': widget.query.children,
          'rooms': widget.query.rooms,
          'flight': widget.withFlight ? 'with' : 'without',
          'add_on_ids': widget.addOnIds,
          'amount': widget.amount,
          'currency': widget.currency,
          'payment_reference': _reference,
          'razorpay_payment_id': payment.paymentId,
          'contact_email': widget.contactEmail,
          'contact_phone': widget.contactPhone,
          'travellers': widget.travellers.map((t) => t.toJson()).toList(),
        },
      );
    } catch (_) {
      // The payment stands. Support can reconcile from _reference.
    }

    // ---- hand the lead to a consultant (API 15) ----
    String? enquiryReference;
    var enquiryFailed = false;
    setState(() => _status = 'Notifying your consultant…');
    try {
      final date = widget.query.departureDate;
      if (date != null) {
        final enquiry = await sl<DiyHolidayApi>().submitEnquiry(
          shareId: widget.shareId,
          customerName: _leadName,
          customerPhone: widget.contactPhone,
          customerEmail: widget.contactEmail,
          departureDate: date,
          adults: widget.query.adults,
          children: widget.query.children,
          withFlight: widget.withFlight,
          addOnIds: widget.addOnIds,
          quotedTotal: widget.amount.toStringAsFixed(2),
          message: 'Paid in app. Payment reference $_reference.',
        );
        enquiryReference = enquiry.reference;
      }
    } catch (_) {
      enquiryFailed = true;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DiyBookingConfirmedScreen(
          packageTitle: widget.packageTitle,
          destination: widget.destination,
          departureDate: widget.query.departureDate,
          nights: widget.nights,
          travellers: widget.travellers.length,
          amount: widget.amount,
          currency: widget.currency,
          paymentReference: _reference,
          paymentId: payment.paymentId,
          enquiryReference: enquiryReference,
          consultantPending: enquiryFailed,
        ),
      ),
    );
  }

  static String _ymd(DateTime? d) {
    if (d == null) return '';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      appBar: diyAppBar(context, title: 'Payment'),
      body: _busy
          ? DiyLoading(message: _status)
          : ListView(
              padding: EdgeInsets.fromLTRB(
                context.w(14),
                context.h(14),
                context.w(14),
                context.h(24),
              ),
              children: [
                _totalCard(),
                if (_error != null) ...[
                  SizedBox(height: context.h(12)),
                  _errorCard(),
                ],
                SizedBox(height: context.h(16)),
                Text(
                  'You will choose how to pay on the next screen — UPI, cards, '
                  'net banking, EMI, wallets and Pay Later are all available.',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    height: 1.45,
                    color: DiyTokens.subGrey,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _busy ? null : _bottomBar(),
    );
  }

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Due',
                      style: TextStyle(
                        fontSize: context.fs(19),
                        fontWeight: FontWeight.w800,
                        color: DiyTokens.navy,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      '${widget.query.origin.name} → '
                      '${widget.destination.isEmpty ? 'Destination' : widget.destination}',
                      style: TextStyle(
                        fontSize: context.fs(11.5),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                diyMoney(widget.amount, currency: widget.currency),
                style: TextStyle(
                  fontSize: context.fs(21),
                  fontWeight: FontWeight.w800,
                  color: DiyTokens.navy,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          const Divider(height: 1, color: DiyTokens.line),
          SizedBox(height: context.h(12)),
          Text(
            widget.packageTitle,
            style: TextStyle(
              fontSize: context.fs(13.5),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
          SizedBox(height: context.h(3)),
          Text(
            '${widget.nights} Night${widget.nights == 1 ? '' : 's'} · '
            '${widget.travellers.length} Traveller'
            '${widget.travellers.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: context.fs(11),
              color: DiyTokens.subGrey,
            ),
          ),
          if (_leadName.isNotEmpty) ...[
            SizedBox(height: context.h(8)),
            Text(
              _leadName.toUpperCase(),
              style: TextStyle(
                fontSize: context.fs(10),
                letterSpacing: 0.3,
                color: DiyTokens.labelGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: context.w(17),
            color: const Color(0xFFD23B3B),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                fontSize: context.fs(11.5),
                height: 1.4,
                color: const Color(0xFFB02A2A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      minimum: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(8),
        context.w(16),
        context.h(12),
      ),
      child: SizedBox(
        height: context.h(48),
        child: ElevatedButton(
          onPressed: _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: DiyTokens.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(10)),
            ),
          ),
          child: Text(
            'CHOOSE PAYMENT METHOD',
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
