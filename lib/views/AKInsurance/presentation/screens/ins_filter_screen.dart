import 'package:flutter/material.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../state/ins_plan_filter.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';

/// "Filters" — Figma `insurance Filter`.
/// Every row is built from the plans the provider actually returned for
/// this search: the supplier names and their counts, and one coverage row
/// per distinct sum insured. Nothing here is a fixed list, so a destination
/// that only has two suppliers shows two rows.
class InsFilterScreen extends StatefulWidget {
  final List<AkInsurancePlanEntity> plans;
  final InsPlanFilter filter;

  const InsFilterScreen({
    super.key,
    required this.plans,
    required this.filter,
  });

  static Future<InsPlanFilter?> show(
      BuildContext context, {
        required List<AkInsurancePlanEntity> plans,
        required InsPlanFilter filter,
      }) {
    return Navigator.of(context).push<InsPlanFilter>(
      MaterialPageRoute(
        builder: (_) => InsFilterScreen(plans: plans, filter: filter),
      ),
    );
  }

  @override
  State<InsFilterScreen> createState() => _InsFilterScreenState();
}

class _InsFilterScreenState extends State<InsFilterScreen> {
  late InsPlanFilter _draft = widget.filter;

  late final List<InsSupplierOption> _suppliers =
  InsPlanFilter.suppliersOf(widget.plans);
  late final List<InsCoverageBand> _bands =
  InsPlanFilter.coverageBandsOf(widget.plans);

  /// How many plans survive the draft — shown on the CTA so the traveller
  /// knows before applying.
  int get _matchCount => _draft.apply(widget.plans).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + context.h(2)),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: context.w(12),
                offset: Offset(0, context.h(3)),
              ),
            ],
          ),
          child: insAppBar(
            context,
            title: 'Filters',
            closeIcon: true,
            actions: [
              TextButton(
                onPressed: () =>
                    setState(() => _draft = const InsPlanFilter()),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: InsTokens.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(16),
          context.w(16),
          context.h(24),
        ),
        children: [
          _sortCard(context),
          SizedBox(height: context.h(16)),
          if (_suppliers.isNotEmpty) ...[
            _checkCard(
              context,
              title: 'Insurance Supplier',
              rows: [
                for (final s in _suppliers)
                  _CheckRow(
                    label: s.name,
                    count: s.count,
                    value: _draft.suppliers.contains(s.name),
                    onChanged: (on) => setState(() {
                      final next = Set<String>.from(_draft.suppliers);
                      on ? next.add(s.name) : next.remove(s.name);
                      _draft = _draft.copyWith(suppliers: next);
                    }),
                  ),
              ],
            ),
            SizedBox(height: context.h(16)),
          ],
          if (_bands.isNotEmpty)
            _checkCard(
              context,
              title: 'Coverage / Sum Assured',
              rows: [
                for (final b in _bands)
                  _CheckRow(
                    label: b.label,
                    count: b.count,
                    value: _draft.coverageFloors.contains(b.from),
                    onChanged: (on) => setState(() {
                      final next = Set<double>.from(_draft.coverageFloors);
                      on ? next.add(b.from) : next.remove(b.from);
                      _draft = _draft.copyWith(coverageFloors: next);
                    }),
                  ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: context.w(12),
              offset: Offset(0, -context.h(3)),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(12),
          context.w(16),
          context.h(0),
        ),
        child: SafeArea(
          top: false,
          child: InsPrimaryButton(
            label: _matchCount == 0
                ? 'NO PLANS MATCH'
                : 'APPLY FILTER ($_matchCount)',
            onPressed: _matchCount == 0
                ? null
                : () => Navigator.of(context).pop(_draft),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- pieces

  Widget _sortCard(BuildContext context) {
    // The filter screen spells the same orderings differently from the sort
    // sheet ("Most Capacity" rather than "Coverage (High to Low)"), so the
    // tile labels are given here rather than taken from the enum.
    final tiles = <(InsSortBy, String, IconData?, String?)>[
      (InsSortBy.popularity, 'Popularity', Icons.star_border_rounded, null),
      (InsSortBy.coverageHighToLow, 'Most Capacity', Icons.group_outlined, null),
      (InsSortBy.premiumHighToLow, 'Price: High to Low', null,
      'assets/NewIcons/priceHigh.png'),
      (InsSortBy.premiumLowToHigh, 'Price: Low to High', null,
      'assets/NewIcons/priceLow.png'),
    ];

    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: insCard(context, border: true, shadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: TextStyle(
              fontSize: context.fs(16),
              color: InsTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(13)),
          for (int r = 0; r < tiles.length; r += 2)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(12), ),
              child: Row(
                children: [
                  Expanded(child: _sortTile(context, tiles[r])),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: r + 1 < tiles.length
                        ? _sortTile(context, tiles[r + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Widget _sortTile(BuildContext context, (InsSortBy, String, IconData) tile) {
  Widget _sortTile(BuildContext context, (InsSortBy, String, IconData?, String?) tile) {
    final (value, label, iconData, assetPath) = tile;
    final selected = _draft.sortBy == value;
    final tint = selected ? InsTokens.blue : InsTokens.navy;

    return GestureDetector(
      onTap: () => setState(() => _draft = _draft.copyWith(sortBy: value)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.h(6),
          horizontal: context.w(12),
        ),
        decoration: BoxDecoration(
          color: selected ? InsTokens.blue.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(
            color: selected ? InsTokens.blue : InsTokens.line,
          ),
        ),
        child: Column(
          children: [
            // Asset image if present, otherwise a Material icon.
            assetPath != null
                ? Image.asset(
              assetPath,
              width: context.w(22),
              height: context.h(22),
              color: tint,          // 👈 tints PNG with the selected colour
            )
                : Icon(
              iconData,
              size: context.w(22),
              color: tint,          // 👈 same tint for the material icon
            ),
            SizedBox(height: context.h(8)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(13.5),
                color: tint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkCard(
      BuildContext context, {
        required String title,
        required List<_CheckRow> rows,
      }) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: insCard(context, border: true, shadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.fs(16),
              color: InsTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(12)),
          const Divider(height: 1, color: InsTokens.line),
          SizedBox(height: context.h(6)),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

/// One `Label (count)  [✓]` row inside a filter card.
class _CheckRow extends StatelessWidget {
  final String label;
  final int count;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckRow({
    required this.label,
    required this.count,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(13)),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w400,
                    color: InsTokens.navy,
                  ),
                  children: [
                    TextSpan(
                      text: ' ($count)',
                      style: TextStyle(
                        fontSize: context.fs(16),
                        color: InsTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InsCheckbox(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
