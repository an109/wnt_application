import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../core/resources/app_colours.dart';
import '../../../core/resources/theme_packages_screen.dart';


class HolidaysByThemeSection extends StatelessWidget {
  const HolidaysByThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themes = [
      {
        'name': 'Pilgrimage',
        'image': 'https://picsum.photos/seed/pilgrimage/400',
        'subcategories': ['Uttar Pradesh', 'South India', 'Gujarat', 'Char Dham'],
        'route': '/pilgrimage',
      },
      {
        'name': 'Honeymoon',
        'image': 'https://picsum.photos/seed/honeymoon/400',
        'subcategories': ['Maldives', 'Bali', 'Goa', 'Kerala'],
        'route': '/honeymoon',
      },
      {
        'name': 'Adventure',
        'image': 'https://picsum.photos/seed/adventure/400',
        'subcategories': ['Rishikesh', 'Manali', 'Goa', 'Andaman'],
        'route': '/adventure',
      },
      {
        'name': 'Family',
        'image': 'https://picsum.photos/seed/family/400',
        'subcategories': ['Dubai', 'Singapore', 'Goa', 'Kerala'],
        'route': '/family',
      },
      {
        'name': 'Luxury',
        'image': 'https://picsum.photos/seed/luxury/400',
        'subcategories': ['Maldives', 'Switzerland', 'Dubai', 'Europe'],
        'route': '/luxury',
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
                'Holidays by Theme',
                style: TextStyle(
                  fontSize: context.titleLarge,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: context.gapXXSmall),
              Text(
                'Pick from our specially curated packages',
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
          height: context.hp(43.3),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.wp(1)),
            itemCount: themes.length,
            separatorBuilder: (context, index) => SizedBox(width: context.gapSmall),
            itemBuilder: (context, index) {
              final theme = themes[index];
              return _buildThemeCard(theme, context);
            },
          ),
        ),
        SizedBox(height: context.gapSmall),
      ],
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme, BuildContext context) {
    final subcategories = theme['subcategories'] as List<String>;

    return GestureDetector(
      onTap: () {
        _navigateToThemePackages(context, theme);
      },
      child: Container(
        width: context.wp(48),
        padding: EdgeInsets.all(context.wp(1.5)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            context.borderRadiusMedium,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            Container(
              height: context.hp(22),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  context.borderRadiusMedium,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      theme['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.lightBg,
                          child: Icon(
                            Icons.category,
                            color: AppColors.textLight,
                            size: context.iconXLarge,
                          ),
                        );
                      },
                      loadingBuilder:
                          (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        return Container(
                          color: AppColors.lightBg,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              value:
                              loadingProgress
                                  .expectedTotalBytes !=
                                  null
                                  ? loadingProgress
                                  .cumulativeBytesLoaded /
                                  loadingProgress
                                      .expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),

                    // Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.25),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.gapSmall),

            // Theme Name
            Text(
              theme['name'],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.titleSmall,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: context.gapXXSmall),

            // Subtitle
            Text(
              'Special curated holiday packages',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),

            SizedBox(height: context.gapSmall),

            // Chips
            Wrap(
              alignment: WrapAlignment.center,
              spacing: context.gapXXSmall,
              runSpacing: context.gapXXSmall,
              children: subcategories.take(4).map((subcat) {
                return _buildSubcategoryChip(
                  subcat,
                  context,
                );
              }).toList(),
            ),

            SizedBox(height: context.gapSmall),

            // View More Button
            Text(
              'View More',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.labelMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryChip(String subcategory, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(2.5),
        vertical: context.hp(0.6),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(context.borderRadiusSmall),
      ),
      child: Text(
        subcategory,
        style: TextStyle(
          fontSize: context.labelSmall,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _navigateToThemePackages(BuildContext context, Map<String, dynamic> theme) {
    // Method 1: Direct navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThemePackagesScreen(
          themeName: theme['name'],
          themeRoute: theme['route'],
        ),
      ),
    );

    // Method 2: Named route navigation (uncomment if using named routes)
    // Navigator.pushNamed(
    //   context,
    //   theme['route'],
    //   arguments: {'themeName': theme['name']},
    // );
  }
}