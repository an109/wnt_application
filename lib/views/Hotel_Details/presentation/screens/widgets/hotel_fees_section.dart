import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../domain/entities/hotel_details_entity.dart';

class HotelFeesWidget extends StatefulWidget {
  final HotelFeesEntity hotelFees;

  const HotelFeesWidget({
    super.key,
    required this.hotelFees,
  });

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hotel Fees & Add-ons',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Optional extras can be added to your total before checkout.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'OPTIONAL ADD-ONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.hotelFees.optional.map((fee) => _buildAddOnItem(fee)),
        ],
      ),
    );
  }

  Widget _buildAddOnItem(HotelFeeEntity fee) {
    final isSelected = _selectedAddOns[fee.feesType] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
              print('HotelFeesWidget: Add-on ${fee.feesType}');
              setState(() {
                _selectedAddOns[fee.feesType] = value ?? false;
              });
            },
            activeColor: Colors.amber.shade700,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feesType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${fee.chargeType} | ${fee.feesCategory}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${fee.feesValue.toLocaleString()}',
            style: TextStyle(
              fontSize: 16,
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