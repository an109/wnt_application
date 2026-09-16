import 'package:flutter/material.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

/// Full "Rating & Review" screen, reached from [AkHotelDetailScreen]'s
/// Reviews & Ratings "View More" — always offered, whichever of the two
/// aggregates that section ended up showing:
///
/// - Real guest review (`hotel.userReview.rating`/`.count`): [reviewCount]
///   is positive, shown as "N User Ratings".
/// - Fallback to the hotel's own star classification (most hotels on this
///   backend don't carry `userReview` at all): [reviewCount] is 0, so the
///   count line is skipped rather than claiming a user-rating count that
///   doesn't exist.
///
/// Either way, Content gives only this one aggregate — no per-tier
/// breakdown, no individual review text/reviewer/date/room — so unlike the
/// reference this was built against, there's no sentiment histogram and no
/// review list below the summary: showing either would mean inventing
/// numbers/text the API never sent.
class AkHotelReviewScreen extends StatelessWidget {
  final String hotelName;
  final double rating;
  final int reviewCount;

  const AkHotelReviewScreen({
    super.key,
    required this.hotelName,
    required this.rating,
    required this.reviewCount,
  });

  static const _navy = AppColors.black;
  static const _muted = AppColors.subhead;

  bool get _hasGuestReview => reviewCount > 0;

  String get _sentimentLabel {
    if (rating >= 4.5) return 'EXCELLENT';
    if (rating >= 3.5) return 'VERY GOOD';
    if (rating >= 2.5) return 'GOOD';
    if (rating >= 1.5) return 'BELOW AVERAGE';
    return 'POOR';
  }

  IconData _starIcon(int index) {
    final threshold = index + 1;
    if (rating >= threshold) return Icons.star;
    if (rating >= threshold - 0.5) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: context.scrollPhysics,
                padding: context.responsivePadding.copyWith(top: context.gapLarge, bottom: context.gapLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow(context),
                    SizedBox(height: context.gapLarge),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.w(14)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(context.r(10)),
                      ),
                      child: Text(
                        _hasGuestReview
                            ? 'This property\'s booking partner provides only an overall rating — individual guest reviews aren\'t available yet.'
                            : 'This property\'s booking partner hasn\'t provided guest reviews yet — the rating above reflects the hotel\'s own star classification.',
                        style: TextStyle(fontSize: context.fs(12.5), color: _muted, height: 1.5),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: context.h(90),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: context.r(10), offset: Offset(0, context.h(2))),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(right: context.w(8), bottom: context.h(2), top: context.h(34)),
        child: Row(
          children: [
            SizedBox(width: context.gapMedium),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: Image.asset(
                'assets/NewIcons/arrowBack.png',
                width: context.w(18),
                height: context.h(18),
                color: AppColors.black,
              ),
            ),
            SizedBox(width: context.gapLarge),
            Text(
              'Rating & Review',
              style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600, color: _navy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    return Padding(
      padding: context.responsivePadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.w(96),
            padding: EdgeInsets.symmetric(vertical: context.h(18)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF17B4EF), Color(0xFF0E86C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(context.r(14)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(fontSize: context.fs(26), fontWeight: FontWeight.w800, color: Colors.white),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  _sentimentLabel,
                  style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4),
                ),
              ],
            ),
          ),
          SizedBox(width: context.gapLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasGuestReview ? 'Overall guest sentiment' : 'Hotel star classification',
                  style: TextStyle(fontSize: context.fs(13), color: _muted),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  _hasGuestReview ? '$reviewCount User Rating${reviewCount == 1 ? '' : 's'}' : '${rating.toStringAsFixed(0)}-Star Hotel',
                  style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: _navy),
                ),
                SizedBox(height: context.h(6)),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(_starIcon(i), color: Colors.amber, size: context.w(18)),
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
