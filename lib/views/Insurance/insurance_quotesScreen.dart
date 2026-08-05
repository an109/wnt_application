import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import 'policy_detail_Screen.dart';

/// Payload handed over by InsuranceSearchCard → GET QUOTES.
class InsuranceQuoteRequest {
  final String insuranceType;
  final String fromCountry;
  final List<String> travellingCountries;
  final DateTime startDate;
  final DateTime endDate;
  final int noOfDays;
  final List<DateTime?> travellerDobs;

  const InsuranceQuoteRequest({
    required this.insuranceType,
    required this.fromCountry,
    required this.travellingCountries,
    required this.startDate,
    required this.endDate,
    required this.noOfDays,
    required this.travellerDobs,
  });

  int get travellers => travellerDobs.length;
  String get destination =>
      travellingCountries.isEmpty ? '—' : travellingCountries.join(', ');
}

class InsurancePolicy {
  final String supplier;
  final String planName;
  final int coverageUsd;
  final int premiumInr;
  const InsurancePolicy({
    required this.supplier,
    required this.planName,
    required this.coverageUsd,
    required this.premiumInr,
  });
}

// TODO: replace with your API response model / data source.
const List<InsurancePolicy> _kPolicies = [
  InsurancePolicy(supplier: 'TATA AIG', planName: 'TATA AIG Travel Insurance - International Plus Silver', coverageUsd: 50000, premiumInr: 539),
  InsurancePolicy(supplier: 'TATA AIG', planName: 'TATA AIG Travel Insurance - International Plus Silver Plus', coverageUsd: 100000, premiumInr: 693),
  InsurancePolicy(supplier: 'TATA AIG', planName: 'TATA AIG Travel Insurance - International Plus Gold', coverageUsd: 250000, premiumInr: 905),
  InsurancePolicy(supplier: 'TATA AIG', planName: 'TATA AIG Travel Insurance - International Plus Platinum', coverageUsd: 500000, premiumInr: 1135),
  InsurancePolicy(supplier: 'TATA AIG', planName: 'TATA AIG Travel Insurance - International Plus Titanium', coverageUsd: 750000, premiumInr: 1529),
  InsurancePolicy(supplier: 'TATA AIG', planName: 'TATA AIG Travel Insurance - International Plus Titanium Plus', coverageUsd: 1000000, premiumInr: 1879),
  InsurancePolicy(supplier: 'HDFC ERGO', planName: 'HDFC ERGO International Travel - Silver', coverageUsd: 50000, premiumInr: 559),
  InsurancePolicy(supplier: 'HDFC ERGO', planName: 'HDFC ERGO International Travel - Gold', coverageUsd: 250000, premiumInr: 949),
  InsurancePolicy(supplier: 'ICICI Lombard', planName: 'ICICI Lombard International Travel - Bronze', coverageUsd: 100000, premiumInr: 719),
  InsurancePolicy(supplier: 'ICICI Lombard', planName: 'ICICI Lombard International Travel - Platinum', coverageUsd: 1000000, premiumInr: 1949),
  InsurancePolicy(supplier: 'Bajaj Allianz', planName: 'Bajaj Allianz Travel Ace - Silver', coverageUsd: 50000, premiumInr: 545),
  InsurancePolicy(supplier: 'Bajaj Allianz', planName: 'Bajaj Allianz Travel Ace - Gold', coverageUsd: 250000, premiumInr: 915),
];

class _Bucket {
  final String label;
  final int min;
  final int max;
  const _Bucket(this.label, this.min, this.max);
}

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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // TODO: call your quotes API here with widget.request.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  String _bucketLabel(int coverage) {
    for (final b in _buckets) {
      if (coverage > b.min && coverage <= b.max) return b.label;
    }
    return _buckets.last.label;
  }

  Map<String, int> get _supplierCounts {
    final m = <String, int>{};
    for (final p in _kPolicies) m[p.supplier] = (m[p.supplier] ?? 0) + 1;
    return m;
  }

  Map<String, int> get _rangeCounts {
    final m = <String, int>{};
    for (final p in _kPolicies) {
      final k = _bucketLabel(p.coverageUsd);
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  List<InsurancePolicy> get _filtered {
    final list = _kPolicies.where((p) {
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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      endDrawer: _buildFilterDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: _brandBlue),
        title: Text('Insurance Quotes',
            style: TextStyle(
                fontSize: 20,
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
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _brandBlue))
                : _buildList(context),
          ),
        ],
      ),
    );
  }

  void _openPolicySheet(BuildContext context, InsurancePolicy p) {
    PolicyDetailsSheet.show(
      context,
      policy: p,
      request: widget.request,
      onContinue: () {
        // TODO: navigate to booking / checkout with the selected policy.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text('Continuing with ${p.planName}…'),
        ));
      },
    );
  }

  // ── Head: selected payload + Modify Search (like web results page) ──────
  Widget _buildSummaryHead(BuildContext context) {
    final r = widget.request;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, // Move color here
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.health_and_safety_rounded,
                size: 24, color: _brandBlue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${r.insuranceType}  ·  ${r.destination}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context), // back to search card
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF4503A), Color(0xFFE23A1E)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Modify Search',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
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
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
      ],
    );
  }

  Widget _headDivider(BuildContext context) => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.grey.shade200,
  );

  // ── List: title + sort + filter trigger + policy cards ─────────────────
  Widget _buildList(BuildContext context) {
    final policies = _filtered;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.request.insuranceType,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _brandBlue)),
                Container(
                  height: 3,
                  width: 40,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_brandBlue, _brandTeal]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text('Showing ${policies.length} of ${_kPolicies.length} policies',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildSortDropdown(context)),
          const SizedBox(width: 8),
          _buildFilterButton(context),
        ]),
        const SizedBox(height: 12),
        if (policies.isEmpty)
          _buildEmptyState(context)
        else
          ...policies.map((p) => _policyCard(context, p)),
      ],
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sort,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade700),
          style: TextStyle(
              fontSize: 14,
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _brandBlue.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune_rounded, size: 20, color: _brandBlue),
          const SizedBox(width: 6),
          Text('Filter',
              style: TextStyle(
                  color: _brandBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          if (_activeFilters > 0)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: _accentOrange, shape: BoxShape.circle),
              child: Text('$_activeFilters',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _logoBox(context, p.supplier),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.planName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(p.supplier,
                        style: TextStyle(
                            fontSize: 12,
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
                          fontSize: 10,
                          color: Colors.grey.shade500)),
                  Text('₹${fmt.format(p.premiumInr)}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _accentOrange)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Coverage',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500)),
                Text('USD ${fmt.format(p.coverageUsd)}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _openPolicySheet(context, p),
              child: Text('Policy details',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _brandBlue,
                      decoration: TextDecoration.underline)),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                // TODO: navigate to checkout / payment screen.
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  content: Text('Proceeding with ${p.planName}…'),
                ));
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_brandTeal, Color(0xFF044A56)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_rounded,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('Select',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A4FA0), Color(0xFF003B95)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Icon(Icons.search_off_rounded,
            size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text('No policies match your filters',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() {
            _selectedSuppliers.clear();
            _selectedRanges.clear();
          }),
          child: Text('Clear all filters',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _brandBlue,
                  decoration: TextDecoration.underline)),
        ),
      ]),
    );
  }

  // ── Filter drawer (supplier + coverage buckets, like web sidebar) ──────
  Widget _buildFilterDrawer(BuildContext context) {
    return Drawer(
      width: 320,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Text('Filter Your Search',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('INSURANCE SUPPLIER',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  for (final entry in _supplierCounts.entries)
                    _filterCheckRow(
                      context,
                      entry.key,
                      entry.value,
                      _selectedSuppliers.contains(entry.key),
                          (v) => setState(() => v
                          ? _selectedSuppliers.add(entry.key)
                          : _selectedSuppliers.remove(entry.key)),
                    ),
                  const SizedBox(height: 20),
                  Text('COVERAGE / SUM ASSURED',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  for (final b in _buckets)
                    _filterCheckRow(
                      context,
                      b.label,
                      _rangeCounts[b.label] ?? 0,
                      _selectedRanges.contains(b.label),
                          (v) => setState(() => v
                          ? _selectedRanges.add(b.label)
                          : _selectedRanges.remove(b.label)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedSuppliers.clear();
                    _selectedRanges.clear();
                  }),
                  child: Text('Clear all',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_brandBlue, _brandTeal]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('APPLY',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Checkbox(
            value: checked,
            activeColor: _brandBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
            onChanged: (value) => onChanged(value ?? false),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
          Text('($count)',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500)),
        ]),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
        ),
      ]),
    );
  }
}