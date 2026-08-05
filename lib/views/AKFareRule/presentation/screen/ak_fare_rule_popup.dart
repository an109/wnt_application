import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/AKFareRule/domain/entity/AKFareRule_entity.dart';
import 'package:wander_nova/views/AKFareRule/presentation/bloc/AKFareRule_bloc.dart';
import 'package:wander_nova/views/AKFareRule/presentation/bloc/AKFareRule_event.dart';
import 'package:wander_nova/views/AKFareRule/presentation/bloc/AKFareRule_state.dart';

/// Cancellation / change-fee rules for the selected fare, fetched from
/// Akbar's FareRule endpoint using the original search tui.
class AkFareRulePopup extends StatelessWidget {
  final String searchTui;
  final String resultIndex;
  final double amount;

  const AkFareRulePopup({
    super.key,
    required this.searchTui,
    required this.resultIndex,
    required this.amount,
  });

  static void show(
    BuildContext context, {
    required String searchTui,
    required String resultIndex,
    required double amount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => AkFareRulePopup(
        searchTui: searchTui,
        resultIndex: resultIndex,
        amount: amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AkFareRuleBloc>(
      create: (_) => sl<AkFareRuleBloc>()
        ..add(LoadAkFareRuleEvent(
          AkFareRuleRequestEntity(
            tui: searchTui,
            trips: [
              AkFareRuleTripRequestEntity(index: resultIndex, amount: amount, orderId: 1),
            ],
          ),
        )),
      child: Padding(
        padding: EdgeInsets.only(
          left: context.w(14),
          right: context.w(14),
          bottom: MediaQuery.of(context).viewInsets.bottom + context.h(14),
          top: context.h(8),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: context.screenHeight * 0.75),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.h(12)),
                child: Container(
                  width: context.w(36),
                  height: context.h(3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xffCBD5E1),
                    borderRadius: BorderRadius.circular(context.r(4)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                child: Row(
                  children: [
                    Icon(Icons.gavel_outlined, size: context.w(18), color: const Color(0xff1663F7)),
                    SizedBox(width: context.w(8)),
                    Text(
                      'Fare Rules',
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff07163B),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, size: context.w(18), color: const Color(0xff4B5563)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(10)),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(context.w(16), 0, context.w(16), context.h(16)),
                  child: BlocBuilder<AkFareRuleBloc, AkFareRuleState>(
                    builder: (context, state) {
                      if (state is AkFareRuleLoading || state is AkFareRuleInitial) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: context.h(30)),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                        );
                      }
                      if (state is AkFareRuleFailed) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: context.h(20)),
                          child: Text(
                            'Could not load fare rules for this fare.',
                            style: TextStyle(color: const Color(0xff6B7280), fontSize: context.fs(12)),
                          ),
                        );
                      }
                      final data = (state as AkFareRuleLoaded).data;
                      if (data.ruleTexts.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: context.h(20)),
                          child: Text(
                            'No fare rule details available for this fare.',
                            style: TextStyle(color: const Color(0xff6B7280), fontSize: context.fs(12)),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final rule in data.ruleTexts)
                            Padding(
                              padding: EdgeInsets.only(bottom: context.h(10)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: context.h(6)),
                                    child: Container(
                                      width: context.w(5),
                                      height: context.w(5),
                                      decoration: const BoxDecoration(
                                        color: Color(0xff1663F7),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: context.w(8)),
                                  Expanded(
                                    child: Text(
                                      rule,
                                      style: TextStyle(
                                        fontSize: context.fs(12),
                                        color: const Color(0xff3D3F4A),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
