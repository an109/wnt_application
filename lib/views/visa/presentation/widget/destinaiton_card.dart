import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class DestinationCard extends StatelessWidget {

  final String image;
  final String country;
  final String type;
  final String price;
  final String processing;

  const DestinationCard({
    super.key,
    required this.image,
    required this.country,
    required this.type,
    required this.price,
    required this.processing,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: context.isMobile ? 240 : 290,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          /// IMAGE
          Stack(
            clipBehavior: Clip.none,
            children: [

              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),

                child: Image.network(
                  image,
                  height: context.isMobile ? 170 : 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                bottom: -25,
                left: 20,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xff21409A),
                    borderRadius:
                    BorderRadius.circular(40),
                  ),

                  child: Column(
                    children: [

                      const Text(
                        "STARTING",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),

                      const Text(
                        "ONLY",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.hp(4)),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  country,
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: context.gapSmall),

                Text(
                  type,
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: context.gapMedium),

                Text(
                  "Processing Time: $processing",
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: context.gapMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}