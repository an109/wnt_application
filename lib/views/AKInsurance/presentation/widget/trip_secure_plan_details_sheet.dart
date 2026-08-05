import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../domain/entity/AKInsurance_entity.dart';
import '../bloc/AKInsurance_bloc.dart';
import '../bloc/AKInsurance_event.dart';
import '../bloc/AKInsurance_state.dart';

/// Bottom sheet for step 4/7 — benefits, deductibles, the PED questionnaire
/// and the terms of a single plan.
///
/// Driven by the same [AkInsuranceBloc] instance as the section that opened
/// it, so the details call and the selection stay in one place.
class TripSecurePlanDetailsSheet extends StatelessWidget {
  final AkInsurancePlanEntity plan;
  final String Function(double amount, String currency) formatAmount;
  final VoidCallback onAddPlan;

  const TripSecurePlanDetailsSheet({
    super.key,
    required this.plan,
    required this.formatAmount,
    required this.onAddPlan,
  });

  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _border = Color(0xFFE2E7F0);

  static Future<void> show({
    required BuildContext context,
    required AkInsuranceBloc bloc,
    required AkInsurancePlanEntity plan,
    required String Function(double amount, String currency) formatAmount,
    required VoidCallback onAddPlan,
  }) {
    bloc.add(LoadAkInsurancePlanDetailsEvent(plan.planId));
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<AkInsuranceBloc>.value(
        value: bloc,
        child: TripSecurePlanDetailsSheet(
          plan: plan,
          formatAmount: formatAmount,
          onAddPlan: onAddPlan,
        ),
      ),
    ).whenComplete(() => bloc.add(const ClearAkInsurancePlanDetailsEvent()));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: context.screenHeight * 0.85),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20))),
      ),
      child: BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: context.h(10)),
              Container(
                width: context.w(40),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: const Color(0xffD8DEEA),
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
              ),
              _header(context, state),
              Divider(height: context.h(1), color: _border),
              Flexible(child: _body(context, state)),
              _footer(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, AkInsuranceState state) {
    final name = state.planDetails?.planName.isNotEmpty == true
        ? state.planDetails!.planName
        : plan.planName;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(14), context.w(8), context.h(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: _blue, size: context.w(22)),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                if (plan.provider.isNotEmpty) ...[
                  SizedBox(height: context.h(2)),
                  Text(
                    plan.provider,
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: const Color(0xff6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, size: context.w(20), color: const Color(0xff6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AkInsuranceState state) {
    if (state.planDetailsStatus == AkInsuranceStatus.loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(48)),
        child: const Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    final details = state.planDetails;
    if (details == null) {
      return Padding(
        padding: EdgeInsets.all(context.w(24)),
        child: Text(
          state.errorMessage.isNotEmpty
              ? state.errorMessage
              : 'Plan details are not available right now.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: context.fs(12), color: const Color(0xff6B7280)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(14), context.w(16), context.h(14)),
      physics: context.scrollPhysics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.benefits.isNotEmpty)
            _group(context, "What's covered", details.benefits, Icons.check_circle_outline),
          if (details.deductibles.isNotEmpty)
            _group(context, 'Deductibles', details.deductibles, Icons.remove_circle_outline),
          if (details.healthQuestions.isNotEmpty) ...[
            _groupTitle(context, 'Health declaration'),
            for (final question in details.healthQuestions)
              Padding(
                padding: EdgeInsets.only(bottom: context.h(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: context.h(5)),
                      child: Container(
                        width: context.w(5),
                        height: context.w(5),
                        decoration: const BoxDecoration(
                          color: Color(0xff9CA3AF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontSize: context.fs(11.5),
                          color: const Color(0xff4B5563),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: context.h(6)),
          ],
          if (details.termsAndConditions.isNotEmpty) ...[
            _groupTitle(context, 'Terms & conditions'),
            Text(
              details.termsAndConditions,
              style: TextStyle(
                fontSize: context.fs(11),
                color: const Color(0xff6B7280),
                height: 1.5,
              ),
            ),
          ],
          if (details.benefits.isEmpty &&
              details.deductibles.isEmpty &&
              details.healthQuestions.isEmpty &&
              details.termsAndConditions.isEmpty)
            Text(
              'The provider did not return any additional detail for this plan.',
              style: TextStyle(fontSize: context.fs(12), color: const Color(0xff6B7280)),
            ),
        ],
      ),
    );
  }

  Widget _groupTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.fs(13),
          fontWeight: FontWeight.w800,
          color: _navy,
        ),
      ),
    );
  }

  Widget _group(
    BuildContext context,
    String title,
    List<AkInsuranceBenefitEntity> rows,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupTitle(context, title),
        for (final row in rows)
          Padding(
            padding: EdgeInsets.only(bottom: context.h(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: context.w(15), color: _blue),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    row.title,
                    style: TextStyle(
                      fontSize: context.fs(11.5),
                      color: const Color(0xff374151),
                      height: 1.35,
                    ),
                  ),
                ),
                if (row.value.isNotEmpty) ...[
                  SizedBox(width: context.w(10)),
                  Text(
                    row.value,
                    style: TextStyle(
                      fontSize: context.fs(11.5),
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ],
              ],
            ),
          ),
        SizedBox(height: context.h(6)),
      ],
    );
  }

  Widget _footer(BuildContext context, AkInsuranceState state) {
    final premium = (state.planDetails?.premium ?? 0) > 0
        ? state.planDetails!.premium
        : plan.premium;
    final currency = state.planDetails?.currency.isNotEmpty == true
        ? state.planDetails!.currency
        : plan.currency;
    final isSelected = state.selectedPlan?.planId == plan.planId;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(context.w(16), context.h(10), context.w(16), context.h(10)),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Premium',
                  style: TextStyle(fontSize: context.fs(10), color: const Color(0xff6B7280)),
                ),
                Text(
                  formatAmount(premium, currency),
                  style: TextStyle(
                    fontSize: context.fs(17),
                    fontWeight: FontWeight.w900,
                    color: _navy,
                  ),
                ),
              ],
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: SizedBox(
                height: context.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    onAddPlan();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(14)),
                    ),
                  ),
                  child: Text(
                    isSelected ? 'Keep this plan' : 'Add this plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: context.fs(13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
