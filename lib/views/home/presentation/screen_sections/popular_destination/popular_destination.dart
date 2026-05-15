import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'destination_card.dart';

class PopularDestinations extends StatefulWidget {
  const PopularDestinations({super.key});

  @override
  State<PopularDestinations> createState() => _PopularDestinationsState();
}

class _PopularDestinationsState extends State<PopularDestinations> {
  int _selectedFilterIndex = 0; // 0: All, 1: Domestic, 2: International
  int _currentPage = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  // Filter options
  final List<String> _filterOptions = ['All', 'Domestic', 'International'];

  // Sample destination data with location type
  final List<Map<String, dynamic>> _allDestinations = [
    {
      'title': 'Dubai',
      'subtitle': 'City of Gold',
      'description': 'Experience luxury shopping, ultramodern architecture, and vibrant nightlife',
      'price': '₹45,000',
      'rating': 4.8,
      'reviews': 12450,
      'imageUrl': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400',
      'color': Colors.orange,
      'tag': 'Trending',
      'duration': '5 Nights',
      'type': 'international', // International destination
      'country': 'UAE',
    },
    {
      'title': 'Bali',
      'subtitle': 'Island of Gods',
      'description': 'Tropical paradise with beautiful beaches, temples, and rice terraces',
      'price': '₹35,000',
      'rating': 4.9,
      'reviews': 18750,
      'imageUrl': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400',
      'color': Colors.green,
      'tag': 'Best Seller',
      'duration': '4 Nights',
      'type': 'international',
      'country': 'Indonesia',
    },
    {
      'title': 'Switzerland',
      'subtitle': 'Alpine Wonderland',
      'description': 'Majestic mountains, scenic train rides, and picturesque villages',
      'price': '₹85,000',
      'rating': 4.9,
      'reviews': 15680,
      'imageUrl': 'https://images.unsplash.com/photo-1530122037265-a6f1f0534e1e?w=400',
      'color': Colors.blue,
      'tag': 'Luxury',
      'duration': '6 Nights',
      'type': 'international',
      'country': 'Switzerland',
    },
    {
      'title': 'Thailand',
      'subtitle': 'Land of Smiles',
      'description': 'Beautiful beaches, rich culture, and amazing street food',
      'price': '₹28,000',
      'rating': 4.7,
      'reviews': 22340,
      'imageUrl': 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=400',
      'color': Colors.red,
      'tag': 'Budget',
      'duration': '4 Nights',
      'type': 'international',
      'country': 'Thailand',
    },
    {
      'title': 'Paris',
      'subtitle': 'City of Love',
      'description': 'Romantic streets, world-class art, and iconic landmarks',
      'price': '₹65,000',
      'rating': 4.8,
      'reviews': 18920,
      'imageUrl': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400',
      'color': Colors.pink,
      'tag': 'Romantic',
      'duration': '5 Nights',
      'type': 'international',
      'country': 'France',
    },
    {
      'title': 'Maldives',
      'subtitle': 'Tropical Paradise',
      'description': 'Overwater bungalows, crystal clear waters, and coral reefs',
      'price': '₹95,000',
      'rating': 4.9,
      'reviews': 14320,
      'imageUrl': 'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=400',
      'color': Colors.teal,
      'tag': 'Honeymoon',
      'duration': '4 Nights',
      'type': 'international',
      'country': 'Maldives',
    },
    {
      'title': 'Singapore',
      'subtitle': 'Garden City',
      'description': 'Modern metropolis with gardens, shopping, and diverse cuisine',
      'price': '₹55,000',
      'rating': 4.7,
      'reviews': 16780,
      'imageUrl': 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400',
      'color': Colors.purple,
      'tag': 'Family',
      'duration': '4 Nights',
      'type': 'international',
      'country': 'Singapore',
    },
    {
      'title': 'Vietnam',
      'subtitle': 'Timeless Charm',
      'description': 'Stunning landscapes, rich history, and delicious cuisine',
      'price': '₹32,000',
      'rating': 4.6,
      'reviews': 11230,
      'imageUrl': 'https://images.unsplash.com/photo-1543359341-73153c4a59bd?w=400',
      'color': Colors.brown,
      'tag': 'Adventure',
      'duration': '5 Nights',
      'type': 'international',
      'country': 'Vietnam',
    },
    // Domestic Destinations (India)
    {
      'title': 'Goa',
      'subtitle': 'Beach Paradise',
      'description': 'Beautiful beaches, vibrant nightlife, and Portuguese architecture',
      'price': '₹15,000',
      'rating': 4.7,
      'reviews': 25680,
      'imageUrl': 'https://images.unsplash.com/photo-1512343879784-960f40e1ff5f?w=400',
      'color': Colors.cyan,
      'tag': 'Trending',
      'duration': '3 Nights',
      'type': 'domestic',
      'country': 'India',
      'state': 'Goa',
    },
    {
      'title': 'Manali',
      'subtitle': 'Mountain Retreat',
      'description': 'Snow-capped mountains, adventure sports, and scenic valleys',
      'price': '₹12,000',
      'rating': 4.8,
      'reviews': 18940,
      'imageUrl': 'https://images.unsplash.com/photo-1583611588604-3e3d6c3e0e8a?w=400',
      'color': Colors.indigo,
      'tag': 'Adventure',
      'duration': '4 Nights',
      'type': 'domestic',
      'country': 'India',
      'state': 'Himachal Pradesh',
    },
    {
      'title': 'Kerala',
      'subtitle': 'God\'s Own Country',
      'description': 'Backwaters, lush greenery, ayurvedic treatments, and houseboats',
      'price': '₹18,000',
      'rating': 4.9,
      'reviews': 22350,
      'imageUrl': 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=400',
      'color': Colors.green,
      'tag': 'Best Seller',
      'duration': '4 Nights',
      'type': 'domestic',
      'country': 'India',
      'state': 'Kerala',
    },
    {
      'title': 'Jaipur',
      'subtitle': 'Pink City',
      'description': 'Royal palaces, colorful markets, and rich Rajput heritage',
      'price': '₹10,000',
      'rating': 4.6,
      'reviews': 15670,
      'imageUrl': 'https://images.unsplash.com/photo-1599661046827-dacff0c0f09c?w=400',
      'color': Colors.pink,
      'tag': 'Cultural',
      'duration': '3 Nights',
      'type': 'domestic',
      'country': 'India',
      'state': 'Rajasthan',
    },
    {
      'title': 'Varanasi',
      'subtitle': 'Spiritual Capital',
      'description': 'Ancient temples, Ganga aarti, and spiritual experiences',
      'price': '₹8,000',
      'rating': 4.5,
      'reviews': 12430,
      'imageUrl': 'https://images.unsplash.com/photo-1561361058-c24ce9ddde0f?w=400',
      'color': Colors.orange,
      'tag': 'Spiritual',
      'duration': '3 Nights',
      'type': 'domestic',
      'country': 'India',
      'state': 'Uttar Pradesh',
    },
    {
      'title': 'Darjeeling',
      'subtitle': 'Queen of Hills',
      'description': 'Tea gardens, Himalayan views, and toy train rides',
      'price': '₹11,000',
      'rating': 4.7,
      'reviews': 9870,
      'imageUrl': 'https://images.unsplash.com/photo-1587472586893-73a07d9f2a59?w=400',
      'color': Colors.brown,
      'tag': 'Scenic',
      'duration': '4 Nights',
      'type': 'domestic',
      'country': 'India',
      'state': 'West Bengal',
    },
    {
      'title': 'Udaipur',
      'subtitle': 'City of Lakes',
      'description': 'Romantic lakes, magnificent palaces, and sunset views',
      'price': '₹14,000',
      'rating': 4.8,
      'reviews': 14320,
      'imageUrl': 'https://images.unsplash.com/photo-1558507652-2d9626c4e67a?w=400',
      'color': Colors.blue,
      'tag': 'Romantic',
      'duration': '3 Nights',
      'type': 'domestic',
      'country': 'India',
      'state': 'Rajasthan',
    },
    {
      'title': 'Munnar',
      'subtitle': 'Tea Garden Paradise',
      'description': 'Rolling tea estates, misty mountains, and wildlife',
      'price': '₹13,000',
      'rating': 4.8,
      'reviews': 11280,
      'imageUrl': 'https://images.unsplash.com/photo-1586007573616-6b0cb5de3bd6?w=400',
      'color': Colors.green,
      'tag': 'Nature',
      'duration': '4 Nights',
      'type': 'domestic',
      'country': 'India',
      'state': 'Kerala',
    },
  ];

  // Get filtered destinations based on selected filter
  List<Map<String, dynamic>> get _filteredDestinations {
    switch (_selectedFilterIndex) {
      case 1: // Domestic
        return _allDestinations.where((dest) => dest['type'] == 'domestic').toList();
      case 2: // International
        return _allDestinations.where((dest) => dest['type'] == 'international').toList();
      default: // All
        return _allDestinations;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section with Title and View All
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(1)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Popular Destinations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: context.gapSmall / 2),
                  Text(
                    'Handpicked destinations just for you',
                    style: TextStyle(
                      fontSize: context.bodySmall,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  _showAllDestinations();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: context.bodySmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: context.gapSmall / 2),
                    Icon(Icons.arrow_forward, size: context.iconSmall),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Filter Tabs (All, Domestic, International)
        Container(
          height: context.hp(6),
          margin: EdgeInsets.only(bottom: context.hp(1.5)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.wp(3)),
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilterIndex == index;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: context.wp(1)),
                child: FilterChip(
                  label: Text(_filterOptions[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilterIndex = index;
                      _currentPage = 0; // Reset to first page when filter changes
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: _getFilterColor(index).withOpacity(0.1),
                  checkmarkColor: _getFilterColor(index),
                  labelStyle: TextStyle(
                    color: isSelected ? _getFilterColor(index) : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected ? _getFilterColor(index) : Colors.grey[300]!,
                    ),
                  ),
                  avatar: _selectedFilterIndex == index ? _getFilterIcon(index) : null,
                ),
              );
            },
          ),
        ),

        // Show message if no destinations found
        if (_filteredDestinations.isEmpty)
          Container(
            height: context.hp(50),
            margin: EdgeInsets.all(context.wp(4)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: context.iconLarge * 2,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No destinations found',
                    style: TextStyle(
                      fontSize: context.titleSmall,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try changing the filter',
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              // Destination Card Carousel
              SizedBox(
                height: context.cardHeight,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _filteredDestinations.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
                      child: DestinationCard(
                        destination: _filteredDestinations[index],
                        onViewDetail: () {
                          _showDestinationDetail(_filteredDestinations[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              // Page Indicator Dots
              if (_filteredDestinations.length > 1)
                Container(
                  padding: EdgeInsets.symmetric(vertical: context.hp(1.5)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _filteredDestinations.length; i++)
                        Container(
                          width: context.isMobile ? 8 : 10,
                          height: context.isMobile ? 8 : 10,
                          margin: EdgeInsets.symmetric(horizontal: context.wp(1)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == i
                                ? Colors.blue
                                : Colors.grey[300],
                          ),
                        ),
                    ],
                  ),
                ),

            ],
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  Color _getFilterColor(int index) {
    switch (index) {
      case 1:
        return Colors.green; // Domestic
      case 2:
        return Colors.purple; // International
      default:
        return Colors.blue; // All
    }
  }

  Widget? _getFilterIcon(int index) {
    switch (index) {
      case 1:
        return const Icon(Icons.home, size: 16, color: Colors.green);
      case 2:
        return const Icon(Icons.flight, size: 16, color: Colors.purple);
      default:
        return const Icon(Icons.public, size: 16, color: Colors.blue);
    }
  }

  void _showAllDestinations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('View all destinations - Coming Soon!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDestinationDetail(Map<String, dynamic> destination) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DestinationDetailSheet(destination: destination),
    );
  }
}

// Bottom Sheet for Destination Details
class DestinationDetailSheet extends StatelessWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailSheet({super.key, required this.destination});

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

          // Destination Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              destination['imageUrl'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: destination['color'].withOpacity(0.2),
                  child: Icon(
                    Icons.location_city,
                    size: 80,
                    color: destination['color'],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Title and Rating
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            destination['title'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: destination['type'] == 'domestic'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  destination['type'] == 'domestic'
                                      ? Icons.home
                                      : Icons.flight,
                                  size: 12,
                                  color: destination['type'] == 'domestic'
                                      ? Colors.green
                                      : Colors.purple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  destination['type'] == 'domestic' ? 'Domestic' : 'International',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: destination['type'] == 'domestic'
                                        ? Colors.green
                                        : Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        destination['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${destination['rating']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${destination['reviews']})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Location and Duration Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        destination['country'],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (destination.containsKey('state'))
                        Text(
                          ', ${destination['state']}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        destination['duration'],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        destination['tag'],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              destination['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
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
                    Text(
                      'Starting from',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      destination['price'],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: destination['color'],
                      ),
                    ),
                    Text(
                      'per person',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking ${destination['title']} trip!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: destination['color'],
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