import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class DestinationCard extends StatelessWidget {
  final Map<String, dynamic> destination;
  final VoidCallback onViewDetail;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.borderRadius),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Tag
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.borderRadius),
                  topRight: Radius.circular(context.borderRadius),
                ),
                child: Image.network(
                  destination['imageUrl'],
                  height: context.imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: context.imageHeight,
                      color: destination['color'].withOpacity(0.2),
                      child: Center(
                        child: Icon(
                          Icons.location_city,
                          size: context.iconLarge,
                          color: destination['color'],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Tag Badge
              Positioned(
                top: context.hp(1.5),
                left: context.wp(3),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.wp(3), vertical: context.hp(0.8)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        destination['color'],
                        destination['color'].withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(context.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: destination['color'].withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    destination['tag'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.labelSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Rating Badge
              Positioned(
                top: context.hp(1.5),
                right: context.wp(3),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.wp(2), vertical: context.hp(0.5)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.borderRadius - 8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: context.iconSmall),
                      SizedBox(width: context.gapSmall),
                      Text(
                        '${destination['rating']}',
                        style: TextStyle(
                          fontSize: context.labelMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content Section
          Padding(
            padding: EdgeInsets.all(context.wp(3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Subtitle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination['title'],
                            style: TextStyle(
                              fontSize: context.titleSmall,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.gapSmall / 4),
                          Text(
                            destination['subtitle'],
                            style: TextStyle(
                              fontSize: context.bodySmall,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Duration
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.wp(2), vertical: context.hp(0.5)),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(context.borderRadius - 8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: context.iconSmall, color: Colors.grey),
                          SizedBox(width: context.gapSmall / 2),
                          Text(
                            destination['duration'],
                            style: TextStyle(
                              fontSize: context.labelSmall,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.gapMedium),

                // Description
                Text(
                  destination['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),

                SizedBox(height: context.gapLarge),

                // Price and Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting from',
                          style: TextStyle(
                            fontSize: context.labelSmall,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          destination['price'],
                          style: TextStyle(
                            fontSize: context.titleMedium,
                            fontWeight: FontWeight.bold,
                            color: destination['color'],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onViewDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: destination['color'],
                        padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(1.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.borderRadius + 8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: context.bodySmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}