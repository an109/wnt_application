import 'dart:async';
import 'dart:math' as math;

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

  const HomeInfoSlide({
    required this.title,
    required this.body,
    this.actionLabel = 'View Details',
    this.onAction,
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

class _InfoBanner extends StatelessWidget {
  final HomeInfoSlide slide;

  const _InfoBanner({required this.slide});

  @override
  Widget build(BuildContext context) {
    const black = Colors.black;

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.fx(8)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Figma: linear-gradient(119.59deg, #80DAFF 28.06%, #FFF 99.13%),
            // i.e. the CSS gradient line's end points on a 380×185 box.
            begin: Alignment(-0.966, -1.124),
            end: Alignment(0.966, 1.124),
            colors: [Color(0xFF80DAFF), Colors.white],
            stops: [0.28055, 0.99129],
          ),
        ),
        child: Stack(
          children: [
            _cloud(context, left: 226.68, top: 0),
            _cloud(context, left: 104, top: 22.48),
            Positioned(
              left: context.fx(163),
              top: context.fx(30),
              width: context.fx(311.918),
              height: context.fx(230.213),
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  // Figma: flipped vertically, then rotated 172°.
                  transform: Matrix4.rotationZ(172 * math.pi / 180)
                    ..multiply(Matrix4.diagonal3Values(1, -1, 1)),
                  child: Image.asset(
                    '$_assets/plane.png',
                    width: context.fx(288),
                    height: context.fx(192),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              left: context.fx(20),
              top: 0,
              bottom: context.fx(10),
              width: context.fx(220),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.ffs(16),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: black,
                    ),
                  ),
                  SizedBox(height: context.fx(4)),
                  Text(
                    slide.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.ffs(12),
                      fontWeight: FontWeight.w400,
                      height: 1.55,
                      color: black,
                    ),
                  ),
                  SizedBox(height: context.fx(12)),
                  GestureDetector(
                    onTap: slide.onAction,
                    child: Container(
                      width: context.fx(100),
                      padding: EdgeInsets.symmetric(vertical: context.fx(8)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7F9),
                        border: Border.all(color: const Color(0xFFF8FAFB)),
                        borderRadius: BorderRadius.circular(context.fx(4)),
                      ),
                      child: Text(
                        slide.actionLabel,
                        style: TextStyle(
                          fontSize: context.ffs(10),
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                          color: const Color(0xFF272835),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cloud(BuildContext context, {required double left, required double top}) {
    return Positioned(
      left: context.fx(left),
      top: context.fx(top),
      width: context.fx(283.471),
      height: context.fx(290.816),
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          // Figma: rotate(-10.38deg) skewX(-1.1deg)
          transform: Matrix4.rotationZ(-10.38 * math.pi / 180)
            ..multiply(Matrix4.skewX(-1.1 * math.pi / 180)),
          child: SvgPicture.asset(
            '$_assets/cloud.svg',
            width: context.fx(247.275),
            height: context.fx(249.514),
          ),
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
  const HomeOffersCarousel({super.key});

  @override
  State<HomeOffersCarousel> createState() => _HomeOffersCarouselState();
}

class _HomeOffersCarouselState extends State<HomeOffersCarousel> {
  static const _fallback = HomeInfoSlide(
    title: 'Travelling Information',
    body: 'Stay informed about your travelling. Access all the details here.',
  );

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
    return [
      for (final deal in latestOffers(deals).take(3))
        HomeInfoSlide(
          title: deal.title.trim(),
          body: offerSummary(deal),
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OffersScreen(focusDealId: deal.id)),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExclusiveDealsBloc, ExclusiveDealsState>(
      builder: (context, state) {
        final slides = state is ExclusiveDealsLoaded ? _slides(state.deals) : const <HomeInfoSlide>[];
        return HomeInfoCarousel(slides: slides.isEmpty ? const [_fallback] : slides);
      },
    );
  }
}
