import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

/// ─────────────────────────────────────────────────────────────
/// Offer data model
/// ─────────────────────────────────────────────────────────────
class _OfferItem {
  final String imagePath;
  final String title;
  final String statement;

  const _OfferItem({
    required this.imagePath,
    required this.title,
    required this.statement,
  });
}

/// ─────────────────────────────────────────────────────────────
/// Offer list — just keep appending here when new offers drop.
/// The carousel picks up the new count automatically.
/// ─────────────────────────────────────────────────────────────
const List<_OfferItem> _offerItems = [
  _OfferItem(
    imagePath: 'assets/images/car.png',
    title: 'Log-in and get exclusive discounts!',
    statement: 'Log in and Unlock all the exclusive offers and use wallet etc',
  ),
  _OfferItem(
    imagePath: 'assets/images/hotel.png',
    title: 'Save big on every flight',
    statement: 'Extra ₹300 cashback credited instantly on every booking',
  ),
  _OfferItem(
    imagePath: 'assets/images/TransHeroImage.png',
    title: 'Zero convenience fee',
    statement: '₹500 off on 3-month easy EMI plan — log in to unlock',
  ),
  // 👇 Add more offers here anytime — no other code changes needed.
  // _OfferItem(
  //   imagePath: 'assets/NewIcons/credit.png',
  //   title: 'Instant bank discount',
  //   statement: 'Flat ₹150 off with net banking payments',
  // ),
];

/// ─────────────────────────────────────────────────────────────
/// Single offer card (left full-height image + white text panel)
/// ─────────────────────────────────────────────────────────────
class _OfferCard extends StatefulWidget {
  final _OfferItem item;
  final VoidCallback? onTap;

  const _OfferCard({required this.item, this.onTap});

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = context.r(14);

    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp:   widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        width: double.infinity,
        height: context.h(68),
        decoration: BoxDecoration(
          color: _pressed
          // Dim the surface a touch so it reads as "pushed back"
              ? const Color(0xFFF2F4F9)
              : Colors.white,
          borderRadius: BorderRadius.circular(radius),
          // Outer drop-shadow only while unpressed (lifted) — collapses
          // when pressed, which is the second half of the MMT effect.
          boxShadow: _pressed
              ? const []
              : [
            BoxShadow(
              color: const Color(0xFF2B3A67).withValues(alpha: 0.06),
              blurRadius: context.w(6),
              offset: Offset(0, context.h(2)),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        // ── Inset shadow overlay, visible only while pressed ────────
        foregroundDecoration: _pressed
            ? BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF000000).withValues(alpha: 0.08),
              const Color(0xFF000000).withValues(alpha: 0.02),
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 0.75],
          ),
        )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left: asset image covering full card height ──────
            SizedBox(
              width: context.w(90),
              child: Image.asset(
                widget.item.imagePath,
                fit: BoxFit.cover,
              ),
            ),

            // ── Right: text on white background ──────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(12.5),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2340),
                      ),
                    ),
                    SizedBox(height: context.h(3)),
                    Text(
                      widget.item.statement,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(9.5),
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Carousel — auto-slides through all offers, no dots indicator
/// ─────────────────────────────────────────────────────────────
class FlightOfferBannerCarousel extends StatelessWidget {
  final void Function(int index)? onOfferTap;

  const FlightOfferBannerCarousel({super.key, this.onOfferTap});

  @override
  Widget build(BuildContext context) {
    // Defensive: if the list is ever empty, render nothing instead of
    // crashing CarouselSlider.
    if (_offerItems.isEmpty) return const SizedBox.shrink();

    return CarouselSlider.builder(
      itemCount: _offerItems.length,
      itemBuilder: (ctx, i, _) {
        final item = _offerItems[i];
        return _OfferCard(
          item: item,
          onTap: onOfferTap == null ? null : () => onOfferTap!(i),
        );
      },
      options: CarouselOptions(
        height: context.h(68),          // matches the card height exactly
        viewportFraction: 1.0,          // full-width slides, one at a time
        autoPlay: _offerItems.length > 1, // only auto-play when there's >1
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 500),
        autoPlayCurve: Curves.easeInOut,
        enableInfiniteScroll: _offerItems.length > 1,
        pauseAutoPlayOnTouch: true,
        scrollPhysics: const BouncingScrollPhysics(),
        padEnds: false,                 // no extra side padding
      ),
    );
  }
}
