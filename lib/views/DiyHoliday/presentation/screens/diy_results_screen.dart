import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_filter_sheet.dart';
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
    _scrollController.addListener(_onScroll);
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
      origin: widget.query.origin.slug,
      destination: widget.query.destination?.slug,
      adults: widget.query.adults,
      children: widget.query.children > 0 ? widget.query.children : null,
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
      });
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await showDiyFilterSheet(
      context,
      initial: _filters,
      origin: widget.query.origin.slug,
      destination: widget.query.destination?.slug,
      adults: widget.query.adults,
      children: widget.query.children,
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
      _load();
    }
  }

  void _openPackage(DiyPackageSummary package) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyPackageDetailScreen(
          shareId: package.shareId,
          query: widget.query,
          withFlight: _filters.withFlight,
          previewImage: package.image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.query.destination;

    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DiyTokens.navy, size: context.w(22)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              destination?.name ?? 'Holiday packages',
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w700,
                color: DiyTokens.navy,
              ),
            ),
            SizedBox(height: context.h(2)),
            Text(
              '${widget.query.origin.name} · '
              '${widget.query.adults} Adult'
              '${widget.query.adults == 1 ? '' : 's'}'
              '${widget.query.children > 0 ? ', ${widget.query.children} Child' : ''}',
              style: TextStyle(
                fontSize: context.fs(11),
                color: DiyTokens.subGrey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.tune_rounded,
                    color: DiyTokens.navy, size: context.w(22)),
                if (_filters.isActive)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: context.w(7),
                      height: context.w(7),
                      decoration: const BoxDecoration(
                        color: DiyTokens.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const DiyLoading(message: 'Finding holiday packages…');
    }
    if (_error != null) {
      return DiyErrorView(message: _error!, onRetry: _load);
    }
    if (_packages.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.w(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.luggage_outlined,
                size: context.w(44),
                color: DiyTokens.labelGrey,
              ),
              SizedBox(height: context.h(12)),
              Text(
                'No packages match this search',
                style: TextStyle(
                  fontSize: context.fs(15),
                  fontWeight: FontWeight.w700,
                  color: DiyTokens.navy,
                ),
              ),
              SizedBox(height: context.h(6)),
              Text(
                'Try a wider budget or a different number of nights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: DiyTokens.subGrey,
                ),
              ),
              SizedBox(height: context.h(16)),
              OutlinedButton(
                onPressed: _openFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DiyTokens.blue,
                  side: const BorderSide(color: DiyTokens.blue),
                ),
                child: const Text('Change filters'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: DiyTokens.blue,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          context.w(14),
          context.h(12),
          context.w(14),
          context.h(24),
        ),
        itemCount: _packages.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.h(10)),
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
          if (index == _packages.length + 1) {
            if (!_loadingMore) return SizedBox(height: context.h(8));
            return Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(16)),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final package = _packages[index - 1];
          return Padding(
            padding: EdgeInsets.only(bottom: context.h(12)),
            child: DiyPackageCard(
              package: package,
              withFlight: _filters.withFlight,
              onTap: () => _openPackage(package),
            ),
          );
        },
      ),
    );
  }
}
