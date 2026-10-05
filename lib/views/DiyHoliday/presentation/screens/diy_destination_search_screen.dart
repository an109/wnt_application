import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import 'diy_image_search_screen.dart';

/// "Travelling to" picker — Figma `Search Desitination holiday`.
///
/// Backed by **API 1 — GET /destinations/**: regions and cities with their
/// package counts. The `slug` of whatever is picked here is what the search
/// sends as `?destination=`.
class DiyDestinationSearchScreen extends StatefulWidget {
  final DiyDestination? initial;

  /// Jump straight to the image-search screen (the orange camera chip on the
  /// search card taps this path).
  final bool openImageSearch;

  const DiyDestinationSearchScreen({
    super.key,
    this.initial,
    this.openImageSearch = false,
  });

  @override
  State<DiyDestinationSearchScreen> createState() =>
      _DiyDestinationSearchScreenState();
}

class _DiyDestinationSearchScreenState
    extends State<DiyDestinationSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late Future<List<DiyDestination>> _future;
  List<DiyDestination> _recent = const [];

  @override
  void initState() {
    super.initState();
    _future = sl<DiyHolidayApi>().getDestinations();
    DiySearchStore.recentDestinations().then((value) {
      if (mounted) setState(() => _recent = value);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.openImageSearch) {
        _openImageSearch();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _reload() {
    // A block body, not `=>`: the arrow form returns the Future it assigns,
    // and setState refuses a callback that returns one.
    setState(() {
      _future = sl<DiyHolidayApi>().getDestinations();
    });
  }

  void _select(DiyDestination destination) {
    DiySearchStore.addRecentDestination(destination);
    Navigator.of(context).pop(destination);
  }

  Future<void> _openImageSearch() async {
    final picked = await Navigator.of(context).push<DiyDestination>(
      MaterialPageRoute(builder: (_) => const DiyImageSearchScreen()),
    );
    if (picked != null && mounted) _select(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _searchField(),
            SizedBox(height: context.h(12)),
            _imageSearchRow(),
            const Divider(height: 1, color: DiyTokens.line),
            Expanded(
              child: FutureBuilder<List<DiyDestination>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const DiyLoading(message: 'Loading destinations…');
                  }
                  if (snapshot.hasError) {
                    return DiyErrorView(
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    );
                  }

                  final all = snapshot.data ?? const <DiyDestination>[];
                  final query = _controller.text.trim().toLowerCase();
                  final filtered = query.isEmpty
                      ? all
                      : all
                            .where(
                              (d) =>
                                  d.name.toLowerCase().contains(query) ||
                                  d.state.toLowerCase().contains(query) ||
                                  d.countryName.toLowerCase().contains(query) ||
                                  d.cities.any(
                                    (c) => c.toLowerCase().contains(query),
                                  ),
                            )
                            .toList();

                  final showRecent = query.isEmpty && _recent.isNotEmpty;

                  if (filtered.isEmpty && !showRecent) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(context.w(24)),
                        child: Text(
                          'No destination matches "${_controller.text}".',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.fs(13),
                            color: DiyTokens.subGrey,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: EdgeInsets.only(bottom: context.h(24)),
                    children: [
                      if (showRecent) ...[
                        _sectionLabel('RECENT SEARCHES', caps: true),
                        for (final d in _recent) _recentTile(d),
                        SizedBox(height: context.h(6)),
                      ],
                      _sectionLabel(
                        query.isEmpty ? 'Popular Searches' : 'Results',
                      ),
                      for (final d in filtered) _destinationTile(d),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(10),
        context.w(14),
        0,
      ),
      child: Container(
        height: context.h(46),
        padding: EdgeInsets.symmetric(horizontal: context.w(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: DiyTokens.blue, width: 1.4),
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(
                Icons.arrow_back,
                size: context.w(20),
                color: DiyTokens.subGrey,
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Travelling To...',
                  hintStyle: TextStyle(
                    fontSize: context.fs(14),
                    color: DiyTokens.labelGrey,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: context.fs(14),
                  color: DiyTokens.navy,
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: () => setState(_controller.clear),
                child: Icon(
                  Icons.close,
                  size: context.w(18),
                  color: DiyTokens.labelGrey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageSearchRow() {
    return InkWell(
      onTap: _openImageSearch,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.w(4)),
              decoration: BoxDecoration(
                color: DiyTokens.orange,
                borderRadius: BorderRadius.circular(context.r(6)),
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                size: context.w(13),
                color: Colors.white,
              ),
            ),
            SizedBox(width: context.w(12)),
            Text(
              'Search with a image',
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w600,
                color: DiyTokens.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {bool caps = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(14),
        context.w(16),
        context.h(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: caps ? context.fs(10) : context.fs(15),
          fontWeight: caps ? FontWeight.w700 : FontWeight.w700,
          letterSpacing: caps ? 0.8 : 0,
          color: caps ? DiyTokens.labelGrey : DiyTokens.navy,
        ),
      ),
    );
  }

  Widget _recentTile(DiyDestination d) {
    return InkWell(
      onTap: () => _select(d),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(8),
        ),
        child: Row(
          children: [
            Container(
              width: context.w(30),
              height: context.w(30),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F4FC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: context.w(16),
                color: DiyTokens.blue,
              ),
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Text(
                d.name,
                style: TextStyle(
                  fontSize: context.fs(15),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationTile(DiyDestination d) {
    return InkWell(
      onTap: () => _select(d),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(9),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: context.w(17),
              color: const Color(0xFFC7CCD6),
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w600,
                      color: DiyTokens.navy,
                    ),
                  ),
                  SizedBox(height: context.h(1)),
                  Text(
                    '${d.packageCount} Package${d.packageCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: context.fs(9),
                      color: DiyTokens.labelGrey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              d.kindLabel,
              style: TextStyle(
                fontSize: context.fs(13),
                color: DiyTokens.subGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
