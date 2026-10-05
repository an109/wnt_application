import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../screens/diy_results_screen.dart';
import 'diy_common.dart';
import '../screens/diy_filter_screen.dart';

/// "Holiday By Theme" — **API 2: GET /themes/**.
///
/// Tapping a tile runs **API 3** with `?theme=<slug>`.
///
/// Laid out as the staggered mosaic in the Figma: a 2-column grid whose
/// columns alternate tall/short so the seam between them is never straight.
/// The Figma fills each tile with a photo; the endpoint returns no artwork
/// (slug / label / blurb only), so a tile without [DiyTheme.image] falls back
/// to its per-theme gradient and icon rather than showing a broken or
/// placeholder photo. Tiles switch to the photo treatment automatically once
/// the backend starts sending `image`.
class DiyThemeSection extends StatefulWidget {
  final DiySearchQuery query;

  /// "Holiday By Theme" on home; the results screen's "Collection".
  final String title;

  /// Replaces opening a new results screen — the results screen filters in
  /// place instead.
  final ValueChanged<DiyTheme>? onPick;

  /// Only these themes, when given — the results screen passes the ones its
  /// search actually has packages for, so a tile never leads nowhere.
  final Set<String>? onlySlugs;

  const DiyThemeSection({
    super.key,
    required this.query,
    this.title = 'Holiday By Theme',
    this.onPick,
    this.onlySlugs,
  });

  @override
  State<DiyThemeSection> createState() => _DiyThemeSectionState();
}

class _DiyThemeSectionState extends State<DiyThemeSection> {
  static const Map<String, List<Color>> _gradients = {
    'wellness': [Color(0xFF3AA17E), Color(0xFF7FD1AE)],
    'adventure': [Color(0xFF6B4F3A), Color(0xFFB08968)],
    'luxury': [Color(0xFF1F3A5F), Color(0xFF4F7CAC)],
    'beach': [Color(0xFF1E88C7), Color(0xFF6FD3F2)],
    'honeymoon': [Color(0xFFB03A6B), Color(0xFFE983AE)],
    'family': [Color(0xFFD97706), Color(0xFFFBBF6B)],
    'pilgrimage': [Color(0xFF6D4C9F), Color(0xFFAB8FD6)],
    'wildlife': [Color(0xFF2F6B3A), Color(0xFF7FB069)],
  };

  static const Map<String, IconData> _icons = {
    'wellness': Icons.spa_rounded,
    'adventure': Icons.hiking_rounded,
    'luxury': Icons.diamond_rounded,
    'beach': Icons.beach_access_rounded,
    'honeymoon': Icons.favorite_rounded,
    'family': Icons.family_restroom_rounded,
    'pilgrimage': Icons.temple_hindu_rounded,
    'wildlife': Icons.pets_rounded,
  };

  late Future<List<DiyTheme>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<DiyHolidayApi>().getThemes();
  }

  void _open(DiyTheme theme) {
    if (widget.onPick != null) {
      widget.onPick!(theme);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyResultsScreen(
          // Theme browsing is destination-agnostic — API 3 accepts `theme`
          // on its own.
          query: widget.query.copyWith(clearDestination: true),
          filters: DiyFilters(theme: theme.slug),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DiyTheme>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: context.h(120),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final only = widget.onlySlugs;
        final themes = (snapshot.data ?? const <DiyTheme>[])
            .where((t) => only == null || only.contains(t.slug))
            .toList();
        if (themes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: context.fs(22),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: DiyTokens.navy,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  _starDivider(),
                ],
              ),
            ),
            SizedBox(height: context.h(14)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: _mosaic(themes),
            ),
            SizedBox(height: context.h(14)),
            Center(child: _starDivider()),
          ],
        );
      },
    );
  }

  Widget _starDivider() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.w(60),
          height: 1,
          color: const Color(0xFFF2C14E),
        ),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(2)),
            child: Icon(
              Icons.star_rounded,
              size: context.w(9),
              color: const Color(0xFFF2C14E),
            ),
          ),
        Container(
          width: context.w(60),
          height: 1,
          color: const Color(0xFFF2C14E),
        ),
      ],
    );
  }

  /// The Figma mosaic: two columns of alternating tall/short tiles, dealt
  /// left-then-right so the two columns stay the same total height while the
  /// horizontal seams never line up.
  Widget _mosaic(List<DiyTheme> themes) {
    final tall = context.h(196);
    final short = context.h(140);
    final left = <Widget>[];
    final right = <Widget>[];

    for (var i = 0; i < themes.length; i++) {
      // Left column starts tall, right column starts short, and each flips
      // every row — which is what staggers the seam.
      final isLeft = i.isEven;
      final row = i ~/ 2;
      final isTall = isLeft ? row.isEven : row.isOdd;
      final tile = Padding(
        padding: EdgeInsets.only(bottom: context.h(12)),
        child: SizedBox(height: isTall ? tall : short, child: _tile(themes[i])),
      );
      (isLeft ? left : right).add(tile);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        SizedBox(width: context.w(12)),
        Expanded(child: Column(children: right)),
      ],
    );
  }

  Widget _tile(DiyTheme theme) {
    final colors = _gradients[theme.slug] ??
        const [Color(0xFF1F3A5F), Color(0xFF4F7CAC)];
    final icon = _icons[theme.slug] ?? Icons.explore_rounded;

    return GestureDetector(
      onTap: () => _open(theme),
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(12)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo tile (Figma). Only reached once the backend sends
            // `image`; a failed load drops back to the gradient beneath.
            if (theme.hasImage)
              Image.network(
                theme.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            // Scrim, so the label stays readable over any photo.
            if (theme.hasImage)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.45, 1],
                  ),
                ),
              ),
            // The oversized watermark icon reads as clutter on top of a
            // photo, so it is gradient-only.
            if (!theme.hasImage)
              Positioned(
                right: -context.w(10),
                top: -context.h(6),
                child: Icon(
                  icon,
                  size: context.w(84),
                  color: Colors.white.withOpacity(0.16),
                ),
              ),
            Positioned(
              left: context.w(12),
              right: context.w(12),
              bottom: context.h(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!theme.hasImage) ...[
                    Icon(icon, size: context.w(20), color: Colors.white),
                    SizedBox(height: context.h(6)),
                  ],
                  Text(
                    theme.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    theme.blurb,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
