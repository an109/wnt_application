import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class TpollFiltersPanel extends StatelessWidget {
  final String? selectedVehicleType;
  final ValueChanged<String?> onVehicleTypeChanged;
  final List<String> vehicleTypes;

  const TpollFiltersPanel({
    super.key,
    required this.selectedVehicleType,
    required this.onVehicleTypeChanged,
    required this.vehicleTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(context.wp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VEHICLE TYPE',
                style: TextStyle(
                  fontSize: context.labelLarge,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
              ),
              TextButton(
                onPressed: () => onVehicleTypeChanged(null),
                child: const Text('Clear'),
              ),
            ],
          ),
          SizedBox(height: context.hp(2)),
          _vehicleTypeOption(
            context: context,
            title: 'All Vehicles',
            value: null,
            isSelected: selectedVehicleType == null,
          ),
          ...vehicleTypes.map((type) => _vehicleTypeOption(
            context: context,
            title: type,
            value: type,
            isSelected: selectedVehicleType == type,
          )),
        ],
      ),
    );
  }

  Widget _vehicleTypeOption({
    required BuildContext context,
    required String title,
    required String? value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onVehicleTypeChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.wp(3),
          vertical: context.hp(1.5),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1663F7).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xff1663F7) : Colors.grey.shade400,
              size: context.iconMedium,
            ),
            SizedBox(width: context.wp(3)),
            Text(
              title,
              style: TextStyle(
                fontSize: context.bodyMedium,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xff1663F7) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}