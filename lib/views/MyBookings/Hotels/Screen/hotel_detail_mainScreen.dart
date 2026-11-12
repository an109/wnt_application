import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';
import '../../shared/cancel_booking_flow.dart';
import '../../shared/trip_detail_widgets.dart';
import '../domain/entity/HotelBookingEntity.dart';
import 'hotel_pdf_builder.dart';

class HotelBookingDetailsScreen extends StatelessWidget {
  final HotelBookingListEntity booking;

  const HotelBookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusInfo(booking.status);
    final gap = SizedBox(height: context.fx(16));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: tripBottomBar(context, [
          TripActionButton(
            label: 'CANCEL',
            icon: Icons.cancel_outlined,
            outlined: true,
            onPressed: () => _onCancel(context),
          ),
          TripActionButton(
            label: 'DOWNLOAD TICKET',
            icon: Icons.download_rounded,
            onPressed: () => saveAndOfferPdf(
              context,
              filename: 'hotel_${booking.confirmationNumber}.pdf',
              build: (logo) => HotelPdfBuilder.buildTicket(booking),
            ),
          ),
        ]),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              tripTopBar(
                context,
                title: 'Hotel Details',
                subtitle: 'Booking ID: ${booking.confirmationNumber}',
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
                          _hotelCard(context, label, color),
                          gap,
                          _guestDetails(context),
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
                colors: [Color(0xFFF2D8C8), Color(0xFFFCEDE4), Colors.white],
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
                borderRadius: BorderRadius.circular(context.fx(10)),
                boxShadow: const [
                  BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.fx(10)),
                child: booking.hotelImage.isNotEmpty
                    ? Image.network(
                        booking.hotelImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _hotelIcon(context),
                      )
                    : _hotelIcon(context),
              ),
            ),
          ),
          Positioned(
            right: context.fx(16),
            top: context.fx(28),
            child: Icon(Icons.hotel_rounded, size: context.fx(64), color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _hotelIcon(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Icon(Icons.hotel_rounded, color: const Color(0xFFD32F2F), size: context.fx(28)),
    );
  }

  Widget _hotelCard(BuildContext context, String statusLabel, Color statusColor) {
    final isCancelled = booking.status.toLowerCase().contains('cancel');
    final isPast = !isCancelled && DateTime.tryParse(booking.checkOut)?.isBefore(DateTime.now()) == true;
    final corner = isCancelled
        ? ('Cancelled', kRed)
        : isPast
            ? ('Completed', const Color(0xFF7CC7EE))
            : null;

    return TripSection(
      padding: EdgeInsets.fromLTRB(context.fx(14), context.fx(14), context.fx(14), context.fx(12)),
      cornerTag: corner,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(context.fx(6)),
                child: booking.hotelImage.isNotEmpty
                    ? Image.network(
                        booking.hotelImage,
                        width: context.fx(32),
                        height: context.fx(32),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.hotel_rounded,
                            size: context.fx(32),
                            color: const Color(0xFFD32F2F)),
                      )
                    : Icon(Icons.hotel_rounded, size: context.fx(32), color: const Color(0xFFD32F2F)),
              ),
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.hotelName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600, color: kInk),
                    ),
                    Text(
                      [booking.hotelAddress, booking.hotelCity, booking.hotelCountry]
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.ffs(11), color: kMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (booking.hotelStars > 0) ...[
            SizedBox(height: context.fx(8)),
            Row(
              children: List.generate(
                booking.hotelStars > 5 ? 5 : booking.hotelStars,
                (_) => Icon(Icons.star_rounded, color: Colors.amber, size: context.fx(16)),
              ),
            ),
          ],
          SizedBox(height: context.fx(14)),
          Row(
            children: [
              Expanded(child: _dateBox(context, 'CHECK-IN', formatTripDate(booking.checkIn), AppColors.AppBlue)),
              SizedBox(width: context.fx(10)),
              Expanded(child: _dateBox(context, 'CHECK-OUT', formatTripDate(booking.checkOut), kOrange)),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.fx(12)),
            child: const Divider(height: 1, color: Color(0xFFF0F1F4)),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: TripStat(icon: Icons.king_bed_rounded, label: 'Room', value: booking.roomType.isEmpty ? '—' : booking.roomType)),
                const VerticalDivider(width: 12, color: kLine),
                Expanded(child: TripStat(icon: Icons.door_front_door_rounded, label: 'Rooms', value: '${booking.rooms}')),
                const VerticalDivider(width: 12, color: kLine),
                Expanded(child: TripStat(icon: Icons.nights_stay_rounded, label: 'Nights', value: '${booking.nights}')),
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

  Widget _guestDetails(BuildContext context) {
    return TripSection(
      title: 'Guest Details',
      icon: Icons.groups_rounded,
      iconColor: AppColors.AppBlue,
      child: Column(
        children: [
          tripKv(context, 'Guest Name', booking.guestName),
          tripKv(context, 'Adults', '${booking.adults}'),
          if (booking.children > 0) tripKv(context, 'Children', '${booking.children}'),
          tripKv(context, 'Total Guests', '${booking.guests}'),
        ],
      ),
    );
  }

  Widget _fare(BuildContext context) {
    final cur = booking.currency.isEmpty ? 'INR' : booking.currency;
    final total = double.tryParse(booking.totalFare) ?? 0;
    final tax = double.tryParse(booking.tax) ?? 0;
    final base = total - tax;
    final taxIsZero = tax == 0;

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
                if (base > 0) tripKv(context, 'Room Charges', formatMoney(base, cur), muted: true),
                tripKv(context, 'Tax', taxIsZero ? 'Included' : formatMoney(tax, cur), muted: true),
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
                tripKv(context, 'Payment Method', 'Online'),
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
          tripKv(context, 'Confirmation No.', booking.confirmationNumber),
          tripKv(context, 'Booking Reference', booking.bookingReferenceId),
          if (booking.guestReference.isNotEmpty)
            tripKv(context, 'Guest Reference', booking.guestReference),
          tripKv(context, 'Status', booking.status),
          tripKv(context, 'Booking Date', formatTripDate(booking.bookingDate ?? booking.created)),
          tripKv(context, 'Email', booking.email),
          tripKv(context, 'Phone', booking.phone),
        ],
      ),
    );
  }

  void _onCancel(BuildContext context) async {
    final cur = booking.currency.isEmpty ? 'INR' : booking.currency;
    final total = double.tryParse(booking.totalFare) ?? 0;
    final cancelled = await showCancelAndRefundSheet(
      context,
      params: CancelBookingParams(
        bookingType: 'Hotel',
        bookingId: booking.confirmationNumber,
        route: booking.hotelName,
        detail: booking.hotelCity,
        amount: total,
        currency: cur,
        apiBookingType: 'hotel',
        entityId: booking.id,
        hotelConfirmationNumber: booking.confirmationNumber,
        checkoutId: booking.checkoutId,
      ),
    );
    if (cancelled == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _importantInfo(BuildContext context) {
    return TripSection(
      title: 'Important Info',
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF6B6B6B),
      compact: true,
      child: Text(
        'Present this voucher at hotel reception for check-in.\n'
        'Carry a valid government-issued ID proof for all guests.\n'
        'Check-in: 2:00 PM | Check-out: 11:00 AM.\n'
        'Early check-in is subject to availability.',
        style: TextStyle(fontSize: context.ffs(11), height: 1.45, color: const Color(0xFF4B5563)),
      ),
    );
  }
}
