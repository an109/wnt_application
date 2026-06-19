import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logoWithoutShimmer.dart';
import '../../../../core/resources/app_colours.dart';
import '../domain/entity/MyBooking_entity.dart';

class BookingTicketWidget extends StatelessWidget {
  final BookingEntity booking;

  const BookingTicketWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    bool isPending = booking.status.toLowerCase().contains('pending');
    bool isCancelled = booking.status.toLowerCase().contains('cancelled');
    Color statusColor = isPending
        ? const Color(0xFFFFA726)
        : (isCancelled ? const Color(0xFFE53935) : const Color(0xFF4CAF50));

    return Container(
      color: AppColors.lightBg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(context.w(12)),
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: context.h(12)),
            _buildConfirmationCard(context, statusColor),
            SizedBox(height: context.h(12)),
            _buildTripDetailsCard(context),
            SizedBox(height: context.h(12)),
            _buildPassengerCard(context),
            SizedBox(height: context.h(12)),
            _buildFareSummary(context),
            SizedBox(height: context.h(10)),
            _buildBookingInformation(context),
            SizedBox(height: context.h(10)),
            _buildImportantInfo(context),
            SizedBox(height: context.h(14)),
            Container(
              height: context.h(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0077CC)],
                ),
                borderRadius: BorderRadius.circular(context.r(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Logo(scaleFactor: 0.6),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                booking.type.toUpperCase(),
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: context.letterSpacingWider,
                ),
              ),
              Text(
                "VOUCHER",
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: context.letterSpacingWider,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationCard(BuildContext context, Color statusColor) {
    bool isPending = booking.status.toLowerCase().contains('pending');
    bool isCancelled = booking.status.toLowerCase().contains('cancelled');
    IconData statusIcon = isPending ? Icons.hourglass_empty_rounded :
    (isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded);

    return Container(
      padding: EdgeInsets.all(context.w(4)),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.w(15),
            backgroundColor: statusColor,
            child: Icon(
              statusIcon,
              color: Colors.white,
              size: context.w(18),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending ? "Booking is Pending" :
                  (isCancelled ? "Booking Cancelled" : "Booking Confirmed"),
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                Text(
                  isPending ? "Your booking is being processed" :
                  (isCancelled ? "This booking has been cancelled" : "Thank you for booking with us"),
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Confirmation No",
                style: TextStyle(
                  fontSize: context.fs(8),
                  color: AppColors.textLight,
                ),
              ),
              Text(
                booking.confirmationNumber,
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard(BuildContext context) {
    return _sectionCard(
      context,
      "TRIP DETAILS",
      [
        _infoRow(context, "Pickup", booking.startAddress),
        _infoRow(context, "Drop-off", booking.endAddress),
        _infoRow(context, "Pickup Time", _formatDateTime(booking.pickupDatetime)),
        if (booking.category == 'Flight') ...[
          _infoRow(context, "Flight Number", booking.flightNumber),
        ] else ...[
          _infoRow(context, "Vehicle", booking.vehicleName),
        ],
        _infoRow(context, "Category", booking.category),
      ],
    );
  }

  Widget _buildPassengerCard(BuildContext context) {
    return _sectionCard(
      context,
      "PASSENGER INFORMATION",
      [
        _infoRow(context, "Name", "${booking.firstName} ${booking.lastName}"),
        _infoRow(context, "Email", booking.email),
        _infoRow(context, "Phone", booking.phoneNumber),
        _infoRow(context, "Applicants", booking.applicantCount.toString()),
      ],
    );
  }

  Widget _buildFareSummary(BuildContext context) {
    String amount = booking.totalPrice;
    if (amount.isEmpty) amount = booking.rawTotalPrice;

    return _sectionCard(
      context,
      "FARE SUMMARY",
      [
        _fareRow(
          context,
          "Base Fare",
          "${booking.currency} ${amount}",
        ),
        _fareRow(
          context,
          "Tax",
          "${booking.currency} 0",
        ),
        Divider(height: context.h(16), color: AppColors.divider),
        _fareRow(
          context,
          "Total Paid",
          _getConvertedAmountText(booking),
          big: true,
        ),
      ],
    );
  }

  Widget _buildBookingInformation(BuildContext context) {
    return _sectionCard(
      context,
      "BOOKING INFORMATION",
      [
        // _infoRow(context, "Booking Reference", booking.re),
        _infoRow(context, "Confirmation No", booking.confirmationNumber),
        _infoRow(context, "Payment Mode", booking.type),
        _infoRow(context, "Status", booking.status),
        _infoRow(context, "Booked Date", booking.bookedDate),
        _infoRow(context, "Provider", booking.providerName),
      ],
    );
  }

  Widget _buildImportantInfo(BuildContext context) {
    bool isAirport = booking.category == 'Flight';
    return _sectionCard(
      context,
      "IMPORTANT INFORMATION",
      [
        _bulletPoint(context, "Please present this voucher to the ${isAirport ? 'airline' : 'driver'} for check-in."),
        _bulletPoint(context, "Carry a valid government-issued ID proof for all travelers."),
        if (isAirport) ...[
          _bulletPoint(context, "Arrive at the airport at least 2 hours before departure."),
          _bulletPoint(context, "Check-in baggage allowance: As per airline policy."),
        ] else ...[
          _bulletPoint(context, "Please be ready at the pickup location 10 minutes before the scheduled time."),
          _bulletPoint(context, "Driver will wait for maximum 15 minutes after the scheduled pickup time."),
        ],
        _bulletPoint(context, "Cancellation policy applies as per booking terms."),
      ],
    );
  }

  Widget _sectionCard(BuildContext context, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: context.letterSpacingWider,
            ),
          ),
          SizedBox(height: context.h(12)),
          ...children,
        ],
      ),
    );
  }

  Widget _fareRow(BuildContext context, String title, String value, {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: big ? context.fs(16) : context.fs(12),
            fontWeight: big ? FontWeight.w800 : FontWeight.w600,
            color: big ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? context.fs(16) : context.fs(12),
            fontWeight: big ? FontWeight.w800 : FontWeight.w600,
            color: big ? AppColors.orange : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: context.fs(11),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(3)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontSize: context.fs(11),
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.fs(10),
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(isoString);
      List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      String time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $time';
    } catch (e) {
      return isoString;
    }
  }

  String _getConvertedAmountText(BookingEntity booking) {
    String amount = booking.totalPrice;
    if (amount.isEmpty) amount = booking.rawTotalPrice;
    return '${booking.currency} $amount';
  }
}