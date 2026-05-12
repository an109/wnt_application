import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/logo.dart';
import '../../Hotel_api/domain/entities/hotel_ui_entity.dart';
import '../../Hotel_api/presentation/bloc/hotel_bloc.dart';
import '../../Hotel_api/presentation/bloc/hotel_event.dart';
import '../../Hotel_api/presentation/bloc/hotel_state.dart';
import '../Filter_drawer/filter_drawer.dart';

class HotelListingScreen extends StatefulWidget {
  final String cityCode;
  final String checkIn;
  final String checkOut;
  final String guestNationality;
  final Map<String, dynamic>? filters;
  final List<Map<String, dynamic>>? paxRooms;

  const HotelListingScreen({
    super.key,
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
    required this.guestNationality,
    this.filters,
    this.paxRooms,
  });

  @override
  State<HotelListingScreen> createState() => _HotelListingScreenState();
}

class _HotelListingScreenState extends State<HotelListingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFilterApplied = false;

  // Local state to maintain hotel list and prevent flickering
  List<HotelUiModel> _displayedHotels = [];
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialHotels();
  }

  void _loadInitialHotels() {
    setState(() {
      _displayedHotels = [];
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isInitialLoading = true;
    });

    context.read<HotelBloc>().add(
      LoadHotelsEvent(
        cityCode: widget.cityCode,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        guestNationality: widget.guestNationality,
        page: 1,
        pageSize: 20,
        filters: widget.filters,
        paxRooms: widget.paxRooms,
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {

      if (!_isLoadingMore && !_hasReachedMax && _displayedHotels.isNotEmpty) {
        setState(() => _isLoadingMore = true);

        final blocState = context.read<HotelBloc>().state;
        int nextPage = 2;
        if (blocState is HotelLoaded) {
          nextPage = blocState.currentPage + 1;
        }

        context.read<HotelBloc>().add(
          LoadMoreHotelsEvent(
            cityCode: widget.cityCode,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            guestNationality: widget.guestNationality,
            nextPage: nextPage,
            pageSize: 20,
            filters: widget.filters,
            paxRooms: widget.paxRooms,
          ),
        );
      }
    }
  }

  void _onRefresh() async {
    setState(() {
      _isLoadingMore = false;
    });

    context.read<HotelBloc>().add(
      RefreshHotelsEvent(
        cityCode: widget.cityCode,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        guestNationality: widget.guestNationality,
        filters: widget.filters,
        paxRooms: widget.paxRooms,
      ),
    );
  }

  void _applyFilters(Map<String, dynamic> newFilters) {
    setState(() {
      _isFilterApplied = true;
      _displayedHotels = [];
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isInitialLoading = true;
    });

    context.read<HotelBloc>().add(
      LoadHotelsEvent(
        cityCode: widget.cityCode,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        guestNationality: widget.guestNationality,
        page: 1,
        pageSize: 20,
        filters: newFilters,
        paxRooms: widget.paxRooms,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _isFilterApplied = false;
      _displayedHotels = [];
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isInitialLoading = true;
    });
    _loadInitialHotels();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HotelFilterDrawer(
        onFiltersApplied: _applyFilters,
        onClearFilters: _clearFilters,
        isFilterApplied: _isFilterApplied,
      ),
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "assets/images/wander_nova_logo.jpg",
              height: 35,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.hotel, size: 35),
            ),
          )
        ],
      ),
      backgroundColor: const Color(0xffF5F5F5),
      body: BlocListener<HotelBloc, HotelState>(
        listener: (context, state) {
          if (state is HotelError) {
            if (_displayedHotels.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            setState(() {
              _isLoadingMore = false;
              _isInitialLoading = false;
            });
          }

          if (state is HotelLoaded) {
            final newHotels = state.hotels
                .map((entity) => HotelUiModel.fromEntity(entity))
                .toList();

            setState(() {
              if (state.currentPage == 1) {
                _displayedHotels = newHotels;
              } else {
                _displayedHotels = [..._displayedHotels, ...newHotels];
              }
              _hasReachedMax = state.hasReachedMax;
              _isLoadingMore = false;
              _isInitialLoading = false;
            });
          }

          if (state is HotelLoading && state is! HotelLoadMoreLoading) {
            if (_displayedHotels.isEmpty) {
              setState(() {
                _isInitialLoading = true;
              });
            }
          }
        },
        child: _buildHotelList(),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
      floatingActionButton: _buildFilterBadge(),
    );
  }

  Widget _buildHotelList() {
    if (_displayedHotels.isEmpty && _isInitialLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: context.gapMedium),
            Text(
              'Finding best hotels for you...',
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_displayedHotels.isEmpty && !_isInitialLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _onRefresh(),
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        key: const ValueKey('hotel_list'),
        controller: _scrollController,
        physics: context.scrollPhysics,
        padding: context.horizontalPadding.copyWith(
          top: context.gapMedium,
          bottom: context.gapLarge + context.buttonHeight + context.gapLarge,
        ),
        itemCount: _displayedHotels.length + (_hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= _displayedHotels.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: context.gapMedium),
              child: Center(
                child: _isLoadingMore
                    ? SizedBox(
                  height: context.iconMedium,
                  width: context.iconMedium,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            );
          }
          return HotelCard(hotel: _displayedHotels[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: context.horizontalPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel_outlined,
              size: context.iconLarge * 2,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: context.gapLarge),
            Text(
              'No hotels found',
              style: TextStyle(
                fontSize: context.titleLarge,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: context.gapSmall),
            Text(
              'Try adjusting your filters or search criteria',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: context.gapLarge),
            SizedBox(
              width: context.buttonWidth,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius),
                  ),
                ),
                onPressed: _clearFilters,
                child: Text(
                  'Clear Filters',
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFilterBadge() {
    if (!_isFilterApplied) return null;

    return FloatingActionButton.small(
      onPressed: _clearFilters,
      backgroundColor: Theme.of(context).primaryColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt, size: context.iconSmall, color: Colors.white),
          if (_isFilterApplied)
            Container(
              margin: EdgeInsets.only(top: context.gapSmall / 4),
              padding: EdgeInsets.symmetric(
                horizontal: context.gapSmall / 2,
                vertical: context.gapSmall / 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '1',
                style: TextStyle(
                  fontSize: context.labelSmall,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HotelCard extends StatelessWidget {
  final HotelUiModel hotel;

  const HotelCard({
    super.key,
    required this.hotel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapLarge),
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
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(context.borderRadius),
              topRight: Radius.circular(context.borderRadius),
            ),
            child: AspectRatio(
              aspectRatio: context.isTablet ? 2.2 : 1.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    hotel.image,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.hotel,
                          size: context.iconLarge,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                  if (!hotel.isRefundable)
                    Positioned(
                      top: context.gapMedium,
                      left: context.gapMedium,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.gapSmall,
                          vertical: context.gapSmall / 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.red.withOpacity(.9),
                        ),
                        child: Text(
                          'Non-refundable',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.labelSmall,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(context.gapMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        '${hotel.cityName}, ${hotel.countryName}',
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.gapMedium),

                Row(
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      size: context.iconSmall,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: context.gapSmall),
                    Expanded(
                      child: Text(
                        hotel.roomInfo,
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // SizedBox(height: context.gapSmall),

                if (hotel.mealType.isNotEmpty && hotel.mealType != 'Room_Only')
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.gapSmall,
                      vertical: context.gapSmall / 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.green.withOpacity(.1),
                    ),
                    child: Text(
                      hotel.mealType.replaceAll('_', ' '),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: context.labelSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // SizedBox(height: context.gapMedium),

                // Text(
                //   hotel.description,
                //   maxLines: 3,
                //   overflow: TextOverflow.ellipsis,
                //   style: TextStyle(
                //     height: 1.4,
                //     fontSize: context.bodyMedium,
                //     color: Colors.grey.shade800,
                //   ),
                // ),

                SizedBox(height: context.gapLarge),

                context.isTablet || context.isDesktop
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _PriceSection(hotel: hotel)),
                    SizedBox(width: context.gapLarge),
                    Expanded(child: _ButtonsSection(hotel: hotel)),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PriceSection(hotel: hotel),
                    SizedBox(height: context.gapMedium),
                    _ButtonsSection(hotel: hotel),
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
  final HotelUiModel hotel;

  const _ButtonsSection({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: context.buttonHeight + 6,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadius),
              ),
            ),
            onPressed: () {
              // Navigate to room selection
            },
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

      ],
    );
  }
}

class _PriceSection extends StatelessWidget {
  final HotelUiModel hotel;

  const _PriceSection({required this.hotel});

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
                color: Colors.black,
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
                color: Colors.grey.shade800,
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

class _RatingWidget extends StatelessWidget {
  final int rating;

  const _RatingWidget({required this.rating});

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