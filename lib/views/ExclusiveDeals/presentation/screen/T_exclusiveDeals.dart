import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/exclusive_deal_entity.dart';
import '../../../../../UI_helper/responsive_layout.dart';
import '../bloc/exclusive_deals_bloc.dart';
import '../bloc/exclusive_deals_event.dart';
import '../bloc/exclusive_deals_state.dart';

class TransportExclusiveDealsSection extends StatefulWidget {
  const TransportExclusiveDealsSection({super.key});

  @override
  State<TransportExclusiveDealsSection> createState() =>
      _TransportExclusiveDealsSectionState();
}

class _TransportExclusiveDealsSectionState
    extends State<TransportExclusiveDealsSection> {
  int selectedTab = 1; // 0=HOT DEAL, 1=FLIGHT, 2=HOTEL, 3=HOLIDAYS
  int currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  // Map tabs to API domain/category filters
  String? _getDomainFilter(int tabIndex) {
    switch (tabIndex) {
      case 0: // HOT DEAL
        return null; // Fetch all hot deals
      case 1: // FLIGHT
        return 'flight';
      case 2: // HOTEL
        return 'hotel';
      case 3: // HOLIDAYS
        return 'holidays';
      default:
        return null;
    }
  }

  List<ExclusiveDealEntity> _filterDealsByCategory(
      List<ExclusiveDealEntity> deals,
      int tabIndex,
      ) {
    if (tabIndex == 0) {
      return deals.where((deal) => deal.isHotDeal).toList();
    }

    final filterMap = {
      1: ['flight'],
      2: ['hotel'],  // Will match if category OR owner_tab contains "hotel"
      3: ['holidays', 'holiday'], // Handle plural/singular
    };

    final filters = filterMap[tabIndex];
    if (filters != null) {
      return deals.where((deal) {
        final category = deal.category.toLowerCase();
        final ownerTab = deal.ownerTab.toLowerCase();

        return filters.any((f) =>
        category.contains(f.toLowerCase()) ||
            ownerTab.contains(f.toLowerCase()));
      }).toList();
    }

    return deals;
  }

  // List<ExclusiveDealEntity> _filterDealsByCategory(
  //     List<ExclusiveDealEntity> deals,
  //     int tabIndex,
  //     ) {
  //   if (tabIndex == 0) {
  //     return deals.where((deal) => deal.isHotDeal).toList();
  //   }
  //   final categoryMap = {
  //     1: 'flight',
  //     2: 'hotel',
  //     3: 'holidays',
  //   };
  //   final category = categoryMap[tabIndex];
  //   if (category != null) {
  //     return deals
  //         .where((deal) =>
  //         deal.category.toLowerCase().contains(category.toLowerCase()))
  //         .toList();
  //   }
  //   return deals;
  // }

  @override
  void initState() {
    super.initState();
    // Load deals when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExclusiveDealsBloc>().add(
          LoadExclusiveDeals(domain: _getDomainFilter(selectedTab)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            "Exclusive Deals",
            style: TextStyle(
              fontSize: context.headlineSmall,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: context.gapLarge),

          /// TABS
          SizedBox(
            height: context.hp(5),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                final isSelected = selectedTab == index;
                final tabs = ["HOT DEAL", "FLIGHT", "HOTEL", "HOLIDAYS"];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTab = index;
                    });
                    // Reload deals with new filter
                    context.read<ExclusiveDealsBloc>().add(
                      LoadExclusiveDeals(domain: _getDomainFilter(index)),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: context.gapLarge),
                    child: Column(
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: context.bodyLarge,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xff005B7F)
                                : Colors.black54,
                          ),
                        ),
                        SizedBox(height: context.gapSmall),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 3,
                          width: context.wp(17),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xff005B7F)
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

          Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),

          SizedBox(height: context.gapMedium),

          /// ARROWS + VIEW ALL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildArrowButton(
                    context,
                    icon: Icons.arrow_back_ios_new,
                    onTap: () {
                      _carouselController.previousPage();
                    },
                  ),
                  SizedBox(width: context.gapMedium),
                  _buildArrowButton(
                    context,
                    icon: Icons.arrow_forward_ios,
                    onTap: () {
                      _carouselController.nextPage();
                    },
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to full deals page
                  debugPrint("View all clicked");
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff005B7F),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.gapLarge),

          /// BLOC BUILDER FOR API DATA
          BlocBuilder<ExclusiveDealsBloc, ExclusiveDealsState>(
            builder: (context, state) {
              if (state is ExclusiveDealsLoading) {
                return _buildLoadingCarousel(context);
              } else if (state is ExclusiveDealsLoaded) {
                final filteredDeals = _filterDealsByCategory(state.deals, selectedTab);

                if (filteredDeals.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _buildDealsCarousel(context, filteredDeals);
              } else if (state is ExclusiveDealsError) {
                return _buildErrorState(context, state.message);
              }
              // return _buildLoadingCarousel(context);
              return const SizedBox.shrink();
            },
          ),

          SizedBox(height: context.gapMedium),

          /// DOTS INDICATOR (only show when deals are loaded)
          BlocBuilder<ExclusiveDealsBloc, ExclusiveDealsState>(
            builder: (context, state) {
              if (state is ExclusiveDealsLoaded) {
                final filteredDeals = _filterDealsByCategory(state.deals, selectedTab);
                if (filteredDeals.isEmpty) return const SizedBox.shrink();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    filteredDeals.length > 5 ? 5 : filteredDeals.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(
                        horizontal: context.gapSmall / 2,
                      ),
                      width: currentIndex == index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: currentIndex == index
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
      ),
    );
  }

  /// Loading state carousel placeholder
  Widget _buildLoadingCarousel(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: 3,
      itemBuilder: (context, index, realIndex) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: context.gapSmall),
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
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                color: const Color(0xff005B7F),
                strokeWidth: 3,
              ),
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: context.isMobile ? context.hp(20) : context.hp(30),
        viewportFraction: 1,
        autoPlay: false,
        enlargeCenterPage: false,
      ),
    );
  }

  /// Error state with retry button
  Widget _buildErrorState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      height: context.isMobile ? context.hp(16) : context.hp(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.borderRadius),
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
                context.read<ExclusiveDealsBloc>().add(
                  LoadExclusiveDeals(domain: _getDomainFilter(selectedTab)),
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
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Retry",
                style: TextStyle(fontSize: context.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Main carousel with API data
  Widget _buildDealsCarousel(
      BuildContext context,
      List<ExclusiveDealEntity> deals,
      ) {
    // Limit to 5 items for carousel display
    final displayDeals = deals.length > 5 ? deals.sublist(0, 5) : deals;

    return CarouselSlider.builder(
      carouselController: _carouselController,
      itemCount: displayDeals.length,
      itemBuilder: (context, index, realIndex) {
        return _buildDealBannerCard(context, deal: displayDeals[index]);
      },
      options: CarouselOptions(
        height: context.isMobile ? context.hp(20) : context.hp(30),
        viewportFraction: 1,
        autoPlay: true,
        enlargeCenterPage: false,
        onPageChanged: (index, reason) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildArrowButton(
      BuildContext context, {
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        height: context.hp(5.5),
        width: context.hp(5.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(
          icon,
          size: context.iconMedium,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildDealBannerCard(
      BuildContext context, {
        required ExclusiveDealEntity deal,
      }) {
    return GestureDetector(
      onTap: () {
        // Handle deal tap - navigate to deal details or apply coupon
        debugPrint("Deal tapped: ${deal.title}");
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: context.gapSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            image: deal.imageUrl.isNotEmpty
                ? NetworkImage(deal.imageUrl)
                : const AssetImage('assets/images/placeholder_deal.png')
            as ImageProvider,
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // Fallback to placeholder on image load error
              return;
            },
          ),
        ),
        child: Stack(
          children: [
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            // Deal info overlay
            Positioned(
              bottom: context.gapMedium,
              left: context.gapMedium,
              right: context.gapMedium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hot deal badge
                  if (deal.isHotDeal)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.gapSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "HOT DEAL",
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (deal.isHotDeal) SizedBox(height: context.gapSmall / 2),

                  // Deal title
                  Text(
                    deal.title,
                    style: TextStyle(
                      fontSize: context.titleMedium,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: context.gapSmall / 2),

                  // Discount text
                  if (deal.discountText.isNotEmpty)
                    Text(
                      deal.discountText,
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade300,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Coupon code chip
                  if (deal.couponCode.isNotEmpty) ...[
                    SizedBox(height: context.gapSmall / 2),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.gapSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Code: ${deal.couponCode}",
                        style: TextStyle(
                          fontSize: context.labelMedium,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff005B7F),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // _carouselController.dispose();
    super.dispose();
  }
}