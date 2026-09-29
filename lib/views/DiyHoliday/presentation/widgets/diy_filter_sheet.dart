import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import 'diy_common.dart';

/// The filters the DIY search endpoint understands.
///
/// [maxPrice], [nights] and [withFlight] map onto `?max_price=`, `?nights=`
/// and `?flight=` on **API 3 — GET /packages/**. [stars] is sent as
/// `?stars=` for the Hotel Category row in the design; the backend currently
/// ignores it, so it is not applied client-side either (package summaries
/// carry no star rating).
class DiyFilters {
  final double? maxPrice;
  final bool withFlight;
  final int? nights;
  final int? stars;
  final String? theme;

  const DiyFilters({
    this.maxPrice,
    this.withFlight = true,
    this.nights,
    this.stars,
    this.theme,
  });

  DiyFilters copyWith({
    double? maxPrice,
    bool? withFlight,
    int? nights,
    int? stars,
    String? theme,
    bool clearMaxPrice = false,
    bool clearNights = false,
    bool clearStars = false,
    bool clearTheme = false,
  }) {
    return DiyFilters(
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      withFlight: withFlight ?? this.withFlight,
      nights: clearNights ? null : (nights ?? this.nights),
      stars: clearStars ? null : (stars ?? this.stars),
      theme: clearTheme ? null : (theme ?? this.theme),
    );
  }

  bool get isActive =>
      maxPrice != null || nights != null || stars != null || theme != null;
}

const double _minBudget = 4000;
const double _maxBudget = 90000;
const double _minNights = 1;
const double _maxNights = 14;

Future<DiyFilters?> showDiyFilterSheet(
  BuildContext context, {
  required DiyFilters initial,
  String? origin,
  String? destination,
  int? adults,
  int? children,
}) {
  return showModalBottomSheet<DiyFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DiyFilterSheet(
      initial: initial,
      origin: origin,
      destination: destination,
      adults: adults,
      children: children,
    ),
  );
}

class _DiyFilterSheet extends StatefulWidget {
  final DiyFilters initial;
  final String? origin;
  final String? destination;
  final int? adults;
  final int? children;

  const _DiyFilterSheet({
    required this.initial,
    this.origin,
    this.destination,
    this.adults,
    this.children,
  });

  @override
  State<_DiyFilterSheet> createState() => _DiyFilterSheetState();
}

class _DiyFilterSheetState extends State<_DiyFilterSheet> {
  late double _budget;
  late bool _withFlight;
  late double _nights;
  int? _stars;

  Timer? _debounce;
  int? _foundCount;
  bool _counting = false;

  @override
  void initState() {
    super.initState();
    _budget = widget.initial.maxPrice ?? _maxBudget;
    _withFlight = widget.initial.withFlight;
    _nights = (widget.initial.nights ?? _minNights).toDouble();
    _stars = widget.initial.stars;
    _recount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  DiyFilters get _current => DiyFilters(
        // A budget parked at the far right means "no ceiling".
        maxPrice: _budget >= _maxBudget ? null : _budget,
        withFlight: _withFlight,
        nights: widget.initial.nights == null && _nights == _minNights
            ? null
            : _nights.round(),
        stars: _stars,
        theme: widget.initial.theme,
      );

  /// Live "Found N Packages" counter — runs the same search the Apply button
  /// will run, and only reads `count`.
  void _recount() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _counting = true);
      final f = _current;
      try {
        final page = await sl<DiyHolidayApi>().searchPackages(
          origin: widget.origin,
          destination: widget.destination,
          adults: widget.adults,
          children: widget.children,
          theme: f.theme,
          flight: f.withFlight ? 'with' : 'without',
          maxPrice: f.maxPrice,
          nights: f.nights,
        );
        if (mounted) setState(() => _foundCount = page.count);
      } catch (_) {
        if (mounted) setState(() => _foundCount = null);
      } finally {
        if (mounted) setState(() => _counting = false);
      }
    });
  }

  void _reset() {
    setState(() {
      _budget = _maxBudget;
      _withFlight = true;
      _nights = _minNights;
      _stars = null;
    });
    _recount();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.screenHeight * 0.92,
      decoration: BoxDecoration(
        color: DiyTokens.pageBg,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(18))),
      ),
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
              ],
            ),
          ),
          _applyBar(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(18))),
      ),
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
            style: TextStyle(
              fontSize: context.fs(15),
              color: DiyTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(10)),
          child,
        ],
      ),
    );
  }

  Widget _budgetSection() {
    final quickPicks = <String, double?>{
      '< ₹15,000': 15000,
      '₹15,000 – ₹20,000': 20000,
      '₹20,000 – ₹25,000': 25000,
      '> ₹25,000': null,
    };

    return _section(
      title: 'Budget (per person)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
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
                diyMoney(_budget),
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: DiyTokens.navy,
                ),
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DiyTokens.blue,
              inactiveTrackColor: const Color(0xFFE3E6EC),
              thumbColor: Colors.white,
              overlayColor: DiyTokens.blue.withOpacity(0.12),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 11,
                elevation: 2,
              ),
            ),
            child: Slider(
              min: _minBudget,
              max: _maxBudget,
              divisions: 86,
              value: _budget.clamp(_minBudget, _maxBudget),
              onChanged: (v) => setState(() => _budget = v),
              onChangeEnd: (_) => _recount(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                diyMoney(_minBudget),
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: DiyTokens.subGrey,
                ),
              ),
              Text(
                diyMoney(_maxBudget),
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: DiyTokens.subGrey,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          Wrap(
            spacing: context.w(10),
            runSpacing: context.h(10),
            children: [
              for (final entry in quickPicks.entries)
                _chip(
                  label: entry.key,
                  selected: entry.value == null
                      ? _budget >= _maxBudget
                      : _budget == entry.value,
                  onTap: () {
                    setState(() => _budget = entry.value ?? _maxBudget);
                    _recount();
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: selected ? DiyTokens.blue : DiyTokens.subGrey,
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
            option(
              label: 'With Flight',
              icon: Icons.flight_takeoff,
              selected: _withFlight,
              onTap: () {
                setState(() => _withFlight = true);
                _recount();
              },
            ),
            option(
              label: 'Without Flight',
              icon: Icons.flight_land,
              selected: !_withFlight,
              onTap: () {
                setState(() => _withFlight = false);
                _recount();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _nightsSection() {
    return _section(
      title: 'Duration  in Nights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
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
                '${_nights.round()} N',
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: DiyTokens.navy,
                ),
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DiyTokens.blue,
              inactiveTrackColor: const Color(0xFFE3E6EC),
              thumbColor: Colors.white,
              overlayColor: DiyTokens.blue.withOpacity(0.12),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 11,
                elevation: 2,
              ),
            ),
            child: Slider(
              min: _minNights,
              max: _maxNights,
              divisions: (_maxNights - _minNights).round(),
              value: _nights.clamp(_minNights, _maxNights),
              onChanged: (v) => setState(() => _nights = v),
              onChangeEnd: (_) => _recount(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_minNights.round()} N',
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: DiyTokens.subGrey,
                ),
              ),
              Text(
                '${_maxNights.round()} N',
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: DiyTokens.subGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hotelCategorySection() {
    const options = <int, String>{
      2: '< 3 Star',
      3: '3 Star',
      4: '4 Star',
      5: '5 Star',
    };

    return _section(
      title: 'Hotel Category',
      child: Wrap(
        spacing: context.w(10),
        runSpacing: context.h(10),
        children: [
          for (final entry in options.entries)
            _chip(
              label: entry.value,
              leading: Icon(
                Icons.star_rounded,
                size: context.w(15),
                color: const Color(0xFFFFC107),
              ),
              selected: _stars == entry.key,
              onTap: () {
                setState(
                  () => _stars = _stars == entry.key ? null : entry.key,
                );
                _recount();
              },
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
                        _foundCount == null
                            ? '— Packages'
                            : '$_foundCount Package${_foundCount == 1 ? '' : 's'}',
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
              label: 'APPLY FILTER',
              onPressed: () => Navigator.of(context).pop(_current),
            ),
          ),
        ],
      ),
    );
  }
}
