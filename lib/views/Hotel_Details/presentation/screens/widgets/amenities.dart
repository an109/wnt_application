import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class AmenitiesSection extends StatelessWidget {
  final List<String> hotelFacilities;
  final Map<String, String> attractions;

  const AmenitiesSection({
    super.key,
    required this.hotelFacilities,
    required this.attractions,
  });

  @override
  Widget build(BuildContext context) {
    print('AmenitiesSection: Building with ${hotelFacilities.length} facilities');

    return Container(
      color: Colors.white,
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities & Info',
            style: TextStyle(
              fontSize: context.headlineMedium,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickAmenities(context),
          const SizedBox(height: 24),
          _buildDetailedAmenities(context),
          if (attractions.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAttractions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAmenities(BuildContext context) {
    final quickAmenities = hotelFacilities.take(4).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: quickAmenities.map((amenity) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check,
              size: context.sp(16),
              color: Colors.green[600],
            ),
            const SizedBox(width: 4),
            Text(
              amenity,
              style: TextStyle(
                fontSize: context.sp(14),
                color: Colors.grey[800],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDetailedAmenities(BuildContext context) {
    // Group facilities by category (you can customize this logic)
    final categories = _categorizeFacilities();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...entry.value.map((facility) => _buildAmenityRow(facility, context)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<String>> _categorizeFacilities() {
    // Simple categorization - you can enhance this based on your needs
    final Map<String, List<String>> categories = {
      'General': [],
      'Services': [],
      'Parking': [],
      'Activities': [],
    };

    for (var facility in hotelFacilities) {
      final lowerFacility = facility.toLowerCase();
      if (lowerFacility.contains('parking')) {
        categories['Parking']!.add(facility);
      } else if (lowerFacility.contains('service') ||
          lowerFacility.contains('cleaning') ||
          lowerFacility.contains('front desk')) {
        categories['Services']!.add(facility);
      } else if (lowerFacility.contains('fitness') ||
          lowerFacility.contains('pool') ||
          lowerFacility.contains('garden')) {
        categories['Activities']!.add(facility);
      } else {
        categories['General']!.add(facility);
      }
    }

    // Remove empty categories
    categories.removeWhere((key, value) => value.isEmpty);

    return categories;
  }

  Widget _buildAmenityRow(String amenity, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: context.sp(16),
            color: Colors.green[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              amenity,
              style: TextStyle(
                fontSize: context.sp(14),
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttractions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nearby Attractions',
          style: TextStyle(
            fontSize: context.headlineSmall,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...attractions.entries.take(10).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: context.sp(16),
                  color: Colors.red[400],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${entry.key} ${entry.value}',
                    style: TextStyle(
                      fontSize: context.sp(13),
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}