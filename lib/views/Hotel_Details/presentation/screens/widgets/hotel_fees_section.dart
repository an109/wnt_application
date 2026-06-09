// import 'package:flutter/material.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
// import '../../../domain/entities/hotel_details_entity.dart';
//
// class HotelFeesWidget extends StatefulWidget {
//   final HotelFeesEntity hotelFees;
//
//   const HotelFeesWidget({
//     super.key,
//     required this.hotelFees,
//   });
//
//   @override
//   State<HotelFeesWidget> createState() => _HotelFeesWidgetState();
// }
//
// class _HotelFeesWidgetState extends State<HotelFeesWidget> {
//   final Map<String, bool> _selectedAddOns = {};
//
//   @override
//   Widget build(BuildContext context) {
//     print('HotelFeesWidget: Building with ${widget.hotelFees.optional.length} optional fees');
//
//     return Container(
//       margin: context.responsivePadding,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.amber.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.amber.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 'Hotel Fees & Add-ons',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.amber.shade900,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Optional extras can be added to your total before checkout.',
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.amber.shade800,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'OPTIONAL ADD-ONS',
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ...widget.hotelFees.optional.map((fee) => _buildAddOnItem(fee)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAddOnItem(HotelFeeEntity fee) {
//     final isSelected = _selectedAddOns[fee.feesType] ?? false;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isSelected ? Colors.amber.shade400 : Colors.grey.shade200,
//           width: isSelected ? 2 : 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Checkbox(
//             value: isSelected,
//             onChanged: (value) {
//               print('HotelFeesWidget: Add-on ${fee.feesType}');
//               setState(() {
//                 _selectedAddOns[fee.feesType] = value ?? false;
//               });
//             },
//             activeColor: Colors.amber.shade700,
//           ),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   fee.feesType,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Text(
//                   '${fee.chargeType} | ${fee.feesCategory}',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             '${fee.feesValue.toLocaleString()}',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.amber.shade900,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// extension NumberFormattingExtension on num {
//   String toLocaleString() {
//     return toStringAsFixed(0).replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//           (Match m) => '${m[1]},',
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../../UI_helper/currency_converter.dart';
import '../../../../../core/utils/storage/shared_preference.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/hotel_details_entity.dart';

class HotelFeesWidget extends StatefulWidget {
  final HotelFeesEntity hotelFees;

  const HotelFeesWidget({super.key, required this.hotelFees});

  @override
  State<HotelFeesWidget> createState() => _HotelFeesWidgetState();
}

class _HotelFeesWidgetState extends State<HotelFeesWidget> {
  final Map<String, bool> _selectedAddOns = {};

  @override
  Widget build(BuildContext context) {
    print('HotelFeesWidget: Building with ${widget.hotelFees.optional.length} optional fees');

    return Container(
      margin: context.responsivePadding,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Colors.amber.shade700, size: context.w(18)),
              SizedBox(width: context.w(8)),
              Text(
                'Hotel Fees & Add-ons',
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(4)),
          Text(
            'Optional extras can be added to your total before checkout.',
            style: TextStyle(fontSize: context.fs(11), color: Colors.amber.shade800),
          ),
          SizedBox(height: context.h(16)),
          Text(
            'OPTIONAL ADD-ONS',
            style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700),
          ),
          SizedBox(height: context.h(12)),
          ...widget.hotelFees.optional.map((fee) => _buildAddOnItem(fee)),
        ],
      ),
    );
  }

  // 🔹 Convert & format using the FEE'S OWN currency
  String _formatFeePrice(num amount, String currency) {
    if (currency.isEmpty) return amount.toLocaleString(); // Safe fallback

    double finalAmount = amount.toDouble();
    String displayCurrency = currency;

    final prefs = sl<PreferencesManager>();
    final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';

    // Convert only if different from user preference
    if (currency.toUpperCase() != targetCurrency.toUpperCase()) {
      finalAmount = CurrencyConverter.convert(
        amount: amount.toDouble(),
        fromCurrency: currency,
        toCurrency: targetCurrency,
      );
      displayCurrency = targetCurrency;
    }

    // Display amount without any currency sign
    final code = displayCurrency.toUpperCase();
    final intAmount = finalAmount.toInt();

    if (code == 'INR') return _formatIndianNumber(intAmount);
    return intAmount.toStringAsFixed(0);
  }

  String _formatIndianNumber(int num) {
    if (num < 1000) return num.toString();
    final str = num.toString();
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    var formatted = '';
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) formatted += ',';
      formatted += remaining[i];
    }
    return '$formatted,$lastThree';
  }

  Widget _buildAddOnItem(HotelFeeEntity fee) {
    final isSelected = _selectedAddOns[fee.feesType] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(
          color: isSelected ? Colors.amber.shade400 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() => _selectedAddOns[fee.feesType] = value ?? false);
            },
            activeColor: Colors.amber.shade700,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feesType,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: context.fs(13)),
                ),
                Text(
                  '${fee.chargeType} | ${fee.feesCategory}',
                  style: TextStyle(
                      fontSize: context.fs(11), color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // 🔹 Uses fee.currency directly (from API: "Currency": "INR")
          Text(
            _formatFeePrice(fee.feesValue, fee.currency),
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

extension NumberFormattingExtension on num {
  String toLocaleString() {
    return toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}