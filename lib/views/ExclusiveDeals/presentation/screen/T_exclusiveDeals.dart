import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/common_widgets/deal_banner_image.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
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
  int selectedTab = 0; // Changed to 0 for HOT DEAL as default
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
      2: ['hotel'],
      3: ['holidays', 'holiday'],
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
            "Offers",
            style: TextStyle(
              fontSize: context.fs(24),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: context.gapXSmall),

          /// SUBTITLE
          Text(
            "Unmissable deals for unforgettable journeys",
            style: TextStyle(
              fontSize: context.bodySmall,
              fontWeight: FontWeight.w400,
              color: AppColors.grey,
            ),
          ),

          SizedBox(height: context.gapLarge),

          /// TABS - Pill-shaped buttons
          SizedBox(
            height: context.h(25),
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
                    context.read<ExclusiveDealsBloc>().add(
                      LoadExclusiveDeals(domain: _getDomainFilter(index)),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: context.gapMedium),
                    padding: EdgeInsets.fromLTRB(
                      context.w(8),
                      context.h(4),
                      context.w(8),
                      context.h(4),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppColors.AppBlue
                            : Colors.grey.shade300,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(context.r(6)),
                      color: isSelected
                          ? Color(0xff00A1E4).withOpacity(0.04)
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          fontSize: context.fs(12),
                          letterSpacing: 0.8,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.AppBlue
                              : AppColors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: context.gapLarge),

          /// BLOC BUILDER FOR API DATA
          BlocListener<ExclusiveDealsBloc, ExclusiveDealsState>(
            // The carousel autoplays through up to five banners but only
            // builds the visible one, so every slide used to start its
            // download the moment it scrolled in — a visible blank card each
            // time. Kicking all five off together the instant the deals
            // arrive downloads them in parallel, in the background, while the
            // first one is still on screen.
            listener: (context, state) {
              if (state is ExclusiveDealsLoaded) {
                DealBannerImage.prefetch(
                  context,
                  _filterDealsByCategory(state.deals, selectedTab)
                      .take(5)
                      .map((d) => d.imageUrl),
                );
              }
            },
            child: BlocBuilder<ExclusiveDealsBloc, ExclusiveDealsState>(
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
                return const SizedBox.shrink();
              },
            ),
          ),

          SizedBox(height: context.gapLarge),

          /// DOTS INDICATOR
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
                        horizontal: context.gapXXSmall,
                      ),
                      width: currentIndex == index
                          ? context.w(20)
                          : context.w(8),
                      height: context.h(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: currentIndex == index
                            ? AppColors.AppBlue
                            : Color(0xFF0066CB).withOpacity(0.24),
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
                strokeWidth: context.h(1.5),
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

  Widget _buildDealsCarousel(
      BuildContext context,
      List<ExclusiveDealEntity> deals,
      ) {
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
        viewportFraction: 1, // Changed to 1 to match design (full width)
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
        // margin: EdgeInsets.symmetric(horizontal: 8),
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DealBannerImage(imageUrl: deal.imageUrl),
              // Gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
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
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
