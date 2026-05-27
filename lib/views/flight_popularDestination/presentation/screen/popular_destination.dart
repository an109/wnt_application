import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/flight_popularDestination/presentation/widget/destination_card.dart';
import 'package:wander_nova/views/home/flight/flight_screen.dart';

import '../../../Holidays/presentation/screen/holidays_screen.dart';
import '../../domain/entities/Popular_destination_entity.dart';
import '../bloc/destination_bloc.dart';
import '../bloc/destination_event.dart';
import '../bloc/destination_state.dart';

class PopularDestinations extends StatefulWidget {
  const PopularDestinations({super.key});

  @override
  State<PopularDestinations> createState() => _PopularDestinationsState();
}

class _PopularDestinationsState extends State<PopularDestinations> {
  int _selectedFilterIndex = 0;
  int _currentPage = 0;
  PageController? _pageController;
  final List<String> _filterOptions = ['All', 'Domestic', 'International'];

  @override
  void initState() {
    super.initState();
    print('PopularDestinations: initState called');
    _pageController = PageController(viewportFraction: 0.85);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print(
          'PopularDestinations: Dispatching FetchPopularDestinations event',
        );
        context.read<PopularDestinationBloc>().add(
          const FetchPopularDestinations(),
        );
      }
    });
  }

  @override
  void dispose() {
    print('PopularDestinations: dispose called');
    _pageController?.dispose();
    super.dispose();
  }

  String _getFilterType(int index) {
    switch (index) {
      case 1:
        return 'domestic';
      case 2:
        return 'international';
      default:
        return 'all';
    }
  }

  Color _getFilterColor(int index) {
    switch (index) {
      case 1:
        return const Color(0xff4CAF50);
      case 2:
        return const Color(0xff9C27B0);
      default:
        return const Color(0xff005B7F);
    }
  }

  List<DestinationEntity> _getFilteredDestinations(
    List<DestinationEntity> allDestinations,
  ) {
    print(
      'PopularDestinations: Filtering - selectedFilter: $_selectedFilterIndex, total: ${allDestinations.length}',
    );

    if (_selectedFilterIndex == 0) {
      print('PopularDestinations: All filter applied');
      return allDestinations;
    } else if (_selectedFilterIndex == 1) {
      final filtered = allDestinations
          .where((dest) => dest.type?.toLowerCase() == 'domestic')
          .toList();
      print(
        'PopularDestinations: Domestic filter - ${filtered.length} results',
      );
      return filtered;
    } else if (_selectedFilterIndex == 2) {
      final filtered = allDestinations
          .where((dest) => dest.type?.toLowerCase() == 'international')
          .toList();
      print(
        'PopularDestinations: International filter - ${filtered.length} results',
      );
      return filtered;
    }
    return allDestinations;
  }

  void _safeAnimateToPage(int page) {
    if (_pageController != null && _pageController!.hasClients) {
      _pageController!.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.wp(4),
            vertical: context.hp(1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Popular Destinations',
                    style: TextStyle(
                      fontSize: context.titleLarge,
                      fontWeight: FontWeight.w700,
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
                  print(
                    'PopularDestinations: View All tapped, navigating to HolidaysScreen',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HolidaysScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff005B7F),
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

        // Filter Tabs - Redesigned like reference screen
        SizedBox(
          height: context.hp(6),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.wp(3)),
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilterIndex == index;
              return GestureDetector(
                onTap: () {
                  print(
                    'PopularDestinations: Filter tapped - ${_filterOptions[index]}',
                  );
                  setState(() {
                    _selectedFilterIndex = index;
                    _currentPage = 0;
                    // _safeAnimateToPage(0);
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted &&
                        _pageController != null &&
                        _pageController!.hasClients) {
                      _safeAnimateToPage(0);
                    }
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: context.gapLarge),
                  child: Column(
                    children: [
                      Text(
                        _filterOptions[index],
                        style: TextStyle(
                          fontSize: context.bodyLarge,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? _getFilterColor(index)
                              : Colors.black54,
                        ),
                      ),
                      SizedBox(height: context.gapSmall),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: context.dividerMedium,
                        width: context.wp(17),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getFilterColor(index)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Divider(color: Colors.grey.shade300, thickness: context.dividerThin),
        SizedBox(height: context.gapMedium),

        // BLOC BUILDER
        BlocBuilder<PopularDestinationBloc, PopularDestinationState>(
          builder: (context, state) {
            print('PopularDestinations: Bloc state - ${state.runtimeType}');

            if (state is PopularDestinationLoading) {
              print('PopularDestinations: Loading state');
              return _buildLoadingCarousel(context);
            } else if (state is PopularDestinationLoaded) {
              final filteredDestinations = _getFilteredDestinations(
                state.destinations,
              );

              // KEY: If empty, hide section completely - no whitespace
              if (filteredDestinations.isEmpty) {
                print(
                  'PopularDestinations: No destinations after filtering, hiding section',
                );
                return const SizedBox.shrink();
              }

              return _buildDestinationsContent(context, filteredDestinations);
            } else if (state is PopularDestinationError) {
              print('PopularDestinations: Error state - ${state.message}');
              return _buildErrorState(context, state.message);
            }
            return const SizedBox.shrink();
          },
        ),

        // Page Indicator - Only show when loaded with data
        BlocBuilder<PopularDestinationBloc, PopularDestinationState>(
          builder: (context, state) {
            if (state is PopularDestinationLoaded) {
              final filteredDestinations = _getFilteredDestinations(
                state.destinations,
              );
              if (filteredDestinations.isEmpty) return const SizedBox.shrink();

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  filteredDestinations.length > 5
                      ? 5
                      : filteredDestinations.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(
                      horizontal: context.gapSmall / 2,
                    ),
                    width: _currentPage == index ? context.wp(5.5) : context.wp(2),
                    height: context.hp(1), // 8px on 800px
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                      color: _currentPage == index
                          ? const Color(0xff005B7F)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        SizedBox(height: context.gapLarge),
      ],
    );
  }

  Widget _buildLoadingCarousel(BuildContext context) {
    print('PopularDestinations: Building loading carousel');
    return SizedBox(
      height: context.cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
            child: Container(
              width: context.wp(85),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.borderRadius),
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  height: context.hp(5), // 40px on 800px
                  width: context.hp(5),
                  child: CircularProgressIndicator(
                    color: const Color(0xff005B7F),
                    strokeWidth: context.dividerMedium,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    print('PopularDestinations: Building error state - $message');
    return Container(
      height: context.hp(35),
      margin: EdgeInsets.all(context.wp(4)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: context.iconLarge,
              color: Colors.red.shade700,
            ),
            SizedBox(height: context.gapSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: context.gapMedium),
            ElevatedButton(
              onPressed: () {
                print('PopularDestinations: Retry button tapped');
                context.read<PopularDestinationBloc>().add(
                  const FetchPopularDestinations(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff005B7F),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.gapLarge,
                  vertical: context.gapSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontSize: context.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationsContent(
    BuildContext context,
    List<DestinationEntity> destinations,
  ) {
    print(
      'PopularDestinations: Building carousel with ${destinations.length} items',
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: context.cardHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) setState(() => _currentPage = index);
            },
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final destination = destinations[index];
              print(
                'PopularDestinations: Building card for ${destination.name}',
              );
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
                child: DestinationCard(
                  destination: destination,
                  onViewDetail: () {
                    print(
                      'PopularDestinations: Card tapped for ${destination.name}',
                    );
                    _showDestinationDetail(destination);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDestinationDetail(DestinationEntity destination) {
    print('PopularDestinations: Showing detail for ${destination.name}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DestinationDetailSheet(destination: destination),
    );
  }
}

// Bottom Sheet for Destination Details
class _DestinationDetailSheet extends StatelessWidget {
  final DestinationEntity destination;

  const _DestinationDetailSheet({required this.destination});

  @override
  Widget build(BuildContext context) {
    print('DestinationDetailSheet: Building for ${destination.name}');

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
          ClipRRect(
            // borderRadius: BorderRadius.circular(16),
            child: destination.imageUrl.isNotEmpty
                ? Image.network(
                    destination.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print(
                        'DestinationDetailSheet: Image load error for ${destination.imageUrl}',
                      );
                      return _buildPlaceholderImage(context);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xff005B7F),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                : _buildPlaceholderImage(context),
          ),

          const SizedBox(height: 16),

          // Title and Type Badge
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
                            destination.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  destination.type?.toLowerCase() == 'domestic'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  destination.type?.toLowerCase() == 'domestic'
                                      ? Icons.home
                                      : Icons.flight,
                                  size: 12,
                                  color:
                                      destination.type?.toLowerCase() ==
                                          'domestic'
                                      ? Colors.green
                                      : Colors.purple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  destination.type?.toLowerCase() == 'domestic'
                                      ? 'Domestic'
                                      : 'International',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        destination.type?.toLowerCase() ==
                                            'domestic'
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
                        destination.tagline.isNotEmpty
                            ? destination.tagline
                            : destination.country,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Location Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        destination.country,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (destination.state?.isNotEmpty == true)
                        Text(
                          ', ${destination.state}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
              destination.description.isNotEmpty
                  ? destination.description
                  : destination.longDescription,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
                        color: Colors.grey.shade600,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: destination.price.isNotEmpty
                                ? destination.price.split('/')[0].trim()
                                : 'Contact for price',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff005B7F),
                            ),
                          ),
                          if (destination.price.contains('/'))
                            TextSpan(
                              text: '\n${destination.price.split('/')[1].trim()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    print(
                      'DestinationDetailSheet: Book Now tapped for ${destination.name}',
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking ${destination.name} trip!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff005B7F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HolidaysScreen()));
                    },
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      height: 200,
      color: const Color(0xff005B7F).withOpacity(0.2),
      child: Icon(
        Icons.location_city,
        size: 80,
        color: const Color(0xff005B7F),
      ),
    );
  }
}
