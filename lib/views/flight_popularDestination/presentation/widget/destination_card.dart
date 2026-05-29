import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../domain/entities/Popular_destination_entity.dart';

class DestinationCard extends StatelessWidget {
  final DestinationEntity destination;
  final VoidCallback onViewDetail;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: context.wp(80),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.borderRadius),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: context.wp(2.5),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.borderRadius),
                  topRight: Radius.circular(context.borderRadius),
                ),
                child: destination.imageUrl.isNotEmpty
                    ? Image.network(
                  destination.imageUrl,
                  height: context.imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage(context);
                  },
                )
                    : _buildPlaceholderImage(context),
              ),
            ],
          ),

          // Content Section
          Padding(
            padding: EdgeInsets.all(context.wp(3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  style: TextStyle(fontSize: context.titleSmall, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.gapSmall / 4),
                Text(
                  destination.country,
                  style: TextStyle(fontSize: context.bodySmall, color: Colors.grey.shade600),
                ),
                SizedBox(height: context.gapMedium),
                Text(
                  destination.description.isNotEmpty ? destination.description : destination.longDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.bodySmall, color: Colors.grey.shade600, height: 1.4),
                ),
                SizedBox(height: context.gapLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Starting from', style: TextStyle(fontSize: context.labelSmall, color: Colors.grey.shade500)),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: destination.price.isNotEmpty
                                    ? destination.price.split('/')[0].trim()
                                    : '',
                                style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold, color: const Color(0xff005B7F)),
                              ),
                              if (destination.price.isNotEmpty && destination.price.contains('/'))
                                TextSpan(
                                  text: '\n${destination.price.split('/')[1].trim()}',
                                  style: TextStyle(fontSize: context.labelSmall, fontWeight: FontWeight.normal, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onViewDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff005B7F),
                        padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(1.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius + 8)),
                        elevation: 0,
                      ),
                      child: Text('View Details', style: TextStyle(
                          fontSize: context.bodySmall,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
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

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      height: context.imageHeight,
      color: const Color(0xff005B7F).withOpacity(0.2),
      child: Center(
        child: Icon(Icons.location_city, size: context.iconLarge, color: const Color(0xff005B7F)),
      ),
    );
  }
}