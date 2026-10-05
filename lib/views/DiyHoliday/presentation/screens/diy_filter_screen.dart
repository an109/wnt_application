import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_sort_sheet.dart';

/// The Filters sheet's choices, sent as `filters` and `sort` on
/// **POST /packages/search/**.
///
/// Budget is **per person** — the backend divides each package's saved price
/// by the adults it was priced for, the same figure the card leads on.
class DiyFilters {
  final double? budgetMin;
  final double? budgetMax;

  /// Which kind of package: null shows both, true only those that offer
  /// flights (priced live once opened), false only land packages.
  final bool? withFlight;
  final int? nightsMax;
  final Set<int> stars;
  final Set<String> cities;
  final String? theme;
  final bool trending;
  final DiySortOption sort;

  const DiyFilters({
    this.budgetMin,
    this.budgetMax,
    this.withFlight,
    this.nightsMax,
    this.stars = const {},
    this.cities = const {},
    this.theme,
    this.trending = false,
    this.sort = DiySortOption.popularity,
  });

  DiyFilters copyWith({
    double? budgetMin,
    double? budgetMax,
    bool? withFlight,
    int? nightsMax,
    Set<int>? stars,
    Set<String>? cities,
    String? theme,
    bool? trending,
    DiySortOption? sort,
    bool clearBudget = false,
    bool clearNights = false,
    bool clearTheme = false,
    bool clearFlight = false,
  }) {
    return DiyFilters(
      budgetMin: clearBudget ? null : (budgetMin ?? this.budgetMin),
      budgetMax: clearBudget ? null : (budgetMax ?? this.budgetMax),
      withFlight: clearFlight ? null : (withFlight ?? this.withFlight),
      nightsMax: clearNights ? null : (nightsMax ?? this.nightsMax),
      stars: stars ?? this.stars,
      cities: cities ?? this.cities,
      theme: clearTheme ? null : (theme ?? this.theme),
      trending: trending ?? this.trending,
      sort: sort ?? this.sort,
    );
  }

  /// Both budget ends replaced at once — either may be null ("no floor",
  /// "no ceiling"), which [copyWith] cannot express.
  DiyFilters withBudget(double? min, double? max) => DiyFilters(
        budgetMin: min,
        budgetMax: max,
        withFlight: withFlight,
        nightsMax: nightsMax,
        stars: stars,
        cities: cities,
        theme: theme,
        trending: trending,
        sort: sort,
      );

  /// Anything narrowing the list. Sort is a choice, not a filter.
  bool get isActive =>
      withFlight != null ||
      budgetMin != null ||
      budgetMax != null ||
      nightsMax != null ||
      stars.isNotEmpty ||
      cities.isNotEmpty ||
      theme != null ||
      trending;

  /// The `filters` object of the search body. Whole rupees: the backend
  /// takes integers.
  Map<String, dynamic> toApi() => {
        if (budgetMin != null) 'budget_min': budgetMin!.round(),
        if (budgetMax != null) 'budget_max': budgetMax!.round(),
        if (nightsMax != null) 'nights_max': nightsMax,
        if (stars.isNotEmpty) 'hotel_stars': stars.toList()..sort(),
        if (cities.isNotEmpty) 'cities': cities.toList(),
        if (theme != null && theme!.isNotEmpty) 'themes': [theme],
        if (trending) 'trending': true,
      };
}

/// Opens Filters as its own screen and returns the chosen [DiyFilters], or
/// null when the customer backs out without applying.
Future<DiyFilters?> openDiyFilterScreen(
  BuildContext context, {
  required DiyFilters initial,
  required DiySearchQuery query,
}) {
  return Navigator.of(context).push<DiyFilters>(
    MaterialPageRoute(
      builder: (_) => DiyFilterScreen(initial: initial, query: query),
    ),
  );
}

/// Quick budget picks from the design, per person: (label, min, max).
const List<(String, double?, double?)> _budgetPicks = [
  ('< ₹15,000', null, 15000),
  ('₹15,000 - ₹20,000', 15000, 20000),
  ('₹20,000 - ₹25,000', 20000, 25000),
  ('> ₹25,000', 25000, null),
];

/// The design's hotel category chips. 2 is the backend's "below three star".
const Map<int, String> _starOptions = {
  2: '< 3 Star',
  3: '3 Star',
  4: '4 Star',
  5: '5 Star',
};

class DiyFilterScreen extends StatefulWidget {
  final DiyFilters initial;
  final DiySearchQuery query;

  const DiyFilterScreen({
    super.key,
    required this.initial,
    required this.query,
  });

  @override
  State<DiyFilterScreen> createState() => _DiyFilterScreenState();
}

class _DiyFilterScreenState extends State<DiyFilterScreen> {
  late DiyFilters _f = widget.initial;

  /// The budget slider's own position, so dragging does not fire a search on
  /// every frame — it is committed to [_f] on release.
  double? _sliderBudget;

  DiySearchFacets _facets = DiySearchFacets.empty;
  Timer? _debounce;
  int? _found;
  int? _total;
  bool _counting = false;

  @override
  void initState() {
    super.initState();
    _recount(immediate: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Runs the search Apply will run, for one card only, and keeps its counts
  /// and facets — the "25/63 Packages" footer and the number on every option.
  void _recount({bool immediate = false}) {
    _debounce?.cancel();
    _debounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 300),
      () async {
        if (!mounted) return;
        setState(() => _counting = true);
        try {
          final result = await sl<DiyHolidayApi>().searchPackagesByBody(
            origin: widget.query.origin.slug,
            destination: widget.query.destination?.slug,
            departureDate: widget.query.departureDate,
            rooms: widget.query.roomsPayload,
            withFlight: _f.withFlight,
            filters: _f.toApi(),
            sort: _f.sort.apiValue,
            pageSize: 1,
          );
          if (!mounted) return;
          setState(() {
            _found = result.page.count;
            _total = result.total;
            _facets = result.facets;
          });
        } catch (_) {
          if (mounted) setState(() => _found = null);
        } finally {
          if (mounted) setState(() => _counting = false);
        }
      },
    );
  }

  void _update(DiyFilters next) {
    setState(() => _f = next);
    _recount();
  }

  void _reset() {
    setState(() {
      _sliderBudget = null;
      _f = const DiyFilters();
    });
    _recount();
  }

  // Slider bounds come from what the destination actually has, so the full
  // track always spans real packages.
  double get _budgetFloor => (_facets.budgetMin ?? 1000).floorToDouble();
  double get _budgetCeiling {
    final top = (_facets.budgetMax ?? 100000).ceilToDouble();
    return top > _budgetFloor ? top : _budgetFloor + 1000;
  }

  int get _nightsFloor => _facets.nightsMin ?? 1;
  int get _nightsCeiling {
    final top = _facets.nightsMax ?? 14;
    return top > _nightsFloor ? top : _nightsFloor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.w(14),
                  context.h(14),
                  context.w(14),
                  context.h(20),
                ),
                children: [
                  _budgetSection(),
                  SizedBox(height: context.h(14)),
                  _flightSection(),
                  SizedBox(height: context.h(14)),
                  _nightsSection(),
                  SizedBox(height: context.h(14)),
                  _hotelCategorySection(),
                  if (_facets.cities.isNotEmpty) ...[
                    SizedBox(height: context.h(14)),
                    _citiesSection(),
                  ],
                  SizedBox(height: context.h(14)),
                  _sortSection(),
                  if (_facets.themes.isNotEmpty || _facets.trending > 0) ...[
                    SizedBox(height: context.h(14)),
                    _themeSection(),
                  ],
                ],
              ),
            ),
            _applyBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(14),
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close, size: context.w(22), color: DiyTokens.navy),
          ),
          SizedBox(width: context.w(14)),
          Text(
            'Filters',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _reset,
            child: Text(
              'Reset',
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w600,
                color: DiyTokens.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: DiyTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: context.fs(15), color: DiyTokens.subGrey),
          ),
          SizedBox(height: context.h(10)),
          child,
        ],
      ),
    );
  }

  SliderThemeData _sliderTheme() => SliderTheme.of(context).copyWith(
        activeTrackColor: DiyTokens.blue,
        inactiveTrackColor: const Color(0xFFE3E6EC),
        thumbColor: Colors.white,
        overlayColor: DiyTokens.blue.withOpacity(0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 2,
        ),
      );

  Widget _valueTag(String text) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(10),
          vertical: context.h(4),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(6)),
          border: Border.all(color: DiyTokens.line),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: context.fs(13),
            fontWeight: FontWeight.w700,
            color: DiyTokens.navy,
          ),
        ),
      ),
    );
  }

  Widget _rangeLabels(String low, String high) {
    final style = TextStyle(fontSize: context.fs(12), color: DiyTokens.subGrey);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(low, style: style), Text(high, style: style)],
    );
  }

  Widget _budgetSection() {
    final floor = _budgetFloor;
    final ceiling = _budgetCeiling;
    final value =
        (_sliderBudget ?? _f.budgetMax ?? ceiling).clamp(floor, ceiling);

    return _section(
      title: 'Budget (per person)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _valueTag(diyMoney(value)),
          SliderTheme(
            data: _sliderTheme(),
            child: Slider(
              min: floor,
              max: ceiling,
              value: value,
              onChanged: (v) => setState(() => _sliderBudget = v),
              onChangeEnd: (v) {
                _sliderBudget = null;
                // The far right means "no ceiling".
                _update(_f.withBudget(null, v >= ceiling ? null : v));
              },
            ),
          ),
          _rangeLabels(diyMoney(floor), diyMoney(ceiling)),
          SizedBox(height: context.h(12)),
          Wrap(
            spacing: context.w(10),
            runSpacing: context.h(10),
            children: [
              for (final (label, low, high) in _budgetPicks)
                _chip(
                  label: label,
                  selected: _f.budgetMin == low && _f.budgetMax == high &&
                      (low != null || high != null),
                  onTap: () {
                    final picked =
                        _f.budgetMin == low && _f.budgetMax == high;
                    _update(
                      picked
                          ? _f.withBudget(null, null)
                          : _f.withBudget(low, high),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flightSection() {
    Widget option({
      required String label,
      required IconData icon,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: context.h(12)),
            decoration: BoxDecoration(
              color: selected ? Colors.white : const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(
                color: selected ? DiyTokens.line : Colors.transparent,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: context.w(8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: context.w(16),
                  color: selected ? DiyTokens.blue : DiyTokens.subGrey,
                ),
                SizedBox(width: context.w(8)),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w600,
                      color: selected ? DiyTokens.blue : DiyTokens.subGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _section(
      title: 'Flights',
      child: Container(
        padding: EdgeInsets.all(context.w(4)),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(context.r(10)),
        ),
        child: Row(
          children: [
            // Tapping the picked side again shows both kinds again.
            option(
              label: 'With Flight (${_facets.withFlight})',
              icon: Icons.flight_takeoff,
              selected: _f.withFlight == true,
              onTap: () => _update(
                _f.withFlight == true
                    ? _f.copyWith(clearFlight: true)
                    : _f.copyWith(withFlight: true),
              ),
            ),
            option(
              label: 'Without Flight (${_facets.withoutFlight})',
              icon: Icons.flight_land,
              selected: _f.withFlight == false,
              onTap: () => _update(
                _f.withFlight == false
                    ? _f.copyWith(clearFlight: true)
                    : _f.copyWith(withFlight: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nightsSection() {
    final floor = _nightsFloor;
    final ceiling = _nightsCeiling;

    // Every package here is the same length: a slider with one stop is noise.
    if (ceiling <= floor) {
      return _section(
        title: 'Duration in Nights',
        child: Text(
          'All packages are $floor night${floor == 1 ? '' : 's'}',
          style: TextStyle(fontSize: context.fs(13), color: DiyTokens.navy),
        ),
      );
    }

    final value = (_f.nightsMax ?? ceiling).clamp(floor, ceiling).toDouble();
    return _section(
      title: 'Duration in Nights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _valueTag('Up to ${value.round()} N'),
          SliderTheme(
            data: _sliderTheme(),
            child: Slider(
              min: floor.toDouble(),
              max: ceiling.toDouble(),
              divisions: ceiling - floor,
              value: value,
              onChanged: (v) => setState(
                () => _f = v.round() >= ceiling
                    ? _f.copyWith(clearNights: true)
                    : _f.copyWith(nightsMax: v.round()),
              ),
              onChangeEnd: (_) => _recount(),
            ),
          ),
          _rangeLabels('$floor N', '$ceiling N'),
        ],
      ),
    );
  }

  Widget _hotelCategorySection() {
    final counts = {
      for (final o in _facets.hotelStars) int.tryParse(o.value) ?? 0: o.count,
    };

    return _section(
      title: 'Hotel Category',
      child: Wrap(
        spacing: context.w(10),
        runSpacing: context.h(10),
        children: [
          for (final entry in _starOptions.entries)
            _chip(
              label: counts.containsKey(entry.key)
                  ? '${entry.value} (${counts[entry.key]})'
                  : entry.value,
              leading: Icon(
                Icons.star_rounded,
                size: context.w(15),
                color: const Color(0xFFFFC107),
              ),
              selected: _f.stars.contains(entry.key),
              onTap: () {
                final next = {..._f.stars};
                next.contains(entry.key)
                    ? next.remove(entry.key)
                    : next.add(entry.key);
                _update(_f.copyWith(stars: next));
              },
            ),
        ],
      ),
    );
  }

  Widget _citiesSection() {
    return _section(
      title: 'Cities',
      child: Wrap(
        spacing: context.w(10),
        runSpacing: context.h(10),
        children: [
          for (final city in _facets.cities)
            _chip(
              label: '${city.label} (${city.count})',
              leading: Icon(
                Icons.location_city_rounded,
                size: context.w(15),
                color: DiyTokens.blue,
              ),
              selected: _f.cities.contains(city.value),
              onTap: () {
                final next = {..._f.cities};
                next.contains(city.value)
                    ? next.remove(city.value)
                    : next.add(city.value);
                _update(_f.copyWith(cities: next));
              },
            ),
        ],
      ),
    );
  }

  Widget _sortSection() {
    Widget card(DiySortOption option) {
      final selected = _f.sort == option;
      return Expanded(
        child: GestureDetector(
          onTap: () => _update(_f.copyWith(sort: option)),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: context.h(10)),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F4FC) : Colors.white,
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(
                color: selected ? DiyTokens.blue : DiyTokens.line,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  option.icon,
                  size: context.w(18),
                  color: selected ? DiyTokens.blue : DiyTokens.navy,
                ),
                SizedBox(height: context.h(4)),
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: context.fs(12.5),
                    fontWeight: FontWeight.w600,
                    color: selected ? DiyTokens.blue : DiyTokens.navy,
                  ),
                ),
                Text(
                  option.caption,
                  style: TextStyle(
                    fontSize: context.fs(9.5),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _section(
      title: 'Sort By',
      child: Row(
        children: [
          card(DiySortOption.popularity),
          SizedBox(width: context.w(10)),
          card(DiySortOption.priceLowToHigh),
          SizedBox(width: context.w(10)),
          card(DiySortOption.priceHighToLow),
        ],
      ),
    );
  }

  Widget _themeSection() {
    return _section(
      title: 'Theme',
      child: Wrap(
        spacing: context.w(10),
        runSpacing: context.h(10),
        children: [
          if (_facets.trending > 0)
            _chip(
              label: 'Trending (${_facets.trending})',
              leading: Icon(
                Icons.local_fire_department_rounded,
                size: context.w(15),
                color: DiyTokens.orange,
              ),
              selected: _f.trending,
              onTap: () => _update(_f.copyWith(trending: !_f.trending)),
            ),
          for (final theme in _facets.themes)
            _chip(
              label: '${theme.label} (${theme.count})',
              selected: _f.theme == theme.value,
              onTap: () => _update(
                _f.theme == theme.value
                    ? _f.copyWith(clearTheme: true)
                    : _f.copyWith(theme: theme.value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? leading,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(9),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F4FC) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(
            color: selected ? DiyTokens.blue : DiyTokens.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading, SizedBox(width: context.w(6))],
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w500,
                color: selected ? DiyTokens.blue : DiyTokens.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applyBar() {
    final found = _found;
    final total = _total;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(12),
        context.w(16),
        context.h(12) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: DiyTokens.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Found',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: DiyTokens.subGrey,
                  ),
                ),
                SizedBox(height: context.h(2)),
                _counting
                    ? SizedBox(
                        width: context.w(16),
                        height: context.w(16),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        found == null
                            ? '— Packages'
                            // The design's "25/63 Packages".
                            : '$found/${total ?? found} '
                                'Package${(total ?? found) == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: context.fs(19),
                          fontWeight: FontWeight.w700,
                          color: DiyTokens.navy,
                        ),
                      ),
              ],
            ),
          ),
          SizedBox(
            width: context.w(160),
            child: DiyPrimaryButton(
              label: 'APPLY',
              onPressed: () => Navigator.of(context).pop(_f),
            ),
          ),
        ],
      ),
    );
  }
}
