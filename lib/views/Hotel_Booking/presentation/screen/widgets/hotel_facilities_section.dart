import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class HotelFacilitiesSection extends StatelessWidget {
  final List<String> facilities;
  final String title;

  const HotelFacilitiesSection({
    super.key,
    required this.facilities,
    this.title = 'HOTEL FACILITIES',
  });

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return const SizedBox.shrink();
    }

    print('HotelFacilitiesSection: Building with ${facilities.length} facilities');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hotel_class,
                  size: context.sp(20),
                  color: Colors.blue.shade700,
                ),
                SizedBox(width: context.gapSmall),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.titleSmall,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFacilitiesGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesGrid(BuildContext context) {
    // Group facilities by category for better mobile display
    final categorizedFacilities = _categorizeFacilities(facilities);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categorizedFacilities.entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: context.gapMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.key != 'Other') ...[
                Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: context.sp(13),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: context.gapSmall),
              ],
              Wrap(
                spacing: context.gapSmall,
                runSpacing: context.gapSmall,
                children: entry.value.map((facility) => _buildFacilityChip(context, facility)).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<String>> _categorizeFacilities(List<String> facilities) {
    final Map<String, List<String>> categories = {
      'General': [],
      'Services': [],
      'Parking': [],
      'Activities': [],
      'Dining': [],
      'Business': [],
      'Other': [],
    };

    for (var facility in facilities) {
      final lower = facility.toLowerCase();

      if (lower.contains('parking') || lower.contains('car')) {
        categories['Parking']!.add(facility);
      } else if (lower.contains('service') ||
          lower.contains('cleaning') ||
          lower.contains('front desk') ||
          lower.contains('concierge') ||
          lower.contains('luggage')) {
        categories['Services']!.add(facility);
      } else if (lower.contains('fitness') ||
          lower.contains('pool') ||
          lower.contains('garden') ||
          lower.contains('spa') ||
          lower.contains('beach')) {
        categories['Activities']!.add(facility);
      } else if (lower.contains('restaurant') ||
          lower.contains('dining') ||
          lower.contains('breakfast') ||
          lower.contains('bar') ||
          lower.contains('cafe')) {
        categories['Dining']!.add(facility);
      } else if (lower.contains('business') ||
          lower.contains('meeting') ||
          lower.contains('conference') ||
          lower.contains('wifi') ||
          lower.contains('internet')) {
        categories['Business']!.add(facility);
      } else {
        categories['General']!.add(facility);
      }
    }

    // Remove empty categories
    categories.removeWhere((key, value) => value.isEmpty);

    // If no categories matched, put everything in 'Other'
    if (categories.isEmpty) {
      categories['Other'] = List.from(facilities);
    }

    return categories;
  }

  Widget _buildFacilityChip(BuildContext context, String facility) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.gapSmall,
        vertical: context.gapSmall / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check,
            size: context.sp(12),
            color: Colors.blue[700],
          ),
          SizedBox(width: context.gapSmall / 2),
          Flexible(
            child: Text(
              facility,
              style: TextStyle(
                fontSize: context.sp(12),
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}