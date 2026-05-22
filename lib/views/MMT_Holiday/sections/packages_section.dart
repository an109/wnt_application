import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';
import '../data/dummy.dart';
import '../screen/package_details.dart';
import '../widget/holiday_package_card.dart';

class PackagesSection extends StatelessWidget {
  const PackagesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Packages',
                style: TextStyle(
                  fontSize: context.titleLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: context.labelMedium,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.gapSmall),
        ...DummyData.packages.map((package) => Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: HolidayPackageCard(
            package: package,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PackageDetailsScreen(package: package),
                ),
              );
            },
          ),
        )),
        SizedBox(height: context.gapLarge),
      ],
    );
  }
}