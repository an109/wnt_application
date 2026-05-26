// import 'package:flutter/material.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
//
// class RoomAmenitiesSection extends StatelessWidget {
//   final List<String> amenities;
//
//   const RoomAmenitiesSection({
//     super.key,
//     required this.amenities,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (amenities.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(context.borderRadius),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: context.responsivePadding,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'ROOM AMENITIES',
//               style: TextStyle(
//                 fontSize: context.titleSmall,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//                 letterSpacing: 0.5,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: amenities.map((amenity) => _buildAmenityChip(context, amenity)).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAmenityChip(BuildContext context, String amenity) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.blue[50],
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(
//           color: Colors.blue[100]!,
//           width: 1,
//         ),
//       ),
//       child: Text(
//         amenity,
//         style: TextStyle(
//           fontSize: context.sp(12),
//           color: Colors.grey[700],
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class RoomAmenitiesSection extends StatefulWidget {
  final List<String> amenities;

  const RoomAmenitiesSection({
    super.key,
    required this.amenities,
  });

  @override
  State<RoomAmenitiesSection> createState() => _RoomAmenitiesSectionState();
}

class _RoomAmenitiesSectionState extends State<RoomAmenitiesSection> {
  bool _isExpanded = false;
  static const int _previewItemCount = 6;

  @override
  Widget build(BuildContext context) {
    if (widget.amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get visible amenities based on expanded state
    final visibleAmenities = _isExpanded
        ? widget.amenities
        : widget.amenities.take(_previewItemCount).toList();

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
            Text(
              'ROOM AMENITIES',
              style: TextStyle(
                fontSize: context.titleSmall,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleAmenities.map((amenity) => _buildAmenityChip(context, amenity)).toList(),
            ),

            // Add Read More / Read Less button if there are more amenities
            if (widget.amenities.length > _previewItemCount) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded ? 'Show Less' : 'Show More',
                      style: TextStyle(
                        fontSize: context.sp(13),
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                    SizedBox(width: context.gapSmall),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: context.iconSmall,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityChip(BuildContext context, String amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: Text(
        amenity,
        style: TextStyle(
          fontSize: context.sp(12),
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}