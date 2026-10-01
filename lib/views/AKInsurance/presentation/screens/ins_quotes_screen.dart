import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../bloc/AKInsurance_bloc.dart';
import '../bloc/AKInsurance_event.dart';
import '../bloc/AKInsurance_state.dart';
import '../state/ins_plan_filter.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';
import '../widgets/ins_plan_card.dart';
import '../widgets/ins_sort_sheet.dart';
import 'ins_edit_search_screen.dart';
import 'ins_filter_screen.dart';
import 'ins_policy_details_screen.dart';
import 'ins_review_screen.dart';

/// "Select plan" — Figma `Select plan Individual`.
///
/// Renders whatever QuotesListing returned for the query it was pushed
/// with. The summary strip at the top re-opens the search through
/// [InsEditSearchScreen]; coming back re-issues the quote rather than
/// filtering the old list, since a different trip is a different rate.
class InsQuotesScreen extends StatefulWidget {
  final InsSearchQuery query;

  const InsQuotesScreen({super.key, required this.query});

  @override
  State<InsQuotesScreen> createState() => _InsQuotesScreenState();
}

class _InsQuotesScreenState extends State<InsQuotesScreen> {
  late InsSearchQuery _query = widget.query;
  InsPlanFilter _filter = const InsPlanFilter();

  AkInsuranceBloc get _bloc => context.read<AkInsuranceBloc>();

  Future<void> _editSearch() async {
    final updated = await InsEditSearchScreen.show(
      context,
      query: _query,
      bloc: _bloc,
    );
    if (updated == null || !mounted) return;

    setState(() {
      _query = updated;
      // Supplier/coverage choices are keyed to the old result set, so they
      // cannot be carried across to a different trip.
      _filter = const InsPlanFilter();
    });
    _bloc.add(LoadAkInsuranceQuotesEvent(updated.toQuotesRequest()));
  }

  Future<void> _openSort() async {
    final picked = await InsSortSheet.show(context, selected: _filter.sortBy);
    if (picked != null && mounted) {
      setState(() => _filter = _filter.copyWith(sortBy: picked));
    }
  }

  Future<void> _openFilter(List<AkInsurancePlanEntity> plans) async {
    final picked = await InsFilterScreen.show(
      context,
      plans: plans,
      filter: _filter,
    );
    if (picked != null && mounted) setState(() => _filter = picked);
  }

  void _openDetails(AkInsurancePlanEntity plan, String tui) {
    _bloc.add(LoadAkInsurancePlanDetailsEvent(plan.planId));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<AkInsuranceBloc>.value(
          value: _bloc,
          child: InsPolicyDetailsScreen(
            plan: plan,
            query: _query,
            tui: tui,
          ),
        ),
      ),
    );
  }

  void _select(AkInsurancePlanEntity plan, String tui) {
    _bloc.add(SelectAkInsurancePlanEvent(plan));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<AkInsuranceBloc>.value(
          value: _bloc,
          child: InsReviewScreen(plan: plan, query: _query, tui: tui),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: insAppBar(context, title: _query.policyType.label),
      body: BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
        builder: (context, state) {
          final all = state.quotes?.plans ?? const <AkInsurancePlanEntity>[];
          final shown = _filter.apply(all);
          final tui = state.quotes?.tui ?? '';

          return Column(
            children: [
              _summary(context),
              Expanded(
                child: switch (state.quotesStatus) {
                  AkInsuranceStatus.loading || AkInsuranceStatus.initial =>
                    const InsLoading(message: 'Finding plans for your trip…'),
                  AkInsuranceStatus.failed => InsEmpty(
                      title: 'We could not load plans',
                      message: state.errorMessage.isEmpty
                          ? 'Please try again in a moment.'
                          : state.errorMessage,
                      actionLabel: 'Try again',
                      icon: Icons.cloud_off_rounded,
                      onAction: () => _bloc.add(
                        LoadAkInsuranceQuotesEvent(_query.toQuotesRequest()),
                      ),
                    ),
                  AkInsuranceStatus.loaded => all.isEmpty
                      ? InsEmpty(
                          title: 'No plans for this trip',
                          message: state.quotes?.message.isNotEmpty == true
                              ? state.quotes!.message
                              : 'No cover is available for these '
                                  'destinations and dates. Try changing '
                                  'the trip.',
                          actionLabel: 'Edit search',
                          onAction: _editSearch,
                        )
                      : shown.isEmpty
                          ? InsEmpty(
                              title: 'No plans match your filters',
                              message:
                                  'Clear a filter to see the other '
                                  '${all.length} plans.',
                              actionLabel: 'Clear filters',
                              icon: Icons.filter_alt_off_rounded,
                              onAction: () => setState(
                                () => _filter = const InsPlanFilter(),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                context.w(14),
                                context.h(16),
                                context.w(14),
                                // Clear the floating Sort/Filter pill.
                                context.h(90),
                              ),
                              itemCount: shown.length,
                              itemBuilder: (_, i) => InsPlanCard(
                                plan: shown[i],
                                onDetails: () => _openDetails(shown[i], tui),
                                onSelect: () => _select(shown[i], tui),
                              ),
                            ),
                },
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
        builder: (context, state) {
          final all = state.quotes?.plans ?? const <AkInsurancePlanEntity>[];
          if (all.isEmpty) return const SizedBox.shrink();
          return _sortFilterBar(context, all);
        },
      ),
    );
  }

  // ------------------------------------------------------------- summary

  Widget _summary(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(8),
        context.w(14),
        context.h(4),
      ),
      child: GestureDetector(
        onTap: _editSearch,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(14),
          ),
          decoration: insCard(context, border: true, shadow: false),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _query.destinationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(16),
                        color: InsTokens.navy,
                      ),
                    ),
                    SizedBox(height: context.h(5)),
                    Text(
                      _query.tripSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(13),
                        color: InsTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(10)),
              Icon(Icons.edit_square,
                  size: context.w(22), color: InsTokens.blue),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------- sort/filter

  Widget _sortFilterBar(
    BuildContext context,
    List<AkInsurancePlanEntity> plans,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: context.h(6)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: context.w(18),
            offset: Offset(0, context.h(5)),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _barButton(
              context,
              icon: Icons.swap_vert_rounded,
              label: 'Sort',
              active: _filter.sortBy != InsSortBy.popularity,
              onTap: _openSort,
            ),
            const VerticalDivider(
              width: 1,
              indent: 12,
              endIndent: 12,
              color: InsTokens.line,
            ),
            _barButton(
              context,
              icon: Icons.tune_rounded,
              label: 'Filter',
              badge: _filter.activeCount,
              active: _filter.activeCount > 0,
              onTap: () => _openFilter(plans),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(21),
          vertical: context.h(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.w(21),
              color: active ? InsTokens.blue : InsTokens.navy,
            ),
            SizedBox(width: context.w(9)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? InsTokens.blue : InsTokens.navy,
              ),
            ),
            if (badge > 0) ...[
              SizedBox(width: context.w(6)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                  vertical: context.h(1),
                ),
                decoration: BoxDecoration(
                  color: InsTokens.blue,
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
