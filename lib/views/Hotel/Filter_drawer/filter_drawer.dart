import 'package:flutter/material.dart';
import '../../../UI_helper/responsive_layout.dart';

class HotelFilterDrawer extends StatefulWidget {
  final Function(Map<String, dynamic>)? onFiltersApplied;
  final VoidCallback? onClearFilters;
  final bool isFilterApplied;

  const HotelFilterDrawer({
    super.key,
    this.onFiltersApplied,
    this.onClearFilters,
    this.isFilterApplied = false,
  });

  @override
  State<HotelFilterDrawer> createState() => _HotelFilterDrawerState();
}

class _HotelFilterDrawerState extends State<HotelFilterDrawer> {
  Map<String, dynamic> _filters = {};

  // Filter states
  double _minPrice = 0;
  double _maxPrice = 100000;
  int? _selectedStarRating;
  List<String> _selectedAmenities = [];
  String? _selectedMealPlan;
  bool _refundableOnly = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          /// HEADER
          Container(
            padding: EdgeInsets.only(
              top: context.statusBarHeight + context.gapMedium,
              left: context.gapMedium,
              right: context.gapMedium,
              bottom: context.gapMedium,
            ),
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: context.gapSmall),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: context.titleLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (widget.isFilterApplied)
                  TextButton(
                    onPressed: () {
                      widget.onClearFilters?.call();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.9),
                        fontSize: context.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          /// FILTER CONTENT
          Expanded(
            child: ListView(
              padding: context.horizontalPadding.copyWith(
                top: context.gapMedium,
                bottom: context.gapLarge,
              ),
              children: [
                /// PRICE RANGE
                _buildFilterSection(
                  title: 'Price Range',
                  child: _buildPriceRangeFilter(),
                ),

                /// STAR RATING
                _buildFilterSection(
                  title: 'Star Rating',
                  child: _buildStarRatingFilter(),
                ),

                /// REFUNDABLE
                _buildFilterSection(
                  title: 'Booking Type',
                  child: _buildRefundableFilter(),
                ),

                /// MEAL PLANS
                _buildFilterSection(
                  title: 'Meal Plans',
                  child: _buildMealPlanFilter(),
                ),

                /// AMENITIES
                _buildFilterSection(
                  title: 'Amenities',
                  child: _buildAmenitiesFilter(),
                ),
              ],
            ),
          ),

          /// APPLY BUTTON
          Container(
            padding: context.horizontalPadding.copyWith(
              top: context.gapSmall,
              bottom: context.gapLarge + context.bottomBarHeight,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: context.buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius),
                  ),
                ),
                onPressed: _applyFilters,
                child: Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.gapMedium),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Container(
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(context.borderRadius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Min: \$${_minPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Max: \$${_maxPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 100000,
            divisions: 100,
            labels: RangeLabels(
              '\$${_minPrice.toStringAsFixed(0)}',
              '\$${_maxPrice.toStringAsFixed(0)}',
            ),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStarRatingFilter() {
    return Wrap(
      spacing: context.gapSmall,
      children: List.generate(5, (index) {
        final starCount = index + 1;
        final isSelected = _selectedStarRating == starCount;

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$starCount',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.star,
                size: context.iconSmall,
                color: isSelected ? Colors.white : Colors.amber,
              ),
            ],
          ),
          selected: isSelected,
          selectedColor: Theme.of(context).primaryColor,
          onSelected: (selected) {
            setState(() {
              _selectedStarRating = selected ? starCount : null;
            });
          },
        );
      }),
    );
  }

  Widget _buildRefundableFilter() {
    return Container(
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(context.borderRadius),
      ),
      child: SwitchListTile(
        title: Text(
          'Refundable Only',
          style: TextStyle(fontSize: context.bodyMedium),
        ),
        subtitle: Text(
          'Show only refundable bookings',
          style: TextStyle(
            fontSize: context.bodySmall,
            color: Colors.grey.shade600,
          ),
        ),
        value: _refundableOnly,
        onChanged: (value) {
          setState(() {
            _refundableOnly = value;
          });
        },
        contentPadding: EdgeInsets.zero,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMealPlanFilter() {
    final mealPlans = [
      {'value': 'Room_Only', 'label': 'Room Only'},
      {'value': 'Breakfast', 'label': 'Breakfast Included'},
      {'value': 'Half_Board', 'label': 'Half Board'},
      {'value': 'Full_Board', 'label': 'Full Board'},
      {'value': 'All', 'label': 'All Meals'},
    ];

    return Column(
      children: mealPlans.map((plan) {
        final value = plan['value'] as String;
        final label = plan['label'] as String;
        final isSelected = _selectedMealPlan == value;

        return Padding(
          padding: EdgeInsets.only(bottom: context.gapSmall / 2),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedMealPlan = isSelected ? null : value;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(context.gapMedium),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    size: context.iconMedium,
                  ),
                  SizedBox(width: context.gapSmall),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmenitiesFilter() {
    final amenities = [
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

    return Wrap(
      spacing: context.gapSmall,
      runSpacing: context.gapSmall,
      children: amenities.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity);

        return FilterChip(
          label: Text(
            amenity,
            style: TextStyle(
              fontSize: context.bodySmall,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedAmenities.add(amenity);
              } else {
                _selectedAmenities.remove(amenity);
              }
            });
          },
        );
      }).toList(),
    );
  }

  void _applyFilters() {
    // Build filters map
    final filters = <String, dynamic>{};

    if (_minPrice > 0 || _maxPrice < 100000) {
      filters['minPrice'] = _minPrice;
      filters['maxPrice'] = _maxPrice;
    }

    if (_selectedStarRating != null) {
      filters['starRating'] = _selectedStarRating;
    }

    if (_refundableOnly) {
      filters['refundable'] = true;
    }

    if (_selectedMealPlan != null && _selectedMealPlan != 'Room_Only') {
      filters['mealType'] = _selectedMealPlan;
    }

    if (_selectedAmenities.isNotEmpty) {
      filters['amenities'] = _selectedAmenities;
    }

    // Call the callback
    widget.onFiltersApplied?.call(filters);

    // Close drawer
    Navigator.pop(context);
  }
}