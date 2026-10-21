import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

/// ─────────────────────────────────────────────────────────────
/// Offer data model
/// ─────────────────────────────────────────────────────────────
class _bankOfferItem {
  final String imagePath;
  final String title;
  final String statement;

  const _bankOfferItem({
    required this.imagePath,
    required this.title,
    required this.statement,
  });
}

/// ─────────────────────────────────────────────────────────────
/// Offer list — just keep appending here when new offers drop.
/// ─────────────────────────────────────────────────────────────
const List<_bankOfferItem> _bankOfferItems = [
  _bankOfferItem(
    imagePath: 'assets/images/yes_bank_logo.png', // Replace with your bank/tag icon
    title: 'MMTYESFEST',
    statement: 'Use coupon MMTYESFEST and get flat 10% off',
  ),
  _bankOfferItem(
    imagePath: 'assets/images/hdfc_logo.png', // Replace with your bank/tag icon
    title: 'HDFC10',
    statement: 'Get 10% instant discount on HDFC credit cards',
  ),
  _bankOfferItem(
    imagePath: 'assets/NewIcons/priceDrop.png',
    title: 'FLYHIGH',
    statement: 'Flat ₹500 off on your first flight booking',
  ),
];

/// ─────────────────────────────────────────────────────────────
/// Single offer card (Icon left, Text middle, Chevron right)
/// ─────────────────────────────────────────────────────────────
class _bankOfferCard extends StatefulWidget {
  final _bankOfferItem item;
  final VoidCallback? onTap;

  const _bankOfferCard({required this.item, this.onTap});

  @override
  State<_bankOfferCard> createState() => _bankOfferCardState();
}

class _bankOfferCardState extends State<_bankOfferCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = context.r(12);

    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        width: double.infinity,
        height: context.h(52),
        decoration: BoxDecoration(
          // Subtle gradient matching the MMT image (light blue to light purple)
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: _pressed
                ? [const Color(0xFFE2E8F0), const Color(0xFFE2E8F0)] // Solid grey when pressed
                : [const Color(0xFFF0F4FF), const Color(0xFFF8F0FF)], // Light gradient when normal
          ),
          borderRadius: BorderRadius.circular(radius),
          // Outer drop-shadow (collapses when pressed)
          // boxShadow: _pressed
          //     ? const []
          //     : [
          //   BoxShadow(
          //     color: const Color(0xFF2B3A67).withValues(alpha: 0.05),
          //     blurRadius: context.w(8),
          //     offset: Offset(0, context.h(2)),
          //   ),
          // ],
        ),
        clipBehavior: Clip.antiAlias,
        // Inset shadow overlay, visible only while pressed
        foregroundDecoration: _pressed
            ? BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF000000).withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ),
        )
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(12)),
          child: Row(
            children: [
              // ── Left: Circular white icon background ──────────────
              Container(
                width: context.w(32),
                height: context.w(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(context.w(6)),
                child: Image.asset(
                  widget.item.imagePath,
                  fit: BoxFit.contain,
                  // Optional: Add an errorBuilder if your icon might be missing
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance,
                    size: 16,
                    color: Color(0xFF1E6FE0),
                  ),
                ),
              ),

              SizedBox(width: context.w(12)),

              // ── Middle: Title and Subtitle ────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w600, // Match MMT's semi-bold title
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      widget.item.statement,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF717171), // MMT grey
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: context.w(8)),

              // ── Right: Chevron arrow ──────────────────────────────
              Icon(
                Icons.chevron_right_rounded,
                size: context.w(22),
                color: const Color(0xFF0071C2), // MMT blue arrow color
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Carousel — auto-slides through all offers, no dots indicator
/// ─────────────────────────────────────────────────────────────
class BankOfferCarousel extends StatelessWidget {
  final void Function(int index)? onOfferTap;

  const BankOfferCarousel({super.key, this.onOfferTap});

  @override
  Widget build(BuildContext context) {
    if (_bankOfferItems.isEmpty) return const SizedBox.shrink();

    return CarouselSlider.builder(
      itemCount: _bankOfferItems.length,
      itemBuilder: (ctx, i, _) {
        final item = _bankOfferItems[i];
        return _bankOfferCard(
          item: item,
          onTap: onOfferTap == null ? null : () => onOfferTap!(i),
        );
      },
      options: CarouselOptions(
        height: context.h(48),          // Matches the new card height exactly
        viewportFraction: 1.0,
        autoPlay: _bankOfferItems.length > 1,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 500),
        autoPlayCurve: Curves.easeInOut,
        enableInfiniteScroll: _bankOfferItems.length > 1,
        pauseAutoPlayOnTouch: true,
        scrollPhysics: const BouncingScrollPhysics(),
        padEnds: false,
      ),
    );
  }
}
