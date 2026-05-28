import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wander_nova/injection_container.dart' as di;
import 'package:wander_nova/views/Hotel_Payment/hotel_confirmation_screen.dart';
import '../../UI_helper/currency_converter.dart';
import '../../UI_helper/responsive_layout.dart';
import '../../common_widgets/logo.dart';
import '../../core/constants/urls.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/hotel_session_service.dart';
import '../../core/utils/storage/shared_preference.dart';

class HotelPaymentScreen extends StatefulWidget {
  final String bookingCode;
  final String hotelName;
  final String checkIn;
  final String checkOut;
  final String roomName;
  final double totalFare;
  final String currency;
  final String email;
  final String phone;
  final String guestTitle;
  final String guestFirstName;
  final String guestLastName;

  const HotelPaymentScreen({
    super.key,
    required this.bookingCode,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
    required this.roomName,
    required this.totalFare,
    required this.currency,
    required this.email,
    required this.phone,
    required this.guestTitle,
    required this.guestFirstName,
    required this.guestLastName,
  });

  @override
  State<HotelPaymentScreen> createState() => _HotelPaymentScreenState();
}

class _HotelPaymentScreenState extends State<HotelPaymentScreen> {
  late final Razorpay _razorpay;

  bool _isCreatingOrder = false;
  bool _isBooking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    print(' Payment Screen received - Amount: ${widget.totalFare}, Currency: ${widget.currency}');
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  bool get _isProcessing => _isCreatingOrder || _isBooking;

  String get _processingMessage {
    if (_isCreatingOrder) return 'Creating payment order...';
    if (_isBooking) return 'Confirming your hotel booking...';
    return '';
  }

// Get user's preferred currency (default: INR)
  String get _preferredCurrency {
    try {
      return di.sl<PreferencesManager>().getPreferredCurrency() ?? 'INR';
    } catch (_) {
      return 'INR'; // Default fallback
    }
  }

  // 🔹 Convert amount for DISPLAY only (payment still in INR)
  // Convert amount for DISPLAY only (payment still in INR)
  double _getDisplayAmount(double inrAmount) {
    final preferred = _preferredCurrency;
    if (preferred.toUpperCase() == 'INR') return inrAmount;

    try {
      // Convert INR → user's preferred currency
      return CurrencyConverter.convert(
        amount: inrAmount,
        fromCurrency: 'INR',
        toCurrency: preferred,
      );
    } catch (_) {
      // If conversion fails, return the original INR amount
      print('Currency conversion failed for $preferred, falling back to INR');
      return inrAmount;
    }
  }

  //  Format amount with correct symbol + Indian commas for INR
  String _formatDisplayAmount(double amount, String currency) {
    final code = currency.toUpperCase();
    final intAmount = amount.toInt();

    if (code == 'INR') return '₹${_indianFormat(intAmount)}';
    if (code == 'USD') return '\$${intAmount.toStringAsFixed(0)}';
    if (code == 'EUR') return '€${intAmount.toStringAsFixed(0)}';
    if (code == 'GBP') return '£${intAmount.toStringAsFixed(0)}';
    if (code == 'AED') return 'د.إ ${intAmount.toStringAsFixed(0)}';

    return '$code ${intAmount.toStringAsFixed(0)}';
  }

  //  Indian number formatting: 3,154 style
  String _indianFormat(int num) {
    if (num < 1000) return num.toString();
    final str = num.toString();
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    var formatted = '';
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) formatted += ',';
      formatted += remaining[i];
    }
    return '$formatted,$lastThree';
  }

  //  Get currency symbol for display
  String _getCurrencySymbol(String currency) {
    const symbols = {
      'INR': '₹', 'USD': '\$', 'EUR': '€', 'GBP': '£', 'AED': 'د.إ',
      'JPY': '¥', 'AUD': 'A\$', 'CAD': 'C\$',
    };
    return symbols[currency.toUpperCase()] ?? '${currency.toUpperCase()} ';
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isCreatingOrder = true;
      _error = null;
    });

    try {
      final dio = di.sl<DioClient>().instance;
      // Backend expects amount in rupees (it converts to paise internally).
      // Razorpay India only supports INR — always force INR.
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': widget.totalFare,          // rupees — backend × 100 → paise
          'currency': 'INR',
          'reference_id': 'hotel_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final orderId = response.data['order_id'];
      final keyId = response.data['key_id'];

      // SDK expects paise to match the order amount (totalFare × 100)
      final options = {
        'key': keyId,
        'amount': (widget.totalFare * 100).toInt(),   // paise for SDK display
        'currency': 'INR',
        'name': 'WanderNova',
        'description': 'Hotel: ${widget.hotelName}',
        'order_id': orderId,
        'prefill': {
          'name': '${widget.guestFirstName} ${widget.guestLastName}'.trim(),
          'email': widget.email,
          'contact': widget.phone,
        },
        'theme': {'color': '#E71D36'},
      };

      setState(() => _isCreatingOrder = false);
      _razorpay.open(options);
    } on DioException catch (e) {
      setState(() {
        _isCreatingOrder = false;
        _error = 'Could not create payment order. Please try again.';
      });
      print('Razorpay order error: ${e.message}');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Hotel payment success: ${response.paymentId}');
    _callBookApi(response.paymentId ?? '');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _error = 'Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet: ${response.walletName}');
  }

  Future<void> _callBookApi(String razorpayPaymentId) async {
    setState(() => _isBooking = true);

    final clientRef = 'WN_${DateTime.now().millisecondsSinceEpoch}';
    final bookedAt = DateTime.now().toUtc().toIso8601String();

    final payload = {
      'BookingCode': widget.bookingCode,
      'CustomerDetails': {
        'PhoneCountryCode': '91',
        'PhoneNumber': widget.phone,
        'Email': widget.email,
      },
      'ClientReferenceId': clientRef,
      'BookingReferenceId': clientRef,
      'TotalFare': widget.totalFare,
      'EmailId': widget.email,
      'PhoneNumber': widget.phone,
      'BookingType': 1,
      'PaymentMode': 'Limit',
      'PaxInfo': [
        {
          'Title': widget.guestTitle.isNotEmpty ? widget.guestTitle : 'Mr',
          'FirstName': widget.guestFirstName.isNotEmpty ? widget.guestFirstName : 'Guest',
          'LastName': widget.guestLastName.isNotEmpty ? widget.guestLastName : 'User',
          'PaxType': 1,
        },
      ],
      'RazorpayPaymentId': razorpayPaymentId,
    };

    try {
      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(Urls.hotelBook, data: payload);

      final data = response.data as Map<String, dynamic>? ?? {};
      final confirmationNumber = data['ConfirmationNumber']?.toString() ??
          data['ConfirmationId']?.toString() ??
          data['BookingReferenceId']?.toString() ??
          clientRef;
      final bookingRefId = data['BookingReferenceId']?.toString() ?? clientRef;

      // Save booking to our DB (fire-and-forget — don't block navigation)
      _saveBookingToDb(
        confirmationNumber: confirmationNumber,
        bookingReferenceId: bookingRefId,
        razorpayPaymentId: razorpayPaymentId,
        clientRef: clientRef,
        bookedAt: bookedAt,
        isPending: false,
      );

      // Clear the 15-minute session — booking is complete
      HotelSessionService.instance.clear();

      if (!mounted) return;
      setState(() => _isBooking = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HotelConfirmationScreen(
            confirmationNumber: confirmationNumber,
            bookingReferenceId: bookingRefId,
            hotelName: widget.hotelName,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            roomName: widget.roomName,
            totalFare: widget.totalFare,
            currency: widget.currency,
            guestName: '${widget.guestFirstName} ${widget.guestLastName}'.trim(),
            email: widget.email,
            bookedAt: bookedAt,
          ),
        ),
      );
    } on DioException catch (e) {
      final errData = e.response?.data as Map<String, dynamic>? ?? {};
      final bookRef = errData['BookingReferenceId']?.toString();
      final bookFailed = errData['book_failed'] == true;

      if (!mounted) return;
      setState(() => _isBooking = false);

      if (bookFailed && bookRef != null && bookRef.isNotEmpty) {
        // TBO book timed out — backend auto-calls booking-detail after 120s.
        // Save as pending and navigate with isPending: true.
        _saveBookingToDb(
          confirmationNumber: bookRef,
          bookingReferenceId: bookRef,
          razorpayPaymentId: razorpayPaymentId,
          clientRef: clientRef,
          bookedAt: bookedAt,
          isPending: true,
        );
        HotelSessionService.instance.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HotelConfirmationScreen(
              confirmationNumber: bookRef,
              bookingReferenceId: bookRef,
              hotelName: widget.hotelName,
              checkIn: widget.checkIn,
              checkOut: widget.checkOut,
              roomName: widget.roomName,
              totalFare: widget.totalFare,
              currency: widget.currency,
              guestName: '${widget.guestFirstName} ${widget.guestLastName}'.trim(),
              email: widget.email,
              isPending: true,
              bookedAt: bookedAt,
            ),
          ),
        );
      } else {
        setState(() => _error =
            'Booking failed: ${e.message}. Your payment was successful — '
            'please contact support with reference: ${widget.bookingCode}');
      }
    }
  }

  /// Save booking to our Django DB (non-blocking, errors logged only).
  Future<void> _saveBookingToDb({
    required String confirmationNumber,
    required String bookingReferenceId,
    required String razorpayPaymentId,
    required String clientRef,
    required String bookedAt,
    required bool isPending,
  }) async {
    try {
      final dio = di.sl<DioClient>().instance;
      final guestName =
          '${widget.guestTitle} ${widget.guestFirstName} ${widget.guestLastName}'.trim();
      await dio.post(Urls.hotelBookings, data: {
        // Primary references
        'confirmation_number': confirmationNumber,
        'booking_reference_id': bookingReferenceId,
        'tbo_booking_id': widget.bookingCode,   // original TBO booking code
        // Hotel info
        'hotel_name': widget.hotelName,
        'room_type': widget.roomName,
        // Dates (camelCase matches DRF serializer aliases)
        'checkIn': widget.checkIn,
        'checkOut': widget.checkOut,
        // Pricing
        'total_fare': widget.totalFare,
        'currency': widget.currency,
        // Guest
        'guest_name': guestName,
        'email': widget.email,
        'phone': widget.phone,
        // Payment
        'checkout_id': razorpayPaymentId,
        'payment_mode': 'Limit',
        // Status
        'status': isPending ? 'pending' : 'confirmed',
      });
      print('[Hotel] Booking saved to DB: $confirmationNumber');
    } catch (e) {
      // Non-fatal — booking succeeded on TBO side; log and move on
      print('[Hotel] Failed to save booking to DB (non-fatal): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/wander_nova_logo.jpg',
              height: 35,
              errorBuilder: (_, __, ___) => const Icon(Icons.hotel, size: 35),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.gapLarge),
            Text(
              'Complete Payment',
              style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: context.gapLarge),
            _buildHotelSummaryCard(context),
            SizedBox(height: context.gapLarge),
            _buildFareCard(context),
            SizedBox(height: context.gapLarge),
            _buildGuestCard(context),
            if (_error != null) ...[
              SizedBox(height: context.gapLarge),
              _buildErrorCard(context),
            ],
            if (_isProcessing) ...[
              SizedBox(height: context.gapLarge),
              _buildProcessingCard(context),
            ],
            SizedBox(height: context.gapLarge),
            _buildPayButton(context),
            SizedBox(height: context.gapLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelSummaryCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hotel, color: Colors.indigo, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Text('Hotel', style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: context.gapMedium),
          Text(widget.hotelName, style: TextStyle(fontSize: context.bodyLarge, fontWeight: FontWeight.w600)),
          SizedBox(height: context.gapSmall),
          if (widget.roomName.isNotEmpty)
            Text(widget.roomName, style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
          SizedBox(height: context.gapSmall),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
              SizedBox(width: context.gapSmall),
              Text('${widget.checkIn}  →  ${widget.checkOut}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareCard(BuildContext context) {
    final sym = CurrencyConverter.getSymbol(widget.currency);

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.indigo, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Text('Fare Breakdown', style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: context.gapLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: TextStyle(fontSize: context.bodyLarge, fontWeight: FontWeight.bold)),
              Text(
                '${widget.totalFare.toStringAsFixed(2)}', // ← Direct use
                style: TextStyle(fontSize: context.bodyLarge, fontWeight: FontWeight.bold, color: const Color(0xFFE71D36)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    final name = '${widget.guestFirstName} ${widget.guestLastName}'.trim();
    return _card(
      context,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.shade50,
            child: Icon(Icons.person, color: Colors.indigo),
          ),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Guest',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.bodyMedium),
                ),
                Text(widget.email, style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
                Text(widget.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: context.iconMedium),
          SizedBox(width: context.gapMedium),
          Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: context.bodySmall))),
          TextButton(onPressed: () => setState(() => _error = null), child: const Text('Dismiss')),
        ],
      ),
    );
  }

  Widget _buildProcessingCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade700),
          ),
          SizedBox(width: context.gapMedium),
          Text(_processingMessage, style: TextStyle(color: Colors.blue.shade800, fontSize: context.bodySmall)),
        ],
      ),
    );
  }

  // Widget _buildPayButton(BuildContext context) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: context.buttonHeight + 10,
  //     child: ElevatedButton(
  //       onPressed: _isProcessing ? null : _initiatePayment,
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: _isProcessing ? Colors.grey : const Color(0xFFE71D36),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius)),
  //         elevation: 2,
  //       ),
  //       child: _isProcessing
  //           ? const SizedBox(
  //               width: 20,
  //               height: 20,
  //               child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
  //             )
  //           : Text(
  //               'Pay ₹${widget.totalFare.toStringAsFixed(2)}',
  //               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: context.bodyLarge),
  //             ),
  //     ),
  //   );
  // }
  Widget _buildPayButton(BuildContext context) {
    final sym = CurrencyConverter.getSymbol(widget.currency);

    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight + 10,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isProcessing ? Colors.grey : const Color(0xFFE71D36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius)),
          elevation: 2,
        ),
        child: _isProcessing
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
        )
            : Text(
          'Pay  ${widget.totalFare.toStringAsFixed(2)}', // ← Direct use
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: context.bodyLarge),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
