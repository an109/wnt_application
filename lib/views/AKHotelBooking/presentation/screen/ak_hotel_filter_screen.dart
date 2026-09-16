import 'package:flutter/material.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';

/// Full-screen replacement for [HotelFilterDrawer] on the Akbar Hotels flow
/// — same Figma two-pane layout (a left rail of categories, a right pane
/// with every section stacked and scrollable, tapping a category scrolls
/// the pane to it) as the reference. Every filter field it produces
/// (`min_price`/`max_price`/`star_rating`/`Refundable`/`MealType`/
/// `amenities`/`NoOfRooms`) is byte-identical in shape to what
/// [HotelFilterDrawer] already sent to [applyAkHotelClientFilters], plus one
/// new field, `search_query`, that layers in the locality/hotel-name search
/// box the reference shows — so nothing already filtering stops working,
/// and the search box actually does something rather than sitting there
/// for show.
///
/// The count shown beside every checkbox is computed live from [hotels] —
/// the same list already on screen — never a placeholder number.
class AkHotelFilterScreen extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final List<HotelUiModel> hotels;
  final void Function(Map<String, dynamic> filters) onApply;
  final VoidCallback onClear;

  const AkHotelFilterScreen({
    super.key,
    required this.initialFilters,
    required this.hotels,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<AkHotelFilterScreen> createState() => _AkHotelFilterScreenState();
}

class _MealPlanOption {
  final String value;
  final String label;
  const _MealPlanOption(this.value, this.label);
}

const _mealPlans = [
  _MealPlanOption('Breakfast', 'Breakfast Included'),
  _MealPlanOption('HalfBoard', 'Half Board'),
  _MealPlanOption('FullBoard', 'Full Board'),
  _MealPlanOption('AllInclusive', 'All Inclusive'),
  _MealPlanOption('RoomOnly', 'Room Only'),
];

const _amenityOptions = [
  'WiFi',
  'Pool',
  'Gym',
  'Parking',
  'Spa',
  'Restaurant',
  'Airport Shuttle',
  'Beach Access',
  'Room Service',
  'Air Conditioning',
];

class _AkHotelFilterScreenState extends State<AkHotelFilterScreen> {
  static const _maxPriceBoundInr = 100000.0;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _priceKey = GlobalKey();
  final _starKey = GlobalKey();
  final _bookingKey = GlobalKey();
  final _mealKey = GlobalKey();
  final _amenitiesKey = GlobalKey();

  late final List<_FilterCategory> _categories = [
    _FilterCategory('Price', _priceKey),
    _FilterCategory('Star Rating', _starKey),
    _FilterCategory('Booking Type', _bookingKey),
    _FilterCategory('Meal Options', _mealKey),
    _FilterCategory('Amenities', _amenitiesKey),
  ];
  int _activeCategory = 0;

  double _minPrice = 0;
  double _maxPrice = _maxPriceBoundInr;
  int? _selectedStarRating;
  final Set<String> _selectedAmenities = {};
  String? _selectedMealPlan;
  bool _refundableOnly = false;

  String _currentCurrency = 'INR';
  late double _convertedMinPrice;
  late double _convertedMaxPrice;

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters;
    _minPrice = (filters['min_price'] as num?)?.toDouble() ?? 0;
    _maxPrice = (filters['max_price'] as num?)?.toDouble() ?? _maxPriceBoundInr;
    _selectedStarRating = (filters['star_rating'] as num?)?.toInt();
    _selectedAmenities.addAll(((filters['amenities'] as List?) ?? const []).map((e) => e.toString()));
    final mealType = filters['MealType'] as String?;
    _selectedMealPlan = (mealType == null || mealType == 'All') ? null : mealType;
    _refundableOnly = filters['Refundable'] == true;
    _searchController.text = (filters['search_query'] as String?) ?? '';

    _currentCurrency = CurrencyConverter.getPreferredCurrency();
    _convertedMinPrice = CurrencyConverter.convert(amount: _minPrice, fromCurrency: 'INR', toCurrency: _currentCurrency);
    _convertedMaxPrice = CurrencyConverter.convert(amount: _maxPrice, fromCurrency: 'INR', toCurrency: _currentCurrency);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _toInr(double amount) {
    if (_currentCurrency == 'INR') return amount;
    return CurrencyConverter.convert(amount: amount, fromCurrency: _currentCurrency, toCurrency: 'INR');
  }

  void _resetAll() {
    Navigator.pop(context);
    widget.onClear();
  }

  void _apply() {
    final filters = <String, dynamic>{};
    filters['Refundable'] = _refundableOnly;
    filters['MealType'] = _selectedMealPlan ?? 'All';
    filters['NoOfRooms'] = 0;
    if (_minPrice > 0) filters['min_price'] = _minPrice;
    if (_maxPrice < _maxPriceBoundInr) filters['max_price'] = _maxPrice;
    if (_selectedStarRating != null) filters['star_rating'] = _selectedStarRating;
    if (_selectedAmenities.isNotEmpty) filters['amenities'] = _selectedAmenities.toList();
    final query = _searchController.text.trim();
    if (query.isNotEmpty) filters['search_query'] = query;

    Navigator.pop(context);
    widget.onApply(filters);
  }

  void _goToCategory(int index) {
    setState(() => _activeCategory = index);
    final ctx = _categories[index].key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0,
      );
    }
  }

  int _countByRating(int rating) => widget.hotels.where((h) => h.rating == rating).length;

  int _countRefundable() => widget.hotels.where((h) => h.isRefundable).length;

  int _countByMeal(String value) =>
      widget.hotels.where((h) => h.mealType.toLowerCase().contains(value.toLowerCase())).length;

  int _countByAmenity(String amenity) {
    final needle = amenity.toLowerCase();
    return widget.hotels.where((h) => h.facilities.join(' ').toLowerCase().contains(needle)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const Divider(height: 1, color: Color(0xFFEDEDED)),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCategoryRail(),
                  const VerticalDivider(width: 1, color: Color(0xFFEDEDED)),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            height: context.buttonHeight,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.OrangeColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
              ),
              child: Text(
                'APPLY FILTER',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: context.fs(14),
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.gapSmall, context.gapSmall, context.gapLarge, context.gapSmall),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.navy, size: context.iconMedium),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Filters',
            style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600, color: AppColors.black),
          ),
          const Spacer(),
          TextButton(
            onPressed: _resetAll,
            child: Text(
              'Reset',
              style: TextStyle(color: AppColors.AppBlue, fontWeight: FontWeight.w600, fontSize: context.fs(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.gapLarge, 0, context.gapLarge, context.gapMedium),
      child: Container(
        height: context.h(42),
        padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: const Color(0xFFE2E7F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: Colors.grey.shade300),
            SizedBox(width: context.gapSmall),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: context.bodyMedium, color: AppColors.navy),
                decoration: InputDecoration(
                  hintText: 'Search for locality / hotel name',
                  hintStyle: TextStyle(fontSize: context.fs(10), color: AppColors.subhead, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRail() {
    return SizedBox(
      width: context.w(100),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final selected = index == _activeCategory;
          return InkWell(
            onTap: () => _goToCategory(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.gapMedium, vertical: context.h(16)),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEAF6FF) : Colors.white,
                border: Border(
                  left: BorderSide(color: selected ? AppColors.AppBlue : Colors.transparent, width: 3),
                ),
              ),
              child: Text(
                _categories[index].label,
                style: TextStyle(
                  fontSize: context.fs(12.5),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.AppBlue : AppColors.navy,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric( vertical: context.gapMedium),
      children: [
        _buildPriceSection(),
        _buildSectionHeader('Star Rating', key: _starKey),
        for (var star = 5; star >= 1; star--)
          _checkboxRow(
            label: '$star Star',
            count: _countByRating(star),
            selected: _selectedStarRating == star,
            onTap: () => setState(() => _selectedStarRating = _selectedStarRating == star ? null : star),
          ),
        _buildSectionHeader('Booking Type', key: _bookingKey),
        _checkboxRow(
          label: 'Refundable Only',
          count: _countRefundable(),
          selected: _refundableOnly,
          onTap: () => setState(() => _refundableOnly = !_refundableOnly),
        ),
        _buildSectionHeader('Meal Options', key: _mealKey),
        for (final plan in _mealPlans)
          _checkboxRow(
            label: plan.label,
            count: _countByMeal(plan.value),
            selected: _selectedMealPlan == plan.value,
            onTap: () => setState(() => _selectedMealPlan = _selectedMealPlan == plan.value ? null : plan.value),
          ),
        _buildSectionHeader('Amenities', key: _amenitiesKey),
        for (final amenity in _amenityOptions)
          _checkboxRow(
            label: amenity,
            count: _countByAmenity(amenity),
            selected: _selectedAmenities.contains(amenity),
            onTap: () => setState(() {
              if (!_selectedAmenities.remove(amenity)) _selectedAmenities.add(amenity);
            }),
          ),
        SizedBox(height: context.gapLarge),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {required Key key}) {
    return Container(
      key: key,
      color: const Color(0xFFF6F9FC),
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      margin: EdgeInsets.only(top: context.gapSmall, bottom: context.gapSmall),
      child: Row(
        children: [
          SizedBox(width: context.w(10),),
          Text(
            title,
            style: TextStyle(fontSize: context.fs(8), fontWeight: FontWeight.w500, color: AppColors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return ValueListenableBuilder<String>(
      key: _priceKey,
      valueListenable: CurrencyConverter.currencyListenable,
      builder: (context, currency, _) {
        if (_currentCurrency != currency) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _currentCurrency = currency;
              _convertedMinPrice = CurrencyConverter.convert(amount: _minPrice, fromCurrency: 'INR', toCurrency: currency);
              _convertedMaxPrice = CurrencyConverter.convert(amount: _maxPrice, fromCurrency: 'INR', toCurrency: currency);
            });
          });
        }
        final symbol = CurrencyConverter.getSymbol(_currentCurrency);
        final upperBound = _toInrInverse(_maxPriceBoundInr);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Per Night',
              style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w600, color: AppColors.subhead),
            ),
            SizedBox(height: context.gapSmall),
            Row(
              children: [
                _priceLabel('Minimum', '$symbol${_convertedMinPrice.toStringAsFixed(0)}'),
                const Spacer(),
                _priceLabel('Maximum', '$symbol${_convertedMaxPrice.toStringAsFixed(0)}${_convertedMaxPrice >= upperBound ? '+' : ''}',
                    alignEnd: true),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.AppBlue,
                inactiveTrackColor: const Color(0xFFE2E7F0),
                thumbColor: AppColors.AppBlue,
                overlayColor: AppColors.AppBlue.withValues(alpha: 0.15),
                rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 9),
              ),
              child: RangeSlider(
                values: RangeValues(_convertedMinPrice.clamp(0, upperBound), _convertedMaxPrice.clamp(0, upperBound)),
                min: 0,
                max: upperBound,
                divisions: 100,
                labels: RangeLabels(
                  '$symbol${_convertedMinPrice.toStringAsFixed(0)}',
                  '$symbol${_convertedMaxPrice.toStringAsFixed(0)}',
                ),
                onChanged: (values) {
                  setState(() {
                    _convertedMinPrice = values.start;
                    _convertedMaxPrice = values.end;
                    _minPrice = _toInr(values.start);
                    _maxPrice = _toInr(values.end);
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Converts an INR bound to the display currency — the inverse direction
  // of _toInr, needed just to know where the slider's upper bound sits.
  double _toInrInverse(double inrAmount) {
    if (_currentCurrency == 'INR') return inrAmount;
    return CurrencyConverter.convert(amount: inrAmount, fromCurrency: 'INR', toCurrency: _currentCurrency);
  }

  Widget _priceLabel(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(10.5), color: Colors.grey.shade500)),
        Text(value, style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: AppColors.navy)),
      ],
    );
  }

  Widget _checkboxRow({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(10)),
        child: Row(
          children: [
            SizedBox(width: context.gapSmall),
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: selected ? AppColors.AppBlue : Colors.grey.shade400,
            ),
            SizedBox(width: context.gapSmall),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: context.bodyMedium, color: AppColors.navy, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCategory {
  final String label;
  final GlobalKey key;
  const _FilterCategory(this.label, this.key);
}
