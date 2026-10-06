import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../screens/diy_filter_screen.dart';
import '../screens/diy_results_screen.dart';
import 'diy_common.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

/// "Book Now" — the round shortcuts under the hero, for **trending** places.
///
/// **GET /destinations/trending/** lists only places that have packages marked
/// trending, with cities folded into their state (Alleppey and Munnar inside
/// Kerala) and a picture of the place itself. Tapping one opens that place's
/// trending packages.
class DiyBookNowSection extends StatefulWidget {
  final DiySearchQuery query;

  const DiyBookNowSection({super.key, required this.query});

  @override
  State<DiyBookNowSection> createState() => _DiyBookNowSectionState();
}

class _DiyBookNowSectionState extends State<DiyBookNowSection> {
  List<DiyDestination> _destinations = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final destinations = await sl<DiyHolidayApi>().getTrendingDestinations();
      if (!mounted) return;
      setState(() {
        _destinations = destinations;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(DiyDestination destination) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyResultsScreen(
          // Shortcuts open on fixed defaults (New Delhi, today, 2 adults)
          // rather than whatever the form above happens to hold.
          query: DiySearchQuery.quickStart(destination: destination),
          filters: const DiyFilters(trending: true),
        ),
      ),
    );
  }

  /// "Munnar, Alleppey" under a region; the package count under a city.
  String _caption(DiyDestination d) {
    if (d.cities.isNotEmpty &&
        !(d.cities.length == 1 && d.cities.first == d.name)) {
      return d.cities.join(', ');
    }
    return '${d.packageCount} package${d.packageCount == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: context.h(140),
        child: const AppLoadingView.compact(message: 'Loading destinations…'),
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
          height: context.h(150),
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
                          url: destination.image,
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
                      Text(
                        _caption(destination),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(10.5),
                          color: DiyTokens.subGrey,
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
