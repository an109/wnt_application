import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../UpcomingTrips/data/models/tripModel.dart';

/// A compact "at a glance" summary card for a visa booking — gradient header
/// with the visa reference + payment status, followed by trip details,
/// dates, the total amount and payment info.
///
/// This is intentionally a brand-new, self-contained widget (not the
/// full-page voucher/invoice look used by [VisaTicketWidget] /
/// [VisaInvoiceWidget]) so it can be dropped in anywhere — a dialog, a
/// bottom sheet, or inline in a list — without touching any existing screen.
class VisaBookingSummaryCard extends StatelessWidget {
  final String refId;
  final String destination;
  final String visaType;
  final int applicants;
  final String travelDate;
  final String returnDate;
  final String bookedDate;
  final String totalAmountDisplay;

  /// e.g. 'Paid', 'Payment Pending', 'Cancelled'.
  final String paymentStatusLabel;

  /// e.g. a CCAvenue/wallet reference number. Shown next to the status if present.
  final String? paymentReference;

  const VisaBookingSummaryCard({
    super.key,
    required this.refId,
    required this.destination,
    required this.visaType,
    required this.applicants,
    required this.travelDate,
    required this.returnDate,
    required this.bookedDate,
    required this.totalAmountDisplay,
    required this.paymentStatusLabel,
    this.paymentReference,
  });

  /// Convenience constructor for the existing [TripItem] model used across
  /// the My Bookings screens (read-only — TripItem itself is untouched).
  factory VisaBookingSummaryCard.fromTrip(
    TripItem trip, {
    String? paymentReference,
  }) {
    final applicants = int.tryParse(trip.applicantCount) ?? 1;
    return VisaBookingSummaryCard(
      refId: trip.refId,
      destination: trip.destination,
      visaType: trip.type,
      applicants: applicants,
      travelDate: trip.onwardDate,
      returnDate: trip.returnDate,
      bookedDate: trip.bookedDate,
      totalAmountDisplay: trip.getFormattedPrice(),
      paymentStatusLabel: trip.status,
      paymentReference: paymentReference,
    );
  }

  static const Color _gradientStart = Color(0xffE91E8C);
  static const Color _gradientEnd = Color(0xff9C27B0);
  static const Color _ink = Color(0xff1A1A2E);
  static const Color _maroon = Color(0xff9C1F3F);

  bool get _isPending => paymentStatusLabel.toLowerCase().contains('pending');
  bool get _isCancelled => paymentStatusLabel.toLowerCase().contains('cancelled');

  Color get _statusColor {
    if (_isCancelled) return const Color(0xffE53935);
    if (_isPending) return const Color(0xffF57C00);
    return const Color(0xff2E7D32);
  }

  /// Convenience wrapper around [show] that maps a [TripItem] the same way
  /// [VisaBookingSummaryCard.fromTrip] does.
  static Future<void> showFromTrip(
    BuildContext context,
    TripItem trip, {
    String? paymentReference,
  }) {
    final applicants = int.tryParse(trip.applicantCount) ?? 1;
    return show(
      context,
      refId: trip.refId,
      destination: trip.destination,
      visaType: trip.type,
      applicants: applicants,
      travelDate: trip.onwardDate,
      returnDate: trip.returnDate,
      bookedDate: trip.bookedDate,
      totalAmountDisplay: trip.getFormattedPrice(),
      paymentStatusLabel: trip.status,
      paymentReference: paymentReference,
    );
  }

  /// Shows the card as a centered dialog with a floating close button,
  /// matching the reference design. Purely additive — does not replace any
  /// existing navigation flow.
  static Future<void> show(
    BuildContext context, {
    required String refId,
    required String destination,
    required String visaType,
    required int applicants,
    required String travelDate,
    required String returnDate,
    required String bookedDate,
    required String totalAmountDisplay,
    required String paymentStatusLabel,
    String? paymentReference,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) {
        return Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: dialogContext.w(20)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: dialogContext.w(420),
                    maxHeight: dialogContext.screenHeight * 0.85,
                  ),
                  child: SingleChildScrollView(
                    child: VisaBookingSummaryCard(
                      refId: refId,
                      destination: destination,
                      visaType: visaType,
                      applicants: applicants,
                      travelDate: travelDate,
                      returnDate: returnDate,
                      bookedDate: bookedDate,
                      totalAmountDisplay: totalAmountDisplay,
                      paymentStatusLabel: paymentStatusLabel,
                      paymentReference: paymentReference,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: dialogContext.h(48),
              right: dialogContext.w(16),
              child: _CloseButton(onTap: () => Navigator.of(dialogContext).pop()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(18)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.w(24), offset: Offset(0, context.h(8))),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: EdgeInsets.all(context.w(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionBlock(
                    context,
                    icon: Icons.description_outlined,
                    title: 'TRIP DETAILS',
                    rows: [
                      _InfoRow('Details', '$applicants applicant(s)'),
                      _InfoRow('Travellers', '$applicants Person${applicants > 1 ? 's' : ''}'),
                      _InfoRow('Applicants', '$applicants'),
                    ],
                  ),
                  SizedBox(height: context.h(12)),
                  _buildSectionBlock(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'DATES',
                    rows: [
                      _InfoRow('Travel', travelDate),
                      _InfoRow('Return', returnDate),
                      _InfoRow('Booked', bookedDate),
                    ],
                  ),
                  SizedBox(height: context.h(12)),
                  _buildTotalAmountBlock(context),
                  SizedBox(height: context.h(12)),
                  _buildSectionBlock(
                    context,
                    icon: Icons.credit_card_outlined,
                    title: 'PAYMENT',
                    rows: [
                      _InfoRow(
                        'Method',
                        paymentReference != null && paymentReference!.isNotEmpty
                            ? '$paymentStatusLabel · $paymentReference'
                            : paymentStatusLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(16)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pill(context, label: 'VISA', background: Colors.white.withOpacity(0.25), textColor: Colors.white),
              _pill(context, label: paymentStatusLabel, background: Colors.white, textColor: _statusColor),
            ],
          ),
          SizedBox(height: context.h(14)),
          Text(
            '$destination — $visaType',
            style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
          ),
          SizedBox(height: context.h(4)),
          Text(
            'Ref: $refId',
            style: TextStyle(fontSize: context.fs(12), color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, {required String label, required Color background, required Color textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(5)),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(context.r(20))),
      child: Text(
        label,
        style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Widget _buildSectionBlock(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<_InfoRow> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.r(10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.iconSmall, color: Colors.grey.shade600),
              SizedBox(width: context.w(6)),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: context.h(8)),
            _row(context, rows[i].label, rows[i].value),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalAmountBlock(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(12)),
      decoration: BoxDecoration(color: const Color(0xffFDF1F4), borderRadius: BorderRadius.circular(context.r(10))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total amount', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: _maroon)),
          Text(
            totalAmountDisplay,
            style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w800, color: _maroon),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade600)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: _ink),
          ),
        ),
      ],
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(context.w(10)),
          child: Icon(Icons.close, size: context.iconMedium, color: const Color(0xff1A1A2E)),
        ),
      ),
    );
  }
}
