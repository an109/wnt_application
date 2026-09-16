import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

/// Category order for the rules grouping. `rules` (policies +
/// checkinSpecialInstructions from Content, already HTML-stripped by the
/// caller) has no category of its own, so — same approach as the
/// amenities/about categorizers elsewhere in this feature — each rule
/// string is bucketed by keyword, defaulting to "Property Policies" rather
/// than dropped.
const _ruleCategoryOrder = [
  'Check-in & Check-out',
  'Cancellation Policy',
  'Children & Extra Beds',
  'Payment & ID',
  'Property Policies',
];

Map<String, List<String>> _categorizeRules(List<String> rules) {
  final map = <String, List<String>>{for (final c in _ruleCategoryOrder) c: []};
  for (final r in rules) {
    final n = r.toLowerCase();
    if (n.contains('check-in') || n.contains('checkin') || n.contains('check-out') || n.contains('checkout') || n.contains('arrival') || n.contains('departure')) {
      map['Check-in & Check-out']!.add(r);
    } else if (n.contains('cancel') || n.contains('refund')) {
      map['Cancellation Policy']!.add(r);
    } else if (n.contains('child') || n.contains('infant') || n.contains('extra bed') || n.contains('cot') || n.contains('crib')) {
      map['Children & Extra Beds']!.add(r);
    } else if (n.contains('payment') || n.contains('credit card') || n.contains('deposit') || n.contains('id proof') || n.contains('passport') || n.contains('identification') || n.contains('age')) {
      map['Payment & ID']!.add(r);
    } else {
      map['Property Policies']!.add(r);
    }
  }
  map.removeWhere((key, value) => value.isEmpty);
  return map;
}

String _shortRuleCategoryLabel(String category) {
  switch (category) {
    case 'Check-in & Check-out':
      return 'Check-in';
    case 'Cancellation Policy':
      return 'Cancellation';
    case 'Children & Extra Beds':
      return 'Children';
    case 'Payment & ID':
      return 'Payment';
    default:
      return 'Policies';
  }
}

/// Full "Property Rules" screen, reached from [AkHotelDetailScreen]'s "View
/// More" — same shadowed-header + search + "Popular Searches" + grouped
/// bordered-card layout as [AkHotelAmenitiesScreen], just over `rules`
/// instead of `facilities`.
class AkHotelPropertyRulesScreen extends StatefulWidget {
  final String hotelName;
  final List<String> rules;

  const AkHotelPropertyRulesScreen({super.key, required this.hotelName, required this.rules});

  @override
  State<AkHotelPropertyRulesScreen> createState() => _AkHotelPropertyRulesScreenState();
}

class _AkHotelPropertyRulesScreenState extends State<AkHotelPropertyRulesScreen> {
  static const _navy = AppColors.black;
  static const _blue = AppColors.AppBlue;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;

  /// (display label, keyword to match against this hotel's real rule
  /// strings) — only shown as a suggestion when a rule actually contains
  /// it, so these never suggest something this property's rules don't
  /// cover.
  static const _popularSearchCandidates = [
    MapEntry('Cancellation', 'cancel'),
    MapEntry('Check-in', 'check-in'),
    MapEntry('Children', 'child'),
    MapEntry('Payment', 'payment'),
    MapEntry('ID Proof', 'id proof'),
    MapEntry('Pets', 'pet'),
  ];

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';
  String? _activeCategory;

  late final Map<String, List<String>> _categories = _categorizeRules(widget.rules);
  late final Map<String, GlobalKey> _sectionKeys = {for (final c in _categories.keys) c: GlobalKey()};

  @override
  void initState() {
    super.initState();
    if (_categories.isNotEmpty) _activeCategory = _categories.keys.first;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _availablePopularSearches {
    final normalized = widget.rules.map((r) => r.toLowerCase()).toList();
    return [
      for (final c in _popularSearchCandidates)
        if (normalized.any((r) => r.contains(c.value))) c.key,
    ];
  }

  void _applyPopularSearch(String term) {
    setState(() => _query = term);
    _searchController.text = term;
    _searchController.selection = TextSelection.collapsed(offset: term.length);
  }

  Map<String, List<String>> get _visibleCategories {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _categories;
    final filtered = <String, List<String>>{};
    for (final entry in _categories.entries) {
      final matches = entry.value.where((r) => r.toLowerCase().contains(q)).toList();
      if (matches.isNotEmpty) filtered[entry.key] = matches;
    }
    return filtered;
  }

  void _scrollToCategory(String category) {
    setState(() => _activeCategory = category);
    final renderObject = _sectionKeys[category]?.currentContext?.findRenderObject();
    if (renderObject == null || !_scrollController.hasClients) return;
    final viewport = RenderAbstractViewport.of(renderObject);
    final revealOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
    _scrollController.animateTo(
      revealOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleCategories;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_searching && _categories.length > 1)
                    Padding(
                      padding: EdgeInsets.only(top: context.h(20), bottom: context.h(10)),
                      child: _buildChipRow(context),
                    ),
                  Expanded(
                    child: _searching && _query.trim().isEmpty
                        ? _buildPopularSearches(context)
                        : visible.isEmpty
                            ? Center(
                                child: Text(
                                  'No rules match "$_query"',
                                  style: TextStyle(color: _muted, fontSize: context.fs(13)),
                                ),
                              )
                            : SingleChildScrollView(
                                controller: _scrollController,
                                physics: context.scrollPhysics,
                                padding: context.responsivePadding.copyWith(top: context.gapMedium, bottom: context.gapLarge),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final entry in visible.entries)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: context.gapMedium),
                                        child: _buildCategoryBox(context, entry.key, entry.value),
                                      ),
                                  ],
                                ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: context.h(100),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: context.r(10), offset: Offset(0, context.h(2))),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(right: context.w(8), bottom: context.h(2), top: context.h(40)),
        child: Row(
          children: [
            SizedBox(width: context.gapMedium),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: Image.asset(
                'assets/NewIcons/arrowBack.png',
                width: context.w(18),
                height: context.h(18),
                color: AppColors.black,
              ),
            ),
            SizedBox(width: context.gapLarge),
            Expanded(
              child: _searching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      style: TextStyle(fontSize: context.fs(15), color: _navy),
                      decoration: InputDecoration(
                        hintText: 'Search property rules...',
                        hintStyle: TextStyle(fontSize: context.fs(14), color: Colors.grey.shade400),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    )
                  : Text(
                      'Property Rules',
                      style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600, color: _navy),
                    ),
            ),
            IconButton(
              icon: Icon(_searching ? Icons.close : Icons.search, color: _border, size: context.w(24)),
              onPressed: () => setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _query = '';
                  _searchController.clear();
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown while the search field is focused and empty — a "Popular
  /// Searches" suggestion row, filtered to only the terms this hotel's own
  /// rules actually mention.
  Widget _buildPopularSearches(BuildContext context) {
    final suggestions = _availablePopularSearches;
    return Padding(
      padding: context.responsivePadding.copyWith(top: context.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Searches',
            style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w700, color: _navy),
          ),
          SizedBox(height: context.gapSmall),
          if (suggestions.isEmpty)
            Text(
              'Type to search property rules...',
              style: TextStyle(fontSize: context.fs(12.5), color: _muted),
            )
          else
            Wrap(
              spacing: context.w(10),
              runSpacing: context.h(10),
              children: [
                for (final term in suggestions)
                  GestureDetector(
                    onTap: () => _applyPopularSearch(term),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(4)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.r(6)),
                        border: Border.all(color: _border),
                        color: Colors.white,
                      ),
                      child: Text(
                        term,
                        style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w600, color: _navy),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChipRow(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: context.scrollPhysics,
        padding: EdgeInsets.symmetric(horizontal: context.w(12)),
        child: Row(
          children: [
            for (final category in _categories.keys)
              Padding(
                padding: EdgeInsets.only(right: context.w(8)),
                child: GestureDetector(
                  onTap: () => _scrollToCategory(category),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.r(6)),
                      border: Border.all(color: _activeCategory == category ? _blue : _border, width: 0.5),
                      color: _activeCategory == category ? _blue.withValues(alpha: 0.04) : Colors.white,
                    ),
                    child: Text(
                      _shortRuleCategoryLabel(category),
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w500,
                        color: _activeCategory == category ? _blue : _muted,
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

  Widget _buildCategoryBox(BuildContext context, String name, List<String> items) {
    return Container(
      key: _query.isEmpty ? _sectionKeys[name] : null,
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        border: Border.all(color: _border, width: 0.5),
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: _navy)),
          SizedBox(height: context.gapSmall),
          for (final item in items) _bulletLine(context, item),
        ],
      ),
    );
  }

  Widget _bulletLine(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.h(6)),
            child: Container(
              width: context.w(4),
              height: context.w(4),
              decoration: const BoxDecoration(color: _muted, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: context.fs(13), color: _navy, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
