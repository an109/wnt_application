import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/views/flight_payment/data/razorpay_custom_checkout_service.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/card_form.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/checkout_ui.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/method_sections.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/upi_section.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_traveller.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import 'diy_booking_confirmed_screen.dart';
import 'diy_booking_payment_screen.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

/// Figma `Payment option Holiday 1` — paying one instalment of a holiday
/// booking inside the app.
///
/// The same seamless checkout the flight payment screen uses: Razorpay Custom
/// Checkout through [RazorpayCustomCheckoutService], with the shared method
/// sections (UPI, card, net banking, EMI, wallets & pay later) — no hosted
/// page. The money goes to the **DIY booking**: the DIY backend creates the
/// order for the instalment (POST /bookings/{id}/order/), so the amount is
/// fixed server-side, and checks Razorpay's signature and records what was
/// captured (POST /bookings/{id}/verify/).
///
/// On a device the native SDK does not support, it falls back to the hosted
/// payment page ([DiyBookingPaymentScreen]).
class DiyHolidayPaymentScreen extends StatefulWidget {
  final DiyBooking booking;
  final DiyInstalment instalment;
  final String packageTitle;
  final String origin;
  final String destination;
  final DateTime? departureDate;
  final int nights;
  final List<DiyTraveller> travellers;

  const DiyHolidayPaymentScreen({
    super.key,
    required this.booking,
    required this.instalment,
    required this.packageTitle,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.nights,
    required this.travellers,
  });

  @override
  State<DiyHolidayPaymentScreen> createState() =>
      _DiyHolidayPaymentScreenState();
}

class _DiyHolidayPaymentScreenState extends State<DiyHolidayPaymentScreen> {
  static const _stroke = Color(0xFFE6E8EC);
  static const _muted = AppColors.subhead;

  /// A UI guard only, as on the flight screen: past it the customer goes back
  /// and re-opens the booking rather than paying against a stale screen.
  static const _holdDuration = Duration(minutes: 15);

  final DiyHolidayApi _api = sl<DiyHolidayApi>();
  final _rz = RazorpayCustomCheckoutService();
  late final Future<List<UpiApp>> _upiApps = _rz.getUpiApps().catchError(
    (_) => <UpiApp>[],
  );

  Timer? _timer;
  Duration _left = _holdDuration;
  bool get _expired => _left <= Duration.zero;

  DiyCheckoutOrder? _order;
  Future<Map<String, dynamic>>? _methods;
  String? _open;
  bool _processing = false;
  String _status = '';
  String? _error;

  double get _amount => widget.instalment.payNow;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final next = _left - const Duration(seconds: 1);
      setState(() => _left = next.isNegative ? Duration.zero : next);
      if (_expired) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------- the order

  /// Made the first time any method is used, then reused: one order takes
  /// one payment, so switching from card to UPI must not create another.
  Future<bool> _ensureOrder() async {
    if (_order != null) return true;
    setState(() {
      _processing = true;
      _status = 'Preparing payment...';
      _error = null;
    });
    try {
      final order = await _api.createBookingOrder(
        bookingId: widget.booking.bookingId,
        percent: widget.instalment.percent,
      );
      if (!mounted) return false;
      setState(() {
        _order = order;
        _processing = false;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _processing = false;
        _error = 'Could not start the payment. ${e.toString()}';
      });
      return false;
    }
  }

  Future<Map<String, dynamic>> _loadMethods() {
    return _methods ??=
        () async {
          if (!await _ensureOrder()) throw Exception('order');
          return _rz.getPaymentMethods(keyId: _order!.keyId);
        }().catchError((Object e) {
          _methods = null;
          throw e;
        });
  }

  void _toggle(String id) => setState(() => _open = _open == id ? null : id);

  // ---------------------------------------------------------------- paying

  Future<void> _pay(Map<String, dynamic> method) async {
    if (_expired || _processing) return;
    FocusScope.of(context).unfocus();

    if (!_rz.isSupported) {
      await _hostedFallback();
      return;
    }
    if (!await _ensureOrder() || !mounted) return;
    final order = _order!;

    setState(() {
      _processing = true;
      _status = 'Complete the payment to continue...';
      _error = null;
    });
    try {
      final result = await _rz.submitPayment(
        keyId: order.keyId,
        data: {
          'amount': order.amountPaise,
          'currency': order.currency,
          'order_id': order.orderId,
          'email': order.email,
          'contact': order.contact,
          'description': order.description,
          ...method,
        },
      );
      await _verify(
        orderId: result.orderId ?? order.orderId,
        paymentId: result.paymentId,
        signature: result.signature ?? '',
      );
    } on RazorpayCustomCheckoutException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      if (e.message.toLowerCase().contains('cancel')) {
        diySnack(context, 'Payment cancelled. You can try again.');
      } else {
        setState(() => _error = e.message);
      }
    }
  }

  Future<void> _payWithGooglePay() async {
    if (_expired || _processing) return;
    final apps = await _upiApps;
    final gpay = apps.where((a) => a.isGooglePay).firstOrNull;
    if (!mounted) return;
    if (gpay == null) {
      diySnack(context, "Google Pay isn't installed. Try another UPI app.");
      setState(() => _open = 'upi');
      return;
    }
    await _pay({
      'method': 'upi',
      '_[flow]': 'intent',
      'upi_app_package_name': gpay.package,
    });
  }

  /// The DIY backend checks the signature and records what Razorpay
  /// captured. If the money has not shown up yet, it asks a few more times —
  /// a captured payment is recorded by the webhook or the sync either way.
  Future<void> _verify({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    setState(() {
      _processing = true;
      _status = 'Verifying payment...';
    });
    final before = widget.booking.amountPaid;
    try {
      var booking = await _api.verifyBookingPayment(
        bookingId: widget.booking.bookingId,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      for (var i = 0; i < 5 && booking.amountPaid <= before; i++) {
        await Future.delayed(const Duration(seconds: 3));
        booking = await _api.syncBooking(widget.booking.bookingId);
      }
      if (!mounted) return;
      if (booking.amountPaid > before) {
        _confirmed(booking, paymentId);
      } else {
        setState(() {
          _processing = false;
          _error =
              'We have your payment ($paymentId) but could not confirm it '
              'yet. It will show on your booking ${booking.reference} shortly — '
              'please do not pay again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error =
            'Could not verify the payment ($paymentId). Please contact '
            'support with booking ${widget.booking.reference} — do not pay again.';
      });
    }
  }

  void _confirmed(DiyBooking paid, String paymentId) {
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DiyBookingConfirmedScreen(
          packageTitle: widget.packageTitle,
          destination: widget.destination,
          departureDate: widget.departureDate,
          nights: widget.nights,
          travellers: widget.travellers.length,
          amount: paid.amountPaid - widget.booking.amountPaid,
          currency: paid.currency,
          paymentReference: paid.reference,
          paymentId: paymentId,
          enquiryReference: paid.balance > 0
              ? 'Balance ${diyMoney(paid.balance, currency: paid.currency)}'
                    '${paid.balanceDueOn.isEmpty ? '' : ' due by ${diyDayDate(paid.balanceDueOn)}'}'
              : null,
        ),
      ),
    );
  }

  /// No native checkout on this device: Razorpay's hosted page instead.
  Future<void> _hostedFallback() async {
    setState(() {
      _processing = true;
      _status = 'Opening secure payment...';
    });
    try {
      final link = await _api.payBooking(
        bookingId: widget.booking.bookingId,
        percent: widget.instalment.percent,
      );
      if (!mounted) return;
      setState(() => _processing = false);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiyBookingPaymentScreen(
            booking: widget.booking,
            link: link,
            packageTitle: widget.packageTitle,
            destination: widget.destination,
            departureDate: widget.departureDate,
            nights: widget.nights,
            travellers: widget.travellers.length,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          _error = e.toString();
        });
      }
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(bottom: context.h(32)),
                  children: [
                    _summary(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.w(14),
                        context.h(20),
                        context.w(14),
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _processing
                            ? [_processingCard()]
                            : _methodsList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final minutes = _left.inMinutes.toString().padLeft(2, '0');
    final seconds = (_left.inSeconds % 60).toString().padLeft(2, '0');
    final timerColor = _expired ? const Color(0xffB42318) : AppColors.AppBlue;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(14),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _processing ? null : () => Navigator.of(context).maybePop(),
            child: Image.asset(
              'assets/NewIcons/arrowBack.png',
              width: context.w(15),
              height: context.h(15),
              color: Colors.black,
            ),
          ),
          SizedBox(width: context.w(15)),
          Expanded(
            child: Text(
              'Payment',
              style: TextStyle(
                fontSize: context.fs(18),
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Icon(Icons.timer_rounded, size: context.w(15), color: timerColor),
          SizedBox(width: context.w(4)),
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w500,
              color: timerColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Total Due, the route, and the package with its travellers — on a white
  /// panel with rounded bottom corners and a soft shadow, as in the design.
  Widget _summary() {
    final start = widget.departureDate;
    final end = start == null ? null : start.add(Duration(days: widget.nights));
    final dates = start == null
        ? ''
        : '${DateFormat('d MMM').format(start)} - '
              '${DateFormat('d MMM').format(end!)} | '
              '${widget.nights} Night${widget.nights == 1 ? '' : 's'} & '
              '${widget.nights + 1} Days';
    final lead = widget.travellers.isEmpty ? null : widget.travellers.first;
    final others = widget.travellers.length - 1;
    final leadLine = lead == null
        ? ''
        : '${lead.fullName.toUpperCase()}'
              '${lead.gender.isEmpty ? '' : ' (${lead.gender[0].toUpperCase()})'}'
              '${lead.age == null ? '' : ' ${lead.age}yrs'}'
              '${others > 0 ? ', +$others traveller${others == 1 ? '' : 's'}' : ''}';

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(8),
        context.w(14),
        context.h(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(context.r(22)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _amountDetails,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Due',
                        style: TextStyle(
                          fontSize: context.fs(17),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${widget.origin} → ${widget.destination}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(12),
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  diyMoney(_amount, currency: widget.booking.currency),
                  style: TextStyle(
                    fontSize: context.fs(19),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: context.w(4)),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: context.w(20),
                  color: AppColors.AppBlue,
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(14)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            child: Row(
              children: [
                Container(
                  width: context.w(34),
                  height: context.w(34),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(context.r(8)),
                  ),
                  child: Icon(
                    Icons.beach_access_rounded,
                    size: context.w(20),
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.packageTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(12.5),
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      if (dates.isNotEmpty)
                        Text(
                          dates,
                          style: TextStyle(
                            fontSize: context.fs(10),
                            color: _muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (leadLine.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(10),
              ),
              child: const Divider(height: 1, color: _stroke),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(8)),
              child: Text(
                leadLine,
                style: TextStyle(fontSize: context.fs(9.5), color: _muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// What this payment is: the share now, the total, the rest and its date.
  void _amountDetails() {
    final b = widget.booking;
    final i = widget.instalment;
    Widget line(String label, double value, {bool strong = false}) => Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(7)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fs(strong ? 14 : 12.5),
                fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            diyMoney(value, currency: b.currency),
            style: TextStyle(
              fontSize: context.fs(strong ? 16 : 12.5),
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              color: strong ? AppColors.AppBlue : Colors.black,
            ),
          ),
        ],
      ),
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(20)),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(18),
            context.h(18),
            context.w(18),
            context.h(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              line('Package total (incl. taxes)', b.grandTotal),
              if (b.amountPaid > 0) line('Already paid', b.amountPaid),
              if (i.balance > 0)
                line(
                  i.balanceDueOn.isEmpty
                      ? 'Remaining balance'
                      : 'Remaining balance (by ${diyDayDate(i.balanceDueOn)})',
                  i.balance,
                ),
              const Divider(color: _stroke),
              line(
                i.balance > 0 ? 'Pay now (${i.percent}%)' : 'Pay now',
                i.payNow,
                strong: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _methodsList() {
    return [
      if (_error != null) ...[
        _banner(_error!),
        SizedBox(height: context.h(14)),
      ],
      if (_expired) ...[
        _banner(
          'This payment session has timed out. Go back and continue from the '
          'review screen again.',
        ),
        SizedBox(height: context.h(14)),
      ],
      _label('Suggested options'),
      SizedBox(height: context.h(10)),
      _googlePayTile(),
      SizedBox(height: context.h(8)),
      CheckoutAccordion(
        title: 'UPI Options',
        subtitle: 'Pay Directly From Your Bank Account',
        badge: 'INSTANT',
        leading: const CheckoutIcon('assets/NewIcons/upi.png'),
        enabled: !_expired,
        expanded: _open == 'upi',
        onTap: () => _toggle('upi'),
        child: _open == 'upi'
            ? UpiSection(
                amount: _amount,
                busy: _processing,
                apps: _upiApps,
                onPayWithApp: (app) => _pay({
                  'method': 'upi',
                  '_[flow]': 'intent',
                  'upi_app_package_name': app.package,
                }),
                onPayWithVpa: (vpa) =>
                    _pay({'method': 'upi', '_[flow]': 'collect', 'vpa': vpa}),
              )
            : const SizedBox.shrink(),
      ),
      CheckoutAccordion(
        title: 'EMI',
        subtitle: 'Credit/Debit Card & Cardless EMI available',
        leading: _emiIcon(),
        enabled: !_expired,
        expanded: _open == 'emi',
        onTap: () => _toggle('emi'),
        child: _open == 'emi'
            ? EmiSection(
                amount: _amount,
                busy: _processing,
                methods: _loadMethods(),
                onPay: (months, card) => _pay({
                  'method': 'emi',
                  'emi_duration': months,
                  'card': card,
                }),
              )
            : const SizedBox.shrink(),
      ),
      SizedBox(height: context.h(10)),
      _label('Other Payment Options'),
      SizedBox(height: context.h(10)),
      CheckoutAccordion(
        title: 'Credit & Debit Cards',
        subtitle: 'Visa, Mastercard, Amex, Rupay and more',
        leading: const CheckoutIcon('assets/NewIcons/credit.png'),
        enabled: !_expired,
        expanded: _open == 'card',
        onTap: () => _toggle('card'),
        child: _open == 'card'
            ? CardForm(
                payLabel: 'Pay ${formatInr(_amount)}',
                busy: _processing,
                onSubmit: (card) => _pay({'method': 'card', 'card': card}),
              )
            : const SizedBox.shrink(),
      ),
      CheckoutAccordion(
        title: 'Net Banking',
        subtitle: 'All major banks available',
        leading: const CheckoutIcon('assets/NewIcons/net_banking.png'),
        enabled: !_expired,
        expanded: _open == 'netbanking',
        onTap: () => _toggle('netbanking'),
        child: _open == 'netbanking'
            ? NetbankingSection(
                amount: _amount,
                busy: _processing,
                methods: _loadMethods(),
                onPay: (bank) => _pay({'method': 'netbanking', 'bank': bank}),
              )
            : const SizedBox.shrink(),
      ),
      CheckoutAccordion(
        title: 'Pay Later & Wallets',
        subtitle: 'LazyPay, Simpl · Paytm, PhonePe, Amazon Pay & more',
        leading: const CheckoutIcon('assets/NewIcons/wallet.png'),
        enabled: !_expired,
        expanded: _open == 'wallet',
        onTap: () => _toggle('wallet'),
        child: _open == 'wallet'
            ? WalletsPayLaterSection(
                amount: _amount,
                busy: _processing,
                methods: _loadMethods(),
                onPayWallet: (w) => _pay({'method': 'wallet', 'wallet': w}),
                onPayLater: (p) => _pay({'method': 'paylater', 'provider': p}),
              )
            : const SizedBox.shrink(),
      ),
      SizedBox(height: context.h(14)),
      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: context.w(13), color: _muted),
            SizedBox(width: context.w(5)),
            Text(
              'Payments are secured by Razorpay',
              style: TextStyle(fontSize: context.fs(10.5), color: _muted),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: context.fs(14),
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
  );

  Widget _emiIcon() => Container(
    width: context.w(34),
    height: context.w(34),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(context.r(8)),
    ),
    child: Icon(
      Icons.calendar_month_rounded,
      size: context.w(20),
      color: const Color(0xFFF59E0B),
    ),
  );

  Widget _googlePayTile() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(14)),
        onTap: (_expired || _processing) ? null : _payWithGooglePay,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(14),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const CheckoutIcon('assets/NewIcons/gpay.png'),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GooglePay',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Pay with GooglePay',
                      style: TextStyle(
                        fontSize: context.fs(11.5),
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: context.w(20),
                color: AppColors.AppBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _processingCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: context.h(36)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke),
      ),
      child: AppLoadingView(message: _status),
    );
  }

  Widget _banner(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xffFEF2F2),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: const Color(0xffFCA5A5)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: context.fs(12),
          color: const Color(0xffB42318),
        ),
      ),
    );
  }
}
