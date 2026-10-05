import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import 'diy_common.dart';

/// How the results list is ordered — sent as `sort` on
/// **POST /packages/search/**, so the order holds across every page rather
/// than only the cards already loaded.
enum DiySortOption {
  popularity,
  priceLowToHigh,
  priceHighToLow,
  durationShortest;

  /// The backend's name for this order.
  String get apiValue => switch (this) {
    DiySortOption.popularity => 'popularity',
    DiySortOption.priceLowToHigh => 'price_low',
    DiySortOption.priceHighToLow => 'price_high',
    DiySortOption.durationShortest => 'duration_short',
  };

  String get label => switch (this) {
    DiySortOption.popularity => 'Popularity',
    DiySortOption.priceLowToHigh => 'Price',
    DiySortOption.priceHighToLow => 'Price',
    DiySortOption.durationShortest => 'Duration',
  };

  String get caption => switch (this) {
    DiySortOption.popularity => 'High to Low',
    DiySortOption.priceLowToHigh => 'Low to High',
    DiySortOption.priceHighToLow => 'High to Low',
    DiySortOption.durationShortest => 'Shortest first',
  };

  IconData get icon => switch (this) {
    DiySortOption.popularity => Icons.star_outline_rounded,
    DiySortOption.priceLowToHigh => Icons.south_rounded,
    DiySortOption.priceHighToLow => Icons.north_rounded,
    DiySortOption.durationShortest => Icons.schedule_rounded,
  };
}

/// Sort — a bottom drawer with the option grid, a live "shown/total" count,
/// and RESET / DONE.
///
/// Returns the chosen option on DONE, or null when dismissed, so backing out
/// leaves the current order alone.
Future<DiySortOption?> showDiySortSheet(
  BuildContext context, {
  required DiySortOption current,
  required int shown,
  required int total,
}) {
  return showModalBottomSheet<DiySortOption>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DiySortSheet(current: current, shown: shown, total: total),
  );
}

class _DiySortSheet extends StatefulWidget {
  final DiySortOption current;
  final int shown;
  final int total;

  const _DiySortSheet({
    required this.current,
    required this.shown,
    required this.total,
  });

  @override
  State<_DiySortSheet> createState() => _DiySortSheetState();
}

class _DiySortSheetState extends State<_DiySortSheet> {
  late DiySortOption _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(context.r(22));

    return SafeArea(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
        ),
        padding: EdgeInsets.fromLTRB(
          context.w(20),
          context.h(10),
          context.w(20),
          context.h(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: context.w(48),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DDE4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: context.h(18)),
            Row(
              children: [
                Text(
                  'Sort',
                  style: TextStyle(
                    fontSize: context.fs(19),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.shown}/${widget.total} '
                  'Package${widget.total == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(18)),
            _grid(),
            SizedBox(height: context.h(20)),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: context.h(48),
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _selected = DiySortOption.popularity),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DiyTokens.subGrey,
                        side: const BorderSide(color: Color(0xFFD9DDE4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(26)),
                        ),
                      ),
                      child: Text(
                        'RESET',
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: SizedBox(
                    height: context.h(48),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DiyTokens.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(26)),
                        ),
                      ),
                      child: Text(
                        'DONE',
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid() {
    const options = DiySortOption.values;
    return Wrap(
      spacing: context.w(12),
      runSpacing: context.h(12),
      children: [
        for (final option in options)
          SizedBox(
            width: (context.screenWidth - context.w(52)) / 2,
            child: _card(option),
          ),
      ],
    );
  }

  Widget _card(DiySortOption option) {
    final selected = option == _selected;

    return GestureDetector(
      onTap: () => setState(() => _selected = option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: context.h(14)),
        decoration: BoxDecoration(
          color: selected ? DiyTokens.blue.withOpacity(0.06) : Colors.white,
          border: Border.all(
            color: selected ? DiyTokens.blue : const Color(0xFFE3E6EC),
          ),
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: context.w(24),
              color: selected ? DiyTokens.blue : DiyTokens.navy,
            ),
            SizedBox(height: context.h(8)),
            Text(
              option.label,
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w600,
                color: selected ? DiyTokens.blue : DiyTokens.navy,
              ),
            ),
            SizedBox(height: context.h(2)),
            Text(
              option.caption,
              style: TextStyle(
                fontSize: context.fs(11.5),
                color: DiyTokens.subGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
