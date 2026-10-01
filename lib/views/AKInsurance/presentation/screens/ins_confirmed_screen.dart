import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../state/ins_booking_details.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';
import '../widgets/ins_plan_card.dart';

/// "Payment Successful" — Figma `insurance booking payment done`.
///
/// Reached only after a verified charge. [issuePending] distinguishes the
/// two outcomes that both involve the customer's money having been taken:
/// the policy came back with a number, or the insurer has not returned one
/// yet and support will reconcile from [paymentReference]. It is never a
/// "payment failed" screen.
class InsConfirmedScreen extends StatelessWidget {
  final AkInsurancePlanEntity plan;
  final InsSearchQuery query;
  final InsBookingDetails details;
  final double amount;
  final String paymentReference;
  final String paymentId;
  final String transactionId;
  final String policyNumber;
  final bool issuePending;
  final String issueMessage;

  const InsConfirmedScreen({
    super.key,
    required this.plan,
    required this.query,
    required this.details,
    required this.amount,
    required this.paymentReference,
    required this.paymentId,
    this.transactionId = '',
    this.policyNumber = '',
    this.issuePending = false,
    this.issueMessage = '',
  });

  /// What the big "CONFIRMATION NUMBER" band shows: the policy number when
  /// the insurer has issued one, otherwise the provider's transaction id,
  /// otherwise the payment reference — always something support can trace.
  String get _confirmation {
    if (policyNumber.isNotEmpty) return policyNumber;
    if (transactionId.isNotEmpty) return transactionId;
    return paymentReference;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // There is nothing useful to go back to — the quote is spent.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(30),
              context.w(14),
              context.h(20),
            ),
            children: [
              _headline(context),
              SizedBox(height: context.h(22)),
              _bookingIdPill(context),
              SizedBox(height: context.h(22)),
              if (issuePending) ...[
                InsErrorCard(
                  message: issueMessage.isEmpty
                      ? 'Your payment went through. The insurer has not '
                          'returned the policy document yet — our team will '
                          'email it to you shortly. Quote reference '
                          '$paymentReference.'
                      : '$issueMessage Your payment went through; quote '
                          'reference $paymentReference.',
                ),
                SizedBox(height: context.h(18)),
              ],
              _holderCard(context),
              SizedBox(height: context.h(16)),
              _planCard(context),
              SizedBox(height: context.h(16)),
              _amountCard(context),
              SizedBox(height: context.h(16)),
              _summaryCard(context),
              SizedBox(height: context.h(26)),
              _footerBrand(context),
            ],
          ),
        ),
        bottomNavigationBar: _actions(context),
      ),
    );
  }

  // ------------------------------------------------------------ headline

  Widget _headline(BuildContext context) {
    return Column(
      children: [
        Text(
          issuePending ? 'Payment Received!' : 'Payment Successful!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.fs(30),
            fontWeight: FontWeight.w700,
            color: InsTokens.blue,
          ),
        ),
        SizedBox(height: context.h(6)),
        Text(
          issuePending
              ? 'Your policy is being issued.'
              : 'Your booking is confirmed.',
          style: TextStyle(
            fontSize: context.fs(16),
            color: InsTokens.subGrey,
          ),
        ),
      ],
    );
  }

  Widget _bookingIdPill(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: paymentReference));
          insSnack(context, 'Booking ID copied');
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(18),
            vertical: context.h(12),
          ),
          decoration: BoxDecoration(
            color: InsTokens.blue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(context.r(10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Booking ID: ',
                style: TextStyle(
                  fontSize: context.fs(15),
                  color: InsTokens.subGrey,
                ),
              ),
              Flexible(
                child: Text(
                  paymentReference,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w600,
                    color: InsTokens.blue,
                  ),
                ),
              ),
              SizedBox(width: context.w(10)),
              Icon(Icons.copy_rounded,
                  size: context.w(19), color: InsTokens.blue),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- holder

  Widget _holderCard(BuildContext context) {
    final lead = details.lead;
    final p = details.proposer;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: InsTokens.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: InsTokens.confirmBand),
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(14),
              context.w(16),
              context.h(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policyNumber.isNotEmpty
                      ? 'POLICY NUMBER:'
                      : 'CONFIRMATION NUMBER:',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    letterSpacing: 0.3,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: context.h(5)),
                Text(
                  _confirmation,
                  style: TextStyle(
                    fontSize: context.fs(21),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(14),
              context.w(16),
              context.h(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POLICY HOLDER',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    letterSpacing: 0.3,
                    color: InsTokens.subGrey,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  '${lead.title} ${lead.fullName}',
                  style: TextStyle(
                    fontSize: context.fs(18),
                    fontWeight: FontWeight.w600,
                    color: InsTokens.navy,
                  ),
                ),
                SizedBox(height: context.h(10)),
                Wrap(
                  spacing: context.w(14),
                  runSpacing: context.h(6),
                  children: [
                    _iconText(context, Icons.mail_outline_rounded, p.email),
                    _iconText(context, Icons.phone_outlined,
                        '${p.dialCode} ${p.mobile}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.w(17), color: InsTokens.subGrey),
        SizedBox(width: context.w(6)),
        Text(
          text,
          style: TextStyle(
            fontSize: context.fs(14),
            color: InsTokens.subGrey,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- plan

  Widget _planCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: InsTokens.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InsProviderLogo(
            provider: plan.provider,
            logoUrl: plan.logoUrl,
            width: 96,
            height: 74,
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.planName,
                  style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: InsTokens.navy,
                  ),
                ),
                SizedBox(height: context.h(10)),
                _infoChip(
                  context,
                  Icons.location_on_rounded,
                  query.destinationLabel,
                ),
                SizedBox(height: context.h(8)),
                _infoChip(
                  context,
                  Icons.calendar_month_rounded,
                  query.tripSummary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(8),
      ),
      decoration: BoxDecoration(
        color: InsTokens.pageBg,
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: context.w(16), color: InsTokens.blue),
          SizedBox(width: context.w(7)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.fs(13.5),
                height: 1.3,
                color: InsTokens.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- amount

  Widget _amountCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        gradient: InsTokens.confirmBand,
      ),
      padding: EdgeInsets.all(context.w(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: context.w(92),
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: context.w(28), color: Colors.white),
                SizedBox(height: context.h(6)),
                Text(
                  'Amount Paid',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(13.5),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(context.w(14)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(9)),
              ),
              child: Column(
                children: [
                  _amountRow(context, 'Base Fare', InsTokens.rupees(amount)),
                  SizedBox(height: context.h(8)),
                  _amountRow(
                    context,
                    'Taxes & Fees',
                    'Included',
                    muted: true,
                  ),
                  SizedBox(height: context.h(10)),
                  const Divider(height: 1, color: InsTokens.line),
                  SizedBox(height: context.h(10)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total Paid',
                          style: TextStyle(
                            fontSize: context.fs(17),
                            fontWeight: FontWeight.w500,
                            color: InsTokens.navy,
                          ),
                        ),
                      ),
                      Text(
                        InsTokens.rupees(amount),
                        style: TextStyle(
                          fontSize: context.fs(19),
                          fontWeight: FontWeight.w700,
                          color: InsTokens.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    String value, {
    bool muted = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.fs(15),
              color: InsTokens.navy,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.fs(15),
            color: muted ? InsTokens.subGrey : InsTokens.navy,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- summary

  Widget _summaryCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: InsTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'BOOKING SUMMARY',
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: InsTokens.blue,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(6),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.r(20)),
                  border: Border.all(
                    color: issuePending ? InsTokens.orange : InsTokens.green,
                  ),
                ),
                child: Text(
                  issuePending ? 'Issuing' : 'Confirmed',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: issuePending ? InsTokens.orange : InsTokens.green,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          Container(
            padding: EdgeInsets.symmetric(vertical: context.h(12)),
            decoration: BoxDecoration(
              color: InsTokens.pageBg,
              borderRadius: BorderRadius.circular(context.r(8)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _summaryCell(
                      context,
                      Icons.credit_card_rounded,
                      'PAYMENT METHOD',
                      // The shared checkout settles every method through
                      // Razorpay, and the payment id is the only per-charge
                      // identifier it hands back.
                      'Razorpay',
                    ),
                  ),
                  const VerticalDivider(width: 1, color: InsTokens.line),
                  Expanded(
                    child: _summaryCell(
                      context,
                      Icons.event_rounded,
                      'BOOKING DATE',
                      DateFormat("d MMM''yy").format(DateTime.now()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(12)),
      child: Row(
        children: [
          Icon(icon, size: context.w(19), color: InsTokens.labelGrey),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(11.5),
                    letterSpacing: 0.2,
                    color: InsTokens.subGrey,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    color: InsTokens.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerBrand(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Thank you for choosing',
            style: TextStyle(
              fontSize: context.fs(11),
              color: InsTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            'WANDER NOVA',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: InsTokens.blue,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            'Have a great trip!',
            style: TextStyle(
              fontSize: context.fs(11),
              color: InsTokens.orange,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- actions

  Widget _actions(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(12),
        context.w(14),
        context.h(12),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: context.h(50),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: InsTokens.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(12)),
                    ),
                  ),
                  child: Text(
                    'GO TO HOME',
                    style: TextStyle(
                      fontSize: context.fs(14.5),
                      fontWeight: FontWeight.w600,
                      color: InsTokens.orange,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: InsPrimaryButton(
                label: 'COPY DETAILS',
                leading:
                    Icon(Icons.copy_all_rounded, size: context.w(19)),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: [
                        plan.planName,
                        if (policyNumber.isNotEmpty) 'Policy: $policyNumber',
                        if (transactionId.isNotEmpty)
                          'Transaction: $transactionId',
                        'Booking ID: $paymentReference',
                        'Payment: $paymentId',
                        'Amount: ${InsTokens.rupees(amount)}',
                      ].join('\n'),
                    ),
                  );
                  insSnack(context, 'Booking details copied');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
