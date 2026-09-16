import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../widgets/ak_hotel_amenity_categorizer.dart';

/// Full "Amenities" screen, reached from [AkHotelDetailScreen]'s "See All
/// Amenities" link and its pinned "Amenities" tab. Every category is shown
/// fully expanded (unlike the rate-details screen's collapsible accordion),
/// with a quick-jump chip row that scrolls to a category, and a search
/// field that filters the same real `facilities` list client-side — no new
/// API call, no fabricated content.
class AkHotelAmenitiesScreen extends StatefulWidget {
  final String hotelName;
  final List<String> facilities;

  const AkHotelAmenitiesScreen({super.key, required this.hotelName, required this.facilities});

  @override
  State<AkHotelAmenitiesScreen> createState() => _AkHotelAmenitiesScreenState();
}

class _AkHotelAmenitiesScreenState extends State<AkHotelAmenitiesScreen> {
  static const _navy = AppColors.black;
  static const _blue = AppColors.AppBlue;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;

  /// (display label, keyword to match against this hotel's real facility
  /// strings) — only shown as a suggestion when the hotel actually has a
  /// matching facility, so these never suggest something this property
  /// doesn't have.
  static const _popularSearchCandidates = [
    MapEntry('Swimming Pool', 'pool'),
    MapEntry('Restaurant', 'restaurant'),
    MapEntry('Parking', 'parking'),
    MapEntry('Wi-Fi', 'wifi'),
  ];

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';
  String? _activeCategory;

  late final Map<String, List<String>> _categories = categorizeAkHotelAmenities(widget.facilities);
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
    final normalizedFacilities = widget.facilities.map((f) => f.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
    return [
      for (final candidate in _popularSearchCandidates)
        if (normalizedFacilities.any((f) => f.contains(candidate.value))) candidate.key,
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
      final matches = entry.value.where((f) => f.toLowerCase().contains(q)).toList();
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
          // Header goes edge-to-edge (no SafeArea around it)
          _buildHeader(context),
          Expanded(
            child: SafeArea(
              top: false, // top already handled by header
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
                        'No amenities match "$_query"',
                        style: TextStyle(color: _muted, fontSize: context.fs(13)),
                      ),
                    )
                        : SingleChildScrollView(
                      controller: _scrollController,
                      physics: context.scrollPhysics,
                      padding: context.responsivePadding.copyWith(
                        top: context.gapMedium,
                        bottom: context.gapLarge,
                      ),
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


  /// AppBar-equivalent: title + hotel-name subtitle (or a search field in
  /// its place) and the quick-jump chip row, all under one drop shadow —
  /// matching the reference's shadowed top bar.
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // IconButton(
                //   icon: Icon(Icons.arrow_back, color: _navy, size: context.w(22)),
                //   onPressed: () => Navigator.of(context).maybePop(),
                // ),
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
                            hintText: 'Search amenities...',
                            hintStyle: TextStyle(fontSize: context.fs(14), color: Colors.grey.shade400),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Amenities',
                              style: TextStyle(fontSize: context.fs(19), fontWeight: FontWeight.w800, color: _navy),
                            ),
                            if (widget.hotelName.isNotEmpty)
                              Text(
                                widget.hotelName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: context.fs(12), color: _muted, fontWeight: FontWeight.w500),
                              ),
                          ],
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
          ],
        ),
      ),
    );
  }

  /// Shown while the search field is focused and empty — a "Popular
  /// Searches" suggestion row, filtered to only the terms this hotel
  /// actually has a matching facility for.
  Widget _buildPopularSearches(BuildContext context) {
    final suggestions = _availablePopularSearches;
    return Padding(
      padding: context.responsivePadding.copyWith(top: context.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Searches',
            style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: _navy),
          ),
          SizedBox(height: context.gapSmall),
          if (suggestions.isEmpty)
            Text(
              'Type to search amenities...',
              style: TextStyle(fontSize: context.fs(12.5), color: _muted),
            )
          else
            Wrap(
              spacing: context.w(14),
              runSpacing: context.h(10),
              children: [
                for (final term in suggestions)
                  GestureDetector(
                    onTap: () => _applyPopularSearch(term),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(4)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.r(4)),
                        border: Border.all(color: _border),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            term,
                            style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w600, color: _navy),
                          ),
                        ],
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
                      shortAkHotelAmenityCategoryLabel(category),
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
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(11)),
              child: Row(
                children: [
                  Icon(iconForAkHotelAmenity(item), size: context.w(16), color: _muted),
                  SizedBox(width: context.w(8)),
                  Expanded(
                    child: Text(item, style: TextStyle(fontSize: context.fs(12), color: _navy, fontWeight: FontWeight.w400)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
