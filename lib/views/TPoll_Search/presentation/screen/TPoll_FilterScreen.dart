import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/resources/app_colours.dart';
import '../../domain/entities/TPollSearchEntity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FILTER STATE — every active filter choice for the Transport results list
// ─────────────────────────────────────────────────────────────────────────────
class TpollFilterState {
  static const String sortPopular = 'popular';
  static const String sortCapacity = 'capacity';
  static const String sortPriceHigh = 'price_high';
  static const String sortPriceLow = 'price_low';
  static const String sortRating = 'rating';

  final String sortBy;
  final Set<String> selectedVehicleTypes; // empty = All Vehicles
  final Set<String> selectedAmenities; // empty = All Amenities
  final double? maxPrice; // null = no price cap (native result currency)
  final int? minPassengers; // null = any

  const TpollFilterState({
    this.sortBy = sortPopular,
    this.selectedVehicleTypes = const {},
    this.selectedAmenities = const {},
    this.maxPrice,
    this.minPassengers,
  });

  TpollFilterState copyWith({String? sortBy}) => TpollFilterState(
        sortBy: sortBy ?? this.sortBy,
        selectedVehicleTypes: selectedVehicleTypes,
        selectedAmenities: selectedAmenities,
        maxPrice: maxPrice,
        minPassengers: minPassengers,
      );

  bool get hasActiveFilters =>
      selectedVehicleTypes.isNotEmpty ||
      selectedAmenities.isNotEmpty ||
      maxPrice != null ||
      minPassengers != null;

  /// Options for the results screen's Sort sheet (Figma "Sort by").
  static const List<TpollSortOption> sheetSortOptions = [
    TpollSortOption(sortPopular, 'Popularity', Icons.star_border_rounded),
    TpollSortOption(
        sortPriceLow, 'Price (Low to High)', Icons.trending_up_rounded),
    TpollSortOption(
        sortPriceHigh, 'Price (High to Low)', Icons.trending_down_rounded),
    TpollSortOption(sortRating, 'Ratings (Highest)', Icons.star_rounded),
  ];

  /// Tiles in the Filter screen's "Sort By" card (Figma).
  static const List<TpollSortOption> sortOptions = [
    TpollSortOption(sortPopular, 'Popularity', Icons.star_border_rounded),
    TpollSortOption(sortCapacity, 'Most Capacity', Icons.groups_2_outlined),
    TpollSortOption(
        sortPriceHigh, 'Price: High to Low', Icons.trending_down_rounded),
    TpollSortOption(
        sortPriceLow, 'Price: Low to High', Icons.trending_up_rounded),
  ];
}

class TpollSortOption {
  final String value;
  final String label;
  final IconData icon;
  const TpollSortOption(this.value, this.label, this.icon);
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER SCREEN (full screen, replaces the old end drawer)
// Pops with the chosen TpollFilterState when "Apply Filter" is tapped.
// ─────────────────────────────────────────────────────────────────────────────
class TpollFilterScreen extends StatefulWidget {
  /// All unfiltered results — filter options are derived from these.
  final List<SearchResultEntity> results;
  final TpollFilterState currentFilters;

  const TpollFilterScreen({
    super.key,
    required this.results,
    required this.currentFilters,
  });

  @override
  State<TpollFilterScreen> createState() => _TpollFilterScreenState();
}

class _TpollFilterScreenState extends State<TpollFilterScreen> {
  static const _cardBorder = Color(0xffE3E5E8);
  static const _sectionTitle = Color(0xff8E8E8E);
  static const _selectedFill = Color(0xffE8F5FC);
  static const _text = Color(0xff1A1A1A);

  late String _sortBy;
  late Set<String> _vehicleTypes;
  late Set<String> _amenities;
  late double _maxPrice;
  late int? _minPassengers;

  late final List<String> _allVehicleTypes;
  late final List<String> _allAmenities;
  late final List<int> _passengerOptions;
  late final double _priceMin;
  late final double _priceMax;
  // Currency the raw result prices (and the slider) are in. Filtering stays in
  // this currency; only labels are converted to the user's preferred currency
  // so they match the prices on the vehicle cards.
  late final String _nativeCurrency;

  @override
  void initState() {
    super.initState();
    final results = widget.results;

    _nativeCurrency =
        results.isNotEmpty && results.first.totalPriceCurrency.isNotEmpty
            ? results.first.totalPriceCurrency
            : 'USD';
    _allVehicleTypes = results
        .map((r) => r.vehicleType)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    _allAmenities = results
        .expand((r) => r.amenities)
        .map((a) => a.name)
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    _passengerOptions = results
        .map((r) => r.maxPassengers)
        .where((p) => p > 0)
        .toSet()
        .toList()
      ..sort();

    final prices = results
        .map((r) => double.tryParse(r.totalPriceAmount) ?? 0)
        .where((p) => p > 0)
        .toList();
    if (prices.isEmpty) {
      _priceMin = 0;
      _priceMax = 0;
    } else {
      _priceMin = prices.reduce((a, b) => a < b ? a : b);
      _priceMax = prices.reduce((a, b) => a > b ? a : b);
    }

    final f = widget.currentFilters;
    _sortBy = f.sortBy;
    _vehicleTypes = Set.of(f.selectedVehicleTypes);
    _amenities = Set.of(f.selectedAmenities);
    _minPassengers = f.minPassengers;
    _maxPrice = (f.maxPrice ?? _priceMax).clamp(_priceMin, _priceMax);
  }

  void _clearAll() {
    setState(() {
      _sortBy = TpollFilterState.sortPopular;
      _vehicleTypes = {};
      _amenities = {};
      _maxPrice = _priceMax;
      _minPassengers = null;
    });
  }

  void _apply() {
    final capped = _priceMax > _priceMin && _maxPrice < _priceMax - 0.5;
    Navigator.pop(
      context,
      TpollFilterState(
        sortBy: _sortBy,
        selectedVehicleTypes: Set.of(_vehicleTypes),
        selectedAmenities: Set.of(_amenities),
        maxPrice: capped ? _maxPrice : null,
        minPassengers: _minPassengers,
      ),
    );
  }

  String _money(double nativeAmount) {
    final preferred = CurrencyConverter.getPreferredCurrency();
    final converted = CurrencyConverter.convert(
      amount: nativeAmount,
      fromCurrency: _nativeCurrency,
      toCurrency: preferred,
    );
    return CurrencyConverter.format(converted, preferred);
  }

  // ───────────────────────────────────────────────────────────────── BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            context.w(15), context.h(16), context.w(15), context.h(24)),
        children: [
          _sortByCard(context),
          if (_priceMax > _priceMin) ...[
            SizedBox(height: context.h(16)),
            _priceCard(context),
          ],
          if (_passengerOptions.isNotEmpty) ...[
            SizedBox(height: context.h(16)),
            _passengersCard(context),
          ],
          if (_allVehicleTypes.isNotEmpty) ...[
            SizedBox(height: context.h(16)),
            _vehicleTypeCard(context),
          ],
          if (_allAmenities.isNotEmpty) ...[
            SizedBox(height: context.h(16)),
            _amenitiesCard(context),
          ],
        ],
      ),
      bottomNavigationBar: _buildApplyBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      scrolledUnderElevation: 4,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppColors.black, size: context.w(22)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Filters',
        style: TextStyle(
          fontSize: context.fs(18),
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearAll,
          child: Text(
            'Clear',
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w500,
              color: AppColors.AppBlue,
            ),
          ),
        ),
        SizedBox(width: context.w(6)),
      ],
    );
  }

  Widget _buildApplyBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: context.w(10),
            offset: Offset(0, -context.h(2)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              context.w(16), context.h(12), context.w(16), context.h(12)),
          child: SizedBox(
            height: context.h(44),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.OrangeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: Text(
                'APPLY FILTER',
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────── SECTIONS
  Widget _card(BuildContext context, String title, Widget child,
      {bool divider = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          context.w(17), context.h(16), context.w(17), context.h(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: context.w(6),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.fs(15),
              fontWeight: FontWeight.w400,
              color: _sectionTitle,
            ),
          ),
          if (divider) ...[
            SizedBox(height: context.h(12)),
            const Divider(height: 1, thickness: 1, color: Color(0xffE9EBEE)),
          ],
          SizedBox(height: context.h(divider ? 4 : 14)),
          child,
        ],
      ),
    );
  }

  // ── Sort By: 2-column grid of tiles ──
  Widget _sortByCard(BuildContext context) {
    const opts = TpollFilterState.sortOptions;
    final gap = context.w(10);
    return _card(
      context,
      'Sort By',
      LayoutBuilder(builder: (context, c) {
        final tileW = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: context.h(10),
          children: opts.map((o) {
            final selected = _sortBy == o.value;
            return GestureDetector(
              onTap: () => setState(() => _sortBy = o.value),
              child: Container(
                width: tileW,
                height: context.h(58),
                decoration: BoxDecoration(
                  color: selected ? _selectedFill : AppColors.white,
                  borderRadius: BorderRadius.circular(context.r(6)),
                  border: Border.all(
                    color: selected ? AppColors.AppBlue : _cardBorder,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      o.icon,
                      size: context.w(18),
                      color: selected ? AppColors.AppBlue : _text,
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      o.label,
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: selected ? AppColors.AppBlue : _text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  // ── Price Range: single slider capping the maximum price ──
  Widget _priceCard(BuildContext context) {
    return _card(
      context,
      'Price Range',
      ValueListenableBuilder<String>(
        valueListenable: CurrencyConverter.currencyListenable,
        builder: (context, _, __) => Column(
          children: [
            _PriceSlider(
              min: _priceMin,
              max: _priceMax,
              value: _maxPrice,
              label: _money(_maxPrice),
              onChanged: (v) => setState(() => _maxPrice = v),
            ),
            SizedBox(height: context.h(6)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_money(_priceMin), style: _priceEndStyle(context)),
                Text(_money(_priceMax), style: _priceEndStyle(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _priceEndStyle(BuildContext context) =>
      TextStyle(fontSize: context.fs(11), color: _text);

  // ── Passengers: chips built from the real capacities in the results ──
  Widget _passengersCard(BuildContext context) {
    Widget chip(int? value, String label) {
      final selected = _minPassengers == value;
      return GestureDetector(
        onTap: () => setState(() => _minPassengers = value),
        child: Container(
          height: context.h(26),
          padding: EdgeInsets.symmetric(horizontal: context.w(10)),
          decoration: BoxDecoration(
            color: selected ? _selectedFill : AppColors.white,
            borderRadius: BorderRadius.circular(context.r(4)),
            border: Border.all(
              color: selected ? AppColors.AppBlue : const Color(0xff9AA0A6),
            ),
          ),
          // widthFactor keeps the chip hugging its label inside the Wrap.
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fs(13),
                color: selected ? AppColors.AppBlue : _text,
              ),
            ),
          ),
        ),
      );
    }

    return _card(
      context,
      'Passengers',
      Wrap(
        spacing: context.w(10),
        runSpacing: context.h(8),
        children: [
          chip(null, 'Any'),
          ..._passengerOptions.map((p) => chip(p, '$p+ pax')),
        ],
      ),
    );
  }

  // ── Vehicle Type: checkbox list ──
  Widget _vehicleTypeCard(BuildContext context) {
    return _card(
      context,
      'Vehicle Type',
      Column(
        children: [
          _checkRow(
            context,
            'All Vehicles',
            _vehicleTypes.isEmpty,
            () => setState(() => _vehicleTypes = {}),
          ),
          ..._allVehicleTypes.map(
            (t) => _checkRow(
              context,
              t,
              _vehicleTypes.contains(t),
              () => setState(() {
                _vehicleTypes.contains(t)
                    ? _vehicleTypes.remove(t)
                    : _vehicleTypes.add(t);
              }),
            ),
          ),
        ],
      ),
      divider: true,
    );
  }

  // ── Amenities: checkbox list of the amenities the API returned ──
  Widget _amenitiesCard(BuildContext context) {
    return _card(
      context,
      'Amenities',
      Column(
        children: [
          _checkRow(
            context,
            'All Amenities',
            _amenities.isEmpty,
            () => setState(() => _amenities = {}),
          ),
          ..._allAmenities.map(
            (a) => _checkRow(
              context,
              a,
              _amenities.contains(a),
              () => setState(() {
                _amenities.contains(a)
                    ? _amenities.remove(a)
                    : _amenities.add(a);
              }),
            ),
          ),
        ],
      ),
      divider: true,
    );
  }

  Widget _checkRow(
      BuildContext context, String label, bool checked, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: context.h(42),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: context.fs(15), color: _text),
              ),
            ),
            Container(
              width: context.w(20),
              height: context.w(20),
              decoration: BoxDecoration(
                color: checked ? AppColors.AppBlue : AppColors.white,
                borderRadius: BorderRadius.circular(context.r(4)),
                border: Border.all(
                  color: checked ? AppColors.AppBlue : const Color(0xffB8BDC3),
                  width: 1.2,
                ),
              ),
              child: checked
                  ? Icon(Icons.check, size: context.w(15), color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single-thumb price slider with the value bubble floating above the thumb.
// ─────────────────────────────────────────────────────────────────────────────
class _PriceSlider extends StatelessWidget {
  final double min;
  final double max;
  final double value;
  final String label;
  final ValueChanged<double> onChanged;

  const _PriceSlider({
    required this.min,
    required this.max,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = context.w(24);
    final bubbleW = context.w(74);
    final bubbleH = context.h(28);
    final pointer = context.w(9);
    final trackH = context.w(5);
    final gap = context.h(4);
    final totalH = bubbleH + gap + thumb;

    return LayoutBuilder(builder: (context, c) {
      final usable = c.maxWidth - thumb;
      final t = max > min ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 1.0;
      final thumbCenter = thumb / 2 + usable * t;
      final thumbTop = bubbleH + gap;
      final trackTop = thumbTop + (thumb - trackH) / 2;

      double valueAt(double dx) {
        final ratio = ((dx - thumb / 2) / usable).clamp(0.0, 1.0);
        return min + ratio * (max - min);
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => onChanged(valueAt(d.localPosition.dx)),
        onHorizontalDragUpdate: (d) => onChanged(valueAt(d.localPosition.dx)),
        child: SizedBox(
          height: totalH,
          width: c.maxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // inactive track
              Positioned(
                left: thumb / 2,
                right: thumb / 2,
                top: trackTop,
                height: trackH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xffE2E4E7),
                    borderRadius: BorderRadius.circular(trackH),
                  ),
                ),
              ),
              // active track
              Positioned(
                left: thumb / 2,
                width: usable * t,
                top: trackTop,
                height: trackH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.AppBlue,
                    borderRadius: BorderRadius.circular(trackH),
                  ),
                ),
              ),
              // thumb
              Positioned(
                left: thumbCenter - thumb / 2,
                top: thumbTop,
                width: thumb,
                height: thumb,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.AppBlue, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              // value bubble
              Positioned(
                left: (thumbCenter - bubbleW / 2)
                    .clamp(0.0, c.maxWidth - bubbleW),
                top: 0,
                width: bubbleW,
                height: bubbleH,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(context.r(6)),
                    border: Border.all(color: const Color(0xffE3E5E8)),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: const Color(0xff1A1A1A),
                    ),
                  ),
                ),
              ),
              // bubble pointer
              Positioned(
                left: thumbCenter - pointer / 2,
                top: bubbleH - pointer / 2 - 0.5,
                width: pointer,
                height: pointer,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border(
                        right: BorderSide(color: Color(0xffE3E5E8)),
                        bottom: BorderSide(color: Color(0xffE3E5E8)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
