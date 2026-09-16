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

  /// Filled button's background. Defaults to the Figma "Flight Sort" orange
  /// so every existing caller keeps its current look.
  final Color primaryColor;

  const SheetActionButtons({
    super.key,
    required this.onPrimary,
    required this.onSecondary,
    this.primaryLabel = 'DONE',
    this.secondaryLabel = 'RESET',
    this.padding,
    this.primaryColor = AppColors.orange,
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
              fillColor: primaryColor,
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
        Color fillColor = AppColors.orange,
      }) {
    final radius = BorderRadius.circular(context.r(12));
    return Material(
      color: filled ? fillColor : Colors.white,
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
