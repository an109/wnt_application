import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';

import '../../../../core/resources/app_colours.dart';

class FlightFilterResult {
  final RangeValues priceRange;
  final Set<String> selectedAirlines;
  final Set<String> selectedDepartureTimes;
  final Set<String> selectedArrivalTimes;
  final bool refundable;
  final bool nonRefundable;

  /// Stop buckets: 0 = non-stop, 1 = 1 stop, 2 = 2+ stops. Empty = no filter.
  final Set<int> selectedStops;

  /// Total-duration window in minutes. Null = no filter.
  final RangeValues? durationRange;

  // NEW FIELDS
  final Set<String> selectedDepartureAirports;
  final Set<String> selectedArrivalAirports;
  final bool checkedInBaggage;
  final bool codeShareFlights;
  final bool hideNearbyAirports;
  final bool hideSelfTransferFlights;

  FlightFilterResult({
    required this.priceRange,
    required this.selectedAirlines,
    required this.selectedDepartureTimes,
    required this.selectedArrivalTimes,
    this.refundable = false,
    this.nonRefundable = false,
    this.selectedStops = const {},
    this.durationRange,
    this.selectedDepartureAirports = const {},
    this.selectedArrivalAirports = const {},
    this.checkedInBaggage = false,
    this.codeShareFlights = false,
    this.hideNearbyAirports = false,
    this.hideSelfTransferFlights = false,
  });
}

/// Full-screen version of the flight filters (was a `Drawer`). Same content,
/// state and `onApply` contract — the outer shell is a `Scaffold`, the header
/// is X / Filters / Clear, and the bottom is a single orange "Done" button.
class FlightFilterScreen extends StatefulWidget {
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

  /// The currency that raw price values (minPrice, maxPrice, airlineMinPrices,
  /// stopMinPrices) are stored in — same currency the API returned for
  /// totalFare.
  final String apiCurrency;

  // ---- Stops ("Stop From <origin>") -----------------------------------------
  /// Origin city name, for the "Stop From …" / "Departure From …" headings.
  final String originCityName;

  /// Destination city name, for the "Arrival at …" heading.
  final String destinationCityName;

  /// Cheapest fare per stop bucket (0 / 1 / 2+), in [apiCurrency].
  final Map<int, double> stopMinPrices;

  /// Highest stop count present in the results, so "1" / "2+" can be greyed
  /// out when nothing matches.
  final int maxStopsAvailable;
  final Set<int> currentSelectedStops;

  // ---- Duration -----------------------------------------------------------
  final double minDuration; // minutes
  final double maxDuration; // minutes
  final RangeValues currentDurationRange;

  // ---- NEW FIELDS ---------------------------------------------------------
  final Map<String, String> departureAirports; // airport code -> airport name
  final Map<String, String> arrivalAirports; // airport code -> airport name
  final Map<String, double> departureAirportPrices;
  final Map<String, double> arrivalAirportPrices;

  /// Cheapest fare per departure / arrival time bucket ('0-6' / '6-12' /
  /// '12-18' / '18-24'), in [apiCurrency]. Optional — an empty map just
  /// renders the time cards without a price line.
  final Map<String, double> departureTimePrices;
  final Map<String, double> arrivalTimePrices;
  final Set<String> currentSelectedDepartureAirports;
  final Set<String> currentSelectedArrivalAirports;
  final bool currentCheckedInBaggage;
  final bool currentCodeShareFlights;
  final bool currentHideNearbyAirports;
  final bool currentHideSelfTransferFlights;

  const FlightFilterScreen({
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
    this.originCityName = '',
    this.destinationCityName = '',
    this.stopMinPrices = const {},
    this.maxStopsAvailable = 0,
    this.currentSelectedStops = const {},
    this.minDuration = 0,
    this.maxDuration = 1440,
    this.currentDurationRange = const RangeValues(0, 1440),
    this.departureAirports = const {},
    this.arrivalAirports = const {},
    this.departureAirportPrices = const {},
    this.arrivalAirportPrices = const {},
    this.departureTimePrices = const {},
    this.arrivalTimePrices = const {},
    this.currentSelectedDepartureAirports = const {},
    this.currentSelectedArrivalAirports = const {},
    this.currentCheckedInBaggage = false,
    this.currentCodeShareFlights = false,
    this.currentHideNearbyAirports = false,
    this.currentHideSelfTransferFlights = false,
  });

  @override
  State<FlightFilterScreen> createState() => _FlightFilterScreenState();
}

class _FlightFilterScreenState extends State<FlightFilterScreen> {
  // Figma "Sec" token (#FF6600) — matches AppColors.OrangeColor.
  static const _orange = AppColors.OrangeColor;
  // Figma "Strok" token.
  static const _stroke = Color(0xFFCCCCCC);
  // Figma section border: rgba(198,198,205,0.3).
  static const _sectionBorder = Color(0x4DC6C6CD);
  // Figma "Neutral/Text+Icon/Title 900".
  static const _title900 = AppColors.black;

  late RangeValues _priceRange;
  late Set<String> _selectedAirlines;
  late Map<String, bool> _departureTimes;
  late Map<String, bool> _arrivalTimes;
  late bool _refundable;
  late bool _nonRefundable;
  late Set<int> _selectedStops;
  late RangeValues _durationRange;

  // NEW STATE
  late Set<String> _selectedDepartureAirports;
  late Set<String> _selectedArrivalAirports;
  late bool _checkedInBaggage;
  late bool _codeShareFlights;
  late bool _hideNearbyAirports;
  late bool _hideSelfTransferFlights;

  // Figma "Flight Filter own way" — four fixed windows. Keys are the tokens
  // handed back in [FlightFilterResult]; flight_search_screen._inSlot buckets
  // flights by these same tokens.
  static const _timeSlots = {
    '0-6': 'Before 6AM',
    '6-12': '6AM-12Noon',
    '12-18': '12 Noon-6PM',
    '18-24': 'After 6PM',
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
    _selectedStops = Set.from(widget.currentSelectedStops);
    _durationRange = widget.currentDurationRange;

    // NEW INIT
    _selectedDepartureAirports = Set.from(widget.currentSelectedDepartureAirports);
    _selectedArrivalAirports = Set.from(widget.currentSelectedArrivalAirports);
    _checkedInBaggage = widget.currentCheckedInBaggage;
    _codeShareFlights = widget.currentCodeShareFlights;
    _hideNearbyAirports = widget.currentHideNearbyAirports;
    _hideSelfTransferFlights = widget.currentHideSelfTransferFlights;
  }

  void _reset() {
    setState(() {
      _priceRange = RangeValues(widget.minPrice, widget.maxPrice);
      _selectedAirlines = Set.from(widget.airlineCounts.keys);
      _departureTimes = {for (final k in _timeSlots.keys) k: false};
      _arrivalTimes = {for (final k in _timeSlots.keys) k: false};
      _refundable = false;
      _nonRefundable = false;
      _selectedStops = {};
      _durationRange = RangeValues(widget.minDuration, widget.maxDuration);

      // NEW RESET
      _selectedDepartureAirports = {};
      _selectedArrivalAirports = {};
      _checkedInBaggage = false;
      _codeShareFlights = false;
      _hideNearbyAirports = false;
      _hideSelfTransferFlights = false;
    });
  }

  void _apply() {
    final fullDuration = _durationRange.start <= widget.minDuration &&
        _durationRange.end >= widget.maxDuration;
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
        selectedStops: _selectedStops,
        durationRange: fullDuration ? null : _durationRange,
        // NEW VALUES
        selectedDepartureAirports: _selectedDepartureAirports,
        selectedArrivalAirports: _selectedArrivalAirports,
        checkedInBaggage: _checkedInBaggage,
        codeShareFlights: _codeShareFlights,
        hideNearbyAirports: _hideNearbyAirports,
        hideSelfTransferFlights: _hideSelfTransferFlights,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(8),
                ),
                children: [
                  // ==========================================================
                  // STOPS SECTION
                  // ==========================================================
                  if (widget.stopMinPrices.isNotEmpty) ...[
                    _sectionContainer(
                      title: widget.originCityName.isNotEmpty
                          ? "Stop From ${widget.originCityName}"
                          : "Stops",
                      child: _buildStopsSection(),
                    ),
                    SizedBox(height: context.h(20)),
                  ],

                  // ==========================================================
                  // PRICE RANGE SECTION
                  // ==========================================================
                  _sectionContainer(
                    title: "Price Range",
                    child: _buildPriceSection(),
                  ),
                  SizedBox(height: context.h(20)),

                  // ==========================================================
                  // DURATION SECTION
                  // ==========================================================
                  _sectionContainer(
                    title: "Duration",
                    child: _buildDurationSection(),
                  ),
                  SizedBox(height: context.h(20)),

                  // ==========================================================
                  // DEPARTURE AIRPORTS SECTION - NEW
                  // ==========================================================
                  if (widget.departureAirports.isNotEmpty) ...[
                    _sectionContainer(
                      title: "Departure Airports",
                      trailing: _selectAllTrailing(
                        selected: _selectedDepartureAirports,
                        all: widget.departureAirports.keys,
                        onToggle: (all) {
                          setState(() {
                            if (all) {
                              _selectedDepartureAirports = Set.from(widget.departureAirports.keys);
                            } else {
                              _selectedDepartureAirports.clear();
                            }
                          });
                        },
                      ),
                      child: _buildAirportSection(
                        airports: widget.departureAirports,
                        prices: widget.departureAirportPrices,
                        selected: _selectedDepartureAirports,
                        onChanged: (code, selected) {
                          setState(() {
                            if (selected) {
                              _selectedDepartureAirports.add(code);
                            } else {
                              _selectedDepartureAirports.remove(code);
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: context.h(20)),
                  ],

                  // ==========================================================
                  // ARRIVAL AIRPORTS SECTION - NEW
                  // ==========================================================
                  if (widget.arrivalAirports.isNotEmpty) ...[
                    _sectionContainer(
                      title: "Arrival Airports",
                      trailing: _selectAllTrailing(
                        selected: _selectedArrivalAirports,
                        all: widget.arrivalAirports.keys,
                        onToggle: (all) {
                          setState(() {
                            if (all) {
                              _selectedArrivalAirports = Set.from(widget.arrivalAirports.keys);
                            } else {
                              _selectedArrivalAirports.clear();
                            }
                          });
                        },
                      ),
                      child: _buildAirportSection(
                        airports: widget.arrivalAirports,
                        prices: widget.arrivalAirportPrices,
                        selected: _selectedArrivalAirports,
                        onChanged: (code, selected) {
                          setState(() {
                            if (selected) {
                              _selectedArrivalAirports.add(code);
                            } else {
                              _selectedArrivalAirports.remove(code);
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: context.h(20)),
                  ],

                  // ==========================================================
                  // AIRLINES SECTION
                  // ==========================================================
                  if (widget.airlineCounts.isNotEmpty) ...[
                    _sectionContainer(
                      title: "Airlines",
                      trailing: _selectAllTrailing(
                        selected: _selectedAirlines,
                        all: widget.airlineCounts.keys,
                        onToggle: (all) {
                          setState(() {
                            if (all) {
                              _selectedAirlines = Set.from(widget.airlineCounts.keys);
                            } else {
                              _selectedAirlines.clear();
                            }
                          });
                        },
                      ),
                      child: _buildAirlinesSection(),
                    ),
                    SizedBox(height: context.h(20)),
                  ],

                  // ==========================================================
                  // DEPARTURE TIME SECTION
                  // ==========================================================
                  _sectionContainer(
                    title: widget.originCityName.isNotEmpty
                        ? "Departure From ${widget.originCityName}"
                        : "Departure Time",
                    child: _buildTimeGrid(_departureTimes, widget.departureTimePrices),
                  ),
                  SizedBox(height: context.h(20)),

                  // ==========================================================
                  // ARRIVAL TIME SECTION
                  // ==========================================================
                  _sectionContainer(
                    title: widget.destinationCityName.isNotEmpty
                        ? "Arrival at ${widget.destinationCityName}"
                        : "Arrival Time",
                    child: _buildTimeGrid(_arrivalTimes, widget.arrivalTimePrices),
                  ),

                  // ==========================================================
                  // OTHER POPULAR FILTER SECTION - NEW
                  // ==========================================================
                  SizedBox(height: context.h(20)),

                  _sectionContainer(
                    title: "Other popular filter",
                    trailing: GestureDetector(
                      onTap: () {
                        final all = !(_checkedInBaggage &&
                            _codeShareFlights &&
                            _hideNearbyAirports &&
                            _hideSelfTransferFlights);
                        setState(() {
                          _checkedInBaggage = all;
                          _codeShareFlights = all;
                          _hideNearbyAirports = all;
                          _hideSelfTransferFlights = all;
                        });
                      },
                      child: Text(
                        "Select All",
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.AppBlue,
                        ),
                      ),
                    ),
                    child: _buildOtherPopularFilters(),
                  ),
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

  // ================================================================
  // SECTION CONTAINER
  // Matches Figma: white card, 16px radius, 0.5px rgba(198,198,205,0.3)
  // border, subtle 1px drop shadow, 24px gap between the title block and
  // the content. Sections that carry a "Select All" action (Airlines,
  // Departure/Arrival Airports, Other popular filter) put it opposite the
  // title with a stroke divider underneath; the simple sections (Price
  // Range, Duration, Stops) just show the title.
  // ================================================================
  Widget _sectionContainer({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final hasHeader = trailing != null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12.5),
        vertical: context.h(20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: _sectionBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader)
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: context.h(12)),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _stroke, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(18),
                        fontWeight: FontWeight.w400,
                        color: AppColors.subhead,
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(8)),
                  trailing,
                ],
              ),
            )
          else
            Text(
              title,
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w500,
                color: AppColors.subhead,
                height: 1.5,
              ),
            ),
          SizedBox(height: context.h(24)),
          child,
        ],
      ),
    );
  }

  /// "Select All" text action shown opposite a section title. Toggles all
  /// keys in [all] on/off in [selected] depending on whether everything is
  /// already selected.
  Widget _selectAllTrailing({
    required Set<String> selected,
    required Iterable<String> all,
    required void Function(bool selectAll) onToggle,
  }) {
    final allSelected = all.isNotEmpty && all.every(selected.contains);
    return GestureDetector(
      onTap: () => onToggle(!allSelected),
      child: Text(
        "Select All",
        style: TextStyle(
          fontSize: context.fs(12),
          fontWeight: FontWeight.w600,
          color: AppColors.AppBlue,
        ),
      ),
    );
  }

  // ================================================================
  // Figma checkbox — a 20px blue rounded square (white tick) when selected,
  // a 0.5px #CCCCCC outline when not. Replaces Material `Checkbox` so the
  // Airlines / Airports / Other-popular rows match the design exactly.
  // ================================================================
  Widget _check(bool selected) {
    return Container(
      width: context.w(20),
      height: context.w(20),
      decoration: BoxDecoration(
        color: selected ? AppColors.AppBlue : Colors.white,
        borderRadius: BorderRadius.circular(context.r(4)),
        border: Border.all(
          color: selected ? AppColors.AppBlue : _stroke,
          width: selected ? 1 : 0.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: context.w(14), color: Colors.white)
          : null,
    );
  }

  // ================================================================
  // AIRPORT SECTION - NEW  (Figma: name + price stacked, checkbox right)
  // ================================================================
  Widget _buildAirportSection({
    required Map<String, String> airports,
    required Map<String, double> prices,
    required Set<String> selected,
    required Function(String, bool) onChanged,
  }) {
    final names = airports.keys.toList()..sort();

    return Column(
      children: [
        ...names.map((code) {
          final name = airports[code] ?? code;
          final price = prices[code];
          final isSel = selected.contains(code);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(code, !isSel),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                              fontSize: context.fs(16), color: AppColors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (price != null) ...[
                          SizedBox(height: context.h(2)),
                          Text(
                            _money(price),
                            style: TextStyle(
                              fontSize: context.fs(13),
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  _check(isSel),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ================================================================
  // OTHER POPULAR FILTERS - NEW
  // ================================================================
  Widget _buildOtherPopularFilters() {
    return Column(
      children: [
        _popularFilterTile("Checked-in Baggage", _checkedInBaggage, (v) {
          setState(() => _checkedInBaggage = v ?? false);
        }),
        _popularFilterTile("Code Share Flights", _codeShareFlights, (v) {
          setState(() => _codeShareFlights = v ?? false);
        }),
        _popularFilterTile("Hide Nearby Airports", _hideNearbyAirports, (v) {
          setState(() => _hideNearbyAirports = v ?? false);
        }),
        _popularFilterTile("Hide self-Transfer Flights", _hideSelfTransferFlights, (v) {
          setState(() => _hideSelfTransferFlights = v ?? false);
        }),
        _popularFilterTile("Refundable Fares", _refundable, (v) {
          setState(() => _refundable = v ?? false);
        }),
      ],
    );
  }

  Widget _popularFilterTile(
      String label,
      bool value,
      void Function(bool?) onChanged,
      ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(12)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w400,
                  color: AppColors.black,
                ),
              ),
            ),
            SizedBox(width: context.w(12)),
            _check(value),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Icon(
              Icons.close,
              size: context.w(24),
              color: _title900,
            ),
          ),
          SizedBox(width: context.w(12)),
          Text(
            "Filters",
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w600,
              color: _title900,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _reset,
            child: Text(
              "Reset",
              style: TextStyle(
                color: AppColors.AppBlue,
                fontSize: context.fs(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- STOPS

  Widget _buildStopsSection() {
    const rows = [
      (0, '0', 'Non Stop'),
      (1, '1', 'Stop'),
      (2, '2+', 'Stops'),
    ];
    return Row(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(width: context.w(10)),
          Expanded(
            child: _stopCard(rows[i].$1, rows[i].$2, rows[i].$3),
          ),
        ],
      ],
    );
  }

  Widget _stopCard(int bucket, String big, String small) {
    final available = bucket == 0
        ? true
        : bucket == 1
        ? widget.maxStopsAvailable >= 1
        : widget.maxStopsAvailable >= 2;
    final selected = _selectedStops.contains(bucket);
    final price = widget.stopMinPrices[bucket];

    return Opacity(
      opacity: available ? 1 : 0.4,
      child: GestureDetector(
        onTap: available
            ? () => setState(() {
          if (!_selectedStops.remove(bucket)) {
            _selectedStops.add(bucket);
          }
        })
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            vertical: context.h(4),
            horizontal: context.w(16),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(4)),
            color: selected ? AppColors.AppBlue.withValues(alpha: 0.06) : Colors.white,
            border: Border.all(
              color: selected ? AppColors.AppBlue : _stroke,
              width: selected ? 1 : 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                big,
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.AppBlue : _title900,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                small,
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: AppColors.subhead,
                ),
              ),
              if (price != null) ...[
                SizedBox(height: context.h(2)),
                Text(
                  _money(price),
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.AppBlue : AppColors.subhead,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _money(double apiAmount) {
    final preferred = CurrencyConverter.getPreferredCurrency();
    final converted = CurrencyConverter.convert(
      amount: apiAmount,
      fromCurrency: widget.apiCurrency,
      toCurrency: preferred,
    );
    return '${CurrencyConverter.getSymbol(preferred)}${converted.toInt()}';
  }

  // ------------------------------------------------------------- PRICE

  Widget _buildPriceSection() {
    final lo = widget.minPrice;
    final hi = widget.maxPrice > widget.minPrice
        ? widget.maxPrice
        : widget.minPrice + 1;
    final value = _priceRange.end.clamp(lo, hi);

    final preferred = CurrencyConverter.getPreferredCurrency();
    final symbol = CurrencyConverter.getSymbol(preferred);
    String label(double apiAmount) {
      final c = CurrencyConverter.convert(
        amount: apiAmount,
        fromCurrency: widget.apiCurrency,
        toCurrency: preferred,
      );
      return '$symbol${c.toInt()}';
    }

    return Column(
      children: [
        _slider(
          value: value,
          min: lo,
          max: hi,
          label: label(value),
          onChanged: (v) =>
              setState(() => _priceRange = RangeValues(widget.minPrice, v)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label(lo), style: _boundStyle),
            Text(label(hi), style: _boundStyle),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------- DURATION

  Widget _buildDurationSection() {
    final lo = widget.minDuration;
    final hi = widget.maxDuration > widget.minDuration
        ? widget.maxDuration
        : widget.minDuration + 1;
    final value = _durationRange.end.clamp(lo, hi);

    return Column(
      children: [
        _slider(
          value: value,
          min: lo,
          max: hi,
          label: _fmtDur(value),
          onChanged: (v) => setState(
                  () => _durationRange = RangeValues(widget.minDuration, v)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmtDur(lo), style: _boundStyle),
            Text(_fmtDur(hi), style: _boundStyle),
          ],
        ),
      ],
    );
  }

  String _fmtDur(double minutes) {
    final t = minutes.round();
    final h = t ~/ 60;
    final m = t % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  TextStyle get _boundStyle => TextStyle(
    color: _title900,
    fontWeight: FontWeight.w400,
    fontSize: context.fs(12),
  );

  Widget _slider({
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: context.h(6),
        activeTrackColor: AppColors.AppBlue,
        inactiveTrackColor: const Color(0xFFE0E0E0),
        thumbColor: AppColors.AppBlue,
        overlayColor: AppColors.AppBlue.withValues(alpha: 0.12),
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: context.w(11),
          elevation: 3,
        ),
        valueIndicatorColor: Colors.white,
        valueIndicatorTextStyle: TextStyle(
          color: _title900,
          fontSize: context.fs(12),
          fontWeight: FontWeight.w600,
        ),
        showValueIndicator: ShowValueIndicator.always,
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        label: label,
        onChanged: onChanged,
      ),
    );
  }

  // ---------------------------------------------------------- AIRLINES

  Widget _buildAirlinesSection() {
    final names = widget.airlineCounts.keys.toList()..sort();

    return Column(
      children: [
        ...names.map((name) {
          final count = widget.airlineCounts[name] ?? 0;
          final minPrice = widget.airlineMinPrices[name];
          final isSel = _selectedAirlines.contains(name);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              if (isSel) {
                _selectedAirlines.remove(name);
              } else {
                _selectedAirlines.add(name);
              }
            }),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(12)),
              child: Row(
                children: [
                  AirlineLogo(
                    code: widget.airlineCodes[name] ?? '',
                    name: name,
                    size: context.w(32),
                    borderRadius: BorderRadius.circular(context.w(8)),
                  ),
                  SizedBox(width: context.w(16)),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.fs(16), color: AppColors.black),
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
                      _money(minPrice),
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: AppColors.AppBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(width: context.w(12)),
                  _check(isSel),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Figma "Departure From …" / "Arrival at …" — a 2-per-row grid of bordered
  /// cards (label + cheapest fare for that window). A window with no flights
  /// (price 0 / null when prices are supplied) is dimmed and not tappable.
  Widget _buildTimeGrid(Map<String, bool> map, Map<String, double> prices) {
    final slots = _timeSlots.keys.toList();
    final hasPrices = prices.isNotEmpty;

    Widget card(String slot) {
      final selected = map[slot] ?? false;
      final label = _timeSlots[slot]!;
      final price = prices[slot];
      final available = !hasPrices || (price != null && price > 0);

      return Opacity(
        opacity: available ? 1 : 0.54,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: available ? () => setState(() => map[slot] = !selected) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(6),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.r(4)),
              color: selected
                  ? AppColors.AppBlue.withValues(alpha: 0.06)
                  : Colors.white,
              border: Border.all(
                color: selected ? AppColors.AppBlue : _stroke,
                width: selected ? 1 : 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.AppBlue : AppColors.black,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  hasPrices ? _money(price ?? 0) : '',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: AppColors.subhead,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < slots.length; i += 2) ...[
          if (i > 0) SizedBox(height: context.h(12)),
          Row(
            children: [
              Expanded(child: card(slots[i])),
              SizedBox(width: context.w(12)),
              if (i + 1 < slots.length)
                Expanded(child: card(slots[i + 1]))
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(19),
        vertical: context.h(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.r(24))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: context.h(48),
        child: ElevatedButton(
          onPressed: _apply,
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(12)),
            ),
          ),
          child: Text(
            "APPLY FILTER",
            style: TextStyle(
              fontSize: context.fs(14),
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}