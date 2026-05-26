import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../core/resources/app_colours.dart';

class SearchFieldTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool showCameraIcon;
  final BuildContext context;

  const SearchFieldTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.showCameraIcon = false,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: context.iconMedium,
          ),
          SizedBox(width: context.gapSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.gapXXSmall),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showCameraIcon) ...[
            Icon(
              Icons.camera_alt_outlined,
              color: AppColors.primary,
              size: context.iconMedium,
            ),
            SizedBox(width: context.gapSmall),
          ],
          Icon(
            Icons.chevron_right,
            color: AppColors.textLight,
            size: context.iconMedium,
          ),
        ],
      ),
    );
  }
}