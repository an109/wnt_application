// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../../UI_helper/responsive_layout.dart';
//
// import '../../../domain/entities/meal_option_entity.dart';
// import '../../../domain/entities/ssr_entity.dart';
// import '../../bloc/ssr_bloc.dart';
// import '../../bloc/ssr_event.dart';
// import '../../bloc/ssr_state.dart';
//
//
// class MealScreen extends StatefulWidget {
//   final String traceId;
//   final String tokenId;
//   final String resultIndex;
//   final int? selectedSegmentIndex;
//   final Function(List<MealOptionEntity>?, int)? onMealSelected;
//
//   const MealScreen({
//     super.key,
//     required this.traceId,
//     required this.tokenId,
//     required this.resultIndex,
//     this.selectedSegmentIndex,
//     this.onMealSelected,
//   });
//
//   @override
//   State<MealScreen> createState() => _MealScreenState();
// }
//
// class _MealScreenState extends State<MealScreen> {
//   int _currentSegmentIndex = 0;
//   int? _selectedMealIndex;
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<SsrBloc, SsrState>(
//       listener: (context, state) {
//         if (state is SsrError) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(state.message),
//               backgroundColor: Colors.red.shade400,
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         }
//       },
//       builder: (context, state) {
//         if (state is SsrLoading) {
//           return _buildLoadingState();
//         }
//
//         if (state is SsrError) {
//           return _buildErrorState(state.message);
//         }
//
//         if (state is SsrLoaded) {
//           return _buildMealContent(state.ssrData);
//         }
//
//         return _buildEmptyState();
//       },
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(
//             width: context.iconLarge,
//             height: context.iconLarge,
//             child: CircularProgressIndicator(
//               strokeWidth: 3,
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
//             ),
//           ),
//           SizedBox(height: context.gapMedium),
//           Text(
//             'Loading meal options...',
//             style: TextStyle(
//               fontSize: context.bodyMedium,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorState(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(context.gapLarge / 2),
//             decoration: BoxDecoration(
//               color: Colors.red.shade50,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.restaurant_outlined,
//               size: context.iconLarge,
//               color: Colors.red.shade400,
//             ),
//           ),
//           SizedBox(height: context.gapMedium),
//           Text(
//             'Unable to load meal options',
//             style: TextStyle(
//               fontSize: context.titleMedium,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: context.gapSmall),
//           Padding(
//             padding: context.horizontalPadding,
//             child: Text(
//               message,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: context.bodySmall,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ),
//           SizedBox(height: context.gapLarge),
//           ElevatedButton(
//             onPressed: () {
//               context.read<SsrBloc>().add(
//                 LoadSsrData(
//                   endUserIp: '122.161.72.69',
//                   traceId: widget.traceId,
//                   tokenId: widget.tokenId,
//                   resultIndex: widget.resultIndex,
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//               foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(
//                 horizontal: context.buttonWidth * 0.3,
//                 vertical: context.gapMedium / 2,
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(context.borderRadius),
//               ),
//             ),
//             child: Text(
//               'Retry',
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(context.gapLarge / 2),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.restaurant_outlined,
//               size: context.iconLarge,
//               color: Colors.grey.shade400,
//             ),
//           ),
//           SizedBox(height: context.gapMedium),
//           Text(
//             'No meal options available',
//             style: TextStyle(
//               fontSize: context.titleMedium,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           SizedBox(height: context.gapSmall),
//           Text(
//             'Meal preferences will appear here once available',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: context.bodySmall,
//               color: Colors.grey.shade500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMealContent(SsrEntity ssrData) {
//     final mealSegments = ssrData.mealOptions;
//
//     if (mealSegments == null || mealSegments.isEmpty) {
//       return _buildEmptyState();
//     }
//
//     final currentSegmentIndex = widget.selectedSegmentIndex ?? _currentSegmentIndex;
//     final segmentMeals = currentSegmentIndex < mealSegments.length
//         ? mealSegments[currentSegmentIndex]
//         : <MealOptionEntity>[];
//
//     return Column(
//       children: [
//         // Flight info card
//         if (segmentMeals.isNotEmpty)
//           _buildFlightInfoCard(segmentMeals.first),
//
//         // Segment selector (if multiple segments)
//         if (mealSegments.length > 1)
//           _buildSegmentSelector(mealSegments.length),
//
//         // Meal options list
//         Expanded(
//           child: segmentMeals.isEmpty
//               ? _buildEmptyState()
//               : ListView.builder(
//             padding: EdgeInsets.symmetric(
//               horizontal: context.gapMedium,
//               vertical: context.gapSmall,
//             ),
//             itemCount: segmentMeals.length,
//             itemBuilder: (context, index) {
//               final option = segmentMeals[index];
//               final isSelected = _selectedMealIndex == index;
//
//               return _buildMealOptionCard(
//                 context,
//                 option: option,
//                 isSelected: isSelected,
//                 onTap: () => _handleMealSelection(index, option),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFlightInfoCard(MealOptionEntity firstOption) {
//     return Container(
//       margin: EdgeInsets.fromLTRB(
//         context.gapMedium,
//         context.gapMedium,
//         context.gapMedium,
//         0,
//       ),
//       padding: EdgeInsets.all(context.w(12)),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(context.borderRadius),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 12,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Airline logo
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: Colors.orange.shade50,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Center(
//               child: Text(
//                 firstOption.airlineCode,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: context.titleSmall,
//                   color: Colors.orange.shade700,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(width: context.gapMedium),
//
//           // Flight details
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '${_getAirlineName(firstOption.airlineCode)} · ${firstOption.flightNumber}',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: context.bodyLarge,
//                   ),
//                 ),
//                 SizedBox(height: context.gapSmall / 2),
//                 Text(
//                   '${firstOption.origin} → ${firstOption.destination}',
//                   style: TextStyle(
//                     color: Colors.grey.shade600,
//                     fontSize: context.bodySmall,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Meal badge
//           Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: context.gapSmall,
//               vertical: context.gapSmall / 2,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.blue.shade50,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               'Meal Service',
//               style: TextStyle(
//                 color: Colors.blue.shade700,
//                 fontSize: context.labelSmall,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSegmentSelector(int segmentCount) {
//     return Container(
//       margin: EdgeInsets.only(top: context.gapMedium),
//       padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
//       child: SizedBox(
//         height: 40,
//         child: ListView.separated(
//           scrollDirection: Axis.horizontal,
//           itemCount: segmentCount,
//           separatorBuilder: (context, index) => SizedBox(width: context.gapSmall),
//           itemBuilder: (context, index) {
//             final isSelected = index == (widget.selectedSegmentIndex ?? _currentSegmentIndex);
//
//             return GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _currentSegmentIndex = index;
//                   _selectedMealIndex = null;
//                 });
//               },
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: context.gapMedium,
//                   vertical: context.gapSmall,
//                 ),
//                 decoration: BoxDecoration(
//                   color: isSelected ? Colors.orange : Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: isSelected ? Colors.orange : Colors.grey.shade300,
//                     width: isSelected ? 0 : 1,
//                   ),
//                   boxShadow: isSelected
//                       ? [
//                     BoxShadow(
//                       color: Colors.orange.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: Offset(0, 2),
//                     ),
//                   ]
//                       : null,
//                 ),
//                 child: Center(
//                   child: Text(
//                     'Segment ${index + 1}',
//                     style: TextStyle(
//                       fontSize: context.labelMedium,
//                       fontWeight: FontWeight.w600,
//                       color: isSelected ? Colors.white : Colors.grey.shade700,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMealOptionCard(
//       BuildContext context, {
//         required MealOptionEntity option,
//         required bool isSelected,
//         required VoidCallback onTap,
//       }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: context.gapMedium),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(context.borderRadius),
//           child: Container(
//             padding: EdgeInsets.all(context.w(12)),
//             decoration: BoxDecoration(
//               color: isSelected ? Colors.orange.shade50 : Colors.white,
//               borderRadius: BorderRadius.circular(context.borderRadius),
//               border: Border.all(
//                 color: isSelected ? Colors.orange.shade400 : Colors.grey.shade200,
//                 width: isSelected ? 1.5 : 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.03),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 // Selection indicator
//                 Container(
//                   width: 22,
//                   height: 22,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: isSelected ? Colors.orange.shade600 : Colors.grey.shade400,
//                       width: 1.5,
//                     ),
//                   ),
//                   child: isSelected
//                       ? Center(
//                     child: Container(
//                       width: 12,
//                       height: 12,
//                       decoration: const BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.orange,
//                       ),
//                     ),
//                   )
//                       : null,
//                 ),
//                 SizedBox(width: context.gapMedium),
//
//                 // Icon with colored background
//                 Container(
//                   padding: EdgeInsets.all(context.gapSmall),
//                   decoration: BoxDecoration(
//                     color: option.iconBgColor,
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: Icon(
//                     option.mealIcon,
//                     color: option.iconColor,
//                     size: 26,
//                   ),
//                 ),
//                 SizedBox(width: context.gapMedium),
//
//                 // Details
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         option.displayTitle,
//                         style: TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: context.bodyLarge,
//                         ),
//                       ),
//                       SizedBox(height: context.gapSmall / 2),
//                       if (option.displaySubtitle.isNotEmpty)
//                         Text(
//                           option.displaySubtitle,
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: context.bodySmall,
//                           ),
//                         ),
//                       if (option.quantity > 0 && !option.isNoMeal)
//                         Padding(
//                           padding: EdgeInsets.only(top: context.gapSmall / 2),
//                           child: Text(
//                             'Quantity: ${option.quantity}',
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: context.bodySmall,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//
//                 // Price
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       option.displayPrice,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: context.bodyLarge,
//                         color: option.isFree
//                             ? Colors.green.shade700
//                             : Colors.black87,
//                       ),
//                     ),
//                     if (!option.isFree && option.quantity > 0)
//                       Padding(
//                         padding: EdgeInsets.only(top: context.gapSmall / 2),
//                         child: Text(
//                           '${option.currency} ${(option.price / option.quantity).toStringAsFixed(2)}/item',
//                           style: TextStyle(
//                             color: Colors.grey.shade500,
//                             fontSize: context.labelSmall,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _handleMealSelection(int index, MealOptionEntity option) {
//     setState(() {
//       _selectedMealIndex = index;
//     });
//
//     final segmentMeals = _getCurrentSegmentMeals();
//     widget.onMealSelected?.call(segmentMeals, index);
//
//     print('Meal selected: ${option.code} - ${option.displayTitle}');
//   }
//
//   List<MealOptionEntity>? _getCurrentSegmentMeals() {
//     final state = context.read<SsrBloc>().state;
//     if (state is SsrLoaded) {
//       final meals = state.ssrData.mealOptions;
//       if (meals != null && meals.isNotEmpty) {
//         final segmentIndex = widget.selectedSegmentIndex ?? _currentSegmentIndex;
//         if (segmentIndex < meals.length) {
//           return meals[segmentIndex];
//         }
//       }
//     }
//     return null;
//   }
//
//   String _getAirlineName(String code) {
//     final airlines = {
//       'SG': 'SpiceJet',
//       'AI': 'Air India',
//       '6E': 'IndiGo',
//       'UK': 'Vistara',
//       'I5': 'AirAsia',
//     };
//     return airlines[code] ?? code;
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../UI_helper/responsive_layout.dart';
import '../../../../../core/resources/app_colours.dart';
import '../../../domain/entities/meal_option_entity.dart';
import '../../../domain/entities/ssr_entity.dart';
import '../../bloc/ssr_bloc.dart';
import '../../bloc/ssr_event.dart';
import '../../bloc/ssr_state.dart';
import 'ssr_price_formatter.dart';

class MealScreen extends StatefulWidget {
  final String traceId;
  final String tokenId;
  final String resultIndex;
  final int? selectedSegmentIndex;
  final Function(List<MealOptionEntity>?, int?)? onMealSelected;

  const MealScreen({
    super.key,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
    this.selectedSegmentIndex,
    this.onMealSelected,
  });

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  int _currentSegmentIndex = 0;
  String? _selectedMealCode;
  int? _selectedMealIndex;

  // Figma veg/non-veg filter — a plain client-side filter over the same
  // list the bloc already loaded; doesn't touch selection semantics.
  bool? _vegOnly; // null = both

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SsrBloc, SsrState>(
      listener: (context, state) {
        if (state is SsrError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SsrLoading) {
          return _buildLoadingState();
        }

        if (state is SsrError) {
          return _buildErrorState(state.message);
        }

        if (state is SsrLoaded) {
          return _buildMealContent(state.ssrData);
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: context.iconLarge,
            height: context.iconLarge,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'Loading meal options...',
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.gapLarge / 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_outlined,
              size: context.iconLarge,
              color: Colors.red.shade400,
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'Unable to load meal options',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Padding(
            padding: context.horizontalPadding,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: context.gapLarge),
          ElevatedButton(
            onPressed: () {
              context.read<SsrBloc>().add(
                LoadSsrData(
                  endUserIp: '122.161.72.69',
                  traceId: widget.traceId,
                  tokenId: widget.tokenId,
                  resultIndex: widget.resultIndex,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: context.buttonWidth * 0.3,
                vertical: context.gapMedium / 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadius),
              ),
            ),
            child: Text(
              'Retry',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.gapLarge / 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_outlined,
              size: context.iconLarge,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: context.gapMedium),
          Text(
            'No meal options available',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'Meal preferences will appear here once available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealContent(SsrEntity ssrData) {
    final mealSegments = ssrData.mealOptions;

    if (mealSegments == null || mealSegments.isEmpty) {
      return _buildEmptyState();
    }

    final currentSegmentIndex =
        widget.selectedSegmentIndex ?? _currentSegmentIndex;

    if (currentSegmentIndex >= mealSegments.length) {
      return _buildEmptyState();
    }

    final segmentMeals = mealSegments[currentSegmentIndex];

    // Filter out "NoMeal" option for better UX
    final availableMeals = segmentMeals
        .where((m) => m.code != 'NoMeal')
        .toList();

    if (availableMeals.isEmpty) {
      return _buildEmptyState();
    }

    // Figma veg/non-veg filter — purely a display filter over the same
    // `availableMeals` list; onTap below still indexes into the unfiltered
    // list so the selection callback's contract doesn't change.
    final displayedMeals = _vegOnly == null
        ? availableMeals
        : availableMeals.where((m) => m.isVegetarian == _vegOnly).toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Segment selector (if multiple segments)
          if (mealSegments.length > 1) _buildSegmentSelector(mealSegments.length),

          Padding(
            padding: EdgeInsets.fromLTRB(context.w(16), context.h(16), context.w(16), 0),
            child: _vegFilterRow(context),
          ),

          // Meal options list
          Expanded(
            child: displayedMeals.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.all(context.w(16)),
                    itemCount: displayedMeals.length,
                    separatorBuilder: (_, __) => SizedBox(height: context.h(12)),
                    itemBuilder: (context, i) {
                      final option = displayedMeals[i];
                      final originalIndex = availableMeals.indexOf(option);
                      final isSelected = _selectedMealCode == option.code;

                      return _buildMealOptionCard(
                        context,
                        option: option,
                        isSelected: isSelected,
                        onTap: () => _handleMealSelection(originalIndex, option),
                      );
                    },
                  ),
          ),

          _selectionSummary(context, availableMeals.length),
        ],
      ),
    );
  }

  Widget _vegFilterRow(BuildContext context) {
    Widget chip(String label, Color dot, bool? value) {
      final selected = _vegOnly == value;
      return GestureDetector(
        onTap: () => setState(() => _vegOnly = selected ? null : value),
        child: Container(
          margin: EdgeInsets.only(right: context.w(12)),
          padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(4)),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? dot : const Color(0xFFCCCCCC)),
            borderRadius: BorderRadius.circular(context.r(4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.w(8),
                height: context.w(8),
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle, border: Border.all(color: dot)),
              ),
              SizedBox(width: context.w(4)),
              Text(label, style: TextStyle(color: AppColors.subhead, fontSize: context.fs(12))),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Veg', const Color(0xFF34C759), true),
        chip('Non Veg', const Color(0xFFFF383C), false),
      ],
    );
  }

  /// Figma's sticky "N meal(s) selected / ₹price · Added to fare" strip —
  /// purely derived from the already-selected state above.
  Widget _selectionSummary(BuildContext context, int totalAvailable) {
    final selected = _selectedMealCode != null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(6)),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFCCCCCC), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            selected ? '1 meal(s) Selected' : 'No meal selected',
            style: TextStyle(color: const Color(0xFF111527), fontSize: context.fs(12), fontWeight: FontWeight.w500),
          ),
          if (selected)
            Text(
              SsrPriceFormatter.format(
                availableMealByCode(_selectedMealCode)?.price ?? 0,
                availableMealByCode(_selectedMealCode)?.currency ?? '',
              ),
              style: TextStyle(color: const Color(0xFF111527), fontSize: context.fs(12), fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  MealOptionEntity? availableMealByCode(String? code) {
    if (code == null) return null;
    final state = context.read<SsrBloc>().state;
    if (state is! SsrLoaded) return null;
    final meals = state.ssrData.mealOptions;
    if (meals == null) return null;
    for (final segment in meals) {
      for (final m in segment) {
        if (m.code == code) return m;
      }
    }
    return null;
  }

  Widget _buildSegmentSelector(int segmentCount) {
    return Container(
      margin: EdgeInsets.only(top: context.gapMedium),
      padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: segmentCount,
          separatorBuilder: (context, index) =>
              SizedBox(width: context.gapSmall),
          itemBuilder: (context, index) {
            final isSelected =
                index == (widget.selectedSegmentIndex ?? _currentSegmentIndex);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentSegmentIndex = index;
                  _selectedMealCode = null;
                  _selectedMealIndex = null;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.gapMedium,
                  vertical: context.gapSmall,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                    width: isSelected ? 0 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Flight ${index + 1}',
                    style: TextStyle(
                      fontSize: context.labelMedium,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Figma "Flighjt meals": a horizontal card — image, veg/non-veg dot +
  // description, price/person, and a +/- stepper. The underlying selection
  // is still single-select (one meal per segment, same as before this
  // redesign) — the stepper only ever shows 0 or 1, "+" selects this meal
  // (deselecting whichever one was selected before) and "-" clears it.
  Widget _buildMealOptionCard(
    BuildContext context, {
    required MealOptionEntity option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5),
      ),
      padding: EdgeInsets.all(context.w(12.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(12)),
            child: SizedBox(
              width: context.w(102),
              height: context.h(101),
              child: Image.network(
                _getMealImageUrl(option.code),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _getMealColor(option.code),
                  child: Icon(option.mealIcon, size: context.iconLarge, color: Colors.white),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: _getMealColor(option.code).withValues(alpha: 0.2),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.w(14),
                      height: context.w(14),
                      margin: EdgeInsets.only(top: context.h(2)),
                      padding: EdgeInsets.all(context.w(3)),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: option.isNoMeal
                              ? AppColors.subhead
                              : (option.isVegetarian ? const Color(0xFF16A34A) : const Color(0xFFFF383C)),
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: option.isNoMeal
                              ? AppColors.subhead
                              : (option.isVegetarian ? const Color(0xFF16A34A) : const Color(0xFFFF383C)),
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    Expanded(
                      child: Text(
                        option.displaySubtitle.isNotEmpty ? option.displaySubtitle : option.displayTitle,
                        style: TextStyle(color: AppColors.subhead, fontSize: context.fs(12)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: SsrPriceFormatter.format(option.price, option.currency),
                            style: TextStyle(
                              color: const Color(0xFF111527),
                              fontWeight: FontWeight.w700,
                              fontSize: context.fs(14),
                            ),
                          ),
                          if (!option.isFree)
                            TextSpan(
                              text: '/person',
                              style: TextStyle(color: AppColors.subhead, fontSize: context.fs(10)),
                            ),
                        ],
                      ),
                    ),
                    _mealStepper(context, isSelected: isSelected, onTap: onTap),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealStepper(BuildContext context, {required bool isSelected, required VoidCallback onTap}) {
    Widget stepperButton(IconData icon, VoidCallback? onPressed) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(8)),
            child: Icon(icon, size: context.w(14), color: onPressed == null ? const Color(0xFFCCCCCC) : AppColors.AppBlue),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          stepperButton(Icons.remove, isSelected ? onTap : null),
          SizedBox(
            width: context.w(20),
            child: Text(
              isSelected ? '1' : '0',
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFF111527), fontSize: context.fs(14), fontWeight: FontWeight.w600),
            ),
          ),
          stepperButton(Icons.add, isSelected ? null : onTap),
        ],
      ),
    );
  }

  void _handleMealSelection(int index, MealOptionEntity option) {
    setState(() {
      if (_selectedMealCode == option.code) {
        _selectedMealCode = null;
        _selectedMealIndex = null;
      } else {
        _selectedMealCode = option.code;
        _selectedMealIndex = index;
      }
    });

    final segmentMeals = _getCurrentSegmentMeals();
    widget.onMealSelected?.call(segmentMeals, _selectedMealIndex);

    print('Meal selected: ${option.code} - ${option.displayTitle}');
  }

  List<MealOptionEntity>? _getCurrentSegmentMeals() {
    final state = context.read<SsrBloc>().state;
    if (state is SsrLoaded) {
      final meals = state.ssrData.mealOptions;
      if (meals != null && meals.isNotEmpty) {
        final segmentIndex =
            widget.selectedSegmentIndex ?? _currentSegmentIndex;
        if (segmentIndex < meals.length) {
          return meals[segmentIndex];
        }
      }
    }
    return null;
  }

  // Helper methods for meal images
  Color _getMealColor(String code) {
    if (code.contains('VGML') || code.contains('VLML'))
      return Colors.green.shade400;
    if (code.contains('DBML')) return Colors.teal.shade400;
    if (code.contains('HNML')) return Colors.orange.shade400;
    if (code.contains('KSML')) return Colors.purple.shade400;
    if (code.contains('MOML')) return Colors.brown.shade400;
    if (code.contains('SFML')) return Colors.blue.shade400;
    if (code.contains('CHML')) return Colors.pink.shade400;
    if (code.contains('BBML')) return Colors.indigo.shade400;
    return Colors.orange.shade400;
  }

  String _getMealImageUrl(String code) {
    // Using placeholder images from placeholder service
    // You can replace this with actual image URLs from your API
    return 'https://picsum.photos/seed/$code/200/200';
  }
}
