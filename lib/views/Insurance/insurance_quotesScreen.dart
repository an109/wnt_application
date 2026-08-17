import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../AKInsurance/presentation/bloc/AKInsurance_bloc.dart';
import '../AKInsurance/presentation/bloc/AKInsurance_event.dart';
import '../AKInsurance/presentation/bloc/AKInsurance_state.dart';
import 'insurance_models.dart';
import 'new_booking_Screen.dart';
import 'policy_detail_Screen.dart';

export 'insurance_models.dart';

class _Bucket {
  final String label;
  final int min;
  final int max;
  const _Bucket(this.label, this.min, this.max);
}

const String _kUnknownCoverageLabel = 'Coverage not specified';

const List<_Bucket> _buckets = [
  _Bucket('USD 0 - 50,000', 0, 50000),
  _Bucket('USD 50,000 - 100,000', 50000, 100000),
  _Bucket('USD 100,000 - 250,000', 100000, 250000),
  _Bucket('USD 250,000 - 500,000', 250000, 500000),
  _Bucket('USD 500,000 - 750,000', 500000, 750000),
  _Bucket('USD 750,000 - 1,000,000', 750000, 1000001),
];

class InsuranceQuotesScreen extends StatefulWidget {
  final InsuranceQuoteRequest request;
  const InsuranceQuotesScreen({super.key, required this.request});

  @override
  State<InsuranceQuotesScreen> createState() => _InsuranceQuotesScreenState();
}

class _InsuranceQuotesScreenState extends State<InsuranceQuotesScreen> {
  static const Color _brandBlue = Color(0xFF003B95);
  static const Color _brandTeal = Color(0xFF005B7F);
  static const Color _accentOrange = Color(0xFFE23A1E);

  static const List<String> _sortOptions = [
    'Premium: Low to High',
    'Premium: High to Low',
    'Coverage: High to Low',
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<String> _selectedSuppliers = {};
  final Set<String> _selectedRanges = {};
  String _sort = _sortOptions[0];

  String _bucketLabel(int coverage) {
    if (coverage <= 0) return _kUnknownCoverageLabel;
    for (final b in _buckets) {
      if (coverage > b.min && coverage <= b.max) return b.label;
    }
    return _buckets.last.label;
  }

  Map<String, int> _supplierCounts(List<InsurancePolicy> all) {
    final m = <String, int>{};
    for (final p in all) m[p.supplier] = (m[p.supplier] ?? 0) + 1;
    return m;
  }

  Map<String, int> _rangeCounts(List<InsurancePolicy> all) {
    final m = <String, int>{};
    for (final p in all) {
      final k = _bucketLabel(p.coverageUsd);
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  List<InsurancePolicy> _filtered(List<InsurancePolicy> all) {
    final list = all.where((p) {
      if (_selectedSuppliers.isNotEmpty &&
          !_selectedSuppliers.contains(p.supplier)) return false;
      if (_selectedRanges.isNotEmpty &&
          !_selectedRanges.contains(_bucketLabel(p.coverageUsd))) return false;
      return true;
    }).toList();
    switch (_sort) {
      case 'Premium: High to Low':
        list.sort((a, b) => b.premiumInr.compareTo(a.premiumInr));
        break;
      case 'Coverage: High to Low':
        list.sort((a, b) => b.coverageUsd.compareTo(a.coverageUsd));
        break;
      default:
        list.sort((a, b) => a.premiumInr.compareTo(b.premiumInr));
    }
    return list;
  }

  int get _activeFilters => _selectedSuppliers.length + _selectedRanges.length;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
      builder: (context, state) {
        final allPolicies =
            state.plans.map(InsurancePolicy.fromPlan).toList();
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8F9FA),
          endDrawer: _buildFilterDrawer(context, allPolicies),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: BackButton(color: _brandBlue),
            title: Text('Insurance Quotes',
                style: TextStyle(
                    fontSize: context.fs(20),
                    fontWeight: FontWeight.w800,
                    color: Colors.black87)),
            actions: [
              IconButton(
                icon: Icon(Icons.tune_rounded, color: _brandBlue),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSummaryHead(context),
              Expanded(
                child: _buildBody(context, state, allPolicies),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, AkInsuranceState state, List<InsurancePolicy> allPolicies) {
    if (state.quotesStatus == AkInsuranceStatus.loading ||
        state.quotesStatus == AkInsuranceStatus.initial) {
      return const Center(child: CircularProgressIndicator(color: _brandBlue));
    }
    if (state.quotesStatus == AkInsuranceStatus.failed) {
      return _buildErrorState(context, state);
    }
    return _buildList(context, allPolicies);
  }

  Widget _buildErrorState(BuildContext context, AkInsuranceState state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.w(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: context.w(48), color: Colors.grey.shade400),
            SizedBox(height: context.h(12)),
            Text(
              state.errorMessage.isNotEmpty
                  ? state.errorMessage
                  : 'Could not fetch travel insurance plans. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700),
            ),
            SizedBox(height: context.h(12)),
            if (state.quotesRequest != null)
              GestureDetector(
                onTap: () => context
                    .read<AkInsuranceBloc>()
                    .add(LoadAkInsuranceQuotesEvent(state.quotesRequest!)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(20), vertical: context.h(10)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_brandBlue, _brandTeal]),
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
                  child: Text('Retry',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openPolicySheet(BuildContext context, InsurancePolicy p) {
    final tui = context.read<AkInsuranceBloc>().state.quotes?.tui ?? '';
    PolicyDetailsSheet.show(
      context,
      policy: p,
      request: widget.request,
      tui: tui,
      onContinue: () => _goToBooking(context, p),
    );
  }

  void _goToBooking(BuildContext context, InsurancePolicy p) {
    final tui = context.read<AkInsuranceBloc>().state.quotes?.tui ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InsuranceBookingScreen(
          request: widget.request,
          policy: p,
          tui: tui,
        ),
      ),
    );
  }

  // ── Head: selected payload + Modify Search (like web results page) ──────
  Widget _buildSummaryHead(BuildContext context) {
    final r = widget.request;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: context.w(8),
              offset: Offset(0, context.h(2))),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.health_and_safety_rounded,
                size: context.w(24), color: _brandBlue),
            SizedBox(width: context.w(6)),
            Expanded(
              child: Text(
                '${r.insuranceType}  ·  ${r.destination}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context), // back to search card
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(12), vertical: context.h(8)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF4503A), Color(0xFFE23A1E)]),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Text('Modify Search',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          SizedBox(height: context.h(10)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _headItem(context, 'FROM', r.fromCountry),
              _headDivider(context),
              _headItem(context, 'START DATE',
                  DateFormat('dd MMM yyyy').format(r.startDate)),
              _headDivider(context),
              _headItem(context, 'END DATE',
                  DateFormat('dd MMM yyyy').format(r.endDate)),
              _headDivider(context),
              _headItem(context, 'NO OF DAYS', '${r.noOfDays}'),
              _headDivider(context),
              _headItem(context, 'TRAVELLERS', '${r.travellers}'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _headItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: context.letterSpacingWider)),
        SizedBox(height: context.h(2)),
        Text(value,
            style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
      ],
    );
  }

  Widget _headDivider(BuildContext context) => Container(
    width: 1,
    height: context.h(28),
    margin: EdgeInsets.symmetric(horizontal: context.w(12)),
    color: Colors.grey.shade200,
  );

  // ── List: title + sort + filter trigger + policy cards ─────────────────
  Widget _buildList(BuildContext context, List<InsurancePolicy> allPolicies) {
    final policies = _filtered(allPolicies);
    return ListView(
      padding: EdgeInsets.all(context.w(12)),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.request.insuranceType,
                    style: TextStyle(
                        fontSize: context.fs(20),
                        fontWeight: FontWeight.w800,
                        color: _brandBlue)),
                Container(
                  height: context.h(3),
                  width: context.w(40),
                  margin: EdgeInsets.only(top: context.h(3)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_brandBlue, _brandTeal]),
                    borderRadius: BorderRadius.circular(context.r(2)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text('Showing ${policies.length} of ${allPolicies.length} policies',
                style: TextStyle(
                    fontSize: context.fs(12), color: Colors.grey.shade600)),
          ],
        ),
        SizedBox(height: context.h(12)),
        Row(children: [
          Expanded(child: _buildSortDropdown(context)),
          SizedBox(width: context.w(8)),
          _buildFilterButton(context),
        ]),
        SizedBox(height: context.h(12)),
        if (allPolicies.isEmpty)
          _buildNoPlansState(context)
        else if (policies.isEmpty)
          _buildEmptyState(context)
        else
          ...policies.map((p) => _policyCard(context, p)),
      ],
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sort,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade700),
          style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w600,
              color: Colors.black87),
          items: [
            for (final s in _sortOptions)
              DropdownMenuItem(value: s, child: Text(s)),
          ],
          onChanged: (v) => setState(() => _sort = v!),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(11)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: _brandBlue.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune_rounded, size: context.w(20), color: _brandBlue),
          SizedBox(width: context.w(6)),
          Text('Filter',
              style: TextStyle(
                  color: _brandBlue,
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700)),
          if (_activeFilters > 0)
            Container(
              margin: EdgeInsets.only(left: context.w(6)),
              padding: EdgeInsets.all(context.w(4)),
              decoration: const BoxDecoration(
                  color: _accentOrange, shape: BoxShape.circle),
              child: Text('$_activeFilters',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w800)),
            ),
        ]),
      ),
    );
  }

  // ── Policy card (same design language as the search card) ──────────────
  Widget _policyCard(BuildContext context, InsurancePolicy p) {
    final fmt = NumberFormat('#,##0');
    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: context.w(8),
              offset: Offset(0, context.h(4))),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _logoBox(context, p.supplier),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.planName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.fs(16),
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    SizedBox(height: context.h(2)),
                    Text(p.supplier,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Premium',
                      style: TextStyle(
                          fontSize: context.fs(10),
                          color: Colors.grey.shade500)),
                  Text('₹${fmt.format(p.premiumInr)}',
                      style: TextStyle(
                          fontSize: context.fs(20),
                          fontWeight: FontWeight.w800,
                          color: _accentOrange)),
                ],
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Divider(height: 1, color: Colors.grey.shade200),
          SizedBox(height: context.h(8)),
          Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Coverage',
                    style: TextStyle(
                        fontSize: context.fs(10),
                        color: Colors.grey.shade500)),
                Text(
                    p.coverageUsd > 0
                        ? 'USD ${fmt.format(p.coverageUsd)}'
                        : '—',
                    style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _openPolicySheet(context, p),
              child: Text('Policy details',
                  style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w600,
                      color: _brandBlue,
                      decoration: TextDecoration.underline)),
            ),
            SizedBox(width: context.w(10)),
            GestureDetector(
              onTap: () => _goToBooking(context, p),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(9)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_brandTeal, Color(0xFF044A56)]),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_rounded,
                      size: context.w(18), color: Colors.white),
                  SizedBox(width: context.w(4)),
                  Text('Select',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
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
            colors: [Color(0xFF1A4FA0), Color(0xFF003B95)]),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: context.fs(16))),
      ),
    );
  }

  Widget _buildNoPlansState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(60)),
      child: Column(children: [
        Icon(Icons.search_off_rounded,
            size: context.w(48), color: Colors.grey.shade400),
        SizedBox(height: context.h(12)),
        Text('No cover is available for this trip right now',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700)),
      ]),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(60)),
      child: Column(children: [
        Icon(Icons.search_off_rounded,
            size: context.w(48), color: Colors.grey.shade400),
        SizedBox(height: context.h(12)),
        Text('No policies match your filters',
            style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700)),
        SizedBox(height: context.h(8)),
        GestureDetector(
          onTap: () => setState(() {
            _selectedSuppliers.clear();
            _selectedRanges.clear();
          }),
          child: Text('Clear all filters',
              style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700,
                  color: _brandBlue,
                  decoration: TextDecoration.underline)),
        ),
      ]),
    );
  }

  // ── Filter drawer (supplier + coverage buckets, like web sidebar) ──────
  Widget _buildFilterDrawer(BuildContext context, List<InsurancePolicy> allPolicies) {
    final supplierCounts = _supplierCounts(allPolicies);
    final rangeCounts = _rangeCounts(allPolicies);
    return Drawer(
      width: context.w(320),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(context.w(16)),
              child: Row(children: [
                Text('Filter Your Search',
                    style: TextStyle(
                        fontSize: context.fs(20),
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: context.w(24)),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(context.w(16)),
                children: [
                  Text('INSURANCE SUPPLIER',
                      style: TextStyle(
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: context.letterSpacingWider)),
                  SizedBox(height: context.h(6)),
                  for (final entry in supplierCounts.entries)
                    _filterCheckRow(
                      context,
                      entry.key,
                      entry.value,
                      _selectedSuppliers.contains(entry.key),
                          (v) => setState(() => v
                          ? _selectedSuppliers.add(entry.key)
                          : _selectedSuppliers.remove(entry.key)),
                    ),
                  SizedBox(height: context.h(20)),
                  Text('COVERAGE / SUM ASSURED',
                      style: TextStyle(
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: context.letterSpacingWider)),
                  SizedBox(height: context.h(6)),
                  for (final b in _buckets)
                    _filterCheckRow(
                      context,
                      b.label,
                      rangeCounts[b.label] ?? 0,
                      _selectedRanges.contains(b.label),
                          (v) => setState(() => v
                          ? _selectedRanges.add(b.label)
                          : _selectedRanges.remove(b.label)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(context.w(16)),
              child: Row(children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedSuppliers.clear();
                    _selectedRanges.clear();
                  }),
                  child: Text('Clear all',
                      style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.w(24), vertical: context.h(10)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_brandBlue, _brandTeal]),
                      borderRadius: BorderRadius.circular(context.r(12)),
                    ),
                    child: Text('APPLY',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: context.fs(14),
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterCheckRow(BuildContext context, String label, int count,
      bool checked, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(6)),
        child: Row(children: [
          Checkbox(
            value: checked,
            activeColor: _brandBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(4))),
            onChanged: (value) => onChanged(value ?? false),
          ),
          SizedBox(width: context.w(4)),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
          Text('($count)',
              style: TextStyle(
                  fontSize: context.fs(12), color: Colors.grey.shade500)),
        ]),
      ),
    );
  }
}
