import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';

class FlightFilterResult {
  final RangeValues priceRange;
  final Set<String> selectedAirlines;
  final Set<String> selectedDepartureTimes;
  final Set<String> selectedArrivalTimes;
  final bool refundable;
  final bool nonRefundable;

  FlightFilterResult({
    required this.priceRange,
    required this.selectedAirlines,
    required this.selectedDepartureTimes,
    required this.selectedArrivalTimes,
    this.refundable = false,
    this.nonRefundable = false,
  });
}

class FlightFilterDrawer extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final RangeValues currentPriceRange;
  final Set<String> currentSelectedAirlines;
  final Set<String> currentSelectedDepartureTimes;
  final Set<String> currentSelectedArrivalTimes;
  final bool currentRefundable;
  final bool currentNonRefundable;
  final Map<String, int> airlineCounts;
  final Map<String, double> airlineMinPrices;
  /// Airline name -> IATA code, used to render the same real logo the
  /// results list shows. Optional/defaults to empty so any other existing
  /// caller that doesn't pass it still gets the old initials-circle look.
  final Map<String, String> airlineCodes;
  final void Function(FlightFilterResult) onApply;
  /// The currency that raw price values (minPrice, maxPrice, airlineMinPrices)
  /// are stored in — same currency the API returned for totalFare.
  final String apiCurrency;

  const FlightFilterDrawer({
    super.key,
    required this.minPrice,
    required this.maxPrice,
    required this.currentPriceRange,
    required this.currentSelectedAirlines,
    required this.currentSelectedDepartureTimes,
    required this.currentSelectedArrivalTimes,
    required this.currentRefundable,
    required this.currentNonRefundable,
    required this.airlineCounts,
    required this.airlineMinPrices,
    this.airlineCodes = const {},
    required this.onApply,
    this.apiCurrency = 'INR',
  });

  @override
  State<FlightFilterDrawer> createState() => _FlightFilterDrawerState();
}

class _FlightFilterDrawerState extends State<FlightFilterDrawer> {
  late RangeValues _priceRange;
  late Set<String> _selectedAirlines;
  late Map<String, bool> _departureTimes;
  late Map<String, bool> _arrivalTimes;
  late bool _refundable;
  late bool _nonRefundable;

  static const _timeSlots = {
    '05am-12pm': 'Morning',
    '12pm-6pm': 'Afternoon',
    '6pm-11pm': 'Evening',
    '11pm-05am': 'Night',
  };

  static const _timeIcons = {
    '05am-12pm': Icons.wb_sunny_outlined,
    '12pm-6pm': Icons.wb_cloudy_outlined,
    '6pm-11pm': Icons.nights_stay_outlined,
    '11pm-05am': Icons.bedtime_outlined,
  };

  @override
  void initState() {
    super.initState();
    _priceRange = widget.currentPriceRange;
    _selectedAirlines = Set.from(widget.currentSelectedAirlines);
    _departureTimes = {
      for (final k in _timeSlots.keys)
        k: widget.currentSelectedDepartureTimes.contains(k),
    };
    _arrivalTimes = {
      for (final k in _timeSlots.keys)
        k: widget.currentSelectedArrivalTimes.contains(k),
    };
    _refundable = widget.currentRefundable;
    _nonRefundable = widget.currentNonRefundable;
  }

  void _reset() {
    setState(() {
      _priceRange = RangeValues(widget.minPrice, widget.maxPrice);
      _selectedAirlines =
          Set.from(widget.airlineCounts.keys); // select all airlines
      _departureTimes = {for (final k in _timeSlots.keys) k: false};
      _arrivalTimes = {for (final k in _timeSlots.keys) k: false};
      _refundable = false;
      _nonRefundable = false;
    });
  }

  void _apply() {
    widget.onApply(
      FlightFilterResult(
        priceRange: _priceRange,
        selectedAirlines: _selectedAirlines,
        selectedDepartureTimes: _departureTimes.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toSet(),
        selectedArrivalTimes: _arrivalTimes.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toSet(),
        refundable: _refundable,
        nonRefundable: _nonRefundable,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = context.isMobile
        ? context.screenWidth * 0.85
        : context.isTablet
            ? 380.0
            : 420.0;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(4),
                ),
                children: [
                  _sectionTitle("Price Range"),
                  SizedBox(height: context.h(6)),
                  _buildPriceSection(),
                  _divider(),

                  if (widget.airlineCounts.isNotEmpty) ...[
                    _sectionTitle("Airlines"),
                    SizedBox(height: context.h(6)),
                    _buildAirlinesSection(),
                    _divider(),
                  ],

                  _sectionTitle("Departure Time"),
                  SizedBox(height: context.h(8)),
                  _buildTimeGrid(_departureTimes),
                  _divider(),

                  _sectionTitle("Arrival Time"),
                  SizedBox(height: context.h(8)),
                  _buildTimeGrid(_arrivalTimes),
                  _divider(),

                  _sectionTitle("Fare Type"),
                  SizedBox(height: context.h(4)),
                  _buildFareType(),
                  SizedBox(height: context.h(16)),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(16),
        context.w(16),
        context.h(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Filters",
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.bold,
              color: const Color(0xff1a1a2e),
            ),
          ),
          TextButton(
            onPressed: _reset,
            child: Text(
              "Reset All",
              style: TextStyle(
                color: const Color(0xff1663F7),
                fontSize: context.fs(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.fs(13),
        fontWeight: FontWeight.w700,
        color: const Color(0xff2C2F36),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(14)),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }

  Widget _buildPriceSection() {
    final effective = RangeValues(
      _priceRange.start.clamp(widget.minPrice, widget.maxPrice),
      _priceRange.end.clamp(widget.minPrice, widget.maxPrice),
    );

    // Resolve preferred currency for display labels only.
    // Slider values stay in the API currency so filtering remains accurate.
    final preferred = CurrencyConverter.getPreferredCurrency();
    final symbol = CurrencyConverter.getSymbol(preferred);
    final displayStart = CurrencyConverter.convert(
      amount: effective.start,
      fromCurrency: widget.apiCurrency,
      toCurrency: preferred,
    );
    final displayEnd = CurrencyConverter.convert(
      amount: effective.end,
      fromCurrency: widget.apiCurrency,
      toCurrency: preferred,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$symbol${displayStart.toInt()}',
              style: TextStyle(
                color: const Color(0xff1663F7),
                fontWeight: FontWeight.w600,
                fontSize: context.fs(13),
              ),
            ),
            Text(
              '$symbol${displayEnd.toInt()}',
              style: TextStyle(
                color: const Color(0xff1663F7),
                fontWeight: FontWeight.w600,
                fontSize: context.fs(13),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: const Color(0xff1663F7),
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: const Color(0xff1663F7),
            overlayColor: const Color(0xff1663F7).withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: RangeSlider(
            values: effective,
            min: widget.minPrice,
            max: widget.maxPrice > widget.minPrice
                ? widget.maxPrice
                : widget.minPrice + 1,
            onChanged: (v) => setState(() => _priceRange = v),
          ),
        ),
      ],
    );
  }

  Widget _buildAirlinesSection() {
    final names = widget.airlineCounts.keys.toList()..sort();
    final allSelected = names.every((n) => _selectedAirlines.contains(n));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Select All",
              style: TextStyle(
                fontSize: context.fs(13),
                color: Colors.grey.shade700,
              ),
            ),
            Checkbox(
              value: allSelected,
              activeColor: const Color(0xff1663F7),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedAirlines = Set.from(names);
                  } else {
                    _selectedAirlines.clear();
                  }
                });
              },
            ),
          ],
        ),
        ...names.map((name) {
          final count = widget.airlineCounts[name] ?? 0;
          final minPrice = widget.airlineMinPrices[name];
          return Row(
            children: [
              AirlineLogo(
                code: widget.airlineCodes[name] ?? '',
                name: name,
                size: context.w(26),
                borderRadius: BorderRadius.circular(context.w(13)),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: context.fs(13)),
                ),
              ),
              Text(
                "($count)",
                style: TextStyle(
                  fontSize: context.fs(11),
                  color: Colors.grey.shade500,
                ),
              ),
              if (minPrice != null) ...[
                SizedBox(width: context.w(4)),
                Text(
                  () {
                    final preferred = CurrencyConverter.getPreferredCurrency();
                    final converted = CurrencyConverter.convert(
                      amount: minPrice,
                      fromCurrency: widget.apiCurrency,
                      toCurrency: preferred,
                    );
                    return '${CurrencyConverter.getSymbol(preferred)}${converted.toInt()}';
                  }(),
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: const Color(0xff1663F7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              Checkbox(
                value: _selectedAirlines.contains(name),
                activeColor: const Color(0xff1663F7),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedAirlines.add(name);
                    } else {
                      _selectedAirlines.remove(name);
                    }
                  });
                },
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTimeGrid(Map<String, bool> map) {
    return Wrap(
      spacing: context.w(8),
      runSpacing: context.h(8),
      children: _timeSlots.keys.map((slot) {
        final selected = map[slot] ?? false;
        final label = _timeSlots[slot]!;
        final icon = _timeIcons[slot]!;
        return GestureDetector(
          onTap: () => setState(() => map[slot] = !selected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(8),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.r(10)),
              color: selected
                  ? const Color(0xff1663F7).withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              border: Border.all(
                color:
                    selected ? const Color(0xff1663F7) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: context.w(14),
                  color: selected
                      ? const Color(0xff1663F7)
                      : Colors.grey.shade500,
                ),
                SizedBox(width: context.w(5)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? const Color(0xff1663F7)
                            : const Color(0xff2C2F36),
                      ),
                    ),
                    Text(
                      slot,
                      style: TextStyle(
                        fontSize: context.fs(9),
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFareType() {
    return Column(
      children: [
        _fareCheckTile("Refundable", _refundable, (v) {
          setState(() => _refundable = v ?? false);
        }),
        _fareCheckTile("Non-refundable", _nonRefundable, (v) {
          setState(() => _nonRefundable = v ?? false);
        }),
      ],
    );
  }

  Widget _fareCheckTile(
    String label,
    bool value,
    void Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xff1663F7),
      title: Text(
        label,
        style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade800),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(12),
        context.w(16),
        context.h(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: context.h(13)),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
              ),
              child: Text(
                "Reset",
                style: TextStyle(
                  fontSize: context.fs(14),
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1663F7),
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: context.h(13)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
              ),
              child: Text(
                "Apply Filters",
                style: TextStyle(
                  fontSize: context.fs(14),
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
