import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

/// Bottom action row for modal sheets — two equal-width buttons
/// (e.g. RESET and DONE), matching the Wander Nova Figma ("Flight Sort").
///
/// Fully responsive — every size goes through the `context.w/h/r/fs`
/// helpers — and it inherits the app's Manrope text theme.
class SheetActionButtons extends StatelessWidget {
  /// Filled orange button label (right side).
  final String primaryLabel;

  /// Outlined button label (left side).
  final String secondaryLabel;

  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  /// Outer padding around the row.
  final EdgeInsetsGeometry? padding;

  const SheetActionButtons({
    super.key,
    required this.onPrimary,
    required this.onSecondary,
    this.primaryLabel = 'DONE',
    this.secondaryLabel = 'RESET',
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            context.w(20),
            context.h(14),
            context.w(20),
            context.h(16),
          ),
      child: Row(
        children: [
          // Both buttons have equal flex (1:1)
          Expanded(
            flex: 1,  // Equal flex
            child: _button(
              context,
              label: secondaryLabel,
              onTap: onSecondary,
              filled: false,
            ),
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            flex: 1,  // Equal flex
            child: _button(
              context,
              label: primaryLabel,
              onTap: onPrimary,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(
      BuildContext context, {
        required String label,
        required VoidCallback onTap,
        required bool filled,
      }) {
    final radius = BorderRadius.circular(context.r(12));
    return Material(
      color: filled ? AppColors.orange : Colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: context.h(44), // Same height for both
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: filled
                ? null
                : Border.all(color: const Color(0xFFCCCCCC), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: filled ? AppColors.white : AppColors.subhead,
            ),
          ),
        ),
      ),
    );
  }
}
