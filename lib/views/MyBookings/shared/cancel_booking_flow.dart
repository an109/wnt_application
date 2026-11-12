import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';
import 'cancellation_service.dart';
import 'trip_detail_widgets.dart';

/// All info needed to cancel + refund a booking.
class CancelBookingParams {
  final String bookingType;
  final String bookingId;
  final String route;
  final String detail;
  final double amount;
  final String currency;

  /// Backend booking_type: flight | hotel | transport | visa | holidays
  final String apiBookingType;

  /// Database primary key of the booking.
  final int entityId;

  /// Hotel confirmation number (for TBO cancel).
  final String? hotelConfirmationNumber;

  /// Mozio reservation ID (for transport cancel).
  final String? transportReservationId;

  final String? checkoutId;
  final String? ccavenueOrderId;
  final String? razorpayOrderId;
  final String? paidVia;

  const CancelBookingParams({
    required this.bookingType,
    required this.bookingId,
    required this.route,
    required this.detail,
    required this.amount,
    required this.currency,
    required this.apiBookingType,
    required this.entityId,
    this.hotelConfirmationNumber,
    this.transportReservationId,
    this.checkoutId,
    this.ccavenueOrderId,
    this.razorpayOrderId,
    this.paidVia,
  });
}

/// Shows a bottom sheet that handles the full cancel + refund flow
/// (matching the frontend's single modal):
/// 1. Confirmation with refund method choice
/// 2. Processing spinner
/// 3. Result (success with breakdown, or error)
///
/// Returns `true` if cancelled successfully, `false`/`null` otherwise.
Future<bool?> showCancelAndRefundSheet(
  BuildContext context, {
  required CancelBookingParams params,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheet) => _CancelRefundSheet(params: params),
  );
}

class _CancelRefundSheet extends StatefulWidget {
  final CancelBookingParams params;
  const _CancelRefundSheet({required this.params});

  @override
  State<_CancelRefundSheet> createState() => _CancelRefundSheetState();
}

class _CancelRefundSheetState extends State<_CancelRefundSheet> {
  String _refundMethod = 'wallet';
  bool _processing = false;
  Map<String, dynamic>? _result;

  CancelBookingParams get p => widget.params;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            context.fx(20), context.fx(12), context.fx(20), context.fx(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: context.fx(40),
                height: context.fx(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: context.fx(16)),
            if (_result != null)
              _resultView(context)
            else if (_processing)
              _processingView(context)
            else
              _confirmView(context),
          ],
        ),
      ),
    );
  }

  // ── Confirm view (step 1) ──
  Widget _confirmView(BuildContext context) {
    final typeLabel = {
      'hotel': 'Hotel',
      'transport': 'Transport',
      'flight': 'Flight',
      'visa': 'Visa',
      'holidays': 'Holiday',
    }[p.apiBookingType] ?? p.bookingType;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cancel $typeLabel Booking?',
          style: TextStyle(
            fontSize: context.ffs(18),
            fontWeight: FontWeight.w700,
            color: kInk,
          ),
        ),
        SizedBox(height: context.fx(6)),
        Text(
          'Are you sure you want to cancel your booking for ${p.route}?',
          style: TextStyle(
            fontSize: context.ffs(14),
            color: const Color(0xFF4B5563),
          ),
        ),
        SizedBox(height: context.fx(4)),
        Text(
          'Ref: ${p.bookingId} · ${p.detail}',
          style: TextStyle(
            fontSize: context.ffs(13),
            color: kMuted,
          ),
        ),
        if (p.apiBookingType == 'flight') ...[
          SizedBox(height: context.fx(6)),
          Text(
            'Cancellation charges as per airline policy will apply.',
            style: TextStyle(fontSize: context.ffs(12), color: const Color(0xFF9CA3AF)),
          ),
        ],
        if (p.amount > 0) ...[
          SizedBox(height: context.fx(14)),
          Container(
            padding: EdgeInsets.all(context.fx(12)),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(context.fx(8)),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where would you like your refund?',
                  style: TextStyle(
                    fontSize: context.ffs(13),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                SizedBox(height: context.fx(8)),
                _radioOption(
                  context,
                  value: 'wallet',
                  label: 'Refund to Wallet',
                  hint: 'Instant, no platform fee',
                  hintColor: kGreen,
                ),
                _radioOption(
                  context,
                  value: 'original_payment',
                  label: 'Refund to Original Payment Method',
                  hint: 'Platform fee applies',
                  hintColor: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: context.fx(18)),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.fx(8))),
                  minimumSize: Size.fromHeight(context.fx(46)),
                ),
                child: Text(
                  'Keep Booking',
                  style: TextStyle(
                    fontSize: context.ffs(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: context.fx(12)),
            Expanded(
              child: FilledButton(
                onPressed: _handleCancelAndRefund,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.fx(8))),
                  minimumSize: Size.fromHeight(context.fx(46)),
                ),
                child: Text(
                  'Yes, Cancel & Refund',
                  style: TextStyle(
                    fontSize: context.ffs(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _radioOption(
    BuildContext context, {
    required String value,
    required String label,
    required String hint,
    required Color hintColor,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _refundMethod = value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.fx(6)),
        child: Row(
          children: [
            Icon(
              _refundMethod == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: context.fx(20),
              color: _refundMethod == value ? AppColors.AppBlue : kMuted,
            ),
            SizedBox(width: context.fx(8)),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: context.ffs(14),
                    color: kInk,
                  ),
                  children: [
                    TextSpan(
                      text: '  ($hint)',
                      style: TextStyle(
                        fontSize: context.ffs(12),
                        fontWeight: FontWeight.w500,
                        color: hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Processing view ──
  Widget _processingView(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.fx(32)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: context.fx(32),
            height: context.fx(32),
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: context.fx(16)),
          Text(
            'Processing cancellation & refund...',
            style: TextStyle(
              fontSize: context.ffs(14),
              fontWeight: FontWeight.w500,
              color: kMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Result view (step 3) ──
  Widget _resultView(BuildContext context) {
    final ok = _result!['success'] == true;
    final message = _result!['message']?.toString() ??
        _result!['error']?.toString() ??
        (ok ? 'Cancellation successful.' : 'Cancellation failed.');
    final refundAmt = (_result!['refund_amount'] as num?)?.toDouble() ?? 0;
    final platformFee = (_result!['platform_fee'] as num?)?.toDouble() ?? 0;
    final providerPenalty =
        (_result!['provider_penalty'] as num?)?.toDouble() ?? 0;
    final cur = p.currency.isEmpty ? 'INR' : p.currency;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ok ? 'Cancellation & Refund' : 'Cancellation Status',
          style: TextStyle(
            fontSize: context.ffs(18),
            fontWeight: FontWeight.w700,
            color: ok ? kGreen : const Color(0xFFDC2626),
          ),
        ),
        SizedBox(height: context.fx(8)),
        Text(
          message,
          style: TextStyle(
            fontSize: context.ffs(14),
            color: const Color(0xFF374151),
          ),
        ),
        if (ok && refundAmt > 0) ...[
          SizedBox(height: context.fx(12)),
          Container(
            padding: EdgeInsets.all(context.fx(12)),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(context.fx(8)),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              children: [
                _breakdownRow(context, 'Refund Amount',
                    formatMoney(refundAmt, cur),
                    bold: true),
                if (platformFee > 0)
                  _breakdownRow(context, 'Platform Fee',
                      formatMoney(platformFee, cur),
                      muted: true),
                if (providerPenalty > 0)
                  _breakdownRow(context, 'Cancellation Charges',
                      formatMoney(providerPenalty, cur),
                      muted: true),
              ],
            ),
          ),
        ],
        SizedBox(height: context.fx(18)),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, ok),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.AppBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.fx(8))),
              padding: EdgeInsets.symmetric(
                  horizontal: context.fx(24), vertical: context.fx(10)),
            ),
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: context.ffs(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _breakdownRow(BuildContext context, String label, String value,
      {bool bold = false, bool muted = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.fx(2)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: context.ffs(13),
                color: muted ? kMuted : kInk,
              )),
          Text(value,
              style: TextStyle(
                fontSize: context.ffs(13),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: muted ? kMuted : kInk,
              )),
        ],
      ),
    );
  }

  // ── Cancel + refund logic (mirrors frontend handleCancelWithRefund) ──
  Future<void> _handleCancelAndRefund() async {
    setState(() => _processing = true);

    try {
      final svc = CancellationService();

      // Step 1: Cancel the booking with the provider.
      if (p.apiBookingType == 'hotel' &&
          p.hotelConfirmationNumber != null &&
          p.hotelConfirmationNumber!.isNotEmpty) {
        try {
          await svc.cancelHotel(p.hotelConfirmationNumber!);
        } catch (e) {
          final msg = e.toString().toLowerCase();
          if (!msg.contains('cancelled')) rethrow;
        }
      } else if (p.apiBookingType == 'transport' &&
          p.transportReservationId != null &&
          p.transportReservationId!.isNotEmpty) {
        await svc.cancelTransport(p.transportReservationId!);
      }

      // Step 2: Process refund.
      final shouldRefund = p.amount > 0 || p.paidVia == 'razorpay';
      if (shouldRefund) {
        final res = await svc.autoRefund(
          bookingType: p.apiBookingType,
          bookingId: p.entityId,
          refundMethod: _refundMethod,
          originalAmount: p.amount,
          checkoutId: p.checkoutId,
          ccavenueOrderId: p.ccavenueOrderId,
          razorpayOrderId: p.razorpayOrderId,
          paidVia: p.paidVia,
        );
        if (!mounted) return;
        setState(() {
          _processing = false;
          _result = res;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _processing = false;
          _result = {
            'success': true,
            'message':
                'Booking cancelled. No refund applicable (amount is zero).',
          };
        });
      }
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString();
      final displayMsg = errMsg.length > 150
          ? errMsg.substring(0, 150)
          : errMsg;
      setState(() {
        _processing = false;
        _result = {
          'success': false,
          'message': 'Cancellation failed: $displayMsg',
        };
      });
    }
  }
}
