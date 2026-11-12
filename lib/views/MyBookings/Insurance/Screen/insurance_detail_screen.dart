import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';
import '../../shared/trip_detail_widgets.dart';
import '../domain/entity/InsuranceBookingEntity.dart';
import 'insurance_pdf_builder.dart';

class InsuranceBookingDetailsScreen extends StatelessWidget {
  final InsuranceBookingEntity booking;

  const InsuranceBookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusInfo(booking.status);
    final gap = SizedBox(height: context.fx(16));
    final id = booking.policyNumber.isNotEmpty
        ? booking.policyNumber
        : booking.transactionId;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: tripBottomBar(context, [
          TripActionButton(
            label: 'DOWNLOAD TICKET',
            icon: Icons.download_rounded,
            onPressed: () => saveAndOfferPdf(
              context,
              filename: 'insurance_$id.pdf',
              build: (logo) => InsurancePdfBuilder.buildTicket(booking),
            ),
          ),
        ]),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              tripTopBar(
                context,
                title: 'Insurance Details',
                subtitle: booking.policyNumber.isNotEmpty
                    ? 'Policy: ${booking.policyNumber}'
                    : 'Transaction: ${booking.transactionId}',
                statusLabel: label,
                statusColor: color,
              ),
              Expanded(
                child: ListView(
                  physics: context.scrollPhysics,
                  padding: EdgeInsets.only(bottom: context.fx(24)),
                  children: [
                    _hero(context),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.fx(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          gap,
                          _policyCard(context),
                          gap,
                          _coverageDetails(context),
                          gap,
                          _fare(context),
                          gap,
                          _bookingInfo(context),
                          gap,
                          _importantInfo(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return SizedBox(
      height: context.fx(116),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFC8E6F2), Color(0xFFE4F2FC), Colors.white],
              ),
            ),
          ),
          Positioned(
            left: context.fx(16),
            top: context.fx(24),
            child: Container(
              width: context.fx(56),
              height: context.fx(56),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(context.fx(10)),
                boxShadow: const [
                  BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))
                ],
              ),
              child: Icon(Icons.shield_moon_outlined, color: AppColors.primary, size: context.fx(28)),
            ),
          ),
          Positioned(
            right: context.fx(16),
            top: context.fx(28),
            child: Icon(Icons.health_and_safety_rounded, size: context.fx(64), color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _policyCard(BuildContext context) {
    return TripSection(
      padding: EdgeInsets.fromLTRB(context.fx(14), context.fx(14), context.fx(14), context.fx(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: context.fx(32),
                height: context.fx(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(context.fx(6)),
                ),
                child: Icon(Icons.shield_moon_outlined, color: AppColors.primary, size: context.fx(20)),
              ),
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.planName.isNotEmpty ? booking.planName : 'Insurance Policy',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600, color: kInk),
                    ),
                    if (booking.providerName.isNotEmpty)
                      Text(
                        booking.providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.ffs(11), color: kMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(14)),
          Row(
            children: [
              Expanded(child: _dateBox(context, 'START DATE', formatTripDate(booking.startDate), AppColors.AppBlue)),
              SizedBox(width: context.fx(10)),
              Expanded(child: _dateBox(context, 'END DATE', formatTripDate(booking.endDate), kOrange)),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.fx(12)),
            child: const Divider(height: 1, color: Color(0xFFF0F1F4)),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: TripStat(icon: Icons.public_rounded, label: 'Destination', value: booking.destination.isEmpty ? '—' : booking.destination)),
                const VerticalDivider(width: 12, color: kLine),
                Expanded(child: TripStat(icon: Icons.groups_rounded, label: 'Travellers', value: '${booking.travellers}')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(context.fx(10)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(context.fx(10)),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: context.ffs(8),
                  color: kMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          SizedBox(height: context.fx(4)),
          Text(value,
              style: TextStyle(
                  fontSize: context.ffs(14),
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }

  Widget _coverageDetails(BuildContext context) {
    return TripSection(
      title: 'Coverage Details',
      icon: Icons.verified_user_rounded,
      iconColor: AppColors.AppBlue,
      child: Column(
        children: [
          tripKv(context, 'Plan', booking.planName.isEmpty ? 'N/A' : booking.planName),
          tripKv(context, 'Provider', booking.providerName.isEmpty ? 'N/A' : booking.providerName),
          tripKv(context, 'Destination', booking.destination.isEmpty ? 'N/A' : booking.destination),
          tripKv(context, 'Coverage Period',
              '${formatTripDate(booking.startDate)} - ${formatTripDate(booking.endDate)}'),
          tripKv(context, 'Travellers', '${booking.travellers}'),
        ],
      ),
    );
  }

  Widget _fare(BuildContext context) {
    final cur = booking.currency.isEmpty ? 'INR' : booking.currency;
    final total = double.tryParse(booking.totalAmount) ?? 0;
    final hasBase = booking.basePremium != null && booking.basePremium!.isNotEmpty;
    final taxVal = double.tryParse(booking.tax ?? '') ?? 0;
    final taxIsZero = booking.tax == null || taxVal == 0;

    return TripSection(
      title: 'Fare Details',
      icon: Icons.description_rounded,
      iconColor: kOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TripInset(
            child: Column(
              children: [
                if (hasBase)
                  tripKv(context, 'Base Premium', formatMoney(double.tryParse(booking.basePremium!) ?? 0, cur), muted: true),
                tripKv(context, 'Tax', taxIsZero ? 'Included' : formatMoney(taxVal, cur), muted: true),
                Divider(height: context.fx(20), color: kLine),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total Paid',
                          style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w500, color: kInk)),
                    ),
                    Text(
                      formatMoney(total, cur),
                      style: TextStyle(fontSize: context.ffs(17), fontWeight: FontWeight.w600, color: AppColors.AppBlue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: context.fx(12)),
          TripInset(
            tinted: true,
            title: 'Payment Details',
            titleIcon: Icons.credit_card_rounded,
            child: Column(
              children: [
                tripKv(context, 'Payment Status', '', chip: ('Success', kGreen)),
                if (booking.paymentMethod.isNotEmpty)
                  tripKv(context, 'Payment Method', booking.paymentMethod),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingInfo(BuildContext context) {
    return TripSection(
      title: 'Booking Information',
      icon: Icons.receipt_long_rounded,
      iconColor: AppColors.AppBlue,
      compact: true,
      child: Column(
        children: [
          if (booking.policyNumber.isNotEmpty)
            tripKv(context, 'Policy Number', booking.policyNumber),
          tripKv(context, 'Transaction ID', booking.transactionId),
          tripKv(context, 'Status', booking.status),
          tripKv(context, 'Booking Date', formatTripDate(booking.created)),
          tripKv(context, 'Holder', booking.holderName),
          tripKv(context, 'Email', booking.email),
          tripKv(context, 'Phone', booking.phone),
        ],
      ),
    );
  }

  Widget _importantInfo(BuildContext context) {
    return TripSection(
      title: 'Important Info',
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF6B6B6B),
      compact: true,
      child: Text(
        'Keep this policy document handy during your travel.\n'
        'Carry a valid government-issued ID proof.\n'
        'In case of emergency, contact the insurance provider directly.\n'
        'Claims must be filed within the policy coverage period.',
        style: TextStyle(fontSize: context.ffs(11), height: 1.45, color: const Color(0xFF4B5563)),
      ),
    );
  }
}
