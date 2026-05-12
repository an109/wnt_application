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
//                   endUserIp: '::1',
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
//       padding: EdgeInsets.all(context.gapMedium),
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
//             padding: EdgeInsets.all(context.gapMedium),
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
import '../../../domain/entities/meal_option_entity.dart';
import '../../../domain/entities/ssr_entity.dart';
import '../../bloc/ssr_bloc.dart';
import '../../bloc/ssr_event.dart';
import '../../bloc/ssr_state.dart';

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
                  endUserIp: '::1',
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

    final currentSegmentIndex = widget.selectedSegmentIndex ?? _currentSegmentIndex;

    if (currentSegmentIndex >= mealSegments.length) {
      return _buildEmptyState();
    }

    final segmentMeals = mealSegments[currentSegmentIndex];

    // Filter out "NoMeal" option for better UX
    final availableMeals = segmentMeals.where((m) => m.code != 'NoMeal').toList();

    if (availableMeals.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Flight info card
        if (availableMeals.isNotEmpty)
          _buildFlightInfoCard(availableMeals.first),

        // Segment selector (if multiple segments)
        if (mealSegments.length > 1)
          _buildSegmentSelector(mealSegments.length),

        // Meal options list
        Expanded(
          child: availableMeals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: EdgeInsets.all(context.gapMedium),
            itemCount: availableMeals.length,
            itemBuilder: (context, index) {
              final option = availableMeals[index];
              final isSelected = _selectedMealCode == option.code;

              return _buildMealOptionCard(
                context,
                option: option,
                isSelected: isSelected,
                onTap: () => _handleMealSelection(index, option),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlightInfoCard(MealOptionEntity firstOption) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        context.gapMedium,
        context.gapMedium,
        context.gapMedium,
        0,
      ),
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Airline logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                firstOption.airlineCode,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.titleSmall,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ),
          SizedBox(width: context.gapMedium),

          // Flight details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getAirlineName(firstOption.airlineCode)} · ${firstOption.flightNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.bodyLarge,
                  ),
                ),
                SizedBox(height: context.gapSmall / 2),
                Text(
                  '${firstOption.origin} → ${firstOption.destination}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: context.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // Meal badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapSmall,
              vertical: context.gapSmall / 2,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Meal Service',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: context.labelSmall,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
          separatorBuilder: (context, index) => SizedBox(width: context.gapSmall),
          itemBuilder: (context, index) {
            final isSelected = index == (widget.selectedSegmentIndex ?? _currentSegmentIndex);

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
                      color: Colors.orange.withOpacity(0.3),
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

  Widget _buildMealOptionCard(
      BuildContext context, {
        required MealOptionEntity option,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Container(
            padding: EdgeInsets.all(context.gapMedium),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(context.borderRadius),
              border: Border.all(
                color: isSelected ? Colors.orange.shade400 : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Placeholder Image
                Container(
                  width: context.wp(20),
                  height: context.wp(20),
                  decoration: BoxDecoration(
                    color: _getMealColor(option.code),
                    borderRadius: BorderRadius.circular(context.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: _getMealColor(option.code).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(context.borderRadius),
                    child: Image.network(
                      _getMealImageUrl(option.code),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: _getMealColor(option.code),
                          child: Icon(
                            option.mealIcon,
                            size: context.iconLarge,
                            color: Colors.white,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: context.gapMedium),

                // Meal Details (Name and Caption)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.displayTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: context.bodyLarge,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: context.gapSmall / 2),
                      Text(
                        option.displaySubtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: context.bodySmall,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (option.quantity > 0 && !option.isNoMeal)
                        Padding(
                          padding: EdgeInsets.only(top: context.gapSmall / 2),
                          child: Text(
                            'Quantity: ${option.quantity}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: context.bodySmall,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Price and Selection Indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      option.displayPrice,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.bodyLarge,
                        color: option.isFree
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    if (!option.isFree && option.quantity > 0)
                      Padding(
                        padding: EdgeInsets.only(top: context.gapSmall / 2),
                        child: Text(
                          '${option.currency} ${(option.price / option.quantity).toStringAsFixed(2)}/item',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: context.labelSmall,
                          ),
                        ),
                      ),
                    if (isSelected)
                      Padding(
                        padding: EdgeInsets.only(top: context.gapSmall / 2),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.gapSmall,
                            vertical: context.gapSmall / 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: context.iconSmall,
                                color: Colors.green.shade700,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Selected',
                                style: TextStyle(
                                  fontSize: context.labelSmall,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        final segmentIndex = widget.selectedSegmentIndex ?? _currentSegmentIndex;
        if (segmentIndex < meals.length) {
          return meals[segmentIndex];
        }
      }
    }
    return null;
  }

  String _getAirlineName(String code) {
    final airlines = {
      'SG': 'SpiceJet',
      'AI': 'Air India',
      '6E': 'IndiGo',
      'UK': 'Vistara',
      'I5': 'AirAsia',
    };
    return airlines[code] ?? code;
  }

  // Helper methods for meal images
  Color _getMealColor(String code) {
    if (code.contains('VGML') || code.contains('VLML')) return Colors.green.shade400;
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