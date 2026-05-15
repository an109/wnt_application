import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;

  const RouteCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.wp(70), // Responsive width
      margin: EdgeInsets.only(right: context.wp(3)),
      padding: EdgeInsets.all(context.wp(2.5)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.blue.shade200),
        color: Colors.white,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.borderRadius - 4),
            child: Image.network(
              route['image'],
              height: context.hp(6.5),
              width: context.wp(12),
              fit: BoxFit.cover,
            ),
          ),

          SizedBox(width: context.wp(2.5)),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route
                Row(
                  children: [
                    Text(
                      route['from'],
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: context.wp(1)),
                    Icon(Icons.flight, size: context.iconSmall, color: Colors.blue),
                    SizedBox(width: context.wp(1)),
                    Text(
                      route['to'],
                      style: TextStyle(fontSize: context.bodySmall,fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                SizedBox(height: context.gapSmall / 2),

                Text(
                  "${route['fromCode']} > ${route['toCode']}",
                  style: TextStyle(  fontSize: context.labelSmall, color: Colors.grey[600]),
                ),

                SizedBox(height: context.gapSmall / 2),

                Text(
                  route['date'],
                  style: TextStyle( fontSize: context.labelSmall - 1, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // Price
          Text(
            route['price'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: context.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

// Route Detail Bottom Sheet
class RouteDetailSheet extends StatelessWidget {
  final Map<String, dynamic> route;

  const RouteDetailSheet({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${route['from']} to ${route['to']}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: route['bgColor'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(route['icon'], size: 14, color: route['color']),
                          const SizedBox(width: 4),
                          Text(
                            route['type'],
                            style: TextStyle(
                              fontSize: 12,
                              color: route['color'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: route['bgColor'],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.trending_up,
                    size: 32,
                    color: route['color'],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Journey Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Departure',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        'Arrival',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        route['time'].split(' - ')[0],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                      Text(
                        route['time'].split(' - ')[1],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            route['fromCode'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            route['from'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            route['duration'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            route['stops'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            route['toCode'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            route['to'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Operator Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, size: 20, color: route['color']),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route['type'] == 'Flights'
                              ? route['airline']
                              : route['type'] == 'Trains'
                              ? route['train']
                              : route['busType'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Operator • ${route['type']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${route['rating']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Price and Book Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        Text(
                          route['originalPrice'],
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          route['price'],
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: route['color'],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Save ${route['discount']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking ${route['from']} to ${route['to']} trip!'),
                        backgroundColor: route['color'],
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: route['color'],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}