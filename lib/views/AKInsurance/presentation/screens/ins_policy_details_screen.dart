import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../bloc/AKInsurance_bloc.dart';
import '../bloc/AKInsurance_event.dart';
import '../bloc/AKInsurance_state.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';
import '../widgets/ins_plan_card.dart';
import 'ins_review_screen.dart';

/// "Policy Details" — Figma `Select plan Individual policy details`.
///
/// Everything below the header comes from the PlanDetails call the quotes
/// screen kicks off before pushing this route; the header itself is drawn
/// from the quote row so there is something on screen while that lands.
class InsPolicyDetailsScreen extends StatelessWidget {
  final AkInsurancePlanEntity plan;
  final InsSearchQuery query;
  final String tui;

  const InsPolicyDetailsScreen({
    super.key,
    required this.plan,
    required this.query,
    required this.tui,
  });

  void _continue(BuildContext context) {
    context.read<AkInsuranceBloc>().add(SelectAkInsurancePlanEvent(plan));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider<AkInsuranceBloc>.value(
          value: context.read<AkInsuranceBloc>(),
          child: InsReviewScreen(plan: plan, query: query, tui: tui),
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final url = plan.documentUrl;
    if (url == null) {
      insSnack(
        context,
        'This insurer does not publish a downloadable wording for this plan.',
      );
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      insSnack(context, 'Could not open the policy document.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: insAppBar(context, title: 'Policy Details', closeIcon: true),
      body: BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
        builder: (context, state) {
          // PlanDetails is per-plan; ignore a response still in flight for a
          // different row the traveller tapped first.
          final details = state.planDetails?.planId == plan.planId
              ? state.planDetails
              : null;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(14),
              context.w(14),
              context.h(24),
            ),
            children: [
              _headerCard(context, details),
              SizedBox(height: context.h(26)),
              Text(
                'Benefits',
                style: TextStyle(
                  fontSize: context.fs(20),
                  fontWeight: FontWeight.w400,
                  color: InsTokens.navy,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                "Travel with confidence. Here's what you're covered for.",
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w400,
                  color: InsTokens.subGrey,
                ),
              ),
              SizedBox(height: context.h(14)),
              if (state.planDetailsStatus == AkInsuranceStatus.loading &&
                  details == null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.h(40)),
                  child: const InsLoading(message: 'Loading benefits…'),
                )
              else if (details == null || details.benefits.isEmpty)
                _noBenefits(context, state)
              else ...[
                  _benefitsTable(context, details),
                  SizedBox(height: context.h(18)),
                  _note(context, details),
                ],
            ],
          );
        },
      ),
      // Footer with upward shadow onto the list above.
      bottomNavigationBar: _footer(context),
    );
  }

  // -------------------------------------------------------------- header

  Widget _headerCard(
      BuildContext context,
      AkInsurancePlanDetailsEntity? details,
      ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            InsTokens.blue.withOpacity(0.22),
            InsTokens.blue.withOpacity(0.06),
          ],
        ),

      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(18),
              context.w(14),
              context.h(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InsProviderLogo(
                      provider: plan.provider,
                      logoUrl: plan.logoUrl,
                      width: 72,
                      height: 58,
                    ),
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: context.w(70)),
                            child: Text(
                              plan.planName,
                              style: TextStyle(
                                fontSize: context.fs(16),
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                                color: InsTokens.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(14)),
                // Full width, below the logo+name row: three chips beside a
                // logo wrap onto two lines on a phone.
                Row(
                  children: [
                    Expanded(
                      child: _chip(context, 'Plan Type',
                          query.policyType.label, InsTokens.green),
                    ),
                    if (plan.sumInsured > 0) ...[
                      SizedBox(width: context.w(8)),
                      Expanded(
                        child: _chip(
                          context,
                          'Coverage',
                          InsTokens.coverage(plan.sumInsured),
                          InsTokens.orange,
                        ),
                      ),
                    ],
                    SizedBox(width: context.w(8)),
                    Expanded(
                      child: _chip(
                        context,
                        'Premium',
                        InsTokens.rupees(details?.premium ?? plan.premium),
                        InsTokens.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(18)),
                Row(
                  children: [
                    Icon(Icons.diamond_rounded,
                        size: context.w(19), color: InsTokens.blue),
                    SizedBox(width: context.w(8)),
                    Text(
                      'Premium Distributions',
                      style: TextStyle(
                        fontSize: context.fs(16),
                        color: InsTokens.navy,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Divider(height: 1, color: InsTokens.blue.withOpacity(0.25)),
                SizedBox(height: context.h(12)),
                _distribution(context, details),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(14),
                vertical: context.h(8),
              ),
              decoration: BoxDecoration(
                color: InsTokens.blue,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(context.r(14)),
                  bottomLeft: Radius.circular(context.r(18)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded,
                      size: context.w(16), color: Colors.white),
                  SizedBox(width: context.w(5)),
                  Text(
                    'SELECTED',
                    style: TextStyle(
                      fontSize: context.fs(12.5),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _chip(
      BuildContext context,
      String label,
      String value,
      Color valueColour,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(6),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(context.r(6)),
        border: Border.all(color: valueColour.withOpacity(0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: context.fs(8),
              fontWeight: FontWeight.w500,
              color: InsTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(1)),
          // Constrained by Expanded now, so a long cover figure shrinks to
          // fit rather than overflowing its chip.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w600,
                color: valueColour,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One row per traveller — the relation the quote was priced with on the
  /// left, the total on the right. The provider prices the party as a whole,
  /// so the total sits against the lead rather than being split per head.
  Widget _distribution(
      BuildContext context,
      AkInsurancePlanDetailsEntity? details,
      ) {
    final total = details?.premium ?? plan.premium;

    return Column(
      children: [
        for (int i = 0; i < query.travellers.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: context.h(6)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relation',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        color: InsTokens.subGrey,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      _titleCase(query.relationFor(i)),
                      style: TextStyle(
                        fontSize: context.fs(17),
                        color: InsTokens.navy,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (i == 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Premium',
                        style: TextStyle(
                          fontSize: context.fs(14),
                          color: InsTokens.orange,
                        ),
                      ),
                      SizedBox(height: context.h(2)),
                      Text(
                        InsTokens.rupees(total),
                        style: TextStyle(
                          fontSize: context.fs(17),
                          fontWeight: FontWeight.w500,
                          color: InsTokens.blue,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  // ------------------------------------------------------------ benefits

  Widget _benefitsTable(
      BuildContext context,
      AkInsurancePlanDetailsEntity details,
      ) {
    // Deductibles arrive as their own list keyed by the same benefit title,
    // so the third column is filled by matching on title and falls back to
    // the provider's own "N.A." when there is no match.
    final deductibleByTitle = {
      for (final d in details.deductibles) d.title.toLowerCase().trim(): d.value,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: InsTokens.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(12)),
        child: Column(
          children: [
            Container(
              color: Color(0xFF80DAFF),
              padding: EdgeInsets.symmetric(vertical: context.h(14)),
              child: Row(
                children: [
                  _cell(context, 'Benefit', flex: 5, header: true),
                  _cell(context, 'Sum Insured', flex: 3, header: true),
                  _cell(context, 'Deductible', flex: 4, header: true),
                ],
              ),
            ),
            for (int i = 0; i < details.benefits.length; i++)
              Container(
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : const Border(
                    top: BorderSide(color: InsTokens.line),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: context.h(14)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cell(context, details.benefits[i].title, flex: 5),
                    _cell(
                      context,
                      details.benefits[i].value.isEmpty
                          ? 'Up to SI'
                          : details.benefits[i].value,
                      flex: 3,
                    ),
                    _cell(
                      context,
                      deductibleByTitle[
                      details.benefits[i].title.toLowerCase().trim()] ??
                          'N.A.',
                      flex: 4,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(
      BuildContext context,
      String text, {
        required int flex,
        bool header = false,
      }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.w(8)),
        child: Text(
          text,
          style: TextStyle(
            fontSize: context.fs(header ? 14 : 12),
            // height: 1.3,
            fontWeight: header ? FontWeight.w600 : FontWeight.w400,
            color: header ? AppColors.white : InsTokens.navy,
          ),
        ),
      ),
    );
  }

  Widget _note(BuildContext context, AkInsurancePlanDetailsEntity details) {
    final terms = details.termsAndConditions.trim();
    return RichText(
      text: TextSpan(
        text: 'Note : ',
        style: TextStyle(
          fontSize: context.fs(14),
          fontWeight: FontWeight.w600,
          color: InsTokens.blue,
        ),
        children: [
          TextSpan(
            text: terms.isEmpty
                ? 'These premiums are inclusive of GST and shown in INR.'
                : terms,
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: InsTokens.subGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noBenefits(BuildContext context, AkInsuranceState state) {
    return Container(
      padding: EdgeInsets.all(context.w(18)),
      decoration: insCard(context, border: true, shadow: false),
      child: Text(
        state.planDetailsStatus == AkInsuranceStatus.failed
            ? (state.errorMessage.isEmpty
            ? 'The insurer did not return a benefit list for this plan.'
            : state.errorMessage)
            : 'The insurer did not return a benefit list for this plan. '
            'The cover and premium above still apply.',
        style: TextStyle(
          fontSize: context.fs(13.5),
          height: 1.45,
          color: InsTokens.subGrey,
        ),
      ),
    );
  }

  // -------------------------------------------------------------- footer

  Widget _footer(BuildContext context) {
    return Container(
      width: double.infinity, // full-bleed to both edges
      decoration: BoxDecoration(
        color: Colors.white,
        // Shadow cast UP onto the list above.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: context.r(10),
            offset: Offset(0, -context.h(4)), // cast UP
          ),
        ],
      ),
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
                height: context.h(48),
                child: OutlinedButton.icon(
                  onPressed: () => _download(context),
                  icon: Image.asset(
                    'assets/NewIcons/download.png',
                    width: context.w(18),
                    height: context.w(18),
                    color: InsTokens.orange,
                  ),
                  label: Text(
                    'DOWNLOAD',
                    style: TextStyle(
                      fontSize: context.fs(14.5),
                      fontWeight: FontWeight.w600,
                      color: InsTokens.orange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: InsTokens.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(12)),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: InsPrimaryButton(
                label: 'CONTINUE',
                onPressed: () => _continue(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}