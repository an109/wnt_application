import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/services/bank_offer_service.dart';

class AllBankOffersScreen extends StatelessWidget {
  final List<BankOffer> offers;

  const AllBankOffersScreen({super.key, required this.offers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bank Offers'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0.5,
      ),
      body: offers.isEmpty
          ? const Center(child: Text('No offers available'))
          : ListView.separated(
              padding: EdgeInsets.all(context.w(16)),
              itemCount: offers.length,
              separatorBuilder: (_, __) => SizedBox(height: context.h(12)),
              itemBuilder: (ctx, i) => _OfferTile(offer: offers[i]),
            ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final BankOffer offer;
  const _OfferTile({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      padding: EdgeInsets.all(context.w(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.w(42),
                height: context.w(42),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(10)),
                  border: Border.all(color: const Color(0xFFE8EAF0), width: 0.5),
                ),
                padding: EdgeInsets.all(context.w(6)),
                child: _buildLogo(context),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.bankName,
                      style: TextStyle(
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7082),
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      offer.title,
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Text(
            offer.displayText,
            style: TextStyle(
              fontSize: context.fs(12),
              color: const Color(0xFF5C6070),
            ),
          ),
          if (offer.terms.isNotEmpty) ...[
            SizedBox(height: context.h(6)),
            Text(
              offer.terms,
              style: TextStyle(
                fontSize: context.fs(10),
                color: const Color(0xFF9197A6),
              ),
            ),
          ],
          if (offer.minAmount > 0) ...[
            SizedBox(height: context.h(4)),
            Text(
              'Min. booking amount: ₹${offer.minAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: context.fs(10),
                color: const Color(0xFF9197A6),
              ),
            ),
          ],
          if (offer.hasCode) ...[
            SizedBox(height: context.h(10)),
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
                  horizontal: context.w(12),
                  vertical: context.h(6),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1FF),
                  borderRadius: BorderRadius.circular(context.r(6)),
                  border: Border.all(color: const Color(0xFFCDD3F0), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer.code,
                      style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3B4FC4),
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(width: context.w(6)),
                    Icon(
                      Icons.copy_rounded,
                      size: context.fs(11),
                      color: const Color(0xFF3B4FC4).withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          color: const Color(0xFF6B7082),
        ),
      );
    }
    return Icon(
      Icons.account_balance_rounded,
      size: context.fs(20),
      color: const Color(0xFF6B7082),
    );
  }
}
