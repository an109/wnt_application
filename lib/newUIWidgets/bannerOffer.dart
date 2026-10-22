

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class _BannerOffer {
  final String imagePath;
  final String headline;
  final String subline;
  final String couponCode;

  const _BannerOffer({
    required this.imagePath,
    required this.headline,
    required this.subline,
    required this.couponCode,
  });
}

const List<_BannerOffer> _bankOffers = [
  _BannerOffer(
    imagePath: 'assets/home/ad_banner.png',
    headline: 'Unlock up to 20% OFF',
    subline: 'Hotels and homestays when you book flights on WanderNova',
    couponCode: 'STAY20',
  ),
  _BannerOffer(
    imagePath: 'assets/home/ad_banner.png',
    headline: 'Flat ₹500 instant cashback',
    subline: 'Book any flight on WanderNova and save on your next stay',
    couponCode: 'FLY500',
  ),
  _BannerOffer(
    imagePath: 'assets/home/ad_banner.png',
    headline: 'Extra 15% OFF on hotels',
    subline: 'Exclusive saving for WanderNova flight travellers',
    couponCode: 'HOTEL15',
  ),
  _BannerOffer(
    imagePath: 'assets/home/ad_banner.png',
    headline: 'Zero convenience fee',
    subline: 'On all domestic flights booked via WanderNova',
    couponCode: 'ZEROFEE',
  ),
];

/// Full-width auto-sliding offer banner shown at the top of flight results.
/// One shared shadow colour across all slides. No dots indicator.
class BannerCarousel extends StatelessWidget {
  const BannerCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: _bankOffers.length,
      itemBuilder: (ctx, i, _) => _BankOfferCard(offer: _bankOffers[i]),
      options: CarouselOptions(
        height: context.h(96),
        viewportFraction: 1,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 600),
        autoPlayCurve: Curves.easeInOut,
        enableInfiniteScroll: true,
        pauseAutoPlayOnTouch: true,
      ),
    );
  }
}

class _BankOfferCard extends StatelessWidget {
final _BannerOffer offer;

const _BankOfferCard({required this.offer});

static const Color _shadowColor  = Color(0xFF4A4A4A);
// static const Color _shadowColor  = Color(0xFF4A4A4A);

static const Color _overlayStart = Color(0xFF757575);
static const Color _overlayEnd   = Colors.grey;

// Brand colours for the "wander NovA" wordmark.
static const Color _wanderBlue   = Color(0xFF1663F7);
static const Color _novaOrange   = Color(0xFFF97316);


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withValues(alpha: 0.20),
            blurRadius: context.w(14),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            offer.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: _overlayStart),
          ),
          // Gradient overlay (same for every slide) so text stays readable
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  _overlayStart.withValues(alpha: 0.95),
                  _overlayEnd.withValues(alpha: 0.40),
                  _overlayEnd.withValues(alpha: 0.04),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Text content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(18),
                vertical: context.h(6),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // ── Headline ────────────────────────────────────────
                Text(
                  offer.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: context.h(1)),

                // ── Subline ─────────────────────────────────────────
                Text(
                  offer.subline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                SizedBox(height: context.h(2)),

                // ── "wander NovA" wordmark ──────────────────────────
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'wander',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w800,
                          color: _wanderBlue,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TextSpan(
                        text: 'NovA',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w800,
                          color: _novaOrange,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(1)),

                // ── Coupon row ──────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Coupon code: ',
                      style: TextStyle(
                        fontSize: context.fs(9),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(2),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(context.r(4)),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        offer.couponCode,
                        style: TextStyle(
                          fontSize: context.fs(9),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}
