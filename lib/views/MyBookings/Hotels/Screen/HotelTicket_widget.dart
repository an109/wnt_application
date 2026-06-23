// hotel_ticket_widget.dart
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logoWithoutShimmer.dart';
import '../../../../core/resources/app_colours.dart';
import '../domain/entity/HotelBookingEntity.dart';

class HotelTicketWidget extends StatelessWidget {
  final HotelBookingListEntity booking;

  const HotelTicketWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(context.w(12)),
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: context.h(10)),
            _buildConfirmationCard(context),
            SizedBox(height: context.h(12)),
            _buildHotelDetailsCard(context),
            SizedBox(height: context.h(10)),
            _buildFareSummary(context),
            SizedBox(height: context.h(10)),
            _buildBookingInformation(context),
            SizedBox(height: context.h(10)),
            _buildGuestInformation(context),
            SizedBox(height: context.h(10)),
            _buildFooter(context),
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
                "HOTEL",
                style: TextStyle(
                  fontSize: context.fs(20),
                  fontWeight: FontWeight.w800,
                  // color: AppColors.primary,
                  color: Colors.black,
                  letterSpacing: context.letterSpacingWider,
                ),
              ),
              Text(
                "VOUCHER",
                style: TextStyle(
                  fontSize: context.fs(20),
                  fontWeight: FontWeight.w800,
                  // color: AppColors.orange,
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

  Widget _buildConfirmationCard(BuildContext context) {
    bool isPending = booking.status.toLowerCase().contains('pending');
    bool isCancelled = booking.status.toLowerCase().contains('cancelled');
    Color statusColor = isPending ? Colors.orange : (isCancelled ? Colors.red : Colors.green);
    IconData statusIcon = isPending ? Icons.hourglass_empty_rounded :
    (isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded);

    return Container(
      padding: EdgeInsets.all(context.w(4)),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        // border: Border.all(color: statusColor.withOpacity(0.3)),
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

  Widget _buildHotelPlaceholder(BuildContext context) {
    return Container(
      width: context.w(52),
      height: context.w(52),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Icon(
        Icons.hotel_rounded,
        color: const Color(0xFFD32F2F),
        size: context.w(24),
      ),
    );
  }

  Widget _buildHotelDetailsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        // border: Border.all(color: AppColors.divider),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColors.shadow,
        //     blurRadius: context.w(4),
        //     offset: Offset(0, context.h(2)),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(context.r(10)),
                child: booking.hotelImage.isNotEmpty
                    ? Image.network(
                  booking.hotelImage,
                  width: context.w(52),
                  height: context.w(52),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      _buildHotelPlaceholder(context),
                )
                    : _buildHotelPlaceholder(context),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.hotelName,
                      style: TextStyle(
                        fontSize: context.fs(16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${booking.hotelAddress}${booking.hotelCity.isNotEmpty ? ', ${booking.hotelCity}' : ''}${booking.hotelCountry.isNotEmpty ? ', ${booking.hotelCountry}' : ''}",
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (booking.hotelStars > 0) ...[
                      SizedBox(height: context.h(4)),
                      Row(
                        children: List.generate(
                          booking.hotelStars > 5 ? 5 : booking.hotelStars,
                              (index) => Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: context.w(14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          Row(
            children: [
              Expanded(
                child: _dateBox(
                  context,
                  "CHECK-IN",
                  _formatDate(booking.checkIn),
                  AppColors.primary,
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: _dateBox(
                  context,
                  "CHECK-OUT",
                  _formatDate(booking.checkOut),
                  AppColors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          Row(
            children: [
              Expanded(child: _infoBox(context, "ROOM TYPE", booking.roomType)),
              Expanded(child: _infoBox(context, "ROOMS", booking.rooms.toString())),
              Expanded(child: _infoBox(context, "GUESTS", booking.guests.toString())),
              Expanded(child: _infoBox(context, "NIGHTS", booking.nights.toString())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateBox(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.fs(8),
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
              letterSpacing: context.letterSpacingWider,
            ),
          ),
          SizedBox(height: context.h(6)),
          Text(
            value,
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.fs(8),
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
            letterSpacing: context.letterSpacingWider,
          ),
        ),
        SizedBox(height: context.h(4)),
        Text(
          value,
          style: TextStyle(
            fontSize: context.fs(11),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          // overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFareSummary(BuildContext context) {
    return _sectionCard(
      context,
      "FARE SUMMARY",
      [
        _fareRow(
          context,
          "Tax",
          "${booking.currency} ${booking.tax}",
        ),
        Divider(height: context.h(16), color: AppColors.divider),
        _fareRow(
          context,
          "Total Paid",
          "${booking.currency} ${booking.totalFare}",
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
        _infoRow(context, "Booking Reference", booking.bookingReferenceId),
        _infoRow(context, "Guest Reference", booking.guestReference),
        // _infoRow(context, "Payment Mode", booking.paymentMode),
        _infoRow(context, "Payment Mode", "Online"),
        _infoRow(context, "Status", booking.status),
        _infoRow(context, "Booking Date", booking.bookingDate ?? booking.created),
      ],
    );
  }

  Widget _buildGuestInformation(BuildContext context) {
    return _sectionCard(
      context,
      "GUEST INFORMATION",
      [
        _infoRow(context, "Guest Name", booking.guestName),
        _infoRow(context, "Email", booking.email),
        _infoRow(context, "Phone", booking.phone),
        _infoRow(context, "Adults", booking.adults.toString()),
        _infoRow(context, "Children", booking.children.toString()),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return _sectionCard(
      context,
      "IMPORTANT INFORMATION",
      [
        _bulletPoint(context, "Please present this voucher at hotel reception for check-in."),
        _bulletPoint(context, "Carry a valid government-issued ID proof for all guests."),
        _bulletPoint(context, "Check-in time: 2:00 PM | Check-out time: 11:00 AM"),
        _bulletPoint(context, "Early check-in is subject to availability."),
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
        // border: Border.all(color: AppColors.divider),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColors.shadow,
        //     blurRadius: context.w(4),
        //     offset: Offset(0, context.h(2)),
        //   ),
        // ],
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

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateString);
      return '${dt.day} ${_getMonth(dt.month)} ${dt.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}