import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';


class ProfileTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final Widget? suffixIcon;

  const ProfileTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.suffixIcon,
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
            color: Colors.black87,
          ),
        ),

        SizedBox(height: context.gapXXSmall),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,

          style: TextStyle(
            fontSize: context.bodyMedium,
          ),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: TextStyle(
              fontSize: context.bodySmall,
              color: Colors.grey.shade500,
            ),

            suffixIcon: suffixIcon,

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
              borderSide: BorderSide(
                color: Colors.grey.shade300,
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
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}