import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/injection_container.dart' as di;
import 'package:wander_nova/views/home/presentation/screens/home_screen.dart';
import '../../UI_helper/responsive_layout.dart';
import '../../common_widgets/logo.dart';
import '../../core/constants/urls.dart';
import '../../core/network/dio_client.dart';

class HotelConfirmationScreen extends StatefulWidget {
  final String confirmationNumber;
  final String bookingReferenceId;
  final String hotelName;
  final String checkIn;
  final String checkOut;
  final String roomName;
  final double totalFare;
  final String currency;
  final String guestName;
  final String email;
  final bool isPending;

  /// ISO-8601 UTC timestamp when the booking was created.
  /// Used to determine HCN SLA window.
  final String bookedAt;

  const HotelConfirmationScreen({
    super.key,
    required this.confirmationNumber,
    required this.bookingReferenceId,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
    required this.roomName,
    required this.totalFare,
    required this.currency,
    required this.guestName,
    required this.email,
    this.isPending = false,
    this.bookedAt = '',
  });

  @override
  State<HotelConfirmationScreen> createState() => _HotelConfirmationScreenState();
}

class _HotelConfirmationScreenState extends State<HotelConfirmationScreen> {
  // HCN state
  String? _hcn;
  String _hcnStatus = 'idle'; // idle | wait | polling | found | escalate | error
  String _hcnMessage = '';
  int _hcnRetryCount = 0;
  Timer? _hcnTimer;

  @override
  void initState() {
    super.initState();
    // Kick off HCN polling only when we have a real booking reference
    if (widget.bookingReferenceId.isNotEmpty &&
        widget.checkIn.isNotEmpty &&
        widget.bookedAt.isNotEmpty) {
      _startHcnPolling();
    }
  }

  @override
  void dispose() {
    _hcnTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // HCN polling
  // ---------------------------------------------------------------------------

  void _startHcnPolling() {
    // First check immediately, then repeat based on backend guidance
    _checkHcnStatus();
  }

  Future<void> _checkHcnStatus() async {
    if (!mounted) return;
    setState(() => _hcnStatus = 'polling');

    try {
      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(Urls.hotelHcnStatus, data: {
        'BookingReferenceId': widget.bookingReferenceId,
        'PaymentMode': 'Limit',
        'BookingCreatedAt': widget.bookedAt.isNotEmpty
            ? widget.bookedAt
            : DateTime.now().toUtc().toIso8601String(),
        'CheckInDate': widget.checkIn,
        'RetryCount': _hcnRetryCount,
      });

      final data = response.data as Map<String, dynamic>? ?? {};
      final status = data['status'] as String? ?? '';

      if (!mounted) return;

      switch (status) {
        case 'found':
          setState(() {
            _hcn = data['hcn']?.toString() ?? '';
            _hcnStatus = 'found';
            _hcnMessage = '';
          });
          break;

        case 'wait':
          final slaHours = data['sla_hours'] ?? 0;
          setState(() {
            _hcnStatus = 'wait';
            _hcnMessage =
                'Hotel confirmation number (HCN) will be available within $slaHours hour(s) of booking.';
          });
          // Re-check after sla_hours (but cap to 6 hours for timer)
          final delayHours = (slaHours as num).toInt().clamp(1, 6);
          _scheduleHcnRetry(Duration(hours: delayHours));
          break;

        case 'retry':
          _hcnRetryCount++;
          final retryAfter = (data['retry_after_seconds'] as num? ?? 3600).toInt();
          setState(() {
            _hcnStatus = 'wait';
            _hcnMessage =
                'HCN not yet available. Checking again in ${retryAfter ~/ 60} min.';
          });
          _scheduleHcnRetry(Duration(seconds: retryAfter));
          break;

        case 'escalate':
          setState(() {
            _hcnStatus = 'escalate';
            _hcnMessage =
                'HCN could not be retrieved. Please contact support with your booking reference.';
          });
          break;

        case 'not_applicable':
          // HCN not expected for this booking window — silent
          setState(() => _hcnStatus = 'idle');
          break;

        default:
          setState(() {
            _hcnStatus = 'error';
            _hcnMessage = 'Unexpected HCN response.';
          });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _hcnStatus = 'error';
        _hcnMessage = 'Could not fetch HCN: ${e.message}';
      });
      // Retry after 30 min on network error
      _scheduleHcnRetry(const Duration(minutes: 30));
    }
  }

  void _scheduleHcnRetry(Duration after) {
    _hcnTimer?.cancel();
    _hcnTimer = Timer(after, () {
      if (mounted) _checkHcnStatus();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _goHome(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const WanderNovaLogo(scaleFactor: 0.6),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: EdgeInsets.all(context.w(8)),
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
            children: [
              SizedBox(height: context.gapLarge),
              _buildStatusBanner(context),
              SizedBox(height: context.gapLarge),
              _buildConfirmationCard(context),
              if (_hcn != null && _hcn!.isNotEmpty) ...[
                SizedBox(height: context.gapLarge),
                _buildHcnCard(context),
              ],
              if (_hcnStatus == 'wait' || _hcnStatus == 'polling') ...[
                SizedBox(height: context.gapLarge),
                _buildHcnPendingCard(context),
              ],
              if (_hcnStatus == 'escalate') ...[
                SizedBox(height: context.gapLarge),
                _buildHcnEscalateCard(context),
              ],
              SizedBox(height: context.gapLarge),
              _buildBookingDetailsCard(context),
              SizedBox(height: context.gapLarge),
              _buildEmailNotice(context),
              SizedBox(height: context.gapLarge),
              _buildHomeButton(context),
              SizedBox(height: context.gapLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.gapLarge),
      decoration: BoxDecoration(
        color: widget.isPending ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(
            color: widget.isPending ? Colors.orange.shade200 : Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(
            widget.isPending ? Icons.access_time_rounded : Icons.check_circle_rounded,
            size: 64,
            color: widget.isPending ? Colors.orange.shade600 : Colors.green.shade600,
          ),
          SizedBox(height: context.gapMedium),
          Text(
            widget.isPending ? 'Booking Pending' : 'Booking Confirmed!',
            style: TextStyle(
              fontSize: context.headlineMedium,
              fontWeight: FontWeight.bold,
              color: widget.isPending ? Colors.orange.shade800 : Colors.green.shade800,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            widget.isPending
                ? 'Your payment was successful. Your booking is being processed and you will receive a confirmation email shortly.'
                : 'Your hotel booking has been confirmed. A confirmation email has been sent to ${widget.email}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.bodySmall,
              color: widget.isPending ? Colors.orange.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Reference',
            style: TextStyle(
                fontSize: context.titleMedium, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: context.gapMedium),
          _refRow(context, 'Confirmation No.', widget.confirmationNumber),
          if (widget.bookingReferenceId != widget.confirmationNumber) ...[
            SizedBox(height: context.gapSmall),
            _refRow(context, 'Reference ID', widget.bookingReferenceId),
          ],
        ],
      ),
    );
  }

  Widget _buildHcnCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hotel, color: Colors.green.shade700, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Text(
                'Hotel Confirmation Number',
                style: TextStyle(
                    fontSize: context.titleMedium, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),
          _refRow(context, 'HCN', _hcn!),
        ],
      ),
    );
  }

  Widget _buildHcnPendingCard(BuildContext context) {
    final isPolling = _hcnStatus == 'polling';
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          if (isPolling)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.blue.shade700),
            )
          else
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Text(
              isPolling
                  ? 'Fetching hotel confirmation number...'
                  : _hcnMessage.isNotEmpty
                      ? _hcnMessage
                      : 'Hotel confirmation number (HCN) will be provided per TBO SLA.',
              style: TextStyle(
                  color: Colors.blue.shade800, fontSize: context.bodySmall),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHcnEscalateCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.shade700, size: context.iconMedium),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Text(
              _hcnMessage,
              style: TextStyle(
                  color: Colors.orange.shade800, fontSize: context.bodySmall),
            ),
          ),
        ],
      ),
    );
  }

  Widget _refRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: context.bodySmall,
                      color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: context.bodyLarge,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied to clipboard'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          color: Colors.grey.shade500,
          tooltip: 'Copy',
        ),
      ],
    );
  }

  Widget _buildBookingDetailsCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hotel, color: Colors.indigo, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Text('Booking Details',
                  style: TextStyle(
                      fontSize: context.titleMedium,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: context.gapMedium),
          _detailRow(context, Icons.business, widget.hotelName),
          if (widget.roomName.isNotEmpty) ...[
            SizedBox(height: context.gapSmall),
            _detailRow(context, Icons.bed, widget.roomName),
          ],
          SizedBox(height: context.gapSmall),
          _detailRow(context, Icons.calendar_today, 'Check-in: ${widget.checkIn}'),
          SizedBox(height: context.gapSmall),
          _detailRow(
              context, Icons.calendar_month, 'Check-out: ${widget.checkOut}'),
          SizedBox(height: context.gapSmall),
          _detailRow(context, Icons.person,
              widget.guestName.isNotEmpty ? widget.guestName : 'Guest'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Paid',
                  style: TextStyle(
                      fontSize: context.bodyLarge,
                      fontWeight: FontWeight.bold)),
              Text(
                '${widget.currency} ${widget.totalFare.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE71D36)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        SizedBox(width: context.gapSmall),
        Expanded(
            child:
                Text(text, style: TextStyle(fontSize: context.bodyMedium))),
      ],
    );
  }

  Widget _buildEmailNotice(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.email_outlined,
              color: Colors.blue.shade700, size: context.iconMedium),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Text(
              'Booking details and hotel voucher will be sent to ${widget.email}',
              style: TextStyle(
                  fontSize: context.bodySmall, color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight + 10,
      child: ElevatedButton(
        onPressed: () => _goHome(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE71D36),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.borderRadius)),
          elevation: 2,
        ),
        child: Text(
          'Back to Home',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: context.bodyLarge),
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    // Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}
