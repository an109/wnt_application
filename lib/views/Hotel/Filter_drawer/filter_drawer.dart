// import 'package:flutter/material.dart';
// import '../../../UI_helper/responsive_layout.dart';
//
// class HotelFilterDrawer extends StatefulWidget {
//   final Function(Map<String, dynamic>)? onFiltersApplied;
//   final VoidCallback? onClearFilters;
//   final bool isFilterApplied;
//
//   const HotelFilterDrawer({
//     super.key,
//     this.onFiltersApplied,
//     this.onClearFilters,
//     this.isFilterApplied = false,
//   });
//
//   @override
//   State<HotelFilterDrawer> createState() => _HotelFilterDrawerState();
// }
//
// class _HotelFilterDrawerState extends State<HotelFilterDrawer> {
//   Map<String, dynamic> _filters = {};
//
//   // Filter states
//   double _minPrice = 0;
//   double _maxPrice = 100000;
//   int? _selectedStarRating;
//   List<String> _selectedAmenities = [];
//   String? _selectedMealPlan;
//   bool _refundableOnly = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: Column(
//         children: [
//           /// HEADER
//           Container(
//             padding: EdgeInsets.only(
//               top: context.statusBarHeight + context.gapMedium,
//               left: context.gapMedium,
//               right: context.gapMedium,
//               bottom: context.gapMedium,
//             ),
//             color: Theme.of(context).primaryColor,
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 SizedBox(width: context.gapSmall),
//                 Text(
//                   'Filters',
//                   style: TextStyle(
//                     fontSize: context.titleLarge,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const Spacer(),
//                 if (widget.isFilterApplied)
//                   TextButton(
//                     onPressed: () {
//                       widget.onClearFilters?.call();
//                       Navigator.pop(context);
//                     },
//                     child: Text(
//                       'Clear All',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(.9),
//                         fontSize: context.bodyMedium,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//
//           /// FILTER CONTENT
//           Expanded(
//             child: ListView(
//               padding: context.horizontalPadding.copyWith(
//                 top: context.gapMedium,
//                 bottom: context.gapLarge,
//               ),
//               children: [
//                 /// PRICE RANGE
//                 _buildFilterSection(
//                   title: 'Price Range',
//                   child: _buildPriceRangeFilter(),
//                 ),
//
//                 /// STAR RATING
//                 _buildFilterSection(
//                   title: 'Star Rating',
//                   child: _buildStarRatingFilter(),
//                 ),
//
//                 /// REFUNDABLE
//                 _buildFilterSection(
//                   title: 'Booking Type',
//                   child: _buildRefundableFilter(),
//                 ),
//
//                 /// MEAL PLANS
//                 _buildFilterSection(
//                   title: 'Meal Plans',
//                   child: _buildMealPlanFilter(),
//                 ),
//
//                 /// AMENITIES
//                 _buildFilterSection(
//                   title: 'Amenities',
//                   child: _buildAmenitiesFilter(),
//                 ),
//               ],
//             ),
//           ),
//
//           /// APPLY BUTTON
//           Container(
//             padding: context.horizontalPadding.copyWith(
//               top: context.gapSmall,
//               bottom: context.gapLarge + context.bottomBarHeight,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: SizedBox(
//               width: double.infinity,
//               height: context.buttonHeight,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).primaryColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(context.borderRadius),
//                   ),
//                 ),
//                 onPressed: _applyFilters,
//                 child: Text(
//                   'Apply Filters',
//                   style: TextStyle(
//                     fontSize: context.bodyLarge,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilterSection({required String title, required Widget child}) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: context.gapLarge),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: context.titleMedium,
//               fontWeight: FontWeight.w600,
//               color: Colors.black,
//             ),
//           ),
//           SizedBox(height: context.gapMedium),
//           child,
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPriceRangeFilter() {
//     return Container(
//       padding: EdgeInsets.all(context.w(12)),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade200),
//         borderRadius: BorderRadius.circular(context.borderRadius),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Min: ₹${_minPrice.toStringAsFixed(0)}',
//                   style: TextStyle(
//                     fontSize: context.bodyMedium,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: Text(
//                   'Max: ₹${_maxPrice.toStringAsFixed(0)}',
//                   style: TextStyle(
//                     fontSize: context.bodyMedium,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   textAlign: TextAlign.end,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: context.gapMedium),
//           RangeSlider(
//             values: RangeValues(_minPrice, _maxPrice),
//             min: 0,
//             max: 100000,
//             divisions: 100,
//             labels: RangeLabels(
//               '₹${_minPrice.toStringAsFixed(0)}',
//               '₹${_maxPrice.toStringAsFixed(0)}',
//             ),
//             onChanged: (values) {
//               setState(() {
//                 _minPrice = values.start;
//                 _maxPrice = values.end;
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStarRatingFilter() {
//     return Wrap(
//       spacing: context.gapSmall,
//       children: List.generate(5, (index) {
//         final starCount = index + 1;
//         final isSelected = _selectedStarRating == starCount;
//
//         return ChoiceChip(
//           label: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 '$starCount',
//                 style: TextStyle(
//                   fontSize: context.bodyMedium,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Icon(
//                 Icons.star,
//                 size: context.iconSmall,
//                 color: isSelected ? Colors.white : Colors.amber,
//               ),
//             ],
//           ),
//           selected: isSelected,
//           selectedColor: Theme.of(context).primaryColor,
//           onSelected: (selected) {
//             setState(() {
//               _selectedStarRating = selected ? starCount : null;
//             });
//           },
//         );
//       }),
//     );
//   }
//
//   Widget _buildRefundableFilter() {
//     return Container(
//       padding: EdgeInsets.all(context.w(12)),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade200),
//         borderRadius: BorderRadius.circular(context.borderRadius),
//       ),
//       child: SwitchListTile(
//         title: Text(
//           'Refundable Only',
//           style: TextStyle(fontSize: context.bodyMedium),
//         ),
//         subtitle: Text(
//           'Show only refundable bookings',
//           style: TextStyle(
//             fontSize: context.bodySmall,
//             color: Colors.grey.shade600,
//           ),
//         ),
//         value: _refundableOnly,
//         onChanged: (value) {
//           setState(() {
//             _refundableOnly = value;
//           });
//         },
//         contentPadding: EdgeInsets.zero,
//         activeColor: Theme.of(context).primaryColor,
//       ),
//     );
//   }
//
//   Widget _buildMealPlanFilter() {
//     final mealPlans = [
//       {'value': 'All', 'label': 'All Meals'},
//       {'value': 'Breakfast', 'label': 'Breakfast Included'},
//       {'value': 'HalfBoard', 'label': 'Half Board'},
//       {'value': 'FullBoard', 'label': 'Full Board'},
//       {'value': 'AllInclusive', 'label': 'All Inclusive'},
//       {'value': 'RoomOnly', 'label': 'Room Only'},
//     ];
//
//     return Column(
//       children: mealPlans.map((plan) {
//         final value = plan['value'] as String;
//         final label = plan['label'] as String;
//         final isSelected = _selectedMealPlan == value;
//
//         return Padding(
//           padding: EdgeInsets.only(bottom: context.gapSmall / 2),
//           child: InkWell(
//             onTap: () {
//               setState(() {
//                 _selectedMealPlan = isSelected ? null : value;
//               });
//             },
//             borderRadius: BorderRadius.circular(8),
//             child: Container(
//               padding: EdgeInsets.all(context.w(12)),
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: isSelected
//                       ? Theme.of(context).primaryColor
//                       : Colors.grey.shade300,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//                 color: isSelected
//                     ? Theme.of(context).primaryColor.withOpacity(0.1)
//                     : Colors.transparent,
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     isSelected
//                         ? Icons.check_circle
//                         : Icons.radio_button_unchecked,
//                     color: isSelected
//                         ? Theme.of(context).primaryColor
//                         : Colors.grey,
//                     size: context.iconMedium,
//                   ),
//                   SizedBox(width: context.gapSmall),
//                   Text(
//                     label,
//                     style: TextStyle(
//                       fontSize: context.bodyMedium,
//                       fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                       color: isSelected
//                           ? Theme.of(context).primaryColor
//                           : Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   Widget _buildAmenitiesFilter() {
//     final amenities = [
//       'WiFi',
//       'Pool',
//       'Gym',
//       'Parking',
//       'Spa',
//       'Restaurant',
//       'Airport Shuttle',
//       'Beach Access',
//       'Room Service',
//       'Air Conditioning',
//     ];
//
//     return Wrap(
//       spacing: context.gapSmall,
//       runSpacing: context.gapSmall,
//       children: amenities.map((amenity) {
//         final isSelected = _selectedAmenities.contains(amenity);
//
//         return FilterChip(
//           label: Text(
//             amenity,
//             style: TextStyle(
//               fontSize: context.bodySmall,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//             ),
//           ),
//           selected: isSelected,
//           selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
//           checkmarkColor: Theme.of(context).primaryColor,
//           onSelected: (selected) {
//             setState(() {
//               if (selected) {
//                 _selectedAmenities.add(amenity);
//               } else {
//                 _selectedAmenities.remove(amenity);
//               }
//             });
//           },
//         );
//       }).toList(),
//     );
//   }
//
//   void _applyFilters() {
//     final filters = <String, dynamic>{};
//
//     // TBO API filter fields — sent to backend and forwarded to TBO search
//     filters['Refundable'] = _refundableOnly;
//     filters['MealType'] = _selectedMealPlan ?? 'All';
//     filters['NoOfRooms'] = 0;
//
//     // Client-side filter fields — applied in Flutter after API response
//     if (_minPrice > 0) {
//       filters['min_price'] = _minPrice;
//     }
//     if (_maxPrice < 100000) {
//       filters['max_price'] = _maxPrice;
//     }
//     if (_selectedStarRating != null) {
//       filters['star_rating'] = _selectedStarRating;
//     }
//     if (_selectedAmenities.isNotEmpty) {
//       filters['amenities'] = _selectedAmenities;
//     }
//
//     widget.onFiltersApplied?.call(filters);
//     Navigator.pop(context);
//   }
// }

import 'package:flutter/material.dart';
import '../../../UI_helper/responsive_layout.dart';
import '../../../UI_helper/currency_converter.dart';

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

  // Currency states
  String _currentCurrency = 'INR';
  double _convertedMinPrice = 0;
  double _convertedMaxPrice = 100000;

  @override
  void initState() {
    super.initState();
    _currentCurrency = CurrencyConverter.getPreferredCurrency();
    // Convert the initial values
    _convertedMinPrice = CurrencyConverter.convert(
      amount: _minPrice,
      fromCurrency: 'INR',
      toCurrency: _currentCurrency,
    );
    _convertedMaxPrice = CurrencyConverter.convert(
      amount: _maxPrice,
      fromCurrency: 'INR',
      toCurrency: _currentCurrency,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  double _convertToINR(double amount) {
    if (_currentCurrency == 'INR') return amount;
    // Convert back to INR for storage/API
    return CurrencyConverter.convert(
      amount: amount,
      fromCurrency: _currentCurrency,
      toCurrency: 'INR',
    );
  }

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
    return ValueListenableBuilder<String>(
      valueListenable: CurrencyConverter.currencyListenable,
      builder: (context, currency, _) {
        if (_currentCurrency != currency) {
          // Currency changed, update conversions
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentCurrency = currency;
                _convertedMinPrice = CurrencyConverter.convert(
                  amount: _minPrice,
                  fromCurrency: 'INR',
                  toCurrency: _currentCurrency,
                );
                _convertedMaxPrice = CurrencyConverter.convert(
                  amount: _maxPrice,
                  fromCurrency: 'INR',
                  toCurrency: _currentCurrency,
                );
              });
            }
          });
        }

        final symbol = CurrencyConverter.getSymbol(_currentCurrency);

        return Container(
          padding: EdgeInsets.all(context.w(12)),
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
                      'Min: $symbol${_convertedMinPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Max: $symbol${_convertedMaxPrice.toStringAsFixed(0)}',
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
                values: RangeValues(_convertedMinPrice, _convertedMaxPrice),
                min: 0,
                max: _convertToINR(100000),
                divisions: 100,
                labels: RangeLabels(
                  '$symbol${_convertedMinPrice.toStringAsFixed(0)}',
                  '$symbol${_convertedMaxPrice.toStringAsFixed(0)}',
                ),
                onChanged: (values) {
                  setState(() {
                    _convertedMinPrice = values.start;
                    _convertedMaxPrice = values.end;
                    // Store in INR for API
                    _minPrice = _convertToINR(values.start);
                    _maxPrice = _convertToINR(values.end);
                  });
                },
              ),
            ],
          ),
        );
      },
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
      padding: EdgeInsets.all(context.w(12)),
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
      {'value': 'All', 'label': 'All Meals'},
      {'value': 'Breakfast', 'label': 'Breakfast Included'},
      {'value': 'HalfBoard', 'label': 'Half Board'},
      {'value': 'FullBoard', 'label': 'Full Board'},
      {'value': 'AllInclusive', 'label': 'All Inclusive'},
      {'value': 'RoomOnly', 'label': 'Room Only'},
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
              padding: EdgeInsets.all(context.w(12)),
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
    final filters = <String, dynamic>{};

    // TBO API filter fields — sent to backend and forwarded to TBO search
    filters['Refundable'] = _refundableOnly;
    filters['MealType'] = _selectedMealPlan ?? 'All';
    filters['NoOfRooms'] = 0;

    // Client-side filter fields — applied in Flutter after API response
    // Values are already stored in INR from the slider updates
    if (_minPrice > 0) {
      filters['min_price'] = _minPrice;
    }
    if (_maxPrice < 100000) {
      filters['max_price'] = _maxPrice;
    }
    if (_selectedStarRating != null) {
      filters['star_rating'] = _selectedStarRating;
    }
    if (_selectedAmenities.isNotEmpty) {
      filters['amenities'] = _selectedAmenities;
    }

    widget.onFiltersApplied?.call(filters);
    Navigator.pop(context);
  }
}