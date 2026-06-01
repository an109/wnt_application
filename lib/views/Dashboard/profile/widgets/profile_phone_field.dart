// import 'package:flutter/material.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
//
//
// class ProfilePhoneField extends StatelessWidget {
//   final TextEditingController controller;
//
//   const ProfilePhoneField({
//     super.key,
//     required this.controller,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Phone Number",
//           style: TextStyle(
//             fontSize: context.bodySmall,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//
//         SizedBox(height: context.gapXXSmall),
//
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(
//               context.borderRadiusMedium,
//             ),
//             border: Border.all(
//               color: Colors.grey.shade300,
//             ),
//           ),
//           child: Row(
//             children: [
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: context.gapMedium,
//                 ),
//                 child: Row(
//                   children: [
//                     const Text("🇮🇳"),
//                     SizedBox(width: context.gapXSmall),
//                     Text(
//                       "+91",
//                       style: TextStyle(
//                         fontSize: context.bodyMedium,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               Container(
//                 width: 1,
//                 height: 24,
//                 color: Colors.grey.shade300,
//               ),
//
//               Expanded(
//                 child: TextFormField(
//                   controller: controller,
//                   keyboardType: TextInputType.phone,
//
//                   decoration: InputDecoration(
//                     hintText: "Phone Number",
//                     border: InputBorder.none,
//
//                     contentPadding: EdgeInsets.symmetric(
//                       horizontal: context.gapMedium,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class ProfilePhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String?>? onCountryCodeChanged;

  const ProfilePhoneField({
    super.key,
    required this.controller,
    this.countryCode = '+91',
    this.onCountryCodeChanged,
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
            borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
                child: Row(
                  children: [
                    const Text("🇮🇳"),
                    SizedBox(width: context.gapXSmall),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: countryCode,
                        items: const [
                          DropdownMenuItem(value: '+91', child: Text('+91')),
                          DropdownMenuItem(value: '+1', child: Text('+1')),
                          DropdownMenuItem(value: '+44', child: Text('+44')),
                        ],
                        onChanged: onCountryCodeChanged,
                        style: TextStyle(fontSize: context.bodyMedium),
                        iconSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "Phone Number",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: context.gapMedium),
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