import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../screens/diy_results_screen.dart';
import 'diy_common.dart';

/// "Book Now" — the round destination shortcuts under the hero.
///
/// The destination list is **API 1 — GET /destinations/**; it carries no
/// artwork, so each circle borrows the image of a package going there
/// (**API 3 — GET /packages/**, one page, matched on destination name).
class DiyBookNowSection extends StatefulWidget {
  final DiySearchQuery query;

  const DiyBookNowSection({super.key, required this.query});

  @override
  State<DiyBookNowSection> createState() => _DiyBookNowSectionState();
}

class _DiyBookNowSectionState extends State<DiyBookNowSection> {
  List<DiyDestination> _destinations = const [];
  Map<String, String> _images = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = sl<DiyHolidayApi>();
      final destinations = await api.getDestinations();
      final packages = await api.searchPackages();
      if (!mounted) return;

      final images = <String, String>{};
      for (final p in packages.results) {
        if (p.image.isEmpty) continue;
        images.putIfAbsent(p.destination.toLowerCase(), () => p.image);
      }

      setState(() {
        _destinations = destinations;
        _images = images;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _imageFor(DiyDestination d) {
    final direct = _images[d.name.toLowerCase()];
    if (direct != null) return direct;
    // A region ("Kerala") won't match a package's city ("Alleppey") — fall
    // back to any city listed under it.
    for (final city in d.cities) {
      final match = _images[city.toLowerCase()];
      if (match != null) return match;
    }
    return '';
  }

  void _open(DiyDestination destination) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyResultsScreen(
          query: widget.query.copyWith(destination: destination),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: context.h(140),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_destinations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book Now',
                style: TextStyle(
                  fontSize: context.fs(24),
                  fontWeight: FontWeight.w700,
                  color: DiyTokens.navy,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                'Lock package price now to avoid price surge',
                style: TextStyle(
                  fontSize: context.fs(12.5),
                  color: DiyTokens.subGrey,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(14)),
        SizedBox(
          height: context.h(132),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            itemCount: _destinations.length,
            separatorBuilder: (_, __) => SizedBox(width: context.w(14)),
            itemBuilder: (context, i) {
              final destination = _destinations[i];
              return GestureDetector(
                onTap: () => _open(destination),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: context.w(104),
                  child: Column(
                    children: [
                      ClipOval(
                        child: DiyImage(
                          url: _imageFor(destination),
                          width: context.w(104),
                          height: context.w(104),
                        ),
                      ),
                      SizedBox(height: context.h(7)),
                      Text(
                        destination.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            },
          ),
        ),
      ],
    );
  }
}
