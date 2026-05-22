import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';
import '../screen/destination_package_screen.dart';

class LastMinuteEscape extends StatelessWidget {
  const LastMinuteEscape({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = [
      {
        'name': 'South India',
        'image': 'https://picsum.photos/seed/goabnp/300',
        'route': '/goa-packages',
      },
      {
        'name': 'Himachal',
        'image': 'https://picsum.photos/seed/himachalbnp/300',
        'route': '/himachal-packages',
      },
      {
        'name': 'Andaman',
        'image': 'https://picsum.photos/seed/andamanbnp/300',
        'route': '/andaman-packages',
      },
      {
        'name': 'Maldives',
        'image': 'https://picsum.photos/seed/maldivesbnp/300',
        'route': '/maldives-packages',
      },
      {
        'name': 'Kerala',
        'image': 'https://picsum.photos/seed/keralabnp/300',
        'route': '/kerala-packages',
      },
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
                'Last-Minute Escape Sale!',
                style: TextStyle(
                  fontSize: context.titleLarge,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: context.gapXXSmall),
              Text(
                'Book your spontaneous gateway. Use code: \nLASTMINUTE',
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
          height: context.hp(16),
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
        SizedBox(height: context.gapSmall),
      ],
    );
  }

  Widget _buildDestinationCard(Map<String, String> dest, BuildContext context) {
    return GestureDetector(
      onTap: () {
        _navigateToDestination(context, dest['name']!, dest['route']!);
      },
      child: Column(
        children: [
          Container(
            width: context.wp(22),
            height: context.hp(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    dest['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.lightBg,
                      child: Icon(
                        Icons.beach_access,
                        color: AppColors.textLight,
                        size: context.iconLarge,
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.lightBg,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.gapSmall),
          SizedBox(
            width: context.wp(24),
            child: Text(
              dest['name']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDestination(BuildContext context, String destination, String route) {
    // Named route navigation
    // Navigator.pushNamed(context, route, arguments: {'destination': destination});

    // OR Direct widget navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationPackagesScreen(
          destination: destination,
          packageType: 'Book Now Pay Later',
        ),
      ),
    );
  }
}