import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../screens/diy_results_screen.dart';
import 'diy_common.dart';
import 'diy_filter_sheet.dart';

/// "Holiday By Theme" — **API 2: GET /themes/**.
///
/// Tapping a tile runs **API 3** with `?theme=<slug>`. The endpoint returns
/// no artwork (slug / label / blurb only), so each tile is drawn from a
/// per-theme gradient and icon rather than a placeholder photo.
class DiyThemeSection extends StatefulWidget {
  final DiySearchQuery query;

  const DiyThemeSection({super.key, required this.query});

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
        final themes = snapshot.data ?? const <DiyTheme>[];
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
                    'Holiday By Theme',
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
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: themes.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: context.h(12),
                  crossAxisSpacing: context.w(12),
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, i) => _tile(themes[i]),
              ),
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
                  Icon(icon, size: context.w(20), color: Colors.white),
                  SizedBox(height: context.h(6)),
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
