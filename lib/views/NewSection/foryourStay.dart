import 'package:flutter/material.dart';
import '../../../../../UI_helper/responsive_layout.dart';

class ForYourStaySection extends StatelessWidget {
  const ForYourStaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "For Your Stay In Delhi",
                    style: TextStyle(
                      fontSize: context.fs(24),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: context.gapXSmall),
                  Text(
                    "Wed, 19 Aug 26 - Thus, 20 Aug 26",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              SizedBox(width: context.w(16)),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff005B7F),
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(
                      Icons.arrow_forward,
                      size: context.iconSmall,
                      color: const Color(0xff005B7F),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapMedium),

          /// HOTEL CAROUSEL
          SizedBox(
            height: context.isMobile
                ? context.h(310)
                : (context.isTablet ? context.h(330) : context.h(350)),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hotelData.length,
              separatorBuilder: (context, index) => SizedBox(
                width: context.gapMedium,
              ),
              itemBuilder: (context, index) {
                return _buildHotelCard(context, hotelData[index]);
              },
            ),
          ),

          SizedBox(height: context.gapLarge),
        ],
      ),
    );
  }

  Widget _buildHotelCard(
      BuildContext context,
      Map<String, dynamic> hotel,
      ) {
    return Container(
      width: context.isMobile
          ? context.w(230)
          : (context.isTablet ? context.w(250) : context.w(270)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HOTEL IMAGE
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(context.borderRadius),
                ),
                child: Image.network(
                  hotel['image'],
                  height: context.isMobile
                      ? context.h(160)
                      : (context.isTablet ? context.h(170) : context.h(180)),
                  // width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: context.isMobile
                          ? context.h(160)
                          : (context.isTablet ? context.h(170) : context.h(180)),
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.hotel,
                        size: context.iconLarge,
                        color: Colors.grey.shade500,
                      ),
                    );
                  },
                ),
              ),
              /// FAVORITE BUTTON
              Positioned(
                top: context.h(12),
                right: context.w(12),
                child: Container(
                  width: context.w(22),
                  height: context.h(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/NewIcons/heart.png',
                    width: context.w(18),
                    height: context.h(18),
                  ),
                ),
              ),
            ],
          ),

          /// HOTEL DETAILS
          Padding(
            padding: EdgeInsets.all(context.gapMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HOTEL NAME
                Text(
                  hotel['name'],
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.gapXSmall),

                /// LOCATION
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: context.iconXSmall,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: context.gapXXSmall),
                    Expanded(
                      child: Text(
                        hotel['location'],
                        style: TextStyle(
                          fontSize: context.fs(12),
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.gapSmall),

                /// PRICE
                Row(
                  children: [
                    Text(
                      "₹${hotel['price']}",
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      " /Night",
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.gapSmall),

                /// RATING AND BOOK NOW BUTTON
                Row(
                  children: [
                    /// STAR RATING
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < hotel['rating']
                              ? Icons.star
                              : Icons.star_border,
                          size: context.fs(14),
                          color: Colors.amber,
                        );
                      }),
                    ),
                    const Spacer(),

                    /// BOOK NOW BUTTON
                    ElevatedButton(
                      onPressed: () {
                        // Book now action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(16),
                          vertical: context.h(8),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.borderRadiusSmall,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Book Now",
                        style: TextStyle(
                          fontSize: context.fs(12),
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

/// STATIC HOTEL DATA
final List<Map<String, dynamic>> hotelData = [
  {
    'name': 'Hotel The Royal Plaza',
    'location': 'Connaught Place',
    'price': '8,222',
    'rating': 4,
    'isFavorite': false,
    'image':
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400',
  },
  {
    'name': 'Hotel The Royal Plaza',
    'location': 'Connaught Place',
    'price': '8,222',
    'rating': 4,
    'isFavorite': true,
    'image':
    'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=400',
  },
  {
    'name': 'Hotel The Royal Plaza',
    'location': 'Connaught Place',
    'price': '8,222',
    'rating': 4,
    'isFavorite': false,
    'image':
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400',
  },
];