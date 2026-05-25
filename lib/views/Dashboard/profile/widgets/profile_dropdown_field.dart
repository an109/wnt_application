import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';


class ProfileDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;

  const ProfileDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.bodySmall,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: context.gapXXSmall),

        DropdownButtonFormField<String>(
          value: value,

          style: TextStyle(
            fontSize: context.bodyMedium,
            color: Colors.black87,
          ),

          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,

            contentPadding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapMedium,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.borderRadiusMedium,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.borderRadiusMedium,
              ),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.borderRadiusMedium,
              ),
              borderSide: const BorderSide(
                color: Color(0xFF0054A0),
              ),
            ),
          ),

          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ],
    );
  }
}