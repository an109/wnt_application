import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';

class PackageInfoSection extends StatelessWidget {
  final String packageName;
  final String duration;
  final String location;
  final String originCity;
  final int travellers;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onModify;

  const PackageInfoSection({
    super.key,
    required this.packageName,
    required this.duration,
    required this.location,
    required this.originCity,
    required this.travellers,
    required this.startDate,
    required this.endDate,
    required this.onModify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.wp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.wp(2),
              vertical: context.hp(0.2),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textSecondary),
              borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            ),
            child: Text(
              duration,
              style: TextStyle(
                fontSize: context.labelMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: context.gapSmall),

          // Package Title
          Text(
            packageName,
            style: TextStyle(
              fontSize: context.headlineSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.gapXXSmall),

          // Location
          Text(
            location,
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: context.gapMedium),

          // Travel Details Card
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.wp(4),
              vertical: context.hp(1.5),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$originCity • $travellers Travellers • ${DateFormat('dd - dd MMM').format(startDate)} - ${DateFormat('dd').format(endDate)}',
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onModify,
                  child: Text(
                    'MODIFY',
                    style: TextStyle(
                      fontSize: context.labelMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}