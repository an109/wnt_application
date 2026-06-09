import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/exclusive_deal_entity.dart';
import '../../../../../UI_helper/responsive_layout.dart';
import '../bloc/exclusive_deals_bloc.dart';
import '../bloc/exclusive_deals_event.dart';
import '../bloc/exclusive_deals_state.dart';
import 'dealDetails_Screen.dart';

class TransportExclusiveDealsSection extends StatefulWidget {
  const TransportExclusiveDealsSection({super.key});

  @override
  State<TransportExclusiveDealsSection> createState() =>
      _TransportExclusiveDealsSectionState();
}

class _TransportExclusiveDealsSectionState
    extends State<TransportExclusiveDealsSection> {
  int selectedTab = 1;
  int currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  String? _getDomainFilter(int tabIndex) {
    switch (tabIndex) {
      case 0: // HOT DEAL
        return null;
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
      2: ['hotel'], // Will match if category OR owner_tab contains "hotel"
      3: ['holidays', 'holiday'], // Handle plural/singular
    };

    final filters = filterMap[tabIndex];
    if (filters != null) {
      return deals.where((deal) {
        final category = deal.category.toLowerCase();
        final ownerTab = deal.ownerTab.toLowerCase();

        return filters.any(
          (f) =>
              category.contains(f.toLowerCase()) ||
              ownerTab.contains(f.toLowerCase()),
        );
      }).toList();
    }

    return deals;
  }

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
              fontSize: context.titleLarge,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          // Text(
          //   "Exclusive Deals",
          //   style: GoogleFonts.playfairDisplay(
          //     fontSize: context.titleLarge,
          //     fontWeight: FontWeight.w700, // Thick stroke profiles look gorgeous in serif
          //     color: const Color(0xFF1A1A1A),
          //     letterSpacing: 0.5,
          //   ),
          // ),
          SizedBox(height: context.gapLarge),

          /// TABS
          SizedBox(
            height: context.h(34),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: context.bodySmall,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xff005B7F)
                                : Colors.black54,
                          ),
                        ),
                        SizedBox(height: context.gapXSmall),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: context.dividerMedium,
                          width: context.w(64),
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

          Divider(color: Colors.grey.shade300, thickness: context.dividerThin),

          SizedBox(height: context.gapMedium),

          /// BLOC BUILDER FOR API DATA
          BlocBuilder<ExclusiveDealsBloc, ExclusiveDealsState>(
            builder: (context, state) {
              if (state is ExclusiveDealsLoading) {
                return _buildLoadingCarousel(context);
              } else if (state is ExclusiveDealsLoaded) {
                final filteredDeals = _filterDealsByCategory(
                  state.deals,
                  selectedTab,
                );

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
                final filteredDeals = _filterDealsByCategory(
                  state.deals,
                  selectedTab,
                );
                if (filteredDeals.isEmpty) return const SizedBox.shrink();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    filteredDeals.length > 5 ? 5 : filteredDeals.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(
                        horizontal: context.gapXXSmall, // Use consistent gap
                      ),
                      width: currentIndex == index
                          ? context.w(20)
                          : context.w(8), // Responsive (22px or 8px on 400px)
                      height: context.h(8), // 8px on 800px
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          context.borderRadiusLarge,
                        ),
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
              height: context.hp(5),
              width: context.hp(5),
              child: CircularProgressIndicator(
                color: const Color(0xff005B7F),
                strokeWidth: context.h(1.5), // Responsive stroke
              ),
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: context.isMobile
            ? context.h(160)
            : (context.isTablet ? context.h(200) : context.h(240)),
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
      height: context.isMobile
          ? context.hp(30)
          : (context.isTablet ? context.h(60) : context.h(90)),
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
                  borderRadius: BorderRadius.circular(
                    context.borderRadiusSmall,
                  ),
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
        height: context.isMobile
            ? context.h(190)
            : (context.isTablet ? context.h(230) : context.h(270)),
        viewportFraction: context.isMobile
            ? 1
            : (context.isTablet ? 0.9 : 0.8), // Better on larger screens
        autoPlay: true,
        enlargeCenterPage: context.isTablet ? true : false, // Enlarge on tablet
        onPageChanged: (index, reason) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDealBannerCard(
    BuildContext context, {
    required ExclusiveDealEntity deal,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DealDetailsScreen(deal: deal),
          ),
        );
        debugPrint("Deal tapped: ${deal.title}");
      },
      child: Container(
        width: double.infinity,
        // margin: EdgeInsets.symmetric(horizontal: context.gapSmall),
        decoration: BoxDecoration(
          // borderRadius: BorderRadius.circular(context.borderRadius),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  stops: const [0.6, 1.0],
                ),
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
