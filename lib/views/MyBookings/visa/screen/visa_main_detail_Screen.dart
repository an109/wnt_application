import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';
import '../../../UpcomingTrips/data/models/tripModel.dart';
import '../../shared/trip_detail_widgets.dart';
import 'visa_booking_summary_card.dart' show VisaBookingSummaryScreen;
import 'visa_pdf_builder.dart';

class VisaBookingDetailsScreen extends StatelessWidget {
  final TripItem trip;

  const VisaBookingDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusInfo(trip.status);
    final gap = SizedBox(height: context.fx(16));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: trip.status.toLowerCase().contains('cancelled')
            ? tripBottomBar(context, [
                TripActionButton(
                  label: 'DOWNLOAD',
                  icon: Icons.download_rounded,
                  onPressed: () => saveAndOfferPdf(
                    context,
                    filename: 'visa_${trip.bookingId}.pdf',
                    build: (logo) async => VisaPdfBuilder.buildTicket(trip),
                  ),
                ),
              ])
            : tripBottomBar(context, [
                TripActionButton(
                  label: 'VIEW INVOICE',
                  icon: Icons.receipt_long_rounded,
                  outlined: true,
                  onPressed: () => VisaBookingSummaryScreen.open(context, trip),
                ),
                TripActionButton(
                  label: 'DOWNLOAD',
                  icon: Icons.download_rounded,
                  onPressed: () => saveAndOfferPdf(
                    context,
                    filename: 'visa_${trip.bookingId}.pdf',
                    build: (logo) async => VisaPdfBuilder.buildTicket(trip),
                  ),
                ),
              ]),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              tripTopBar(
                context,
                title: 'Visa Details',
                subtitle: 'Booking ID: ${trip.bookingId}',
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
                          _visaCard(context),
                          gap,
                          _travellerDetails(context),
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
                colors: [Color(0xFFD6D0E8), Color(0xFFEDE8F5), Colors.white],
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
              child: Icon(Icons.card_travel_rounded, color: AppColors.primary, size: context.fx(28)),
            ),
          ),
          Positioned(
            right: context.fx(16),
            top: context.fx(28),
            child: Icon(Icons.card_travel_rounded, size: context.fx(64), color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _visaCard(BuildContext context) {
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
                child: Icon(Icons.card_travel_rounded, color: AppColors.primary, size: context.fx(20)),
              ),
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.destination} Visa',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600, color: kInk),
                    ),
                    Text(
                      trip.type.isNotEmpty ? trip.type : 'Visa Application',
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
              Expanded(child: _dateBox(context, 'ONWARD DATE', formatTripDate(trip.onwardDate), AppColors.AppBlue)),
              SizedBox(width: context.fx(10)),
              Expanded(child: _dateBox(context, 'RETURN DATE', formatTripDate(trip.returnDate), kOrange)),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.fx(12)),
            child: const Divider(height: 1, color: Color(0xFFF0F1F4)),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: TripStat(icon: Icons.public_rounded, label: 'Destination', value: trip.destination.isEmpty ? '—' : trip.destination)),
                const VerticalDivider(width: 12, color: kLine),
                Expanded(child: TripStat(icon: Icons.groups_rounded, label: 'Applicants', value: trip.applicantCount)),
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

  Widget _travellerDetails(BuildContext context) {
    return TripSection(
      title: 'Traveller Details',
      icon: Icons.groups_rounded,
      iconColor: AppColors.AppBlue,
      child: Column(
        children: [
          tripKv(context, 'Applicants', trip.applicantCount),
          if (trip.travellerNames.isNotEmpty)
            for (int i = 0; i < trip.travellerNames.length; i++)
              tripKv(context, 'Traveller ${i + 1}', trip.travellerNames[i]),
        ],
      ),
    );
  }

  Widget _fare(BuildContext context) {
    final cur = trip.originalCurrency.isEmpty ? 'INR' : trip.originalCurrency;
    final total = trip.price;

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
                tripKv(context, 'Visa Fee', formatMoney(total, cur), muted: true),
                tripKv(context, 'Tax', 'Included', muted: true),
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
                tripKv(context, 'Payment Mode', trip.type),
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
          tripKv(context, 'Booking ID', trip.bookingId),
          if (trip.refId.isNotEmpty && trip.refId != 'VISA')
            tripKv(context, 'Reference ID', trip.refId),
          tripKv(context, 'Visa Type', trip.type),
          tripKv(context, 'Status', trip.status),
          tripKv(context, 'Booking Date', formatTripDate(trip.bookedDate)),
          tripKv(context, 'Category', trip.category),
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
        'Processing times may vary based on destination country.\n'
        'Ensure all documents submitted are valid and up to date.\n'
        'Carry printed copies of your visa approval for travel.\n'
        'Check destination entry requirements before departure.',
        style: TextStyle(fontSize: context.ffs(11), height: 1.45, color: const Color(0xFF4B5563)),
      ),
    );
  }
}
