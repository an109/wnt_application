import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../ExclusiveDeals/domain/entities/exclusive_deal_entity.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_event.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_state.dart';
import '../../../offers/offers_screen.dart';

// Top-of-home widgets from the "MAIN HOME" Figma frame (412px wide, hence
// `context.fx`).

const String _assets = 'assets/home';

/// One slide of the "Travelling Information" carousel.
class HomeInfoSlide {
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? bannerAsset;

  const HomeInfoSlide({
    required this.title,
    required this.body,
    this.actionLabel = 'View Details',
    this.onAction,
    this.bannerAsset,
  });
}

/// Swipeable info banners with the pill-style page indicator underneath.
class HomeInfoCarousel extends StatefulWidget {
  final List<HomeInfoSlide> slides;

  const HomeInfoCarousel({super.key, required this.slides});

  @override
  State<HomeInfoCarousel> createState() => _HomeInfoCarouselState();
}

class _HomeInfoCarouselState extends State<HomeInfoCarousel> {
  static const _autoPlayEvery = Duration(seconds: 4);

  final PageController _controller = PageController();
  Timer? _autoPlay;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(HomeInfoCarousel old) {
    super.didUpdateWidget(old);
    if (old.slides.length != widget.slides.length) {
      // e.g. the placeholder slide was replaced by the offers from the API.
      if (_page >= widget.slides.length) _page = 0;
      if (_controller.hasClients) _controller.jumpToPage(_page);
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoPlay?.cancel();
    if (widget.slides.length < 2) return;
    _autoPlay = Timer.periodic(_autoPlayEvery, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: context.fx(185),
          child: NotificationListener<ScrollStartNotification>(
            // Restart the timer when the user swipes, so auto-play never
            // jumps right after a manual swipe.
            onNotification: (n) {
              if (n.dragDetails != null) _startAutoPlay();
              return false;
            },
            child: PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _InfoBanner(slide: widget.slides[i]),
            ),
          ),
        ),
        SizedBox(height: context.fx(24)),
        _PageDots(count: widget.slides.length, current: _page),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(width: context.fx(4)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: context.fx(i == current ? 34 : 12),
            height: context.fx(12),
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.AppBlue
                  : const Color(0xFF0066CB).withOpacity(0.24),
              borderRadius: BorderRadius.circular(context.fx(6)),
            ),
          ),
        ],
      ],
    );
  }
}

// -- Original _InfoBanner (gradient + clouds + plane) commented out --
// class _InfoBanner extends StatelessWidget { ... }

/// Promotional banner slide from the Figma design: each slide is a
/// full-bleed image with text baked in. Tapping it fires [slide.onAction].
class _InfoBanner extends StatelessWidget {
  final HomeInfoSlide slide;

  const _InfoBanner({required this.slide});

  /// Static promotional banners matching the Figma "MAIN HOME" design.
  static const List<String> promoBanners = [
    '$_assets/banner_first_flight.png',
    '$_assets/banner_klm.png',
    '$_assets/banner_lowest_price.png',
    '$_assets/banner_indigo.png',
    '$_assets/banner_holidays.png',
    '$_assets/banner_visa.png',
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: slide.onAction,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.fx(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              slide.bannerAsset ?? promoBanners[0],
              fit: BoxFit.cover,
            ),
            // Subtle gradient overlay at bottom for readability if needed
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: context.fx(50),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sponsored banner ("Go Where You're Loved." / EXPLORE) with the "Ad"
/// tab sitting in the image's bottom-right cut-out.
class HomeAdBanner extends StatelessWidget {
  final VoidCallback? onExplore;

  const HomeAdBanner({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.fx(380),
      height: context.fx(185),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('$_assets/ad_banner.png', fit: BoxFit.fill),
          ),
          Positioned(
            left: context.fx(266.97),
            top: context.fx(24.05),
            width: context.fx(101.333),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go Where You’re Loved.',
                  style: TextStyle(
                    fontSize: context.ffs(12),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: context.fx(8)),
                GestureDetector(
                  onTap: onExplore,
                  child: Container(
                    color: AppColors.OrangeColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.fx(4),
                      vertical: context.fx(2),
                    ),
                    child: Text(
                      'EXPLORE',
                      style: TextStyle(
                        fontSize: context.ffs(12),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: context.fx(305.95),
            top: context.fx(144.3),
            height: context.fx(33.3),
            child: Row(
              children: [
                Text(
                  'Ad',
                  style: TextStyle(
                    fontSize: context.ffs(12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF757575),
                  ),
                ),
                SizedBox(width: context.fx(4)),
                SvgPicture.asset(
                  '$_assets/info.svg',
                  width: context.fx(18),
                  height: context.fx(18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The info carousel fed by the backend offers (Exclusive Deals API): the
/// 3 newest active offers, in the same banner design. While the offers are
/// loading — or if there are none — it shows the static "Travelling
/// Information" slide so the layout never jumps or goes blank.
class HomeOffersCarousel extends StatefulWidget {
  const HomeOffersCarousel({super.key, this.categories});

  /// When set, only offers whose category or owner tab contains one of these
  /// keywords are shown (same matching as DealsSection's tabs).
  final List<String>? categories;

  @override
  State<HomeOffersCarousel> createState() => _HomeOffersCarouselState();
}

class _HomeOffersCarouselState extends State<HomeOffersCarousel> {
  static const _promoSlides = [
    HomeInfoSlide(
      title: 'New User Deal On First Flight',
      body: 'Use code EMTFIRST for your first booking',
      bannerAsset: '$_assets/banner_first_flight.png',
    ),
    HomeInfoSlide(
      title: 'KLM Royal Dutch Airlines',
      body: 'Exclusive discounts awaits!',
      bannerAsset: '$_assets/banner_klm.png',
    ),
    HomeInfoSlide(
      title: 'Lowest Price Guaranteed',
      body: 'Book flights at the lowest price guaranteed',
      bannerAsset: '$_assets/banner_lowest_price.png',
    ),
    HomeInfoSlide(
      title: 'Fly with IndiGo',
      body: 'Great fares, greater journeys',
      bannerAsset: '$_assets/banner_indigo.png',
    ),
    HomeInfoSlide(
      title: 'Explore Dream Holidays',
      body: 'Amazing packages. Unforgettable experiences.',
      bannerAsset: '$_assets/banner_holidays.png',
    ),
    HomeInfoSlide(
      title: 'Get Your Visa Easier & Faster',
      body: 'One step closer to your next destination',
      bannerAsset: '$_assets/banner_visa.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<ExclusiveDealsBloc>();
      if (bloc.state is ExclusiveDealsInitial ||
          bloc.state is ExclusiveDealsError) {
        bloc.add(const LoadExclusiveDeals());
      }
    });
  }

  /// The 3 newest active offers; "View Details" opens the Offers screen
  /// led by that offer.
  List<HomeInfoSlide> _slides(List<ExclusiveDealEntity> deals) {
    final filters = widget.categories;
    final matching = filters == null
        ? deals
        : deals.where((deal) {
            final category = deal.category.toLowerCase();
            final ownerTab = deal.ownerTab.toLowerCase();
            return filters.any((f) =>
                category.contains(f.toLowerCase()) ||
                ownerTab.contains(f.toLowerCase()));
          }).toList();
    final top = latestOffers(matching).take(3).toList();
    return [
      for (var i = 0; i < top.length; i++)
        HomeInfoSlide(
          title: top[i].title.trim(),
          body: offerSummary(top[i]),
          bannerAsset: _InfoBanner.promoBanners[i % _InfoBanner.promoBanners.length],
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OffersScreen(focusDealId: top[i].id)),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExclusiveDealsBloc, ExclusiveDealsState>(
      builder: (context, state) {
        final slides = state is ExclusiveDealsLoaded ? _slides(state.deals) : const <HomeInfoSlide>[];
        return HomeInfoCarousel(slides: slides.isEmpty ? _promoSlides : slides);
      },
    );
  }
}
