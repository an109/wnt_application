import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/views/ExclusiveDeals/presentation/section/terms&Condition.dart';
import '../../../../common_widgets/logo.dart';
import '../../domain/entities/exclusive_deal_entity.dart';
import '../../../../../UI_helper/responsive_layout.dart';

class DealDetailsScreen extends StatelessWidget {
  final ExclusiveDealEntity deal;

  const DealDetailsScreen({super.key, required this.deal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: WanderNovaLogo(
          scaleFactor: context.isMobile ? 0.6 : (context.isTablet ? 0.8 : 1.0),
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.wp(2)),
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: context.hp(4.5),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            _buildBannerImage(context),

            SizedBox(height: context.gapLarge),

            // Main Content
            Padding(
              padding: context.horizontalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCouponCodeCard(context),

                  SizedBox(height: context.gapMedium),

                  // Terms & Conditions
                  TermsAndConditionsSection(termsText: _getDefaultTerms()),

                  SizedBox(height: context.gapXLarge),

                  // Book Now Button
                  // _buildBookNowButton(context),

                  // SizedBox(height: context.gapXLarge * 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: context.isMobile
          ? context.hp(29)
          : context.isTablet
          ? context.hp(39)
          : context.hp(49),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: deal.imageUrl.isNotEmpty
              ? NetworkImage(deal.imageUrl)
              : const AssetImage('assets/images/placeholder_deal.png')
                    as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCodeCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          Image.asset(
            'assets/images/scissor.png',
            width: context.wp(15),
            height: context.wp(12),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.directions_car,
                size: context.wp(18),
                color: Colors.grey.shade400,
              );
            },
          ),
          // SizedBox(height: context.gapSmall),

          // Coupon Code Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.gapMedium,
              vertical: context.gapMedium,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xff005B7F).withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Use coupon code: ${deal.couponCode}',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(16, 15, 14),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Copy Button
                IconButton(
                  onPressed: () => _copyCouponCode(context),
                  icon: Icon(
                    Icons.copy,
                    size: context.responsiveFontSize(20, 18, 16),
                    color: const Color(0xff005B7F),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          SizedBox(height: context.gapMedium),

          // Validity Info
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.gapSmall),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(
                    context.borderRadiusSmall,
                  ),
                ),
                child: Icon(
                  Icons.event,
                  color: Colors.blue.shade700,
                  size: context.responsiveFontSize(20, 18, 16),
                ),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valid Up To : ${_getValidityDate()}',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14, 13, 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Sector type: ${deal.sectorType ?? 'International'}',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(13, 12, 11),
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookNowButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.isMobile ? 50 : 56,
      child: ElevatedButton(
        onPressed: () {
          _bookNow(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.red.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.borderRadiusMedium),
          ),
        ),
        child: Text(
          'BOOK NOW',
          style: TextStyle(
            fontSize: context.responsiveFontSize(18, 16, 15),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBookNowButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              _bookNow(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadiusMedium),
              ),
            ),
            child: Text(
              'BOOK NOW',
              style: TextStyle(
                fontSize: context.responsiveFontSize(16, 15, 14),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyCouponCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: deal.couponCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon code "${deal.couponCode}" copied to clipboard!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _bookNow(BuildContext context) {
    // Navigate to booking screen or apply coupon
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Redirecting to booking...'),
        backgroundColor: const Color(0xff005B7F),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Add your navigation logic here
    // Navigator.pushNamed(context, '/booking', arguments: deal);
  }

  void _shareDeal(BuildContext context) {
    // Share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share deal functionality'),
        backgroundColor: const Color(0xff005B7F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getValidityDate() {
    // You can parse this from deal entity or set dynamically
    return 'March 31, 2026';
  }

  String _getDefaultTerms() {
    return '''

Instant discounts are applicable on Economy, Premium Economy, Business & First Class.

• The offer is valid for both Domestic and International flight bookings made through debit card, credit card, or net banking.

• Customers must ensure the promotional discount is applied on the payment page before completing the booking.

• This offer is valid only on bookings made through www.thewandernova.com.

• The offer cannot be combined with any other promotional offer available on thewandernova.com.

• Any date change, rebooking, or cancellation will be subject to the airline fare rules and applicable charges.

• thewandernova.com reserves the right to modify, update, or withdraw this offer at any time without prior notice.

• thewandernova.com will not be responsible for any delay, loss, or issue caused due to circumstances beyond control such as natural events, technical failures, or other force majeure situations.

• Under this promotional offer, the maximum liability of thewandernova.com will not exceed the value of the discount provided.

• thewandernova.com shall not be liable for any indirect, special, incidental, or consequential damages arising from the use of this offer.

• Any disputes related to this offer will be subject to the jurisdiction as decided by thewandernova.com.

• Travel agents or individuals booking on behalf of third parties for commercial purposes may not be eligible for this offer. thewandernova.com reserves the right to reject or cancel such bookings without refund.

• By availing this offer, customers confirm that they have read, understood, and agreed to all the terms and conditions mentioned above.''';
  }
}
