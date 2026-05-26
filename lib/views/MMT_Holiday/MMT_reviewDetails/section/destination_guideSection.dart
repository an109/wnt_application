import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

class DestinationGuideSection extends StatelessWidget {
  final String destination;

  const DestinationGuideSection({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.gapMedium,
      ),
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your $destination Destination Guide',
            style: TextStyle(
              fontSize: context.titleSmall,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Text(
            'Soak in the essence of $destination on this 5-day journey! Unwind at a beachside resort, party under the stars on a boat, and discover even more experiences. Customise your getaway from a pool of optional activities to make it truly unforgettable.',
            style: TextStyle(
              fontSize: context.bodySmall,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: context.gapMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Read More',
                style: TextStyle(
                  fontSize: context.labelMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: context.gapXXSmall),
              Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: context.iconSmall),
            ],
          ),
        ],
      ),
    );
  }
}