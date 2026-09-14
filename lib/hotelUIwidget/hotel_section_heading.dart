import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../core/resources/app_colours.dart';

/// Reusable section heading used across the redesigned Hotel screen
/// (Figma node 137:1117) — a title, an optional subtitle underneath, and an
/// optional trailing "View all →" link. Kept generic (title/subtitle/
/// onViewAll only) so it isn't tied to any one section's data source.
class HotelSectionHeading extends StatelessWidget {
  const HotelSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.onViewAll,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: context.fs(20),
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: context.h(4)),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: AppColors.subhead,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(left: context.w(8), top: context.h(2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.AppBlue,
                    ),
                  ),
                  SizedBox(width: context.w(4)),
                  Icon(Icons.arrow_forward,
                      size: context.iconSmall, color: AppColors.AppBlue),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
