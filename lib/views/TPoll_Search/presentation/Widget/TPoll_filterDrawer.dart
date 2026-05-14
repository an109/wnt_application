import 'package:flutter/material.dart';
import '../../domain/entities/TPollSearchEntity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL  — holds every active filter choice
// ─────────────────────────────────────────────────────────────────────────────
class TpollFilterState {
  final String? selectedVehicleType; // null = All Vehicles
  final String sortBy; // 'price_low' | 'price_high' | 'top_rated' | 'capacity'
  final Set<String> selectedAmenities; // empty = All Amenities
  final RangeValues? priceRange; // null = no price filter
  final int? minPassengers; // null = any

  const TpollFilterState({
    this.selectedVehicleType,
    this.sortBy = 'price_low',
    this.selectedAmenities = const {},
    this.priceRange,
    this.minPassengers,
  });

  TpollFilterState copyWith({
    Object? selectedVehicleType = _sentinel,
    String? sortBy,
    Set<String>? selectedAmenities,
    Object? priceRange = _sentinel,
    Object? minPassengers = _sentinel,
  }) {
    return TpollFilterState(
      selectedVehicleType: selectedVehicleType == _sentinel
          ? this.selectedVehicleType
          : selectedVehicleType as String?,
      sortBy: sortBy ?? this.sortBy,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      priceRange:
      priceRange == _sentinel ? this.priceRange : priceRange as RangeValues?,
      minPassengers: minPassengers == _sentinel
          ? this.minPassengers
          : minPassengers as int?,
    );
  }

  bool get hasActiveFilters =>
      selectedVehicleType != null ||
          sortBy != 'price_low' ||
          selectedAmenities.isNotEmpty ||
          priceRange != null ||
          minPassengers != null;

  int get activeFilterCount {
    int count = 0;
    if (selectedVehicleType != null) count++;
    if (sortBy != 'price_low') count++;
    if (selectedAmenities.isNotEmpty) count++;
    if (priceRange != null) count++;
    if (minPassengers != null) count++;
    return count;
  }

  static const _sentinel = Object();
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN DRAWER WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class TpollFilterDrawer extends StatefulWidget {
  /// All unfiltered results — used to derive dynamic filter options
  final List<SearchResultEntity> results;

  /// The current filter state (so drawer opens pre-filled)
  final TpollFilterState currentFilters;

  /// Called when user taps "Apply Filters"
  final ValueChanged<TpollFilterState> onApply;

  const TpollFilterDrawer({
    super.key,
    required this.results,
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<TpollFilterDrawer> createState() => _TpollFilterDrawerState();
}

class _TpollFilterDrawerState extends State<TpollFilterDrawer> {
  // ── local mutable copy of filters ──
  late String? _selectedVehicleType;
  late String _sortBy;
  late Set<String> _selectedAmenities;
  late RangeValues _priceRange;
  late RangeValues _priceRangeLimits;
  late int? _minPassengers;

  // ── design tokens ──
  static const _primaryBlue = Color(0xff1663F7);
  static const _primaryOrange = Color(0xffF97316);
  static const _darkNavy = Color(0xff0D1B3D);
  static const _bgGray = Color(0xffF8F9FA);
  static const _divider = Color(0xffF0F1F3);

  // ── derived data from results ──
  late List<String> _vehicleTypes;
  late List<String> _amenityNames;
  late List<int> _passengerOptions;

  @override
  void initState() {
    super.initState();
    _initFromFilters(widget.currentFilters);
    _deriveOptionsFromResults();
  }

  void _initFromFilters(TpollFilterState f) {
    _selectedVehicleType = f.selectedVehicleType;
    _sortBy = f.sortBy;
    _selectedAmenities = Set.from(f.selectedAmenities);
    _minPassengers = f.minPassengers;
  }

  void _deriveOptionsFromResults() {
    final results = widget.results;

    // Vehicle types
    _vehicleTypes = results.map((r) => r.vehicleType).toSet().toList()..sort();

    // Amenity names (union of all results)
    _amenityNames = results
        .expand((r) => r.amenities)
        .map((a) => a.name)
        .toSet()
        .toList()
      ..sort();

    // Passenger capacity options
    _passengerOptions =
    results.map((r) => r.maxPassengers).toSet().toList()..sort();

    // Price range limits
    final prices = results
        .map((r) => double.tryParse(r.totalPriceAmount) ?? 0)
        .where((p) => p > 0)
        .toList();

    if (prices.isNotEmpty) {
      final minP = prices.reduce((a, b) => a < b ? a : b);
      final maxP = prices.reduce((a, b) => a > b ? a : b);
      _priceRangeLimits = RangeValues(minP, maxP);
      _priceRange = widget.currentFilters.priceRange ??
          RangeValues(minP, maxP);
    } else {
      _priceRangeLimits = const RangeValues(0, 10000);
      _priceRange =
          widget.currentFilters.priceRange ?? const RangeValues(0, 10000);
    }
  }

  int get _activeCount {
    int c = 0;
    if (_selectedVehicleType != null) c++;
    if (_sortBy != 'price_low') c++;
    if (_selectedAmenities.isNotEmpty) c++;
    if (_minPassengers != null) c++;
    final defaultRange = _priceRangeLimits;
    if (_priceRange.start > defaultRange.start ||
        _priceRange.end < defaultRange.end) c++;
    return c;
  }

  void _resetAll() {
    setState(() {
      _selectedVehicleType = null;
      _sortBy = 'price_low';
      _selectedAmenities = {};
      _priceRange = _priceRangeLimits;
      _minPassengers = null;
    });
  }

  void _apply() {
    final defaultRange = _priceRangeLimits;
    final priceChanged = _priceRange.start > defaultRange.start ||
        _priceRange.end < defaultRange.end;

    widget.onApply(TpollFilterState(
      selectedVehicleType: _selectedVehicleType,
      sortBy: _sortBy,
      selectedAmenities: Set.from(_selectedAmenities),
      priceRange: priceChanged ? _priceRange : null,
      minPassengers: _minPassengers,
    ));
    Navigator.pop(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSection(
                    title: 'VEHICLE TYPE',
                    icon: Icons.directions_car_outlined,
                    child: _buildVehicleTypeSection(),
                  ),
                  _buildDivider(),
                  _buildSection(
                    title: 'SORT BY',
                    icon: Icons.sort,
                    child: _buildSortBySection(),
                  ),
                  _buildDivider(),
                  _buildSection(
                    title: 'PRICE RANGE',
                    icon: Icons.attach_money,
                    child: _buildPriceRangeSection(),
                  ),
                  _buildDivider(),
                  if (_passengerOptions.isNotEmpty) ...[
                    _buildSection(
                      title: 'PASSENGERS',
                      icon: Icons.people_outline,
                      child: _buildPassengersSection(),
                    ),
                    _buildDivider(),
                  ],
                  if (_amenityNames.isNotEmpty) ...[
                    _buildSection(
                      title: 'AMENITIES',
                      icon: Icons.star_outline,
                      child: _buildAmenitiesSection(),
                    ),
                    _buildDivider(),
                  ],
                  const SizedBox(height: 100), // space for bottom buttons
                ],
              ),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _divider, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, color: _darkNavy, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          if (_activeCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _primaryOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_activeCount',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (_activeCount > 0)
            TextButton(
              onPressed: _resetAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: _primaryBlue,
              ),
              child: const Text(
                'Clear all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(color: _divider, height: 1, thickness: 1);

  // ── VEHICLE TYPE ──────────────────────────────────────────────────────────
  Widget _buildVehicleTypeSection() {
    final options = [
      _VehicleOption(null, 'All Vehicles', Icons.directions_car_outlined),
      ..._vehicleTypes.map((t) => _VehicleOption(t, t, _vehicleIcon(t))),
    ];

    return Column(
      children: options.map((opt) {
        final selected = _selectedVehicleType == opt.value;
        return _buildRadioRow(
          label: opt.label,
          icon: opt.icon,
          selected: selected,
          onTap: () => setState(() => _selectedVehicleType = opt.value),
          resultCount: opt.value == null
              ? widget.results.length
              : widget.results
              .where((r) => r.vehicleType == opt.value)
              .length,
        );
      }).toList(),
    );
  }

  // ── SORT BY ───────────────────────────────────────────────────────────────
  Widget _buildSortBySection() {
    const options = [
      _SortOption('price_low', 'Price: Low to High', Icons.trending_down),
      _SortOption('price_high', 'Price: High to Low', Icons.trending_up),
      _SortOption('top_rated', 'Top Rated', Icons.star_outline),
      _SortOption('capacity', 'Most Capacity', Icons.people_outline),
    ];

    return Column(
      children: options.map((opt) {
        final selected = _sortBy == opt.value;
        return _buildRadioRow(
          label: opt.label,
          icon: opt.icon,
          selected: selected,
          onTap: () => setState(() => _sortBy = opt.value),
        );
      }).toList(),
    );
  }

  // ── PRICE RANGE ───────────────────────────────────────────────────────────
  Widget _buildPriceRangeSection() {
    final min = _priceRangeLimits.start;
    final max = _priceRangeLimits.end;
    final isDefault =
        _priceRange.start <= min && _priceRange.end >= max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display selected range
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _priceLabel(_priceRange.start.toInt()),
            Text(
              '—',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            _priceLabel(_priceRange.end.toInt()),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _primaryBlue,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Colors.white,
            overlayColor: _primaryBlue.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 3,
            ),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 3,
            ),
            trackHeight: 4,
          ),
          child: RangeSlider(
            values: _priceRange,
            min: min,
            max: max,
            divisions: max > min ? ((max - min) / 100).round().clamp(1, 100) : 1,
            onChanged: (v) => setState(() => _priceRange = v),
          ),
        ),
        if (!isDefault)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  setState(() => _priceRange = _priceRangeLimits),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: _primaryBlue,
              ),
              child: const Text('Reset', style: TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _priceLabel(int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgGray,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        '₹$value',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _darkNavy,
        ),
      ),
    );
  }

  // ── PASSENGERS ────────────────────────────────────────────────────────────
  Widget _buildPassengersSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "Any" chip
        _passengerChip(null, 'Any'),
        ..._passengerOptions.map(
              (p) => _passengerChip(p, '$p+ pax'),
        ),
      ],
    );
  }

  Widget _passengerChip(int? value, String label) {
    final selected = _minPassengers == value;
    return GestureDetector(
      onTap: () => setState(() => _minPassengers = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _primaryBlue : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ── AMENITIES ─────────────────────────────────────────────────────────────
  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "All Amenities" row
        _buildCheckRow(
          label: 'All Amenities',
          selected: _selectedAmenities.isEmpty,
          onTap: () => setState(() => _selectedAmenities = {}),
          isAllOption: true,
        ),
        ..._amenityNames.map((name) {
          final selected = _selectedAmenities.contains(name);
          return _buildCheckRow(
            label: name,
            selected: selected,
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedAmenities.remove(name);
                } else {
                  _selectedAmenities.add(name);
                }
              });
            },
          );
        }),
      ],
    );
  }

  // ── Reusable row types ────────────────────────────────────────────────────

  /// Radio-style row (single selection) — used for Vehicle Type & Sort By
  Widget _buildRadioRow({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    int? resultCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _primaryBlue : Colors.transparent,
                border: Border.all(
                  color: selected ? _primaryBlue : Colors.grey.shade400,
                  width: selected ? 0 : 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              size: 16,
              color: selected ? _primaryBlue : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? _primaryBlue : const Color(0xff374151),
                ),
              ),
            ),
            if (resultCount != null)
              Text(
                '($resultCount)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Checkbox-style row (multi selection) — used for Amenities
  Widget _buildCheckRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isAllOption = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: selected ? _primaryBlue : Colors.transparent,
                border: Border.all(
                  color: selected ? _primaryBlue : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? _primaryBlue
                      : isAllOption
                      ? const Color(0xff374151)
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom action buttons ─────────────────────────────────────────────────
  Widget _buildBottomActions(BuildContext context) {
    // Count how many results match current filters
    final matchCount = _countMatchingResults();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _divider, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Result count preview
          Text(
            '$matchCount result${matchCount != 1 ? 's' : ''} match these filters',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Reset button
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: _resetAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkNavy,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Apply button
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _countMatchingResults() {
    return widget.results.where((r) {
      if (_selectedVehicleType != null &&
          r.vehicleType != _selectedVehicleType) return false;

      if (_selectedAmenities.isNotEmpty) {
        final names = r.amenities.map((a) => a.name).toSet();
        if (!_selectedAmenities.every((a) => names.contains(a))) return false;
      }

      if (_minPassengers != null && r.maxPassengers < _minPassengers!) {
        return false;
      }

      final price = double.tryParse(r.totalPriceAmount) ?? 0;
      if (price < _priceRange.start || price > _priceRange.end) return false;

      return true;
    }).length;
  }

  IconData _vehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'private car':
      case 'sedan':
        return Icons.directions_car_outlined;
      case 'shared shuttle':
        return Icons.airport_shuttle_outlined;
      case 'minivan':
      case 'suv':
      case 'minivan / suv':
        return Icons.airline_seat_recline_extra_outlined;
      case 'bus':
      case 'bus / coach':
        return Icons.directions_bus_outlined;
      case 'premium':
        return Icons.star_border_outlined;
      default:
        return Icons.directions_car_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER MODELS  (private, used only within this file)
// ─────────────────────────────────────────────────────────────────────────────
class _VehicleOption {
  final String? value;
  final String label;
  final IconData icon;
  const _VehicleOption(this.value, this.label, this.icon);
}

class _SortOption {
  final String value;
  final String label;
  final IconData icon;
  const _SortOption(this.value, this.label, this.icon);
}