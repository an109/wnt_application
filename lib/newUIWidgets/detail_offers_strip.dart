import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class _BankOffer {
  final String logoPath;
  final String bankName;
  final String title;
  final String description;
  final String couponCode;

  const _BankOffer({
    required this.logoPath,
    required this.bankName,
    required this.title,
    required this.description,
    required this.couponCode,
  });
}

const List<_BankOffer> _bankOffers = [
  _BankOffer(
    logoPath: 'assets/images/yes_bank_logo.png',
    bankName: 'YES BANK',
    title: 'Flat 10% instant discount',
    description: 'On YES BANK credit & debit cards. Max discount ₹1,500',
    couponCode: 'YESFEST',
  ),
  _BankOffer(
    logoPath: 'assets/NewIcons/credit.png',
    bankName: 'HDFC BANK',
    title: 'Up to ₹2,000 OFF',
    description: 'On HDFC Bank credit card EMI transactions',
    couponCode: 'HDFCEMI',
  ),
  _BankOffer(
    logoPath: 'assets/NewIcons/net_banking.png',
    bankName: 'SBI CARD',
    title: 'Flat ₹750 instant discount',
    description: 'On SBI credit cards. Min booking ₹5,000',
    couponCode: 'SBIFLY',
  ),
  _BankOffer(
    logoPath: 'assets/NewIcons/upi.png',
    bankName: 'UPI',
    title: 'No convenience fee',
    description: 'Pay via any UPI app and save on every booking',
    couponCode: 'UPIFREE',
  ),
];

const Color _cardBg = Color(0xFFF7F8FC);
const Color _borderColor = Color(0xFFE8EAF0);
const Color _titleColor = Color(0xFF1A1D26);
const Color _subtitleColor = Color(0xFF5C6070);
const Color _couponBg = Color(0xFFEEF1FF);
const Color _couponBorder = Color(0xFFCDD3F0);
const Color _couponText = Color(0xFF3B4FC4);
const Color _bankNameColor = Color(0xFF6B7082);
const Color _dotActive = Color(0xFF3B4FC4);

class DetailOffersStrip extends StatefulWidget {
  const DetailOffersStrip({super.key});

  @override
  State<DetailOffersStrip> createState() => _DetailOffersStripState();
}

class _DetailOffersStripState extends State<DetailOffersStrip> {
  late final PageController _controller;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _bankOffers.length;
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: context.h(106),
          child: PageView.builder(
            controller: _controller,
            itemCount: _bankOffers.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) => Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(4)),
              child: _BankOfferCard(offer: _bankOffers[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _BankOfferCard extends StatelessWidget {
  final _BankOffer offer;
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
          // Bank logo
          Container(
            width: context.w(42),
            height: context.w(42),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(10)),
              border: Border.all(color: _borderColor, width: 0.5),
            ),
            padding: EdgeInsets.all(context.w(6)),
            child: Image.asset(
              offer.logoPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.account_balance_rounded,
                size: context.fs(20),
                color: _bankNameColor,
              ),
            ),
          ),
          SizedBox(width: context.w(12)),
          // Text content
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
                  offer.description,
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
                // Coupon chip
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: offer.couponCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Coupon ${offer.couponCode} copied!'),
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
                          offer.couponCode,
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
}
