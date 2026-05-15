import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

extension FormValidationHelper on BuildContext {
  /// Returns error border color for invalid fields
  Color get errorBorderColor => const Color(0xffDC2626);

  /// Returns success border color for valid fields
  Color get successBorderColor => const Color(0xff10B981);
}

/// Reusable text field with validation styling
class ValidatedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.hasError = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: context.bodySmall,
                fontWeight: FontWeight.w600,
                color: hasError ? context.errorBorderColor : const Color(0xff0D1B3D),
              ),
            ),
            if (label.contains('*'))
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '*',
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    fontWeight: FontWeight.w700,
                    color: hasError ? context.errorBorderColor : const Color(0xffF97316),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? context.errorBorderColor : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? context.errorBorderColor : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? context.errorBorderColor : const Color(0xff1663F7),
                width: 2,
              ),
            ),
            errorText: hasError ? 'This field is required' : null,
            contentPadding: EdgeInsets.all(context.wp(3)),
          ),
        ),
      ],
    );
  }
}

/// Utility class for amenity handling
class AmenityUtils {
  /// Check if amenity should be displayed
  static bool shouldDisplayAmenity(String key, bool chargeable, bool included) {
    return chargeable || included;
  }

  /// Format amenity price with currency
  static String formatPrice(String value, String prefixSymbol) {
    final price = double.tryParse(value) ?? 0;
    return '$prefixSymbol${price.toStringAsFixed(2)}';
  }
}