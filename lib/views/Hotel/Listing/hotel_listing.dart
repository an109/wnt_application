import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/logo.dart';
import '../../home/presentation/screens/home_screen.dart';
import '../Filter_drawer/filter_drawer.dart';


class HotelListingScreen extends StatelessWidget {
  HotelListingScreen({super.key});

  final List<HotelModel> hotels = [
    HotelModel(
      image:
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1200&auto=format&fit=crop',
      hotelName: 'The Z Hotel Shoreditch',
      address:
      '136-144 City Rd, London EC1V 2RL, UK, London, United Kingdom',
      price: '15,362',
      taxes: '2,746',
      rating: 3,
      roomInfo: 'Double Room, 1 Double Bed, NonSmoking',
      description:
      "Welcome to The Z Hotel Shoreditch, an urban retreat nestled in the heart of London's tech city.",
      features: [
        'first aid kit available',
        'linens, towels and laundry washed in accordance with local authority guidelines',
        'contactless check-in/check-out',
        'staff follow all safety protocols as directed by local authorities',
        'cashless payment available',
        'coffee house on site',
      ],
    ),
    HotelModel(
      image:
      'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?q=80&w=1200&auto=format&fit=crop',
      hotelName: 'Royal Palm Hotel',
      address: '221 Baker Street, London, United Kingdom',
      price: '12,500',
      taxes: '1,800',
      rating: 4,
      roomInfo: 'Premium Room, King Bed',
      description: 'Luxury stay with premium city view and modern amenities.',
      features: [
        'free wifi',
        '24 hour front desk',
        'breakfast included',
        'airport shuttle',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HotelFilterDrawer(),
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset("assets/images/wander_nova_logo.jpg", height: 35),
          )
        ],
      ),
      backgroundColor: const Color(0xffF5F5F5),
      body: ListView.separated(
        padding: context.horizontalPadding.copyWith(
          top: context.gapMedium,
          bottom: context.gapLarge,
        ),
        itemCount: hotels.length,
        separatorBuilder: (_, __) => SizedBox(height: context.gapLarge),
        itemBuilder: (context, index) {
          return HotelCard(hotel: hotels[index]);
        },
      ),
      // bottomNavigationBar: CustomBottomNav(
      //   currentIndex: 1,
      //   onTap: (i) {
      //     if (i == 0) {
      //       Navigator.pushReplacement(
      //         context,
      //         MaterialPageRoute(
      //           builder: (_) => const HomeScreen(),
      //         ),
      //       );
      //     }
      //   },
      // ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 1,
      ),
    );
  }
}

class HotelCard extends StatelessWidget {
  final HotelModel hotel;

  const HotelCard({
    super.key,
    required this.hotel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(context.borderRadius),
              topRight: Radius.circular(context.borderRadius),
            ),
            child: AspectRatio(
              aspectRatio: context.isTablet ? 2.2 : 1.45,
              child: Image.network(
                hotel.image,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(context.gapMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TITLE + RATING
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        hotel.hotelName,
                        style: TextStyle(
                          fontSize: context.titleLarge,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    SizedBox(width: context.gapSmall),

                    _RatingWidget(rating: hotel.rating),
                  ],
                ),

                SizedBox(height: context.gapSmall),

                /// ADDRESS
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: context.iconSmall,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: context.gapSmall),

                    Expanded(
                      child: Text(
                        hotel.address,
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.gapMedium),

                /// FEATURES
                Wrap(
                  spacing: context.gapSmall,
                  runSpacing: context.gapSmall,
                  children: hotel.features
                      .map(
                        (e) => _FeatureChip(text: e),
                  )
                      .toList(),
                ),

                SizedBox(height: context.gapMedium),

                /// ROOM INFO
                Row(
                  children: [
                    Icon(
                      Icons.coffee_outlined,
                      size: context.iconSmall,
                    ),
                    SizedBox(width: context.gapSmall),
                    Expanded(
                      child: Text(
                        hotel.roomInfo,
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.gapSmall),

                /// NON REFUNDABLE
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.gapSmall,
                    vertical: context.gapSmall / 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.red.withOpacity(.08),
                  ),
                  child: Text(
                    'Non-refundable',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: context.bodySmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                SizedBox(height: context.gapMedium),

                /// DESCRIPTION
                Text(
                  hotel.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.4,
                    fontSize: context.bodyMedium,
                    color: Colors.grey.shade800,
                  ),
                ),

                SizedBox(height: context.gapLarge),

                /// PRICE + BUTTON
                context.isTablet || context.isDesktop
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _PriceSection(hotel: hotel),
                    ),

                    SizedBox(width: context.gapLarge),

                    Expanded(
                      child: _ButtonsSection(),
                    ),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PriceSection(hotel: hotel),

                    SizedBox(height: context.gapMedium),

                    _ButtonsSection(),
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

class _ButtonsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        /// SELECT ROOM
        SizedBox(
          width: double.infinity,
          height: context.buttonHeight + 6,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            child: Text(
              'Select Room',
              style: TextStyle(
                fontSize: context.bodyLarge,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        SizedBox(height: context.gapMedium),

        /// SHORTLIST
        Container(
          width: double.infinity,
          height: context.buttonHeight + 4,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                color: Colors.red,
                size: context.iconMedium,
              ),
              SizedBox(width: context.gapSmall),
              Text(
                'Shortlist',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceSection extends StatelessWidget {
  final HotelModel hotel;

  const _PriceSection({
    required this.hotel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.gapMedium,
            vertical: context.gapSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.white,
                size: context.iconSmall,
              ),
              SizedBox(width: context.gapSmall / 2),
              Text(
                hotel.rating.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: context.bodyLarge,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              hotel.price,
              style: TextStyle(
                fontSize: context.headlineSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'per night',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: context.bodyMedium,
              ),
            ),
            SizedBox(height: context.gapSmall / 2),
            Text(
              'Total: ${hotel.price}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: context.bodyMedium,
              ),
            ),
            Text(
              '+ ${hotel.taxes} taxes',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: context.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String text;

  const _FeatureChip({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.wp(75),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.gapSmall,
        vertical: context.gapSmall,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF2F2F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.bodySmall,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _RatingWidget extends StatelessWidget {
  final int rating;

  const _RatingWidget({
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
            (index) => Padding(
          padding: EdgeInsets.only(left: context.gapSmall / 3),
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: context.iconSmall,
          ),
        ),
      ),
    );
  }
}

class HotelModel {
  final String image;
  final String hotelName;
  final String address;
  final String price;
  final String taxes;
  final int rating;
  final String roomInfo;
  final String description;
  final List<String> features;

  HotelModel({
    required this.image,
    required this.hotelName,
    required this.address,
    required this.price,
    required this.taxes,
    required this.rating,
    required this.roomInfo,
    required this.description,
    required this.features,
  });
}