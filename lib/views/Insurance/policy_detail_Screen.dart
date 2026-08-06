import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../core/error/data_state.dart';
import '../../injection_container.dart' as di;
import '../AKInsurance/domain/entity/AKInsurance_entity.dart';
import '../AKInsurance/domain/usecase/AKInsurance_usecase.dart';
import 'insurance_quotesScreen.dart';

/// Bottom → top sliding "Policy Details" sheet (mirrors the web panel):
/// summary card, Premium Distributions table, Benefits table, Notes,
/// and a sticky CONTINUE CTA at the bottom (instead of Close).
///
/// Benefits/deductibles/terms are fetched live from PlanDetails (step 4/7)
/// when the sheet opens — [tui] is the tui the QuotesListing response that
/// produced [policy] carried, and must be echoed back on this call.
class PolicyDetailsSheet extends StatefulWidget {
  final InsurancePolicy policy;
  final InsuranceQuoteRequest request;
  final String tui;
  final VoidCallback? onContinue;

  const PolicyDetailsSheet({
    super.key,
    required this.policy,
    required this.request,
    required this.tui,
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
    required String tui,
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
        tui: tui,
        onContinue: onContinue,
      ),
    );
  }

  @override
  State<PolicyDetailsSheet> createState() => _PolicyDetailsSheetState();
}

enum _DetailsStatus { loading, loaded, failed }

class _PolicyDetailsSheetState extends State<PolicyDetailsSheet> {
  _DetailsStatus _status = _DetailsStatus.loading;
  AkInsurancePlanDetailsEntity? _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _DetailsStatus.loading);

    final isoFmt = DateFormat('yyyy-MM-dd');
    final travellers = [
      for (int i = 0; i < widget.request.travellerDobs.length; i++)
        AkInsuranceTravellerEntity(
          id: i,
          birthdate: isoFmt.format(widget.request.travellerDobs[i]!),
          relation: i == 0 ? 'SELF' : 'OTHER',
        ),
    ];

    final result = await di.sl<AkInsurancePlanDetailsUseCase>().call(
          AkInsurancePlanDetailsRequestEntity(
            planId: widget.policy.planId,
            countryNames: widget.request.travellingCountries,
            policyType: widget.request.insuranceType.toUpperCase(),
            startDate: isoFmt.format(widget.request.startDate),
            endDate: isoFmt.format(widget.request.endDate),
            travellers: travellers,
            tui: widget.tui,
          ),
        );

    if (!mounted) return;
    if (result is DataSuccess<AkInsurancePlanDetailsEntity>) {
      setState(() {
        _details = result.data;
        _status = _DetailsStatus.loaded;
      });
    } else {
      setState(() => _status = _DetailsStatus.failed);
    }
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
                ..._benefitsSection(context),
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
              widget.onContinue?.call();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: context.h(14)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [PolicyDetailsSheet._brandTeal, Color(0xFF044A56)]),
                borderRadius: BorderRadius.circular(context.r(12)),
                boxShadow: [
                  BoxShadow(
                      color: PolicyDetailsSheet._brandTeal.withOpacity(0.35),
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

  // ── Benefits / Deductibles — live from PlanDetails (step 4/7) ──────────
  List<Widget> _benefitsSection(BuildContext context) {
    if (_status == _DetailsStatus.loading) {
      return [
        _sectionTitle(context, 'Benefits'),
        SizedBox(height: context.h(10)),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(24)),
            child: const CircularProgressIndicator(
                color: PolicyDetailsSheet._brandBlue),
          ),
        ),
      ];
    }

    if (_status == _DetailsStatus.failed || _details == null) {
      return [
        _sectionTitle(context, 'Benefits'),
        SizedBox(height: context.h(10)),
        Container(
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
              Text('Could not load full benefit details right now.',
                  style: TextStyle(
                      fontSize: context.labelLarge,
                      color: Colors.grey.shade700)),
              SizedBox(height: context.h(8)),
              GestureDetector(
                onTap: _load,
                child: Text('Retry',
                    style: TextStyle(
                        fontSize: context.labelLarge,
                        fontWeight: FontWeight.w700,
                        color: PolicyDetailsSheet._brandBlue,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ),
      ];
    }

    final details = _details!;
    final widgets = <Widget>[
      _sectionTitle(context, 'Benefits'),
      SizedBox(height: context.h(10)),
      details.benefits.isEmpty
          ? _emptyNote(context, 'No benefit breakdown provided for this plan.')
          : _table(
              context,
              ['Benefit', 'Cover'],
              details.benefits.map((b) => [b.title, b.value]).toList(),
              flexes: const [3, 2],
            ),
    ];

    if (details.deductibles.isNotEmpty) {
      widgets.addAll([
        SizedBox(height: context.h(18)),
        _sectionTitle(context, 'Deductibles'),
        SizedBox(height: context.h(10)),
        _table(
          context,
          ['Item', 'Deductible'],
          details.deductibles.map((d) => [d.title, d.value]).toList(),
          flexes: const [3, 2],
        ),
      ]);
    }

    if (details.healthQuestions.isNotEmpty) {
      widgets.addAll([
        SizedBox(height: context.h(18)),
        _sectionTitle(context, 'Health Questions'),
        SizedBox(height: context.h(10)),
        Container(
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
              for (final q in details.healthQuestions)
                Padding(
                  padding: EdgeInsets.only(bottom: context.h(6)),
                  child: Text('•  $q',
                      style: TextStyle(
                          fontSize: context.labelLarge,
                          height: 1.5,
                          color: Colors.grey.shade700)),
                ),
            ],
          ),
        ),
      ]);
    }

    return widgets;
  }

  Widget _emptyNote(BuildContext context, String text) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: context.labelLarge, color: Colors.grey.shade700)),
      );

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
          _logoBox(context, widget.policy.supplier),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(widget.policy.planName,
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
          _stat(context, 'Plan Type', widget.request.insuranceType),
          _vDivider(context),
          _stat(context, 'Coverage', 'USD${fmt.format(widget.policy.coverageUsd)}'),
          _vDivider(context),
          _stat(context, 'Premium', '₹${fmt.format(widget.policy.premiumInr)}',
              color: PolicyDetailsSheet._accentOrange),
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
    final total = widget.policy.premiumInr * widget.request.travellers;
    return _tableBox(context, [
      _tableRow(context, ['Relation', 'Total Premium'],
          flexes: const [3, 2], header: true),
      for (int i = 0; i < widget.request.travellers; i++) ...[
        Divider(height: 1, color: Colors.grey.shade200),
        _tableRow(context, [
          widget.request.travellers == 1 ? 'SELF' : 'Traveller ${i + 1}',
          '₹${fmt.format(widget.policy.premiumInr)}'
        ], flexes: const [3, 2]),
      ],
      Divider(height: 1, color: Colors.grey.shade200),
      _tableRow(context, ['Grand Total', '₹${fmt.format(total)}'],
          flexes: const [3, 2], bold: true, shaded: true),
    ]);
  }

  Widget _notesCard(BuildContext context) {
    final terms = _details?.termsAndConditions ?? '';
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
          if (terms.isNotEmpty) ...[
            Text(terms,
                style: TextStyle(
                    fontSize: context.labelLarge,
                    height: 1.5,
                    color: Colors.grey.shade700)),
            SizedBox(height: context.h(8)),
          ],
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
      color: header || shaded ? PolicyDetailsSheet._tableHead : Colors.white,
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
            colors: [Color(0xFF1A4FA0), PolicyDetailsSheet._brandBlue]),
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
