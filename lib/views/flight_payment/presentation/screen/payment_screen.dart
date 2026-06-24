import 'dart:async';
import 'dart:convert';

// ----- Razorpay flow (commented out) -----
// import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wander_nova/injection_container.dart' as di;
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/storage/shared_preference.dart';
// ----- CCAvenue flow -----
import '../../data/ccavenue_service.dart';
import 'ccavenue_payment_page.dart';
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
import '../../../flight_ssr/presentation/screen/ssr/ssr_price_formatter.dart';
import '../../../wallet/data/data_source/wallet_api_service.dart';

class FlightPaymentScreen
    extends StatefulWidget {
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
  final CCAvenueService _ccavenueService = CCAvenueService();
  late final Razorpay _razorpay;
  late final BookingBloc _bookingBloc;
  late final TicketBloc _ticketBloc;
  String? _razorpayOrderId;

  // TBO session expires ~15 min from FareQuote. Start the clock when this
  // screen opens (FareQuote was called just before navigation here).
  Timer? _sessionTimer;
  int _secondsRemaining = 15 * 60;

  bool _isCreatingOrder = false;
  String _loadingMessage = 'Creating payment order...';
  String? _error;

  // Payment method chosen by the user. Null until a method is selected, which
  // keeps the Pay button disabled. 'wallet' uses the wallet-balance flow; every
  // other method opens the Razorpay checkout.
  String? _selectedPaymentMethod;

  BookingPassengerModel? _builtPassenger;
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _pageBg = Color(0xFFF3F6FC);
  static const _successGreen = Color(0xFF10B981);
  static const _lightGreen = Color(0xFFECFDF5);

  @override
  void initState() {
    super.initState();
    _bookingBloc = di.sl<BookingBloc>();
    _ticketBloc = di.sl<TicketBloc>();

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) _secondsRemaining--;
      });
    });

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);

    _builtPassenger = _buildPassengerFromForm();

    _bookingBloc.stream.listen(_onBookingStateChange);
    _ticketBloc.stream.listen(_onTicketStateChange);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _razorpay.clear();
    _bookingBloc.close();
    _ticketBloc.close();
    super.dispose();
  }

  bool get _sessionExpired => _secondsRemaining == 0;

  String get _sessionTimerLabel {
    if (_sessionExpired) return 'Session expired';
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} remaining';
  }

  Color get _sessionTimerColor {
    if (_secondsRemaining == 0) return Colors.red.shade700;
    if (_secondsRemaining < 5 * 60) return Colors.red.shade600;
    if (_secondsRemaining < 10 * 60) return Colors.orange.shade700;
    return _successGreen;
  }

  Color get _sessionTimerBg {
    if (_secondsRemaining == 0) return Colors.red.shade50;
    if (_secondsRemaining < 5 * 60) return Colors.red.shade50;
    if (_secondsRemaining < 10 * 60) return Colors.orange.shade50;
    return _lightGreen;
  }

  BookingPassengerModel _buildPassengerFromForm() {
    final data = widget.passengerData;
    return BookingPassengerModel(
      title: data['gender'] == 'Female' ? 'Ms' : 'Mr',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      paxType: 1,
      dateOfBirth: _formatDateOfBirth(data['dateOfBirth']),
      gender: data['gender'] == 'Female' ? 2 : 1,
      passportNo: data['passportNumber'] ?? data['passport'] ?? '',
      passportExpiry: _formatPassportExpiry(data['passportExpiry']),
      nationality: _nationalityToCode(data['nationality'] ?? 'India'),
      contactNo: data['mobileNumber'] ?? data['phone'] ?? '',
      email: data['email'] ?? '',
      isLeadPax: true,
      baggage: _buildSsrList('baggage'),
      mealDynamic: _buildSsrList('meal'),
      seatDynamic: _buildSsrList('seat'),
    );
  }

  String _formatDateOfBirth(String? raw) {
    if (raw == null || raw.isEmpty) return '2000-01-01T00:00:00';
    try {
      // DD/MM/YYYY or DD/MM/YY
      final parts = raw.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2].length == 2 ? '19${parts[2]}' : parts[2];
        return '$year-$month-${day}T00:00:00';
      }
      // Already ISO: 1990-01-01 or 1990-01-01T00:00:00
      if (raw.length >= 10 && raw[4] == '-') {
        return '${raw.substring(0, 10)}T00:00:00';
      }
      final parsed = DateFormat('dd MMM yyyy').parseStrict(raw);
      return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(parsed);
    } catch (_) {}
    return '2000-01-01T00:00:00';
  }

  String _formatPassportExpiry(String? raw) {
    if (raw == null || raw.isEmpty) return '2030-01-01T00:00:00';
    try {
      final parts = raw.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2].length == 2 ? '20${parts[2]}' : parts[2];
        return '$year-$month-${day}T00:00:00';
      }
      if (raw.length >= 10 && raw[4] == '-') {
        return '${raw.substring(0, 10)}T00:00:00';
      }
      final parsed = DateFormat('dd MMM yyyy').parseStrict(raw);
      return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(parsed);
    } catch (_) {}
    return '2030-01-01T00:00:00';
  }

  String _nationalityToCode(String nationality) {
    const map = {
      'india': 'IN',
      'indian': 'IN',
      'american': 'US',
      'united states': 'US',
      'british': 'GB',
      'uk': 'GB',
      'canadian': 'CA',
      'australian': 'AU',
    };
    return map[nationality.toLowerCase()] ?? 'IN';
  }

  /// Builds the passenger's Baggage / MealDynamic / SeatDynamic list from the
  /// selections made on the SSR screen. The selections are already the complete
  /// TBO SSR objects (see [BaggageOptionEntity.toTboJson] etc.), so we pass them
  /// through verbatim — TBO rejects partial/stubbed SSR objects.
  List<Map<String, dynamic>> _buildSsrList(String type) {
    final sel = widget.ssrSelections;

    if (type == 'baggage') {
      final baggage = sel['baggage'];
      return baggage is Map
          ? [Map<String, dynamic>.from(baggage)]
          : const [];
    }
    if (type == 'meal') {
      final meal = sel['meal'];
      return meal is Map ? [Map<String, dynamic>.from(meal)] : const [];
    }
    if (type == 'seat') {
      final raw = sel['seat'];
      final seats = raw is List ? raw : (raw == null ? const [] : [raw]);
      return seats
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
    }
    return const [];
  }

  double get _totalAmount {
    final fare = widget.route.fareQuoteData;
    if (fare != null) return fare.total;
    final price = double.tryParse(
      widget.route.price.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    return price ?? 0.0;
  }

  String get _currency => widget.route.fareQuoteData?.currency ?? 'INR';
  double get _displayAmount =>
      SsrPriceFormatter.convertAmount(_totalAmount, _currency);
  String get _displayCurrency => SsrPriceFormatter.preferredCurrency(_currency);
  String get _displayTotal => SsrPriceFormatter.format(_totalAmount, _currency);

  // ============================================================
  // ----- Razorpay flow (commented out) -----
  // ============================================================
  /*
  Future<void> _initiatePayment() async {
    setState(() {
      _isCreatingOrder = true;
      _error = null;
    });

    try {
      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': _displayAmount,
          'currency': _displayCurrency,
          'reference_id': 'flight_${widget.traceId}',
        },
      );

      final orderId = response.data['order_id'];
      final keyId = response.data['key_id'];

      final options = {
        'key': keyId,
        'amount': (_displayAmount * 100).toInt(),
        'currency': _displayCurrency,
        'name': 'WanderNova',
        'description':
            'Flight Booking ${widget.route.from} → ${widget.route.to}',
        'order_id': orderId,
        'prefill': {
          'name':
              '${widget.passengerData['firstName'] ?? ''} ${widget.passengerData['lastName'] ?? ''}',
          'email': widget.passengerData['email'] ?? '',
          'contact':
              widget.passengerData['mobileNumber'] ??
              widget.passengerData['phone'] ??
              '',
        },
        'theme': {'color': '#1769F6'},
      };

      setState(() {
        _isCreatingOrder = false;
      });
      _razorpay.open(options);
    } on DioException catch (e) {
      setState(() {
        _isCreatingOrder = false;
        _error = 'Could not create payment order. Please try again.';
      });
      print('Razorpay order error: ${e.message}');
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment success: ${response.paymentId}');

    // Verify the payment signature server-side before booking. Razorpay's
    // client-side success callback can be spoofed; the backend re-computes the
    // HMAC and only marks the transaction paid if it matches.
    setState(() {
      _isCreatingOrder = true;
      _error = null;
    });

    try {
      final dio = di.sl<DioClient>().instance;
      final verifyResponse = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'reference_id': 'flight_${widget.traceId}',
        },
      );

      if (!mounted) return;
      setState(() => _isCreatingOrder = false);

      if (verifyResponse.data['success'] == true) {
        _startBookingFlow();
      } else {
        setState(() {
          _error = 'Payment verification failed. Please contact support.';
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingOrder = false;
        _error = 'Could not verify payment. Please contact support.';
      });
      print('Razorpay verify error: ${e.message}');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _error = 'Payment failed: ${response.message}';
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet: ${response.walletName}');
  }
  */

  // ============================================================
  // ----- CCAvenue hosted-checkout flow -----
  // ============================================================

  /// CCAvenue order_id must equal the TBO traceId so the backend's finalize
  /// endpoint can match the CCAvenue transaction to the booking session.
  /// Sanitise: alphanumeric + hyphens only, max 30 chars.
  String _ccavenueOrderId() {
    final safe = widget.traceId.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
    return safe.length > 40 ? safe.substring(0, 40) : safe;
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isCreatingOrder = true;
      _loadingMessage = 'Preparing your booking...';
      _error = null;
    });

    try {
      final prefs = di.sl<PreferencesManager>();

      // 1. Persist the Book/Ticket payload server-side BEFORE opening CCAvenue.
      //    finalize_ticket will read this after payment to issue the ticket
      //    without depending on any client state.
      await _callPrepareTicket(prefs);
      if (!mounted) return;

      final orderId = _ccavenueOrderId();
      // CCAvenue requires an amount with at most 2 decimal places.
      final amount = double.parse(_displayAmount.toStringAsFixed(2));

      final session = await _ccavenueService.createCheckout(
        orderId: orderId,
        amount: amount,
        currency: _displayCurrency,
        transactionType: 'flight',
        userId: prefs.getUserId(),
        firstName: widget.passengerData['firstName'] ?? '',
        lastName: widget.passengerData['lastName'] ?? '',
        email: widget.passengerData['email'] ?? '',
        phone:
            widget.passengerData['mobileNumber'] ??
            widget.passengerData['phone'] ??
            '',
        successUrl: Urls.ccavenueSuccessUrl,
        failureUrl: Urls.ccavenueFailureUrl,
      );

      if (!mounted) return;
      setState(() => _isCreatingOrder = false);

      final result = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          builder: (_) => CCAvenuePaymentPage(
            service: _ccavenueService,
            session: session,
          ),
        ),
      );

      if (!mounted) return;
      switch (result) {
        // case PaymentResult.success:
        //   // 2. Payment confirmed — ask the server to issue the ticket.
        //   //    finalize verifies the CCAvenue transaction by order_id == traceId.
        //   await _callFinalizeTicket();
        //   break;
        case PaymentResult.success:
          if (_isLcc) {
            await _callFinalizeTicket();
          } else {
            _startBookingFlow();
          }
          break;
        case PaymentResult.failure:
          setState(() => _error = 'Payment failed. Please try again.');
          break;
        case PaymentResult.cancelled:
        case null:
          setState(() => _error = 'Payment cancelled.');
          break;
      }
    } on CCAvenueException catch (e) {
      setState(() {
        _isCreatingOrder = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isCreatingOrder = false;
        _error = 'Could not start payment. Please try again.';
      });
      print('CCAvenue checkout error: $e');
    }
  }

  /// POST /api/flights/prepare-ticket/
  /// Stores the full Book/Ticket payload on the server keyed by traceId so the
  /// server can issue the ticket after payment without any client-side state.
  Future<void> _callPrepareTicket(PreferencesManager prefs, {String gateway = 'ccavenue'}) async {
    final dio = di.sl<DioClient>().instance;

    final Map<String, dynamic> payload;
    final itineraryResultIndex =
    (_rawItinerary['ResultIndex'] as String?)?.trim();

    final effectiveResultIndex =
    (itineraryResultIndex != null && itineraryResultIndex.isNotEmpty)
        ? itineraryResultIndex
        : widget.resultIndex.trim();

    if (_isLcc) {
      final req = TicketRequestModel.lcc(
        endUserIp: _endUserIp,
        traceId: widget.traceId,
        // resultIndex: widget.resultIndex,
        resultIndex: effectiveResultIndex,
        itinerary: _rawItinerary,
        passengers: [_builtPassenger!],
      );
      payload = {
        'trace_id': widget.traceId,
        'is_lcc': true,
        'book_payload': null,
        'ticket_payload': req.toJson(),
        'gateway': gateway,
        'booking_meta': _buildBookingMeta(prefs),
      };
    } else {
      final req = BookingRequestModel(
        endUserIp: _endUserIp,
        traceId: widget.traceId,
        tokenId: '',
        // resultIndex: widget.resultIndex,
        resultIndex: effectiveResultIndex,
        itinerary: _rawItinerary,
        passengers: [_builtPassenger!],
      );
      payload = {
        'trace_id': widget.traceId,
        'is_lcc': false,
        'book_payload': req.toJson(),
        'ticket_payload': null,
        'gateway': gateway,
        'booking_meta': _buildBookingMeta(prefs),
      };
    }

    print('====== PREPARE-TICKET PAYLOAD ======');
    print(jsonEncode(payload));
    print('=====================================');

    try {
      await dio.post(Urls.prepareTicket, data: payload);
    }catch (e) {
      throw Exception('Could not prepare ticket payload: $e');
    }
  }

  Map<String, dynamic> _buildBookingMeta(PreferencesManager prefs) {
    final p = widget.passengerData;
    return {
      'user_id': prefs.getUserId(),
      'email': p['email'] ?? '',
      'phone': p['mobileNumber'] ?? p['phone'] ?? '',
      'passengers_data': [
        {
          'first_name': p['firstName'] ?? '',
          'last_name': p['lastName'] ?? '',
          'email': p['email'] ?? '',
          'phone': p['mobileNumber'] ?? p['phone'] ?? '',
        }
      ],
    };
  }

  /// POST /api/flights/finalize/
  /// Verifies the payment transaction and issues the TBO ticket server-side.
  Future<void> _callFinalizeTicket({String gateway = 'ccavenue'}) async {
    setState(() {
      _isCreatingOrder = true;
      _loadingMessage = 'Issuing your ticket...';
      _error = null;
    });

    try {
      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(Urls.finalizeTicket, data: {
        'reference_id': widget.traceId,
        'gateway': gateway,
      });

      if (!mounted) return;
      setState(() => _isCreatingOrder = false);

      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['success'] == true) {
        final rawBookingId = data['tbo_booking_id'];
        final ticket = TicketEntity(
          responseStatus: 1,
          pnr: data['pnr'] as String?,
          bookingId: rawBookingId is int
              ? rawBookingId
              : rawBookingId != null ? int.tryParse('$rawBookingId') : null,
          passengers: const [],
        );
        if (!mounted) return;
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
      } else {
        // finalize returned success:false — check why.
        final errStr = '${data['error'] ?? ''}';
        if (errStr.contains('payment_not_confirmed')) {
          setState(() => _error =
              'Payment could not be verified. Please contact support with your payment ID.');
        } else {
          // TBO-side error (e.g. session expired) — direct Book would hit the
          // same error, so fall back only for non-TBO failures.
          print('finalize failed: $errStr — falling back to direct flow');
          _startBookingFlow();
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingOrder = false);
      final body = e.response?.data;
      final errCode =
          (body is Map<String, dynamic>) ? body['error'] as String? : null;
      // 402 payment_not_confirmed: CCAvenue/Razorpay response was never
      // received by the backend (e.g. Mixed Content block in dev). Payment was
      // NOT confirmed — do not tell the user their payment was received.
      if (e.response?.statusCode == 402 ||
          errCode == 'payment_not_confirmed') {
        print('finalize 402 payment_not_confirmed');
        setState(() => _error =
            'Payment could not be verified. Please contact support with your payment ID.');
        return;
      }
      // Parse the response to distinguish TBO errors from infra errors.
      final tboMsg = _extractTboErrorMessage(body);
      if (tboMsg != null) {
        // TBO rejected the booking — falling back to direct Book would hit the
        // same TBO error. Show a clear message with the reference ID so support
        // can locate the payment and complete the booking manually.
        print('finalize TBO error: $tboMsg');
        setState(() => _error =
            'Ticket issuance failed. Your payment was received — please '
            'contact support with your reference: '
            '${widget.traceId.substring(0, 8).toUpperCase()}');
      } else {
        print('finalize error: ${e.message} — falling back to direct flow');
        _startBookingFlow();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingOrder = false);
      print('finalize unexpected error: $e — falling back to direct flow');
      _startBookingFlow();
    }
  }

  /// Returns a TBO error string if the response body is a known TBO/finalize
  /// error format, or null if it is not (so the caller can fall back).
  ///
  /// Handles two formats:
  ///   • Backend 502 wrapping a TBO failure:
  ///       {"success":false,"stage":"ticket","error":"Object reference..."}
  ///   • TBO structured error relayed by the backend:
  ///       {"Response":{"Error":{"ErrorMessage":"..."}}}
  String? _extractTboErrorMessage(dynamic body) {
    try {
      final map = body as Map<String, dynamic>?;
      if (map == null) return null;

      // Format 1: finalize 502 — backend caught a TBO error and re-raised it.
      if (map['success'] == false && map['error'] != null) {
        return '${map['error']}';
      }

      // Format 2: TBO JSON error envelope.
      final msg = map['Response']?['Error']?['ErrorMessage'] as String?;
      return msg;
    } catch (_) {
      return null;
    }
  }

  static const _endUserIp = '122.161.72.69';

  bool get _isLcc => widget.route.fareQuoteData?.isLcc ?? false;
  Map<String, dynamic> get _rawItinerary =>
      widget.route.fareQuoteData?.rawItinerary ?? const {};

  /// Entry point after a successful payment. Routes to the correct TBO flow:
  ///   LCC      → Ticket directly (Book + Ticket in one call).
  ///   Non-LCC  → Book first, then Ticket on success.
  /// The Book endpoint is Non-LCC only — calling it for an LCC fare makes TBO
  /// throw "an unhandled exception", which is the 500 we were hitting.
  void _startBookingFlow() {
    // TraceId/ResultIndex come from the Search/FareQuote session and key the
    // whole booking; empty values make TBO return a session error.
    final traceId = widget.traceId.trim();
    final resultIndex = widget.resultIndex.trim();
    if (traceId.isEmpty || resultIndex.isEmpty) {
      print(
        'BOOKING ABORTED: traceId="$traceId", resultIndex="$resultIndex" '
        '(empty — the search session was lost or expired)',
      );
      setState(() {
        _error =
            'Your search session expired. Please go back and search again.';
      });
      return;
    }

    // TBO Book/Ticket need the full FareQuote result as the `Itinerary`. Without
    // it the payload is a stub and TBO 500s.
    if (_rawItinerary.isEmpty) {
      print('BOOKING ABORTED: itinerary missing (FareQuote result not captured)');
      setState(() {
        _error = 'Flight details are incomplete. Please reselect the flight.';
      });
      return;
    }

    // Non-truncated diagnostic: confirms the itinerary really is the FareQuote
    // result (Android logcat truncates the full payload dump).
    print('====== ITINERARY DIAGNOSTIC ======');
    print('fareQuoteData null? ${widget.route.fareQuoteData == null}');
    print('isLcc            : $_isLcc');
    print('itinerary length : ${_rawItinerary.length}');
    print('itinerary keys   : ${_rawItinerary.keys.toList()}');
    print('itinerary.ResultIndex : ${_rawItinerary['ResultIndex']}');
    print('itinerary.IsLcc       : ${_rawItinerary['IsLcc']}');
    print('itinerary.Fare != null: ${_rawItinerary['Fare'] != null}');
    print('itinerary.Segments != null: ${_rawItinerary['Segments'] != null}');
    print('widget.resultIndex (search): $resultIndex');
    print('==================================');

    // The ResultId sent to Book/Ticket must match the Itinerary it describes.
    // FareQuote can return a NEW ResultIndex, so prefer the one inside the
    // itinerary; fall back to the search index only if absent.
    final itineraryResultIndex =
        (_rawItinerary['ResultIndex'] as String?)?.trim();
    final effectiveResultIndex =
        (itineraryResultIndex != null && itineraryResultIndex.isNotEmpty)
            ? itineraryResultIndex
            :
        resultIndex;

    print('BOOKING FLOW: isLcc=$_isLcc, resultIndex=$effectiveResultIndex');
    if (_isLcc) {
      _callLccTicketApi(traceId, effectiveResultIndex);
    } else {
      _callBookApi(traceId, effectiveResultIndex);
    }
  }

  void _printLongText(String text) {
    const int chunkSize = 800;
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint(text.substring(i, end));
    }
  }

  /// Non-LCC: hold the booking (PNR) before ticketing.
  void _callBookApi(String traceId, String resultIndex) {
    // TokenId left empty — the backend injects the real TBO token for every
    // /tbo/ endpoint. The app JWT travels in the Authorization header instead.
    final request = BookingRequestModel(
      endUserIp: _endUserIp,
      traceId: traceId,
      tokenId: '',
      resultIndex: resultIndex,
      itinerary: _rawItinerary,
      passengers: [_builtPassenger!],
    );

    final jsonPayload = jsonEncode(request.toJson());

    // Use debugPrint with larger limit (default is 1000)
    debugPrint('====== FULL BOOK API PAYLOAD ======');
    debugPrint(jsonPayload);
    debugPrint('========================================');

    // Or split into chunks
    _printLongText('====== FULL BOOK API PAYLOAD ======\n$jsonPayload\n========================================');

    final debugJson = request.toJson();
    print('====== PASSENGER ONLY ======');
    print(jsonEncode(debugJson['Itinerary']['Passenger']));
    print('====== LAST TICKET DATE ======');
    print(debugJson['Itinerary']['LastTicketDate']);

    print('====== BOOK API PAYLOAD (Non-LCC) ======');
    print('EndUserIp  : ${request.endUserIp}');
    print('TrackingId : ${request.traceId}');
    print('ResultIndex: ${request.resultIndex}');
    print('IsLcc      : false');
    print('--- full JSON ---');
    print(jsonEncode(request.toJson()));
    print('========================================');

    _bookingBloc.add(BookFlightEvent(request));
  }

  void _onBookingStateChange(BookingState state) {
    if (state is BookingSuccess) {
      final pnr = state.booking.pnr;
      final bookingId = state.booking.bookingId;
      print('Booking success: PNR=$pnr, BookingId=$bookingId');
      if (pnr == null || bookingId == null) {
        setState(() => _error = 'Booking returned no PNR. Please contact support.');
        return;
      }
      _callNonLccTicketApi(pnr, bookingId);
    } else if (state is BookingError) {
      final msg = state.message;
      final isSessionExpiry = msg.toLowerCase().contains('unhandled exception') ||
          msg.toLowerCase().contains('non-json');
      final isPassportError = msg.toLowerCase().contains('passport');
      setState(() {
        _error = isPassportError
            ? 'This flight requires passport details. Please go back, fill in your '
                'passport number and expiry date, then try again.'
            : isSessionExpiry
                ? 'Booking session expired. Your payment was received — please contact '
                    'support to complete your booking. (Ref: ${widget.traceId.substring(0, 8)})'
                : 'Booking failed: $msg';
      });
    }
  }

  /// LCC: Book + Ticket in a single call, carrying the full Itinerary.
  void _callLccTicketApi(String traceId, String resultIndex) {
    final request = TicketRequestModel.lcc(
      endUserIp: _endUserIp,
      traceId: traceId,
      resultIndex: resultIndex,
      itinerary: _rawItinerary,
      passengers: [_builtPassenger!],
    );

    print('====== TICKET API PAYLOAD (LCC) ======');
    print('EndUserIp  : ${request.endUserIp}');
    print('TrackingId : ${request.traceId}');
    print('ResultIndex: ${request.resultIndex}');
    print('IsLcc      : true');
    print('--- full JSON ---');
    print(jsonEncode(request.toJson()));
    print('======================================');

    _ticketBloc.add(IssueTicketEvent(request));
  }

  /// Non-LCC: issue the ticket on the already-booked PNR.
  void _callNonLccTicketApi(String pnr, int bookingId) {
    final request = TicketRequestModel.nonLcc(
      endUserIp: _endUserIp,
      traceId: widget.traceId.trim(),
      bookingId: bookingId,
      pnr: pnr,
    );

    print('====== TICKET API PAYLOAD (Non-LCC) ======');
    print('EndUserIp  : ${request.endUserIp}');
    print('TrackingId : ${request.traceId}');
    print('BookingId  : ${request.bookingId}');
    print('PNR        : ${request.pnr}');
    print('--- full JSON ---');
    print(jsonEncode(request.toJson()));
    print('==========================================');

    _ticketBloc.add(IssueTicketEvent(request));
  }

  void _onTicketStateChange(TicketState state) {
    if (state is TicketSuccess || state is TicketPending) {
      final ticket = state is TicketSuccess
          ? state.ticket
          : (state as TicketPending).ticket;
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
      setState(() {
        _error = 'Ticket issuance failed: ${state.message}';
      });
    }
  }

  bool get _isProcessing {
    return _isCreatingOrder ||
        _bookingBloc.state is BookingLoading ||
        _ticketBloc.state is TicketLoading;
  }

  String get _processingMessage {
    if (_isCreatingOrder) return _loadingMessage;
    if (_bookingBloc.state is BookingLoading) return 'Confirming your booking...';
    if (_ticketBloc.state is TicketLoading) return 'Issuing your ticket...';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: _pageBg,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset(
              'assets/images/wander_logo.png',
              height: 35,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSessionTimerBanner(context),
          Expanded(
            child: SingleChildScrollView(
              padding: context.smallPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.gapSmall),
                  _buildFlightSummaryCard(context),
                  SizedBox(height: context.gapSmall),
                  _buildFareSummaryCard(context),
                  SizedBox(height: context.gapSmall),
                  _buildPassengerSummaryCard(context),
                  SizedBox(height: context.gapSmall),
                  _buildPaymentMethodSection(context),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTimerBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _sessionTimerBg,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      child: Row(
        children: [
          Icon(
            _sessionExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
            color: _sessionTimerColor,
            size: 18,
          ),
          SizedBox(width: context.gapSmall),
          Expanded(
            child: Text(
              _sessionExpired
                  ? 'Booking session expired — go back and search again.'
                  : 'Booking session: $_sessionTimerLabel',
              style: TextStyle(
                fontSize: context.bodySmall,
                color: _sessionTimerColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              // Icon(
              //   Icons.flight_takeoff,
              //   color: _blue,
              //   size: context.iconMedium,
              // ),
              // SizedBox(width: context.gapSmall),
              Text(
                'Flight',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.route.from,
                    style: TextStyle(
                      fontSize: context.headlineSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.route.departureTime,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: context.bodySmall,
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward, color: Colors.grey),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.route.to,
                    style: TextStyle(
                      fontSize: context.headlineSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.route.arrivalTime,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: context.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),
          Text(
            '${widget.route.airline} · ${widget.route.flightNo}',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: context.bodySmall,
            ),
          ),
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
              // Icon(Icons.receipt_long, color: _blue, size: context.iconMedium),
              // SizedBox(width: context.gapSmall),
              Text(
                'Fare Breakdown',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapLarge),
          if (fare != null) ...[
            _fareRow(
              context,
              'Base Fare',
              SsrPriceFormatter.format(fare.baseFare, fare.currency),
            ),
            SizedBox(height: context.gapSmall),
            _fareRow(
              context,
              'Taxes & Fees',
              SsrPriceFormatter.format(fare.tax, fare.currency),
            ),
            Divider(height: context.gapLarge, color: Colors.grey.shade200),
            _fareRow(
              context,
              'Total Amount',
              SsrPriceFormatter.format(fare.total, fare.currency),
              isTotal: true,
            ),
          ] else
            _fareRow(
              context,
              'Total Amount',
              widget.route.price,
              isTotal: true,
            ),
        ],
      ),
    );
  }

  Widget _fareRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? _navy : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? _blue : _navy,
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerSummaryCard(BuildContext context) {
    return _card(
      context,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _blue.withValues(alpha: 0.09),
            child: const Icon(Icons.person, color: _blue),
          ),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.passengerData['firstName'] ?? ''} ${widget.passengerData['lastName'] ?? ''}'
                      .trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.bodyMedium,
                  ),
                ),
                Text(
                  widget.passengerData['email'] ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: context.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    print("--------------------- $_error!");
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: context.iconMedium,
          ),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: context.bodySmall,
              ),
            ),
          ),
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
      padding: EdgeInsets.all(context.w(12)),
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(width: context.gapMedium),
          Text(
            _processingMessage,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: context.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ----- Payment method selection -----
  // ============================================================
  Widget _buildPaymentMethodSection(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: _blue, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Expanded(
                child: Text(
                  'Choose Payment Method',
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.verified_user, color: _successGreen, size: 16),
              const SizedBox(width: 4),
              Text(
                'SSL Secured',
                style: TextStyle(
                  fontSize: context.labelSmall,
                  color: _successGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),
          Text(
            '100% secure & encrypted payments',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: context.bodySmall,
            ),
          ),
          SizedBox(height: context.gapMedium),
          _buildPaymentMethodsList(context),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList(BuildContext context) {
    final paymentMethods = [
      {
        'id': 'wallet',
        'name': 'My Wallet',
        'subtitle': 'Pay using your wallet balance',
        'icon': Icons.account_balance_wallet,
      },
      {
        'id': 'card',
        'name': 'Credit / Debit Card',
        'subtitle': 'Visa, Mastercard, Rupay',
        'icon': Icons.credit_card,
      },
      {
        'id': 'netbanking',
        'name': 'Net Banking',
        'subtitle': '40+ Banks Available',
        'icon': Icons.account_balance,
      },
      {
        'id': 'wallets',
        'name': 'Digital Wallets',
        'subtitle': 'Paytm, PhonePe, Amazon Pay',
        'icon': Icons.wallet,
      },
      {
        'id': 'upi',
        'name': 'UPI',
        'subtitle': 'GPay, PhonePe, BHIM & more',
        'icon': Icons.payment,
      },
      {
        'id': 'razorpay',
        'name': 'Razorpay',
        'subtitle': 'Cards, UPI, Net Banking (INR)',
        'icon': Icons.payment,
      },
    ];

    return Column(
      children: paymentMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method['id'];
        final isWallet = method['id'] == 'wallet';
        return GestureDetector(
          onTap: () {
            setState(() {
              // Toggle selection - deselect if already selected.
              _selectedPaymentMethod =
                  isSelected ? null : method['id'] as String;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(context.wp(3)),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isWallet ? _lightGreen : _blue.withValues(alpha: 0.05))
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? (isWallet ? _successGreen : _blue)
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  method['icon'] as IconData,
                  size: context.iconMedium,
                  color: isSelected
                      ? (isWallet ? _successGreen : _blue)
                      : Colors.grey.shade600,
                ),
                SizedBox(width: context.wp(3)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method['name'] as String,
                            style: TextStyle(
                              fontSize: context.bodyMedium,
                              fontWeight: FontWeight.w600,
                              color: _navy,
                            ),
                          ),
                          if (isSelected) ...[
                            const Spacer(),
                            Icon(
                              Icons.check_circle,
                              color: isWallet ? _successGreen : _blue,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        method['subtitle'] as String,
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // ----- Razorpay native-checkout flow -----
  // ============================================================

  Future<void> _initiateRazorpayPayment() async {
    setState(() {
      _isCreatingOrder = true;
      _loadingMessage = 'Preparing your booking...';
      _error = null;
    });

    try {
      final prefs = di.sl<PreferencesManager>();

      // Persist payload server-side before opening Razorpay checkout.
      await _callPrepareTicket(prefs, gateway: 'razorpay');
      if (!mounted) return;

      final dio = di.sl<DioClient>().instance;
      // reference_id must equal traceId so finalize can match the
      // RazorpayOrder via reference_id == trace_id.
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': _displayAmount,
          'currency': _displayCurrency,
          'reference_id': widget.traceId,
        },
      );

      _razorpayOrderId = response.data['order_id'] as String?;
      final keyId = response.data['key_id'] as String?;

      if (!mounted) return;
      setState(() => _isCreatingOrder = false);

      _razorpay.open({
        'key': keyId ?? '',
        'amount': (_displayAmount * 100).toInt(),
        'currency': _displayCurrency,
        'name': 'WanderNova',
        'description': 'Flight ${widget.route.from} → ${widget.route.to}',
        'order_id': _razorpayOrderId ?? '',
        'prefill': {
          'name':
              '${widget.passengerData['firstName'] ?? ''} ${widget.passengerData['lastName'] ?? ''}'
                  .trim(),
          'email': widget.passengerData['email'] ?? '',
          'contact':
              widget.passengerData['mobileNumber'] ??
              widget.passengerData['phone'] ??
              '',
        },
        'theme': {'color': '#1769F6'},
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingOrder = false;
        _error = 'Could not create payment order. Please try again.';
      });
      print('Razorpay order error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingOrder = false;
        _error = 'Could not start payment. Please try again.';
      });
      print('Razorpay init error: $e');
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isCreatingOrder = true;
      _loadingMessage = 'Verifying payment...';
      _error = null;
    });

    try {
      final dio = di.sl<DioClient>().instance;
      final verifyResponse = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'reference_id': widget.traceId,
        },
      );

      if (!mounted) return;
      setState(() => _isCreatingOrder = false);

      // if (verifyResponse.data['success'] == true) {
      //   await _callFinalizeTicket(gateway: 'razorpay');
      // }
      if (verifyResponse.data['success'] == true) {
        if (_isLcc) {
          await _callFinalizeTicket(gateway: 'razorpay');
        } else {
          _startBookingFlow();
        }
      }
      else {
        setState(() => _error = 'Payment verification failed. Please contact support.');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingOrder = false;
        _error = 'Could not verify payment. Please contact support.';
      });
      print('Razorpay verify error: ${e.message}');
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    setState(() => _error = 'Payment failed: ${response.message ?? 'Unknown error'}');
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    print('Razorpay external wallet: ${response.walletName}');
  }

  // ============================================================

  /// Routes payment to the correct gateway based on [_selectedPaymentMethod]:
  ///   wallet    → wallet-balance check then direct booking
  ///   razorpay  → Razorpay native checkout
  ///   everything else → CCAvenue hosted checkout (card/UPI/netbanking/wallets)
  Future<void> _processPayment() async {
    if (_sessionExpired) {
      setState(() => _error = 'Booking session expired. Please go back and search again.');
      return;
    }
    if (_selectedPaymentMethod == null) {
      setState(() => _error = 'Please select a payment method');
      return;
    }
    if (_selectedPaymentMethod == 'wallet') {
      await _payWithWallet();
      return;
    }
    if (_selectedPaymentMethod == 'razorpay') {
      await _initiateRazorpayPayment();
      return;
    }
    await _initiatePayment(); // CCAvenue: card, netbanking, wallets, upi
  }

  /// Pays from the wallet if its balance covers the total (uses
  /// [Urls.walletBalance]). There is no debit endpoint, so a sufficient
  /// balance is treated as a successful payment and the booking proceeds.
  Future<void> _payWithWallet() async {
    final prefs = di.sl<PreferencesManager>();
    if (!prefs.isLoggedIn()) {
      setState(() => _error = 'Please log in to pay with your wallet');
      return;
    }

    setState(() {
      _isCreatingOrder = true;
      _loadingMessage = 'Checking wallet balance...';
      _error = null;
    });

    try {
      final response = await di.sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;

      if (!mounted) return;
      setState(() => _isCreatingOrder = false);

      if (balance >= _displayAmount) {
        _startBookingFlow();
      } else {
        setState(() {
          _error =
              'Insufficient wallet balance '
              '($_displayCurrency ${balance.toStringAsFixed(2)} available)';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingOrder = false;
        _error = 'Could not fetch wallet balance. Please try again.';
      });
      print('Wallet balance error: $e');
    }
  }

  Widget _buildPayButton(BuildContext context) {
    final isEnabled = _selectedPaymentMethod != null && !_isProcessing && !_sessionExpired;
    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight + 10,
      child: ElevatedButton(
        onPressed: isEnabled ? _processPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? _blue : Colors.grey.shade300,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                _selectedPaymentMethod == null
                    ? 'Select a payment method'
                    : 'Pay $_displayTotal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: context.bodyLarge,
                ),
              ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(24),
        // border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
