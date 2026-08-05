import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/logo.dart';
import 'package:wander_nova/core/constants/urls.dart';
import 'package:wander_nova/core/network/dio_client.dart';
import 'package:wander_nova/injection_container.dart';
import '../../../../core/error/data_state.dart';
import '../../../AKHotelRetrieveBooking/domain/entity/AKHotelRetrieveBooking_entity.dart';
import '../../../AKHotelRetrieveBooking/domain/usecase/AKHotelRetrieveBooking_usecase.dart';
import '../../../AKHotelStartPay/domain/entity/AKHotelStartPay_entity.dart';
import '../../../AKHotelStartPay/domain/usecase/AKHotelStartPay_usecase.dart';
import '../../../wallet/data/data_source/wallet_api_service.dart';
import 'ak_hotel_booking_confirmed_screen.dart';

/// Payment step for the Akbar Hotels flow: this app's own gateway (Razorpay
/// or wallet), NOT an Akbar call — exactly like the flight flow. The
/// payment reference recorded here is handed to StartPay, which looks it up
/// and refuses to book without a settled transaction against it. StartPay
/// is the only irreversible call in the whole chain, so it's called once
/// (not retried blindly) — a timeout is resolved by reading the truth back
/// via RetrieveBooking, not by calling StartPay again.
class AkHotelPaymentScreen extends StatefulWidget {
  final String transactionId;
  final double netAmount;
  final String hotelName;
  final String checkIn;
  final String checkOut;
  final String searchTracingKey;

  const AkHotelPaymentScreen({
    super.key,
    required this.transactionId,
    required this.netAmount,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
    required this.searchTracingKey,
  });

  @override
  State<AkHotelPaymentScreen> createState() => _AkHotelPaymentScreenState();
}

class _AkHotelPaymentScreenState extends State<AkHotelPaymentScreen> {
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _pageBg = Color(0xFFF3F6FC);

  late final Razorpay _razorpay;
  bool _processing = false;
  String _statusMessage = '';
  String? _errorMessage;
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() => _errorMessage = 'Please select a payment method');
      return;
    }
    if (_selectedPaymentMethod == 'wallet') {
      await _payWithWallet();
      return;
    }
    await _initiatePayment();
  }

  Future<void> _payWithWallet() async {
    setState(() {
      _processing = true;
      _errorMessage = null;
      _statusMessage = 'Checking wallet balance...';
    });

    try {
      final response = await sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;

      if (!mounted) return;

      if (balance >= widget.netAmount) {
        await _runStartPay(gateway: 'wallet', paymentReference: widget.transactionId);
      } else {
        setState(() {
          _processing = false;
          _errorMessage = 'Insufficient wallet balance (₹${balance.toStringAsFixed(2)} available)';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not fetch wallet balance. Please try again.';
      });
      print('Hotel wallet balance error: $e');
    }
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _processing = true;
      _errorMessage = null;
      _statusMessage = 'Opening secure payment...';
    });

    try {
      final dio = sl<DioClient>().instance;
      // reference_id must equal the itinerary TransactionID so hotel
      // StartPay's payment guard can look up this exact paid transaction.
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': widget.netAmount,
          'currency': 'INR',
          'reference_id': widget.transactionId,
        },
      );

      final orderId = response.data['order_id'] as String?;
      final keyId = response.data['key_id'] as String?;
      print("Razorpay Key: $keyId");

      if (!mounted) return;
      setState(() => _processing = false);

      _razorpay.open({
        'key': keyId ?? '',
        'amount': (widget.netAmount * 100).toInt(),
        'currency': 'INR',
        'name': 'WanderNova',
        'description': 'Hotel booking: ${widget.hotelName}',
        'order_id': orderId ?? '',
        'theme': {'color': '#1769F6'},
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not create payment order. Please try again.';
      });
      print('Hotel Razorpay order error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not start payment: $e';
      });
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() {
      _processing = true;
      _statusMessage = 'Verifying payment...';
      _errorMessage = null;
    });

    try {
      final dio = sl<DioClient>().instance;
      final verifyResponse = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'reference_id': widget.transactionId,
        },
      );

      if (!mounted) return;

      if (verifyResponse.data['success'] == true) {
        await _runStartPay(gateway: 'razorpay', paymentReference: widget.transactionId);
      } else {
        setState(() {
          _processing = false;
          _errorMessage = 'Payment verification failed. Please contact support.';
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not verify payment. Please contact support.';
      });
      print('Hotel Razorpay verify error: ${e.message}');
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _errorMessage = 'Payment failed: ${response.message ?? 'Please try again.'}';
    });
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    print('Hotel Razorpay external wallet: ${response.walletName}');
  }

  Future<void> _runStartPay({required String gateway, required String paymentReference}) async {
    setState(() {
      _processing = true;
      _statusMessage = 'Confirming your booking...';
    });

    final result = await sl<AkHotelStartPayUseCase>().call(
      AkHotelStartPayRequestEntity(
        transactionId: widget.transactionId,
        netAmount: widget.netAmount,
        paymentAmount: widget.netAmount,
        paymentReference: paymentReference,
        gateway: gateway,
        searchTracingKey: widget.searchTracingKey,
      ),
    );

    if (!mounted) return;

    if (result is DataSuccess<AkHotelStartPayEntity> && result.data!.isBooked) {
      await _retrieveBookingAndNavigate(result.data!);
      return;
    }

    // Payment has already been captured by this point (Razorpay charged, or
    // wallet balance treated as debited) — StartPay refusing here does NOT
    // mean the customer wasn't charged, so the message always carries the
    // Transaction ID they'll need for support to reconcile it.
    final reason = result is DataFailed<AkHotelStartPayEntity>
        ? (result.error?.message ?? 'booking confirmation failed')
        : 'booking confirmation failed';
    setState(() {
      _processing = false;
      _errorMessage =
          'Payment received, but the booking could not be confirmed yet ($reason). '
          'Please contact support with Transaction ID ${widget.transactionId} — do not pay again.';
    });
  }

  /// RetrieveBooking is read-only and safe to call any time — used here to
  /// enrich the confirmation screen, not to decide success (StartPay's own
  /// isBooked already did that).
  Future<void> _retrieveBookingAndNavigate(AkHotelStartPayEntity startPay) async {
    final result = await sl<AkHotelRetrieveBookingUseCase>().call(
      AkHotelRetrieveBookingRequestEntity(referenceNumber: widget.transactionId),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelBookingConfirmedScreen(
          hotelName: widget.hotelName,
          transactionId: widget.transactionId,
          crsPnr: startPay.crsPnr,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          booking: result is DataSuccess<AkHotelRetrieveBookingEntity> ? result.data : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: _pageBg,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: context.scrollPhysics,
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: context.hp(4)),
              Container(
                padding: EdgeInsets.all(context.w(16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(14)),
                  border: Border.all(color: const Color(0xffE6ECFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hotelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: const Color(0xff6B7280), fontSize: context.fs(12), fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: context.h(4)),
                    Text('Total Payable', style: TextStyle(color: const Color(0xff6B7280), fontSize: context.fs(12), fontWeight: FontWeight.w600)),
                    SizedBox(height: context.h(4)),
                    Text(
                      '₹${widget.netAmount.toStringAsFixed(2)}',
                      style: TextStyle(color: _navy, fontSize: context.fs(24), fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.hp(3)),
              if (_processing) ...[
                const Center(child: CircularProgressIndicator(color: _blue)),
                SizedBox(height: context.h(12)),
                Center(
                  child: Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff4B5563), fontSize: context.fs(13))),
                ),
              ] else ...[
                if (_errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(context.w(12)),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF2F2),
                      borderRadius: BorderRadius.circular(context.r(10)),
                      border: Border.all(color: const Color(0xffFCA5A5)),
                    ),
                    child: Text(_errorMessage!, style: TextStyle(color: const Color(0xffB42318), fontSize: context.fs(12))),
                  ),
                  SizedBox(height: context.h(16)),
                ],
                _paymentMethodSection(context),
                SizedBox(height: context.h(16)),
                SizedBox(
                  height: context.buttonHeight + 10,
                  child: ElevatedButton(
                    onPressed: _selectedPaymentMethod == null ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      disabledBackgroundColor: const Color(0xffD1D5DB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(18))),
                    ),
                    child: Text(
                      _selectedPaymentMethod == null ? 'Select a payment method' : 'Pay Now',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: context.bodyLarge),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentMethodSection(BuildContext context) {
    const methods = [
      {'id': 'wallet', 'name': 'My Wallet', 'subtitle': 'Pay using your wallet balance', 'icon': Icons.account_balance_wallet},
      {'id': 'razorpay', 'name': 'Razorpay', 'subtitle': 'Cards, UPI, Net Banking, Wallets', 'icon': Icons.payment},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Payment Method', style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.bold, color: _navy)),
        SizedBox(height: context.h(10)),
        for (final method in methods) ...[
          _paymentMethodTile(
            context,
            id: method['id'] as String,
            name: method['name'] as String,
            subtitle: method['subtitle'] as String,
            icon: method['icon'] as IconData,
          ),
          SizedBox(height: context.h(8)),
        ],
      ],
    );
  }

  Widget _paymentMethodTile(BuildContext context, {required String id, required String name, required String subtitle, required IconData icon}) {
    final isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedPaymentMethod = isSelected ? null : id;
        _errorMessage = null;
      }),
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: isSelected ? _blue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: isSelected ? _blue : const Color(0xffE6ECFF), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.w(20), color: isSelected ? _blue : const Color(0xff6B7280)),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w600, color: _navy)),
                  Text(subtitle, style: TextStyle(fontSize: context.fs(10.5), color: const Color(0xff6B7280))),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: _blue, size: context.w(20)),
          ],
        ),
      ),
    );
  }
}
