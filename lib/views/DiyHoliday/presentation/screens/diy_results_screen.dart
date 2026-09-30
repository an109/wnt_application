import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';
import '../../../../injection_container.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../widgets/diy_edit_search_drawer.dart';
import '../widgets/diy_flight_choice_sheet.dart';
import '../widgets/diy_sort_sheet.dart';
import '../../data/diy_features.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import 'diy_filter_screen.dart';
import '../widgets/diy_package_card.dart';
import 'diy_package_detail_screen.dart';

/// Search results — **API 3: GET /packages/**.
///
/// The departure date the user chose is deliberately not sent: every package
/// carries a fixed date and filtering on one returns nothing. The date is
/// carried forward instead and applied on the detail screen through
/// **API 5 — POST /packages/{share_id}/price/**.
class DiyResultsScreen extends StatefulWidget {
  final DiySearchQuery query;
  final DiyFilters filters;

  const DiyResultsScreen({
    super.key,
    required this.query,
    this.filters = const DiyFilters(),
  });

  @override
  State<DiyResultsScreen> createState() => _DiyResultsScreenState();
}

class _DiyResultsScreenState extends State<DiyResultsScreen> {
  final ScrollController _scrollController = ScrollController();

  late DiyFilters _filters;

  /// The search can be edited in place from the top drawer, so the screen
  /// keeps its own copy rather than reading [widget.query] directly.
  late DiySearchQuery _query;

  /// Client-side ordering — the search endpoint takes no sort parameter.
  DiySortOption _sort = DiySortOption.recommended;

  /// The holidays hero from site settings — the same artwork the Holidays
  /// screen's search card uses, so the two headers match.
  String? _heroImage;

  final List<DiyPackageSummary> _packages = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = false;
  int _page = 1;
  int _count = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filters = widget.filters;
    _query = widget.query;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<GeneralSettingsBloc>()
          .add(const LoadSectionHeroes(domain: 'thewandernova.com'));
    });
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasNext || _loadingMore || _loading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<DiyPackagePage> _fetch(int page) {
    return sl<DiyHolidayApi>().searchPackages(
      origin: _query.origin.slug,
      destination: _query.destination?.slug,
      adults: _query.adults,
      children: _query.children > 0 ? _query.children : null,
      theme: _filters.theme,
      flight: _filters.withFlight ? 'with' : 'without',
      maxPrice: _filters.maxPrice,
      nights: _filters.nights,
      page: page,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(1);
      if (!mounted) return;
      setState(() {
        _packages
          ..clear()
          ..addAll(page.results);
        _count = page.count;
        _hasNext = page.hasNext;
        _page = 1;
        _loading = false;
        _applySort();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_page + 1);
      if (!mounted) return;
      setState(() {
        _packages.addAll(page.results);
        _hasNext = page.hasNext;
        _page += 1;
        _applySort();
      });
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await openDiyFilterScreen(
      context,
      initial: _filters,
      origin: _query.origin.slug,
      destination: _query.destination?.slug,
      adults: _query.adults,
      children: _query.children,
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
      _load();
    }
  }

  /// Tapping a card asks which fare to open it on. Both figures are already
  /// on the search row, so the sheet costs no extra request, and the answer —
  /// not the list's current filter — is what the detail screen is priced on.
  Future<void> _openPackage(DiyPackageSummary package) async {
    final withFlight = await showDiyFlightChoiceSheet(
      context,
      package: package,
    );
    if (withFlight == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyPackageDetailScreen(
          shareId: package.shareId,
          query: _query,
          withFlight: withFlight,
          previewImage: package.image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeneralSettingsBloc, GeneralSettingsState>(
      listener: (context, state) {
        if (state is SectionHeroesLoaded && mounted) {
          setState(() => _heroImage = state.sectionHeroes.holidays);
        }
      },
      child: _scaffold(),
    );
  }

  Widget _scaffold() {
    return Scaffold(
      backgroundColor: AppColors.white,
      // Figma floats Sort/Filter over the list rather than putting filters in
      // the app bar.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _packages.isEmpty ? null : _sortFilterPill(),
      body: _body(),
    );
  }

  // ------------------------------------------------------------ Figma header


  Widget _heroHeader() {
    final destination = _query.destination;

    return SizedBox(
      height: context.h(312),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ---- Image + bottom gradient fade, wrapped together ----
          Positioned.fill(
            bottom: context.h(46),
            child: Stack(
              children: [
                Positioned.fill(child: _heroBackdrop()),

                // ====== LAYER GRADIENT EFFECT (NO BLUR) ======
                // Layer 1: Soft white gradient that creates the "cloudy" look
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: context.h(40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.92),
                          Colors.white.withOpacity(0.72),
                          Colors.white.withOpacity(0.38),
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.05),
                        ],
                        stops: const [0.0, 0.20, 0.40, 0.60, 0.80, 1.0],
                      ),
                    ),
                  ),
                ),

                // Layer 2: Additional subtle gradient overlay for depth
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: context.h(80),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrim so the back arrow and weather chip stay legible.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: context.h(96),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                ),
              ),
            ),
          ),

          Positioned(
            left: context.w(6),
            top: MediaQuery.of(context).padding.top + context.h(2),
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Colors.white, size: context.w(22)),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),

          if (DiyFeatures.weather)
            Positioned(
              right: context.w(14),
              top: MediaQuery.of(context).padding.top + context.h(10),
              child: _weatherChip(),
            ),

          Positioned(
            left: context.w(20),
            right: context.w(20),
            bottom: 30,
            child: _tripSummaryCard(destination),
          ),
        ],
      ),
    );
  }

  /// Same source and fallback as the Holidays search card's backdrop: the
  /// `holidays` section hero, with the brand gradient standing in until it
  /// loads (or if it fails).
  Widget _heroBackdrop() {
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E9BE0), Color(0xFF8FD3F4)],
        ),
      ),
    );

    final hero = _heroImage;
    if (hero == null || hero.isEmpty) return fallback;

    return Image.network(
      hero,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
    );
  }

  Widget _weatherChip() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(context.r(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_sunny_rounded,
              size: context.w(13), color: const Color(0xFFFFC53D)),
          SizedBox(width: context.w(5)),
          Text(
            _query.destination?.name ?? '',
            style: TextStyle(
              fontSize: context.fs(11),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// "New Delhi to Goa · 09-13 Oct (4N/5D) · 2 Adults, 1 Room" with the edit
  /// pencil that returns to the search form.
  Widget _tripSummaryCard(DiyDestination? destination) {
    final nightsLabel = _packages.isEmpty
        ? ''
        : ' (${_packages.first.nights}N/${_packages.first.days}D)';

    return Material(
      color: AppColors.white.withAlpha(80),
      borderRadius: BorderRadius.circular(context.r(12)),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(11),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_query.origin.name} to '
                    '${destination?.name ?? 'Anywhere'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: DiyTokens.navy,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: context.w(11), color: DiyTokens.subGrey),
                      SizedBox(width: context.w(5)),
                      Flexible(
                        child: Text(
                          '${_departureLabel()}$nightsLabel'
                          '  •  ${_query.adults} Adult'
                          '${_query.adults == 1 ? '' : 's'}'
                          '${_query.children > 0 ? ', ${_query.children} Child' : ''}'
                          ', ${_query.rooms} Room'
                          '${_query.rooms == 1 ? '' : 's'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(11),
                            color: DiyTokens.subGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _openEditSearch,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(left: context.w(8)),
                child: Image.asset(
                  'assets/NewIcons/edit.png',
                  width: context.w(16),
                  height: context.w(16),
                  color: AppColors.AppBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Edit pencil — slides the "Edit Your Search" drawer down over the
  /// results. It returns the edited query only on MODIFY SEARCH, so a
  /// dismissed drawer leaves the current results untouched.
  Future<void> _openEditSearch() async {
    final edited = await showDiyEditSearchDrawer(context, query: _query);
    if (edited == null || !mounted) return;
    setState(() => _query = edited);
    await _load();
  }

  String _departureLabel() {
    final d = _query.departureDate;
    return d == null ? 'Flexible dates' : diyDayDate(d.toIso8601String());
  }

  /// The "All Packages / Honeymoon / Beach Side Stays …" chip row. Built from
  /// the themes actually present in the results, so a chip never leads to an
  /// empty list.
  Widget _categoryChips() {
    final themes = <String>{for (final p in _packages) ...p.themes}.toList()
      ..sort();
    if (themes.isEmpty) return const SizedBox.shrink();

    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Padding(
        padding: EdgeInsets.only(right: context.w(8)),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(14),
              vertical: context.h(7),
            ),
            decoration: BoxDecoration(
              color: selected ? DiyTokens.blue.withOpacity(0.08) : Colors.white,
              border: Border.all(
                color: selected ? DiyTokens.blue : DiyTokens.line,
              ),
              borderRadius: BorderRadius.circular(context.r(20)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fs(11.5),
                fontWeight: FontWeight.w600,
                color: selected ? DiyTokens.blue : DiyTokens.subGrey,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: context.h(34),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.w(14)),
        children: [
          chip('All Packages', _filters.theme == null, () {
            setState(() => _filters = _filters.copyWith(clearTheme: true));
            _load();
          }),
          for (final t in themes)
            chip(t, _filters.theme == t, () {
              setState(() => _filters = _filters.copyWith(theme: t));
              _load();
            }),
        ],
      ),
    );
  }

  Widget _sortFilterPill() {
    Widget half(IconData icon, String label, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.r(30)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(20),
            vertical: context.h(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: context.w(16), color: DiyTokens.navy),
              SizedBox(width: context.w(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.navy,
                ),
              ),
              if (label == 'Filter' && _filters.isActive) ...[
                SizedBox(width: context.w(5)),
                Container(
                  width: context.w(6),
                  height: context.w(6),
                  decoration: const BoxDecoration(
                    color: DiyTokens.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(context.r(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          half(Icons.swap_vert_rounded, 'Sort', _openSort),
          Container(
            width: 1,
            height: context.h(20),
            color: DiyTokens.line,
          ),
          half(Icons.tune_rounded, 'Filter', _openFilters),
        ],
      ),
    );
  }

  /// The filters currently narrowing the search, each paired with the
  /// version of [DiyFilters] that drops it.
  ///
  /// This exists because every dead end we can actually hit is a filter the
  /// customer cannot see from the results screen — most of all `theme`, which
  /// arrives silently from a "Holiday By Theme" tile and matches nothing
  /// while packages carry no themes. Naming it and letting them clear it in
  /// one tap turns a dead end into a recoverable state.
  List<(String, DiyFilters)> _activeFilters() {
    final out = <(String, DiyFilters)>[];
    final f = _filters;

    if (f.theme != null && f.theme!.isNotEmpty) {
      final label = f.theme![0].toUpperCase() + f.theme!.substring(1);
      out.add(('Theme: $label', f.copyWith(clearTheme: true)));
    }
    if (f.nights != null) {
      out.add((
        '${f.nights} night${f.nights == 1 ? '' : 's'}',
        f.copyWith(clearNights: true),
      ));
    }
    if (f.maxPrice != null) {
      out.add((
        'Under ${diyMoney(f.maxPrice!)}',
        f.copyWith(clearMaxPrice: true),
      ));
    }
    if (f.stars != null) {
      out.add(('${f.stars}-star hotels', f.copyWith(clearStars: true)));
    }
    if (!f.withFlight) {
      out.add(('Without flight', f.copyWith(withFlight: true)));
    }
    return out;
  }

  Future<void> _applyFilters(DiyFilters next) async {
    setState(() => _filters = next);
    await _load();
  }

  Widget _emptyState() {
    final active = _activeFilters();

    // The hero normally carries the back arrow, but it is not drawn when
    // there are no results — so the empty state needs its own, or the only
    // way out is an edge swipe.
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: context.w(6), top: context.h(2)),
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: DiyTokens.navy, size: context.w(22)),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(child: _emptyBody(active)),
        ],
      ),
    );
  }

  Widget _emptyBody(List<(String, DiyFilters)> active) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.w(24),
        context.h(12),
        context.w(24),
        context.h(24),
      ),
      children: [
        Icon(
          Icons.luggage_outlined,
          size: context.w(44),
          color: DiyTokens.labelGrey,
        ),
        SizedBox(height: context.h(12)),
        Text(
          'No packages match this search',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.fs(15),
            fontWeight: FontWeight.w700,
            color: DiyTokens.navy,
          ),
        ),
        SizedBox(height: context.h(6)),
        Text(
          active.isEmpty
              ? 'We have nothing for ${_query.destination?.name ?? 'this destination'} '
                  'from ${_query.origin.name} yet. Try another destination or '
                  'starting city.'
              : 'These filters are narrowing it down. Tap one to remove it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.fs(12),
            height: 1.45,
            color: DiyTokens.subGrey,
          ),
        ),
        if (active.isNotEmpty) ...[
          SizedBox(height: context.h(16)),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: context.w(8),
            runSpacing: context.h(8),
            children: [
              for (final (label, cleared) in active)
                GestureDetector(
                  onTap: () => _applyFilters(cleared),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(12),
                      vertical: context.h(7),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: DiyTokens.blue),
                      borderRadius: BorderRadius.circular(context.r(20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: context.fs(11.5),
                            fontWeight: FontWeight.w600,
                            color: DiyTokens.blue,
                          ),
                        ),
                        SizedBox(width: context.w(5)),
                        Icon(
                          Icons.close_rounded,
                          size: context.w(13),
                          color: DiyTokens.blue,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.h(18)),
          Center(
            child: TextButton(
              onPressed: () => _applyFilters(
                // Keep the flight preference — it is the one choice the
                // customer made on the search form, not in the filters.
                DiyFilters(withFlight: _filters.withFlight),
              ),
              child: Text(
                'Clear all filters',
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: DiyTokens.blue,
                ),
              ),
            ),
          ),
        ] else ...[
          SizedBox(height: context.h(18)),
          Center(
            child: OutlinedButton(
              onPressed: _openEditSearch,
              style: OutlinedButton.styleFrom(
                foregroundColor: DiyTokens.blue,
                side: const BorderSide(color: DiyTokens.blue),
              ),
              child: const Text('Edit your search'),
            ),
          ),
        ],
      ],
    );
  }

  /// Same idiom as the hotel screens' share action.
  void _sharePackage(DiyPackageSummary package) {
    Share.share(
      '${package.title} — ${diyMoney(package.priceFor(_filters.withFlight), currency: package.currency)} '
      'for ${package.adults} adult${package.adults == 1 ? '' : 's'}. '
      'Check it out on Wander Nova!',
    );
  }

  /// Sorting is client-side: the search endpoint takes no ordering parameter,
  /// so the list is reordered in place and nothing is re-fetched.
  Future<void> _openSort() async {
    final picked = await showDiySortSheet(
      context,
      current: _sort,
      shown: _packages.length,
      total: _count,
    );
    if (picked == null || !mounted) return;

    // "Recommended" is the backend's own order, which a client-side sort
    // cannot reconstruct once the list has been shuffled — so re-fetch for it
    // rather than pretending the current order is still the original.
    if (picked == DiySortOption.recommended) {
      setState(() => _sort = picked);
      await _load();
      return;
    }
    setState(() {
      _sort = picked;
      _applySort();
    });
  }

  /// Reapplies the chosen order to [_packages]. Called after every load too,
  /// so paging in more results or clearing a filter does not silently drop
  /// the sort the customer picked.
  void _applySort() {
    switch (_sort) {
      case DiySortOption.recommended:
        break; // already in the order the backend returned
      case DiySortOption.priceLowToHigh:
        _packages.sort((a, b) => a
            .priceFor(_filters.withFlight)
            .compareTo(b.priceFor(_filters.withFlight)));
      case DiySortOption.priceHighToLow:
        _packages.sort((a, b) => b
            .priceFor(_filters.withFlight)
            .compareTo(a.priceFor(_filters.withFlight)));
      case DiySortOption.durationShortest:
        _packages.sort((a, b) => a.nights.compareTo(b.nights));
    }
  }

  Widget _body() {
    if (_loading) {
      return const DiyLoading(message: 'Finding holiday packages…');
    }
    if (_error != null) {
      return DiyErrorView(message: _error!, onRetry: _load);
    }
    if (_packages.isEmpty) return _emptyState();

    // Header rows the list carries before the cards: hero, chips, count.
    const headerRows = 3;

    return RefreshIndicator(
      onRefresh: _load,
      color: DiyTokens.blue,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(bottom: context.h(84)),
        itemCount: _packages.length + headerRows + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _heroHeader();
          if (index == 1) {
            return Padding(
              padding: EdgeInsets.only(top: context.h(12)),
              child: _categoryChips(),
            );
          }
          if (index == 2) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(14),
                context.h(12),
                context.w(14),
                context.h(4),
              ),
              child: Text(
                '$_count package${_count == 1 ? '' : 's'} found'
                '${_filters.withFlight ? ' · with flight' : ' · without flight'}',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.subGrey,
                ),
              ),
            );
          }
          if (index == _packages.length + headerRows) {
            if (!_loadingMore) return SizedBox(height: context.h(8));
            return Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(16)),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final package = _packages[index - headerRows];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(6),
              context.w(14),
              context.h(6),
            ),
            child: DiyPackageCard(
              package: package,
              withFlight: _filters.withFlight,
              onTap: () => _openPackage(package),
              onShare: () => _sharePackage(package),
            ),
          );
        },
      ),
    );
  }
}
