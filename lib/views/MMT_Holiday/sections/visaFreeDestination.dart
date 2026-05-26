import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';

class VisaFreeSection extends StatelessWidget {
  const VisaFreeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = [
      {'name': 'Kashmir', 'image': 'https://picsum.photos/seed/kashmir/200'},
      {'name': 'Himachal', 'image': 'https://picsum.photos/seed/himachal/200'},
      {'name': 'Kerala', 'image': 'https://picsum.photos/seed/kerala/200'},
      {'name': 'Coorg & Ooty', 'image': 'https://picsum.photos/seed/coorg/200'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visa Free Destination',
                style: TextStyle(
                  fontSize: context.titleLarge,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: context.gapXXSmall),
              Text(
                'Dream Destinations, Zero Paperwork!',
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.gapMedium),
        SizedBox(
          height: context.hp(18),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
            itemCount: destinations.length,
            separatorBuilder: (context, index) => SizedBox(width: context.gapMedium),
            itemBuilder: (context, index) {
              final dest = destinations[index];
              return _buildDestinationCard(dest, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationCard(Map<String, String> dest, BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.wp(22),
          height: context.hp(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              dest['image']!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.lightBg,
                child: Icon(
                  Icons.landscape,
                  color: AppColors.textLight,
                  size: context.iconLarge,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.gapSmall),
        SizedBox(
          width: context.wp(22),
          child: Text(
            dest['name']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.bodyMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}