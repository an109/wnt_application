import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wander_nova/injection_container.dart' as di;
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../flight_booking/data/models/booking_request_model.dart';
import '../../../flight_booking/presentation/bloc/booking_bloc.dart';
import '../../../flight_booking/presentation/bloc/booking_event.dart';
import '../../../flight_booking/presentation/bloc/booking_state.dart';
import '../../../flight_search/presentation/screen/booking_screen.dart';
import '../../../flight_ticket/data/models/ticket_request_model.dart';
import '../../../flight_ticket/domain/entities/ticket_entity.dart';
import '../../../flight_ticket/presentation/bloc/ticket_bloc.dart';
import '../../../flight_ticket/presentation/bloc/ticket_event.dart';
import '../../../flight_ticket/presentation/bloc/ticket_state.dart';
import '../../../flight_ticket/presentation/screen/ticket_voucher_screen.dart';

class FlightPaymentScreen extends StatefulWidget {
  final FlightRouteSegment route;
  final String traceId;
  final String resultIndex;
  final Map<String, dynamic> passengerData;
  final Map<String, dynamic> ssrSelections;

  const FlightPaymentScreen({
    super.key,
    required this.route,
    required this.traceId,
    required this.resultIndex,
    required this.passengerData,
    required this.ssrSelections,
  });

  @override
  State<FlightPaymentScreen> createState() => _FlightPaymentScreenState();
}

class _FlightPaymentScreenState extends State<FlightPaymentScreen> {
  late final Razorpay _razorpay;
  late final BookingBloc _bookingBloc;
  late final TicketBloc _ticketBloc;

  bool _isCreatingOrder = false;
  String? _error;
  String? _razorpayPaymentId;

  BookingPassengerModel? _builtPassenger;

  @override
  void initState() {
    super.initState();
    _bookingBloc = di.sl<BookingBloc>();
    _ticketBloc = di.sl<TicketBloc>();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _builtPassenger = _buildPassengerFromForm();

    _bookingBloc.stream.listen(_onBookingStateChange);
    _ticketBloc.stream.listen(_onTicketStateChange);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _bookingBloc.close();
    _ticketBloc.close();
    super.dispose();
  }

  BookingPassengerModel _buildPassengerFromForm() {
    final data = widget.passengerData;
    return BookingPassengerModel(
      title: data['gender'] == 'Female' ? 'Ms' : 'Mr',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      paxType: 1,
      dateOfBirth: '1990-01-01T00:00:00',
      gender: data['gender'] == 'Female' ? 2 : 1,
      passportNo: data['passport'] ?? '',
      passportExpiry: _formatPassportExpiry(data['passportExpiry']),
      nationality: _nationalityToCode(data['nationality'] ?? 'India'),
      contactNo: data['phone'] ?? '',
      email: data['email'] ?? '',
      isLeadPax: true,
      baggage: _buildSsrList('baggage'),
      mealDynamic: _buildSsrList('meal'),
      seatDynamic: _buildSsrList('seat'),
    );
  }

  String _formatPassportExpiry(String? raw) {
    if (raw == null || raw.isEmpty) return '2030-01-01T00:00:00';
    try {
      final parts = raw.split('/');
      if (parts.length == 3) {
        return '20${parts[2]}-${parts[1]}-${parts[0]}T00:00:00';
      }
    } catch (_) {}
    return '2030-01-01T00:00:00';
  }

  String _nationalityToCode(String nationality) {
    const map = {
      'india': 'IN', 'indian': 'IN',
      'american': 'US', 'united states': 'US',
      'british': 'GB', 'uk': 'GB',
      'canadian': 'CA',
      'australian': 'AU',
    };
    return map[nationality.toLowerCase()] ?? 'IN';
  }

  List<Map<String, dynamic>> _buildSsrList(String type) {
    final sel = widget.ssrSelections;
    if (type == 'baggage' && sel['baggage'] != null) {
      return [
        {'Code': sel['baggage'], 'Description': 'Extra Baggage', 'AirlineCode': '', 'Amount': 0, 'Origin': '', 'Destination': ''},
      ];
    }
    if (type == 'meal' && sel['meal'] != null) {
      return [
        {'Code': sel['meal'], 'Description': 'Meal', 'AirlineCode': '', 'Amount': 0, 'Origin': '', 'Destination': ''},
      ];
    }
    if (type == 'seat' && sel['seat'] != null) {
      return [
        {'Code': sel['seat'], 'Description': 'Seat', 'AirlineCode': '', 'Amount': 0, 'Origin': '', 'Destination': ''},
      ];
    }
    return [];
  }

  double get _totalAmount {
    final fare = widget.route.fareQuoteData;
    if (fare != null) return fare.total;
    final price = double.tryParse(widget.route.price.replaceAll(RegExp(r'[^0-9.]'), ''));
    return price ?? 0.0;
  }

  String get _currency => widget.route.fareQuoteData?.currency ?? 'INR';

  Future<void> _initiatePayment() async {
    setState(() { _isCreatingOrder = true; _error = null; });

    try {
      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': (_totalAmount * 100).toInt(),
          'currency': _currency,
          'reference_id': 'flight_${widget.traceId}',
        },
      );

      final orderId = response.data['order_id'];
      final keyId = response.data['key_id'];

      final options = {
        'key': keyId,
        'amount': (_totalAmount * 100).toInt(),
        'currency': _currency,
        'name': 'WanderNova',
        'description': 'Flight Booking ${widget.route.from} → ${widget.route.to}',
        'order_id': orderId,
        'prefill': {
          'name': '${widget.passengerData['firstName'] ?? ''} ${widget.passengerData['lastName'] ?? ''}',
          'email': widget.passengerData['email'] ?? '',
          'contact': widget.passengerData['phone'] ?? '',
        },
        'theme': {'color': '#E71D36'},
      };

      setState(() { _isCreatingOrder = false; });
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
    print('Payment success: ${response.paymentId}');
    _razorpayPaymentId = response.paymentId;
    _callBookApi();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() { _error = 'Payment failed: ${response.message}'; });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet: ${response.walletName}');
  }

  void _callBookApi() {
    final prefs = di.sl<PreferencesManager>();
    final tokenId = prefs.getToken() ?? '';

    final request = BookingRequestModel(
      endUserIp: '::1',
      traceId: widget.traceId,
      tokenId: tokenId,
      resultIndex: widget.resultIndex,
      passengers: [_builtPassenger!],
    );

    _bookingBloc.add(BookFlightEvent(request));
  }

  void _onBookingStateChange(BookingState state) {
    if (state is BookingSuccess) {
      print('Booking success: PNR=${state.booking.pnr}, BookingId=${state.booking.bookingId}');
      _callTicketApi(state.booking.pnr!, state.booking.bookingId!);
    } else if (state is BookingError) {
      setState(() { _error = 'Booking failed: ${state.message}'; });
    }
  }

  void _callTicketApi(String pnr, int bookingId) {
    final prefs = di.sl<PreferencesManager>();
    final tokenId = prefs.getToken() ?? '';

    final request = TicketRequestModel(
      endUserIp: '::1',
      traceId: widget.traceId,
      tokenId: tokenId,
      bookingId: bookingId,
      pnr: pnr,
      passengers: [_builtPassenger!],
    );

    _ticketBloc.add(IssueTicketEvent(request));
  }

  void _onTicketStateChange(TicketState state) {
    if (state is TicketSuccess || state is TicketPending) {
      final ticket = state is TicketSuccess ? state.ticket : (state as TicketPending).ticket;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TicketVoucherScreen(
            ticket: ticket,
            route: widget.route,
            passengerData: widget.passengerData,
          ),
        ),
      );
    } else if (state is TicketError) {
      setState(() { _error = 'Ticket issuance failed: ${state.message}'; });
    }
  }

  bool get _isProcessing {
    return _isCreatingOrder ||
        _bookingBloc.state is BookingLoading ||
        _ticketBloc.state is TicketLoading;
  }

  String get _processingMessage {
    if (_isCreatingOrder) return 'Creating payment order...';
    if (_bookingBloc.state is BookingLoading) return 'Confirming your booking...';
    if (_ticketBloc.state is TicketLoading) return 'Issuing your ticket...';
    return '';
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
            child: Image.asset('assets/images/wander_nova_logo.jpg', height: 35),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.gapLarge),
            Text('Complete Payment', style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.bold)),
            SizedBox(height: context.gapLarge),
            _buildFlightSummaryCard(context),
            SizedBox(height: context.gapLarge),
            _buildFareSummaryCard(context),
            SizedBox(height: context.gapLarge),
            _buildPassengerSummaryCard(context),
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

  Widget _buildFlightSummaryCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_takeoff, color: Colors.indigo, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Text('Flight', style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: context.gapMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.route.from, style: TextStyle(fontSize: context.headlineSmall, fontWeight: FontWeight.bold)),
                  Text(widget.route.departureTime, style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
                ],
              ),
              Icon(Icons.arrow_forward, color: Colors.grey),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(widget.route.to, style: TextStyle(fontSize: context.headlineSmall, fontWeight: FontWeight.bold)),
                  Text(widget.route.arrivalTime, style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
                ],
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),
          Text('${widget.route.airline} · ${widget.route.flightNo}', style: TextStyle(color: Colors.grey.shade500, fontSize: context.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildFareSummaryCard(BuildContext context) {
    final fare = widget.route.fareQuoteData;
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
          if (fare != null) ...[
            _fareRow(context, 'Base Fare', '${fare.currency} ${fare.baseFare.toStringAsFixed(2)}'),
            SizedBox(height: context.gapSmall),
            _fareRow(context, 'Taxes & Fees', '${fare.currency} ${fare.tax.toStringAsFixed(2)}'),
            Divider(height: context.gapLarge, color: Colors.grey.shade200),
            _fareRow(context, 'Total Amount', '${fare.currency} ${fare.total.toStringAsFixed(2)}', isTotal: true),
          ] else
            _fareRow(context, 'Total Amount', widget.route.price, isTotal: true),
        ],
      ),
    );
  }

  Widget _fareRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.black : Colors.grey.shade700,
        )),
        Text(value, style: TextStyle(
          fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          color: isTotal ? const Color(0xFFE71D36) : Colors.black,
        )),
      ],
    );
  }

  Widget _buildPassengerSummaryCard(BuildContext context) {
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
                  '${widget.passengerData['firstName'] ?? ''} ${widget.passengerData['lastName'] ?? ''}'.trim(),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.bodyMedium),
                ),
                Text(widget.passengerData['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: context.bodySmall)),
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
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: context.iconMedium),
          SizedBox(width: context.gapMedium),
          Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: context.bodySmall))),
          TextButton(
            onPressed: () => setState(() => _error = null),
            child: const Text('Dismiss'),
          ),
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
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade700)),
          SizedBox(width: context.gapMedium),
          Text(_processingMessage, style: TextStyle(color: Colors.blue.shade800, fontSize: context.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context) {
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
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Text(
                'Pay ${_currency} ${_totalAmount.toStringAsFixed(2)}',
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
