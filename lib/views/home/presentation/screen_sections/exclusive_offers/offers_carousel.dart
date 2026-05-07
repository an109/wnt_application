import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _selectedTabIndex = 0;
  int _currentCarouselIndex = 0;

  final List<String> _filterTabs = ['All', 'Flights', 'Hotels', 'Buses', 'Trains'];

  // Sample offer data
  final List<Map<String, dynamic>> _offers = [
    {
      'title': 'FLAT 20% OFF',
      'subtitle': 'On domestic flights',
      'code': 'FLY20',
      'validTill': '31 Dec 2025',
      'category': 'Flights',
      'color': Colors.orange,
    },
    {
      'title': 'HOTEL DEALS',
      'subtitle': 'Get upto 35% off',
      'code': 'STAY35',
      'validTill': '15 Jan 2026',
      'category': 'Hotels',
      'color': Colors.green,
    },
    {
      'title': 'BUS SPECIAL',
      'title2': 'Save ₹200',
      'subtitle': 'On first bus booking',
      'code': 'BUS200',
      'validTill': '30 Nov 2025',
      'category': 'Buses',
      'color': Colors.purple,
    },
    {
      'title': 'TRAIN OFFER',
      'subtitle': 'Zero payment gateway fee',
      'code': 'TRAINZERO',
      'validTill': '31 Mar 2026',
      'category': 'Trains',
      'color': Colors.red,
    },
    {
      'title': 'WEEKEND GETAWAY',
      'subtitle': 'Save ₹500 on hotel + flight',
      'code': 'WEEKEND500',
      'validTill': '28 Feb 2026',
      'category': 'Flights',
      'color': Colors.teal,
    },
  ];

  List<Map<String, dynamic>> get _filteredOffers {
    if (_selectedTabIndex == 0) {
      return _offers;
    }
    final category = _filterTabs[_selectedTabIndex];
    return _offers.where((offer) => offer['category'] == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and View All Button Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exclusive Offers',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all offers screen
                 print("view all button tapped");
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Filter Tabs
        Container(
          height: 45,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _filterTabs.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedTabIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(_filterTabs[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTabIndex = index;
                      _currentCarouselIndex = 0; // Reset carousel index
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Colors.blue.withOpacity(0.1),
                  checkmarkColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Carousel Slider
        if (_filteredOffers.isNotEmpty)
          CarouselSlider(
            options: CarouselOptions(
              height: 180,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.85,
              autoPlayInterval: const Duration(seconds: 3),
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
            ),
            items: _filteredOffers.map((offer) {
              return _buildOfferCard(offer);
            }).toList(),
          )
        else
          Container(
            height: 180,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No offers available',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Carousel Indicator Dots
        if (_filteredOffers.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _filteredOffers.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentCarouselIndex == i
                          ? Colors.blue
                          : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            offer['color'] as Color,
            (offer['color'] as Color).withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (offer['color'] as Color).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.local_offer,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (offer.containsKey('title2'))
                      Text(
                        offer['title2'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      offer['subtitle'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'CODE: ${offer['code']}',
                        style: TextStyle(
                          color: offer['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'Valid till ${offer['validTill']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tap to copy code overlay
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _copyOfferCode(offer['code']);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyOfferCode(String code) {
    // You can implement actual clipboard copy here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied code: $code'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}