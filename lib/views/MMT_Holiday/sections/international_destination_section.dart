import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../core/resources/app_colours.dart';
import '../screen/destination_package_screen.dart';

class InternationalDestinationsSection extends StatelessWidget {
  const InternationalDestinationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = [
      {
        'name': 'Thailand',
        'image': 'https://picsum.photos/seed/thailand/400',
        'price': '50,200',
        'route': '/thailand-packages',
      },
      {
        'name': 'Maldives',
        'image': 'https://picsum.photos/seed/maldivesint/400',
        'price': '75,500',
        'route': '/maldives-intl-packages',
      },
      {
        'name': 'Laos',
        'image': 'https://picsum.photos/seed/laos/400',
        'price': '47,100',
        'badge': 'New Launch',
        'route': '/laos-packages',
      },
      {
        'name': 'Singapore',
        'image': 'https://picsum.photos/seed/singapore/400',
        'price': '65,000',
        'route': '/singapore-packages',
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
                'International Destinations',
                style: TextStyle(
                  fontSize: context.titleLarge,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: context.gapXXSmall),
              Text(
                'Where Wanderlust Meets Wonder!',
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
          height: context.isMobile
              ? context.hp(24)
              : context.hp(30),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
            itemCount: destinations.length,
            // separatorBuilder: (context, index) => SizedBox(width: context.gapMedium),
            separatorBuilder: (context, index) =>
                SizedBox(width: context.wp(4)),
            itemBuilder: (context, index) {
              final dest = destinations[index];
              return _buildInternationalCard(dest, context);
            },
          ),
        ),
        // SizedBox(height: context.gapLarge),
      ],
    );
  }

  Widget _buildInternationalCard(
      Map<String, String> dest,
      BuildContext context,
      ) {
    return GestureDetector(
      onTap: () {
        _navigateToDestination(
          context,
          dest['name']!,
          dest['route']!,
        );
      },
      child: SizedBox(
        width: context.isMobile
            ? context.wp(36)
            : context.isTablet
            ? context.wp(24)
            : context.wp(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// CARD AREA
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [

                /// SHADOW CARD 1
                Positioned(
                  bottom: -context.hp(1.8),
                  child: Container(
                    width: context.isMobile
                        ? context.wp(30)
                        : context.wp(20),

                    height: context.hp(3),

                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                /// SHADOW CARD 2
                Positioned(
                  bottom: -context.hp(1.1),
                  child: Container(
                    width: context.isMobile
                        ? context.wp(34)
                        : context.wp(22),

                    height: context.hp(2.4),

                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),

                /// MAIN CARD
                Container(
                  height: context.isMobile
                      ? context.hp(16)
                      : context.hp(22),

                  width: double.infinity,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [

                        /// IMAGE
                        Image.network(
                          dest['image']!,
                          fit: BoxFit.cover,

                          errorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.image,
                                size: context.iconLarge,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),

                        /// DARK OVERLAY
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.12),
                              ],
                            ),
                          ),
                        ),

                        /// COUNTRY LABEL
                        Positioned(
                          top: context.hp(1),
                          left: context.wp(2),

                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.wp(2.5),
                              vertical: context.hp(0.6),
                            ),

                            decoration: BoxDecoration(
                              color: const Color(0xFFFBEFD9),
                              borderRadius:
                              BorderRadius.circular(4),
                            ),

                            child: Text(
                              dest['name']!,
                              style: TextStyle(
                                fontSize: context.bodySmall,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        /// NEW LAUNCH TAG
                        if (dest.containsKey('badge'))
                          Positioned(
                            top: context.hp(0.7),
                            right: context.wp(1.8),

                            child: Text(
                              '*${dest['badge']}',
                              style: TextStyle(
                                fontSize: context.overline,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: context.hp(1.8)),

            /// STARTING TEXT
            Text(
              'Starting at',
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: context.hp(0.2)),

            /// PRICE
            Text(
              '₹ ${dest['price']}',
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDestination(BuildContext context, String destination, String route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationPackagesScreen(
          destination: destination,
          packageType: 'International',
        ),
      ),
    );
  }
}