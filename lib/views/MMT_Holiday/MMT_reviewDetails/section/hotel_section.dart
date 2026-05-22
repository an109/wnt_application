import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';

class HotelSection extends StatelessWidget {
  const HotelSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.wp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hotel, color: AppColors.textSecondary, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESORT • 4 Nights • In Goa',
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_up, color: AppColors.textSecondary),
            ],
          ),
          SizedBox(height: context.gapMedium),

          // Rating
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(1.5),
                  vertical: context.hp(0.5),
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '4.1',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(width: context.gapXXSmall),
              Text(
                'Very Good',
                style: TextStyle(
                  fontSize: context.bodySmall,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1976D2),
                ),
              ),
              SizedBox(width: context.gapXXSmall),
              Text(
                '(506 Ratings)',
                style: TextStyle(
                  fontSize: context.labelSmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),

          // Hotel Name
          Text(
            'Sharanam Greens Resort',
            style: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.gapXXSmall),

          // Location
          Text(
            'Calangute, 7 minutes walk to Calangute Beach',
            style: TextStyle(
              fontSize: context.bodySmall,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: context.gapSmall),

          // Room Details
          Row(
            children: [
              Icon(Icons.people, size: context.iconXSmall, color: AppColors.textLight),
              SizedBox(width: context.gapXXSmall),
              Text(
                '1 Room | 2 Adults',
                style: TextStyle(
                  fontSize: context.labelSmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapSmall),

          // Dates
          Row(
            children: [
              Icon(Icons.access_time, size: context.iconXSmall, color: AppColors.textLight),
              SizedBox(width: context.gapXXSmall),
              Expanded(
                child: Text(
                  '22nd Jun 1 PM - 26th Jun 11 AM, 4 Nights',
                  style: TextStyle(
                    fontSize: context.labelSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapMedium),

          // Actions
          Row(
            children: [
              Text(
                'Change Hotel',
                style: TextStyle(
                  fontSize: context.labelMedium,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                'More Details',
                style: TextStyle(
                  fontSize: context.labelMedium,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}