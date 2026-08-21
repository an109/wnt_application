import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
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
  final List<String> _filterOptions = ['All', 'Domestic', 'International'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PopularDestinationBloc>().add(
          const FetchPopularDestinations(),
        );
      }
    });
  }

  List<DestinationEntity> _getFilteredDestinations(
      List<DestinationEntity> allDestinations,
      ) {
    if (_selectedFilterIndex == 0) {
      return allDestinations;
    } else if (_selectedFilterIndex == 1) {
      return allDestinations
          .where((dest) => dest.type?.toLowerCase() == 'domestic')
          .toList();
    } else if (_selectedFilterIndex == 2) {
      return allDestinations
          .where((dest) => dest.type?.toLowerCase() == 'international')
          .toList();
    }
    return allDestinations;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular Destination',
                style: TextStyle(
                  fontSize: context.fs(24),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: context.h(4)),
              Text(
                'Travel to the Most Loved Destinations',
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: context.h(16)),

        // Filter Tabs and View All - Row Layout
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Row(
            children: [
              // Filter Pills
              Expanded(
                child: SizedBox(
                  height: context.h(30),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterOptions.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(width: context.w(12)),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedFilterIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                            context.w(8),
                            context.h(4),
                            context.w(8),
                            context.h(4),
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xff005B7F)
                                  : Colors.grey.shade300,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(context.r(6)),
                            color: isSelected
                                ? const Color(0xff005B7F).withOpacity(0.05)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              _filterOptions[index].toUpperCase(),
                              style: TextStyle(
                                fontSize: context.fs(12),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xff005B7F)
                                    : Colors.grey.shade700,
                                letterSpacing: 0.8
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // View All Link
              SizedBox(width: context.w(16)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HolidaysScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w400,
                        color: AppColors.AppBlue,
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(
                      Icons.arrow_forward,
                      size: context.iconSmall,
                      color: AppColors.AppBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: context.h(20)),

        // Destinations Carousel
        BlocBuilder<PopularDestinationBloc, PopularDestinationState>(
          builder: (context, state) {
            if (state is PopularDestinationLoading) {
              return _buildLoadingCarousel(context);
            } else if (state is PopularDestinationLoaded) {
              final filteredDestinations = _getFilteredDestinations(
                state.destinations,
              );

              if (filteredDestinations.isEmpty) {
                return const SizedBox.shrink();
              }

              return _buildDestinationsContent(context, filteredDestinations);
            } else if (state is PopularDestinationError) {
              return _buildErrorState(context, state.message);
            }
            return const SizedBox.shrink();
          },
        ),

        SizedBox(height: context.h(32)),
      ],
    );
  }

  Widget _buildLoadingCarousel(BuildContext context) {
    return SizedBox(
      height: context.h(304),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
        itemCount: 3,
        separatorBuilder: (context, index) => SizedBox(width: context.w(16)),
        itemBuilder: (context, index) {
          return Container(
            width: context.w(260),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.r(16)),
              color: Colors.grey.shade200,
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: const Color(0xff005B7F),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Container(
      height: context.h(200),
      margin: EdgeInsets.symmetric(horizontal: context.wp(4)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(16)),
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: context.w(48),
              color: Colors.red.shade700,
            ),
            SizedBox(height: context.h(12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(14),
                color: Colors.red.shade700,
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
    return SizedBox(
      height: context.h(280),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
        itemCount: destinations.length,
        separatorBuilder: (context, index) => SizedBox(width: context.w(16)),
        itemBuilder: (context, index) {
          final destination = destinations[index];
          return _buildDestinationCard(context, destination);
        },
      ),
    );
  }

  Widget _buildDestinationCard(
      BuildContext context,
      DestinationEntity destination,
      ) {
    return GestureDetector(
      onTap: () {
        _showDestinationDetail(destination);
      },
      child: Container(
        width: context.w(210),
        height: context.h(220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Full Image
            ClipRRect(
              borderRadius: BorderRadius.circular(context.r(12)),
              child: SizedBox(
                height: context.h(304),
                width: double.infinity,
                child: destination.imageUrl.isNotEmpty
                    ? Image.network(
                  destination.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.location_city,
                        size: context.w(48),
                        color: Colors.grey.shade600,
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.location_city,
                    size: context.w(48),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.r(12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Heart Icon
            Positioned(
              top: context.h(15),
              right: context.w(15),
              child: Container(
                width: context.w(25),
                height: context.h(25),
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
                  'assets/NewIcons/heartHD.png',
                  width: context.w(18),
                  height: context.h(18),
                ),
              ),
            ),
            // Content Overlay at Bottom
            Positioned(
              left: context.w(16),
              right: context.w(16),
              bottom: context.h(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Destination Name
                  Text(
                    destination.name,
                    style: TextStyle(
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.h(4)),
                  // Description
                  Text(
                    destination.description.isNotEmpty
                        ? destination.description
                        : 'Experience luxury, adventure, and iconic landmarks',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.h(12)),
                  // Price and View All
                  Text(
                    destination.price.isNotEmpty
                        ? destination.price
                        : '',
                    style: TextStyle(
                      fontSize: context.fs(16),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: context.h(12)),
                  Row(
                    children: [
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xffFF6600),
                        ),
                      ),
                      SizedBox(width: context.w(4)),
                      Icon(
                        Icons.arrow_forward,
                        size: context.w(14),
                        color: const Color(0xffFF6B00),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDestinationDetail(DestinationEntity destination) {
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.r(24)),
          topRight: Radius.circular(context.r(24)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            child: destination.imageUrl.isNotEmpty
                ? Image.network(
              destination.imageUrl,
              height: context.h(200),
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(
              height: context.h(200),
              color: Colors.grey.shade300,
              child: Icon(Icons.location_city, size: context.w(80)),
            ),
          ),
          SizedBox(height: context.h(16)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  style: TextStyle(
                    fontSize: context.fs(24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.h(8)),
                Text(
                  destination.country,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: context.h(16)),
                Text(
                  destination.description.isNotEmpty
                      ? destination.description
                      : destination.longDescription,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: context.h(20)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting from',
                          style: TextStyle(
                            fontSize: context.fs(12),
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          destination.price.isNotEmpty
                              ? destination.price.split('/')[0].trim()
                              : 'Contact for price',
                          style: TextStyle(
                            fontSize: context.fs(28),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff005B7F),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff005B7F),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(32),
                          vertical: context.h(16),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(30)),
                        ),
                      ),
                      child: Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: context.fs(16),
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(20)),
        ],
      ),
    );
  }
}
