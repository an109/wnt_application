import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';


class ProfilePhoneField extends StatelessWidget {
  final TextEditingController controller;

  const ProfilePhoneField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
          style: TextStyle(
            fontSize: context.bodySmall,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: context.gapXXSmall),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              context.borderRadiusMedium,
            ),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.gapMedium,
                ),
                child: Row(
                  children: [
                    const Text("🇮🇳"),
                    SizedBox(width: context.gapXSmall),
                    Text(
                      "+91",
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 1,
                height: 24,
                color: Colors.grey.shade300,
              ),

              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,

                  decoration: InputDecoration(
                    hintText: "Phone Number",
                    border: InputBorder.none,

                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.gapMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}