import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/services/bank_offer_service.dart';

const Color _cardBg = Color(0xFFF7F8FC);
const Color _borderColor = Color(0xFFE8EAF0);
const Color _titleColor = Color(0xFF1A1D26);
const Color _subtitleColor = Color(0xFF5C6070);
const Color _couponBg = Color(0xFFEEF1FF);
const Color _couponBorder = Color(0xFFCDD3F0);
const Color _couponText = Color(0xFF3B4FC4);
const Color _bankNameColor = Color(0xFF6B7082);

class DetailOffersStrip extends StatefulWidget {
  const DetailOffersStrip({super.key});

  @override
  State<DetailOffersStrip> createState() => _DetailOffersStripState();
}

class _DetailOffersStripState extends State<DetailOffersStrip> {
  late final PageController _controller;
  int _current = 0;
  Timer? _timer;
  List<BankOffer>? _offers;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await BankOfferService().fetchOffers(type: 'flight');
      if (mounted) {
        setState(() { _offers = offers; _loading = false; });
        if (offers.length > 1) _startAutoPlay();
      }
    } catch (_) {
      if (mounted) setState(() { _offers = []; _loading = false; });
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _offers == null || _offers!.isEmpty) return;
      final next = (_current + 1) % _offers!.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _offers == null || _offers!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: context.h(106),
          child: PageView.builder(
            controller: _controller,
            itemCount: _offers!.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) => Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(4)),
              child: _BankOfferCard(offer: _offers![i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _BankOfferCard extends StatelessWidget {
  final BankOffer offer;
  const _BankOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(42),
            height: context.w(42),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(10)),
              border: Border.all(color: _borderColor, width: 0.5),
            ),
            padding: EdgeInsets.all(context.w(6)),
            child: _buildLogo(context),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  offer.bankName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(9),
                    fontWeight: FontWeight.w700,
                    color: _bankNameColor,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  offer.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  offer.displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w400,
                    color: _subtitleColor,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: context.h(6)),
                if (offer.hasCode)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: offer.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Coupon ${offer.code} copied!'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(3),
                      ),
                      decoration: BoxDecoration(
                        color: _couponBg,
                        borderRadius: BorderRadius.circular(context.r(4)),
                        border: Border.all(color: _couponBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            offer.code,
                            style: TextStyle(
                              fontSize: context.fs(9),
                              fontWeight: FontWeight.w800,
                              color: _couponText,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(width: context.w(4)),
                          Icon(
                            Icons.copy_rounded,
                            size: context.fs(9),
                            color: _couponText.withValues(alpha: 0.60),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final url = offer.logoUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => Icon(
          Icons.account_balance_rounded,
          size: context.fs(20),
          color: _bankNameColor,
        ),
      );
    }
    return Icon(
      Icons.account_balance_rounded,
      size: context.fs(20),
      color: _bankNameColor,
    );
  }
}
