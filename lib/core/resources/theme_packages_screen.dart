import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../views/MMT_Holiday/data/dummy.dart';
import '../../views/MMT_Holiday/widget/holiday_package_card.dart';
import 'app_colours.dart';

class ThemePackagesScreen extends StatelessWidget {
  final String themeName;
  final String themeRoute;

  const ThemePackagesScreen({
    super.key,
    required this.themeName,
    required this.themeRoute,
  });

  @override
  Widget build(BuildContext context) {
    // Filter packages based on theme (dummy implementation)
    final packages = DummyData.packages.take(6).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              themeName,
              style: TextStyle(
                fontSize: context.titleMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Theme Packages',
              style: TextStyle(
                fontSize: context.labelSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.textPrimary),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(context.wp(4)),
                padding: context.responsivePadding,
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$themeName Packages',
                            style: TextStyle(
                              fontSize: context.titleMedium,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(height: context.gapXXSmall),
                          Text(
                            'Explore our best ${themeName.toLowerCase()} packages',
                            style: TextStyle(
                              fontSize: context.bodySmall,
                              color: AppColors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.celebration,
                      color: AppColors.white,
                      size: context.iconLarge,
                    ),
                  ],
                ),
              ),
            ),

            // Packages List
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final package = packages[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: context.gapMedium),
                      child: HolidayPackageCard(
                        package: package,
                        onTap: () {
                          _navigateToPackageDetails(context, package);
                        },
                      ),
                    );
                  },
                  childCount: packages.length,
                ),
              ),
            ),

            // Bottom Padding
            SliverToBoxAdapter(
              child: SizedBox(height: context.hp(2)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.borderRadiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: context.gapMedium),
              width: context.wp(10),
              height: context.hp(0.5),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: context.responsivePadding,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Filter Packages',
                    style: TextStyle(
                      fontSize: context.titleMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.divider, height: 1),
            // Add filter options here
            SizedBox(height: context.gapMedium),
          ],
        ),
      ),
    );
  }

  void _navigateToPackageDetails(BuildContext context, dynamic package) {
    // Navigate to package details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(package.title),
            backgroundColor: AppColors.white,
          ),
          body: Center(
            child: Text(
              'Package Details Screen',
              style: TextStyle(fontSize: context.bodyLarge),
            ),
          ),
        ),
      ),
    );
  }
}