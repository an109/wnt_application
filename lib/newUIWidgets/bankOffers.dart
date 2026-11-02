import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/services/bank_offer_service.dart';

/// Single offer card (Icon left, Text middle, Chevron right)
class _bankOfferCard extends StatefulWidget {
  final BankOffer item;
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
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: _pressed
                ? [const Color(0xFFE2E8F0), const Color(0xFFE2E8F0)]
                : [const Color(0xFFF0F4FF), const Color(0xFFF8F0FF)],
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
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
              Container(
                width: context.w(32),
                height: context.w(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(context.w(6)),
                child: _buildLogo(context),
              ),
              SizedBox(width: context.w(12)),
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
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      widget.item.displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF717171),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(8)),
              Icon(
                Icons.chevron_right_rounded,
                size: context.w(22),
                color: const Color(0xFF0071C2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final url = widget.item.logoUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => const Icon(
          Icons.account_balance,
          size: 16,
          color: Color(0xFF1E6FE0),
        ),
      );
    }
    return const Icon(
      Icons.account_balance,
      size: 16,
      color: Color(0xFF1E6FE0),
    );
  }
}

/// Carousel — auto-slides through all offers, no dots indicator.
/// Fetches offers from the API on first build.
class BankOfferCarousel extends StatefulWidget {
  final void Function(List<BankOffer> offers)? onOfferTap;

  const BankOfferCarousel({super.key, this.onOfferTap});

  @override
  State<BankOfferCarousel> createState() => _BankOfferCarouselState();
}

class _BankOfferCarouselState extends State<BankOfferCarousel> {
  List<BankOffer>? _offers;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await BankOfferService().fetchOffers(type: 'flight');
      if (mounted) setState(() { _offers = offers; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _offers = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _offers == null || _offers!.isEmpty) {
      return const SizedBox.shrink();
    }

    final offers = _offers!;

    return CarouselSlider.builder(
      itemCount: offers.length,
      itemBuilder: (ctx, i, _) {
        return _bankOfferCard(
          item: offers[i],
          onTap: widget.onOfferTap == null
              ? null
              : () => widget.onOfferTap!(offers),
        );
      },
      options: CarouselOptions(
        height: context.h(48),
        viewportFraction: 1.0,
        autoPlay: offers.length > 1,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 500),
        autoPlayCurve: Curves.easeInOut,
        enableInfiniteScroll: offers.length > 1,
        pauseAutoPlayOnTouch: true,
        scrollPhysics: const BouncingScrollPhysics(),
        padEnds: false,
      ),
    );
  }
}
