import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';
import '../../shared/cancel_booking_flow.dart';
import '../../shared/trip_detail_widgets.dart';
import '../domain/entity/MyBooking_entity.dart';
import 'transport_pdf_builder.dart';

class BookingDetailsScreen extends StatelessWidget {
  final BookingEntity booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusInfo(booking.status);
    final gap = SizedBox(height: context.fx(16));
    final isAirport = booking.category == 'Flight';

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
              filename: 'transport_${booking.confirmationNumber}.pdf',
              build: (logo) async => TransportPdfBuilder.buildTicket(booking),
            ),
          ),
        ]),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              tripTopBar(
                context,
                title: 'Trip Details',
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
                          _tripCard(context, isAirport),
                          gap,
                          _passengerDetails(context),
                          gap,
                          _fare(context),
                          gap,
                          _bookingInfo(context),
                          gap,
                          _importantInfo(context, isAirport),
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
                colors: [Color(0xFFD4E8D0), Color(0xFFE8F5E4), Colors.white],
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
                child: booking.imageUrl.isNotEmpty
                    ? Image.network(booking.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _transportIcon(context))
                    : _transportIcon(context),
              ),
            ),
          ),
          Positioned(
            right: context.fx(16),
            top: context.fx(28),
            child: Icon(Icons.directions_car_rounded, size: context.fx(64), color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _transportIcon(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Icon(Icons.directions_car_rounded, color: AppColors.primary, size: context.fx(28)),
    );
  }

  Widget _tripCard(BuildContext context, bool isAirport) {
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
                child: Icon(
                  isAirport ? Icons.flight_rounded : Icons.directions_car_rounded,
                  color: AppColors.primary,
                  size: context.fx(20),
                ),
              ),
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.category.isNotEmpty ? '${booking.category} Transfer' : 'Transport',
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
          _routeBox(context),
          if (booking.pickupDatetime.isNotEmpty) ...[
            SizedBox(height: context.fx(10)),
            _dateBox(context, 'PICKUP TIME', _formatPickupTime(booking.pickupDatetime), AppColors.AppBlue),
          ],
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.fx(12)),
            child: const Divider(height: 1, color: Color(0xFFF0F1F4)),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TripStat(
                    icon: isAirport ? Icons.flight_rounded : Icons.directions_car_rounded,
                    label: isAirport ? 'Flight' : 'Vehicle',
                    value: isAirport
                        ? (booking.flightNumber.isEmpty ? '—' : booking.flightNumber)
                        : (booking.vehicleName.isEmpty ? '—' : booking.vehicleName),
                  ),
                ),
                const VerticalDivider(width: 12, color: kLine),
                Expanded(
                  child: TripStat(
                    icon: Icons.groups_rounded,
                    label: 'Travellers',
                    value: '${booking.applicantCount}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeBox(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(context.fx(10)),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Icon(Icons.circle, size: context.fx(10), color: kGreen),
              Container(width: 1, height: context.fx(20), color: kLine),
              Icon(Icons.circle, size: context.fx(10), color: kRed),
            ],
          ),
          SizedBox(width: context.fx(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.startAddress.isEmpty ? 'Pickup location' : booking.startAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.ffs(12), fontWeight: FontWeight.w500, color: kInk),
                ),
                SizedBox(height: context.fx(12)),
                Text(
                  booking.endAddress.isEmpty ? 'Drop-off location' : booking.endAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.ffs(12), fontWeight: FontWeight.w500, color: kInk),
                ),
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

  Widget _passengerDetails(BuildContext context) {
    return TripSection(
      title: 'Passenger Details',
      icon: Icons.groups_rounded,
      iconColor: AppColors.AppBlue,
      child: Column(
        children: [
          tripKv(context, 'Name', '${booking.firstName} ${booking.lastName}'.trim()),
          tripKv(context, 'Email', booking.email.isEmpty ? 'N/A' : booking.email),
          tripKv(context, 'Phone', booking.phoneNumber.isEmpty ? 'N/A' : booking.phoneNumber),
          tripKv(context, 'Travellers', '${booking.applicantCount}'),
        ],
      ),
    );
  }

  Widget _fare(BuildContext context) {
    final cur = booking.currency.isEmpty ? 'INR' : booking.currency;
    final price = booking.totalPrice.isNotEmpty ? booking.totalPrice : booking.rawTotalPrice;
    final total = double.tryParse(price) ?? 0;

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
                tripKv(context, 'Base Fare', formatMoney(total, cur), muted: true),
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
                if (booking.paymentMethod.isNotEmpty)
                  tripKv(context, 'Payment Method', booking.paymentMethod),
                tripKv(context, 'Payment Mode', booking.type),
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
          tripKv(context, 'Category', booking.category),
          tripKv(context, 'Status', booking.status),
          tripKv(context, 'Booking Date', formatTripDate(booking.bookedDate)),
          tripKv(context, 'Provider', booking.providerName),
        ],
      ),
    );
  }

  void _onCancel(BuildContext context) async {
    final cur = booking.currency.isEmpty ? 'INR' : booking.currency;
    final price = booking.totalPrice.isNotEmpty ? booking.totalPrice : booking.rawTotalPrice;
    final total = double.tryParse(price) ?? 0;
    final route = [booking.startAddress, booking.endAddress]
        .where((s) => s.isNotEmpty)
        .join(' → ');
    final cancelled = await showCancelAndRefundSheet(
      context,
      params: CancelBookingParams(
        bookingType: 'Transport',
        bookingId: booking.confirmationNumber,
        route: route.isNotEmpty ? route : 'Transport Booking',
        detail: booking.providerName,
        amount: total,
        currency: cur,
        apiBookingType: 'transport',
        entityId: booking.id,
        transportReservationId: booking.confirmationNumber,
        paidVia: booking.paymentMethod,
      ),
    );
    if (cancelled == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _importantInfo(BuildContext context, bool isAirport) {
    final text = isAirport
        ? 'Present this voucher at the airline for check-in.\n'
          'Carry a valid government-issued ID proof for all travellers.\n'
          'Arrive at the airport at least 2 hours before departure.\n'
          'Cancellation policy applies as per booking terms.'
        : 'Please be ready at the pickup location 10 minutes early.\n'
          'Carry a valid government-issued ID proof for all travellers.\n'
          'Driver will wait for maximum 15 minutes after pickup time.\n'
          'Cancellation policy applies as per booking terms.';

    return TripSection(
      title: 'Important Info',
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF6B6B6B),
      compact: true,
      child: Text(
        text,
        style: TextStyle(fontSize: context.ffs(11), height: 1.45, color: const Color(0xFF4B5563)),
      ),
    );
  }

  String _formatPickupTime(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $time';
    } catch (_) {
      return isoString;
    }
  }
}
