import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../UI_helper/responsive_layout.dart';
import 'insurance_quotesScreen.dart';


/// Bottom → top sliding "Policy Details" sheet (mirrors the web panel):
/// summary card, Premium Distributions table, Benefits table, Notes,
/// and a sticky CONTINUE CTA at the bottom (instead of Close).
class PolicyDetailsSheet extends StatelessWidget {
  final InsurancePolicy policy;
  final InsuranceQuoteRequest request;
  final VoidCallback? onContinue;

  const PolicyDetailsSheet({
    super.key,
    required this.policy,
    required this.request,
    this.onContinue,
  });

  static const Color _brandBlue = Color(0xFF003B95);
  static const Color _brandTeal = Color(0xFF005B7F);
  static const Color _accentOrange = Color(0xFFE23A1E);
  static const Color _tableHead = Color(0xFFEEF2F7);

  /// Slides the sheet in from the bottom.
  static Future<void> show(
      BuildContext context, {
        required InsurancePolicy policy,
        required InsuranceQuoteRequest request,
        VoidCallback? onContinue,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => PolicyDetailsSheet(
        policy: policy,
        request: request,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(context.r(20))),
      ),
      child: Column(children: [
        // drag handle
        Container(
          margin: EdgeInsets.only(top: context.h(10)),
          width: context.w(44),
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // header: title + Download + close
        Padding(
          padding: EdgeInsets.fromLTRB(
              context.w(16), context.h(12), context.w(14), context.h(12)),
          child: Row(children: [
            Expanded(
              child: Text('Policy Details',
                  style: TextStyle(
                      fontSize: context.titleMedium,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
            ),
            GestureDetector(
              onTap: () {
                // TODO: download policy PDF.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('PDF will be available after purchase')));
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(14), vertical: context.h(8)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF8BD418), Color(0xFF6FB500)]),
                  borderRadius: BorderRadius.circular(context.r(20)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.download_rounded,
                      size: context.iconXSmall + 4, color: Colors.white),
                  SizedBox(width: context.w(4)),
                  Text('Download',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: context.labelLarge,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.only(left: context.w(10)),
                padding: EdgeInsets.all(context.w(5)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(Icons.close_rounded,
                    size: context.iconSmall, color: Colors.grey.shade600),
              ),
            ),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        // scrollable body
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.w(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryCard(context, fmt),
                SizedBox(height: context.h(18)),
                _sectionTitle(context, 'Premium Distributions'),
                SizedBox(height: context.h(10)),
                _premiumTable(context, fmt),
                SizedBox(height: context.h(18)),
                _sectionTitle(context, 'Benefits'),
                SizedBox(height: context.h(10)),
                _table(context, ['Name', 'Sum Insured', 'Deductible'],
                    _benefits(fmt)),
                SizedBox(height: context.h(18)),
                _sectionTitle(context, 'Notes'),
                SizedBox(height: context.h(10)),
                _notesCard(context),
              ],
            ),
          ),
        ),
        // sticky CONTINUE (replaces web's Close)
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
              context.w(16), context.h(10), context.w(16), context.h(12)),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context); // dismiss sheet first
              onContinue?.call();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: context.h(14)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_brandTeal, Color(0xFF044A56)]),
                borderRadius: BorderRadius.circular(context.r(12)),
                boxShadow: [
                  BoxShadow(
                      color: _brandTeal.withOpacity(0.35),
                      blurRadius: context.w(12),
                      offset: Offset(0, context.h(4))),
                ],
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('CONTINUE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: context.bodyLarge,
                            fontWeight: FontWeight.w800,
                            letterSpacing: context.letterSpacingWider)),
                    SizedBox(width: context.w(6)),
                    Icon(Icons.arrow_forward_rounded,
                        size: context.iconSmall, color: Colors.white),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Summary card (logo + name + Plan Type / Coverage / Premium) ────────
  Widget _summaryCard(BuildContext context, NumberFormat fmt) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: [
        Row(children: [
          _logoBox(context, policy.supplier),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(policy.planName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87)),
          ),
        ]),
        SizedBox(height: context.h(10)),
        Divider(height: 1, color: Colors.grey.shade200),
        SizedBox(height: context.h(8)),
        Row(children: [
          _stat(context, 'Plan Type', request.insuranceType),
          _vDivider(context),
          _stat(context, 'Coverage', 'USD${fmt.format(policy.coverageUsd)}'),
          _vDivider(context),
          _stat(context, 'Premium', '₹${fmt.format(policy.premiumInr)}',
              color: _accentOrange),
        ]),
      ]),
    );
  }

  Widget _stat(BuildContext context, String label, String value,
      {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: context.overline,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: context.letterSpacingWider)),
          SizedBox(height: context.h(2)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w800,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _vDivider(BuildContext context) => Container(
    width: 1,
    height: context.h(26),
    margin: EdgeInsets.symmetric(horizontal: context.w(10)),
    color: Colors.grey.shade200,
  );

  // ── Premium Distributions (SELF / per-traveller + grand total) ─────────
  Widget _premiumTable(BuildContext context, NumberFormat fmt) {
    final total = policy.premiumInr * request.travellers;
    return _tableBox(context, [
      _tableRow(context, ['Relation', 'Total Premium'],
          flexes: const [3, 2], header: true),
      for (int i = 0; i < request.travellers; i++) ...[
        Divider(height: 1, color: Colors.grey.shade200),
        _tableRow(context, [
          request.travellers == 1 ? 'SELF' : 'Traveller ${i + 1}',
          '₹${fmt.format(policy.premiumInr)}'
        ], flexes: const [3, 2]),
      ],
      Divider(height: 1, color: Colors.grey.shade200),
      _tableRow(context, ['Grand Total', '₹${fmt.format(total)}'],
          flexes: const [3, 2], bold: true, shaded: true),
    ]);
  }

  // ── Benefits rows (same content as the web panel) ──────────────────────
  List<List<String>> _benefits(NumberFormat fmt) {
    final cov = 'USD ${fmt.format(policy.coverageUsd)}';
    return [
      ['Medical Expenses – Injury and/or Illness', 'Unlimited Sum Insured with $cov per incident/loss arising out of the same illness/injury. Maximum liability – PED upto USD 2,500 (life threatening condition)', 'Nil'],
      ['Emergency Medical Evacuation', 'Upto Section 1 Sum Insured', 'USD 100'],
      ['Repatriation of Mortal Remains', '25% of Section 1 Sum Insured (over and above)', 'Nil'],
      ['Accidental Death & Disablement (Overseas)', 'AD: USD 10,000; Disablement: USD 10,000; Total – USD 10,000', 'Nil'],
      ['Emergency Medical Dental Expenses', 'USD 300', 'USD 50'],
      ['Personal Liability', 'USD 100,000', 'USD 200'],
      ['Trip Curtailment', 'USD 500', 'USD 50'],
      ['Trip Cancellation', 'USD 500', 'USD 50'],
      ['Missed Flight/Connection', 'USD 250', 'Nil'],
      ['Bounced Hotel / Airline Booking', 'USD 500', 'USD 50'],
      ['Fraudulent Charges', 'Per Occurrence Limit: USD 250; Aggregate Limit: USD 500', 'Nil'],
      ['Emergency Extension of the Policy', '7 days', 'Nil'],
      ['Home Content Burglary (In INR)', 'INR 50,000', 'INR 5,000'],
      ['Accommodation Extension', 'USD 100 per day, max upto 10 days', 'Nil'],
    ];
  }

  Widget _notesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'We understand that this policy does not cover any pre-existing medical condition/injury/illness/deformity and complications arising from them that are declared or undeclared.',
              style: TextStyle(
                  fontSize: context.labelLarge,
                  height: 1.5,
                  color: Colors.grey.shade700)),
          SizedBox(height: context.h(8)),
          Text('These Premium are inclusive of @18% GST and in INR.',
              style: TextStyle(
                  fontSize: context.labelLarge,
                  height: 1.5,
                  color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // ── Generic table helpers ───────────────────────────────────────────────
  Widget _sectionTitle(BuildContext context, String t) => Text(t,
      style: TextStyle(
          fontSize: context.titleSmall,
          fontWeight: FontWeight.w800,
          color: Colors.black87));

  Widget _tableBox(BuildContext context, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }

  Widget _table(BuildContext context, List<String> header,
      List<List<String>> rows,
      {List<int> flexes = const [3, 5, 2]}) {
    return _tableBox(context, [
      _tableRow(context, header, flexes: flexes, header: true),
      for (final r in rows) ...[
        Divider(height: 1, color: Colors.grey.shade200),
        _tableRow(context, r, flexes: flexes),
      ],
    ]);
  }

  Widget _tableRow(BuildContext context, List<String> cells,
      {List<int> flexes = const [3, 5, 2],
        bool header = false,
        bool bold = false,
        bool shaded = false}) {
    return Container(
      color: header || shaded ? _tableHead : Colors.white,
      padding: EdgeInsets.symmetric(
          horizontal: context.w(12), vertical: context.h(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < cells.length; i++)
            Expanded(
              flex: flexes[i],
              child: Text(cells[i],
                  style: TextStyle(
                      fontSize: header
                          ? context.labelLarge
                          : context.labelMedium,
                      fontWeight:
                      header || bold ? FontWeight.w800 : FontWeight.w500,
                      color: header
                          ? Colors.grey.shade700
                          : Colors.black87)),
            ),
        ],
      ),
    );
  }

  Widget _logoBox(BuildContext context, String supplier) {
    final initials = supplier
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    return Container(
      width: context.w(44),
      height: context.w(44),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A4FA0), _brandBlue]),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: context.bodyLarge)),
      ),
    );
  }
}