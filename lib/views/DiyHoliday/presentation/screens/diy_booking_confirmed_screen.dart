import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../widgets/diy_common.dart';

/// "Booking payment done" — the Figma confirmation.
///
/// Reached only after the charge has settled and been verified server-side,
/// so this screen never fails: it reports what happened and gives the
/// customer their references. [consultantPending] is true when the DIY
/// enquiry could not be filed after payment — the booking still stands, so
/// the copy says a consultant will be in touch rather than showing an error.
class DiyBookingConfirmedScreen extends StatelessWidget {
  final String packageTitle;
  final String destination;
  final DateTime? departureDate;
  final int nights;
  final int travellers;
  final double amount;
  final String currency;
  final String paymentReference;
  final String paymentId;
  final String? enquiryReference;
  final bool consultantPending;

  const DiyBookingConfirmedScreen({
    super.key,
    required this.packageTitle,
    required this.amount,
    required this.paymentReference,
    required this.paymentId,
    this.destination = '',
    this.departureDate,
    this.nights = 0,
    this.travellers = 0,
    this.currency = 'INR',
    this.enquiryReference,
    this.consultantPending = false,
  });

  String get _dateLabel {
    final d = departureDate;
    return d == null ? '' : diyFullDate(d);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back must not return to the payment screen — that money is spent.
      canPop: false,
      child: Scaffold(
        backgroundColor: DiyTokens.pageBg,
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.w(18),
              context.h(28),
              context.w(18),
              context.h(24),
            ),
            children: [
              Center(
                child: Container(
                  width: context.w(78),
                  height: context.w(78),
                  decoration: const BoxDecoration(
                    color: Color(0xFF17A46A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: context.w(44),
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: context.h(18)),
              Text(
                'Booking Confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.fs(21),
                  fontWeight: FontWeight.w800,
                  color: DiyTokens.navy,
                ),
              ),
              SizedBox(height: context.h(7)),
              Text(
                consultantPending
                    ? 'Your payment went through. A consultant will confirm '
                          'the details with you shortly.'
                    : 'Your payment went through and your consultant has your '
                          'trip. They will be in touch to confirm the details.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.fs(12.5),
                  height: 1.5,
                  color: DiyTokens.subGrey,
                ),
              ),
              SizedBox(height: context.h(22)),
              _summaryCard(context),
              SizedBox(height: context.h(12)),
              _referenceCard(context),
              SizedBox(height: context.h(24)),
              SizedBox(
                height: context.h(48),
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiyTokens.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                  ),
                  child: Text(
                    'DONE',
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            packageTitle,
            style: TextStyle(
              fontSize: context.fs(15),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
          SizedBox(height: context.h(4)),
          Text(
            [
              if (destination.isNotEmpty) destination,
              if (_dateLabel.isNotEmpty) _dateLabel,
              if (nights > 0) '$nights Night${nights == 1 ? '' : 's'}',
              if (travellers > 0)
                '$travellers Traveller${travellers == 1 ? '' : 's'}',
            ].join(' · '),
            style: TextStyle(
              fontSize: context.fs(11.5),
              color: DiyTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(14)),
          const Divider(height: 1, color: DiyTokens.line),
          SizedBox(height: context.h(12)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Amount paid',
                  style: TextStyle(
                    fontSize: context.fs(12.5),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ),
              Text(
                diyMoney(amount, currency: currency),
                style: TextStyle(
                  fontSize: context.fs(17),
                  fontWeight: FontWeight.w800,
                  color: DiyTokens.navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referenceCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        children: [
          _referenceRow(context, 'Booking reference', paymentReference),
          SizedBox(height: context.h(10)),
          _referenceRow(context, 'Payment ID', paymentId),
          if (enquiryReference != null && enquiryReference!.isNotEmpty) ...[
            SizedBox(height: context.h(10)),
            _referenceRow(context, 'Consultant reference', enquiryReference!),
          ],
        ],
      ),
    );
  }

  Widget _referenceRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.fs(11.5),
              color: DiyTokens.subGrey,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(11.5),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
        ),
        SizedBox(width: context.w(6)),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            diySnack(context, '$label copied');
          },
          behavior: HitTestBehavior.opaque,
          child: Icon(
            Icons.copy_rounded,
            size: context.w(14),
            color: DiyTokens.blue,
          ),
        ),
      ],
    );
  }
}
