import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logoWithoutShimmer.dart';
import '../../../../core/resources/app_colours.dart';
import '../domain/entity/HotelBookingEntity.dart';

class HotelInvoiceWidget extends StatelessWidget {
  final HotelBookingListEntity booking;

  const HotelInvoiceWidget({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: EdgeInsets.all(context.w(2)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LOGO
              const Expanded(
                child: Logo(scaleFactor: 0.5),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "INVOICE",
                      style: TextStyle(
                        fontSize: context.fs(24),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff293241),
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      "INVOICE ${booking.confirmationNumber}",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: context.fs(11),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          SizedBox(height: context.h(20)),

          /// CUSTOMER DETAILS
          Text(
            booking.guestName.isNotEmpty ? booking.guestName : "Guest",
            style: TextStyle(
              fontSize: context.fs(18),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.h(10)),
          _detailText(
            context,
            // "Date: ${booking.bookingDate}",
            "Date: ${_todayDate()}",
          ),
          _detailText(
            context,
            "Email: ${booking.email.isNotEmpty ? booking.email : 'N/A'}",
          ),
          _detailText(
            context,
            "Phone: ${booking.phone.isNotEmpty ? booking.phone : 'N/A'}",
          ),
          SizedBox(height: context.h(16)),
          Divider(color: Colors.grey[300]),
          SizedBox(height: context.h(16)),

          /// TABLE SECTION - Redesigned
          _buildInvoiceTable(context),

          SizedBox(height: context.h(20)),

          /// BILLING + TOTAL
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LEFT - Billing Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _billingRow(
                      context,
                      "Billed by:",
                      booking.guestName.isNotEmpty ? booking.guestName : "Guest",
                    ),
                    _billingRow(
                      context,
                      "Issued by:",
                      "WANDER NOVA",
                    ),
                    _billingRow(
                      context,
                      "Billing Cycle:",
                      "Immediate",
                    ),
                    _billingRow(
                      context,
                      "Payment Basis:",
                      "Invoice Date",
                    ),
                    _billingRow(
                      context,
                      "Invoice Status:",
                      booking.status.toUpperCase(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(20)),

              /// RIGHT - Amount
              Expanded(
                child: Column(
                  children: [
                    _amountRow(
                      context,
                      "ROOM CHARGE",
                      "${booking.currency} ${booking.totalFare}",
                    ),
                    _amountRow(
                      context,
                      "TAX & FEES",
                      "${booking.currency} ${booking.tax}",
                    ),
                    Divider(color: Colors.grey[300]),
                    SizedBox(height: context.h(8)),
                    _amountRow(
                      context,
                      "TOTAL",
                      "${booking.currency} ${booking.totalFare}",
                      big: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(20)),
          Divider(color: Colors.grey[300]),
          SizedBox(height: context.h(20)),

          /// TERMS
          Text(
            "TERMS AND CONDITIONS",
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
              color: const Color(0xff293241),
            ),
          ),
          SizedBox(height: context.h(10)),
          Text(
            "Payment is due within 30 days of invoice date. Late payments may incur additional charges. All bookings are subject to our terms and conditions. Cancellations must be made at least 24 hours before departure for a full refund. For any queries or support, please contact us. This invoice is valid for the services listed above.",
            style: TextStyle(
              fontSize: context.fs(12),
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          SizedBox(height: context.h(20)),

          /// BOTTOM BAR
          Container(
            height: context.h(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0077CC)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInvoiceTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(10),
              vertical: context.h(8),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0077CC)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.r(8)),
                topRight: Radius.circular(context.r(8)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Description',
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Details',
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          _buildTableRow(context, 'Hotel Name', booking.hotelName),
          _buildTableRow(context, 'Room Type', booking.roomType),
          _buildTableRow(context, 'Check-in', _formatDate(booking.checkIn)),
          _buildTableRow(context, 'Check-out', _formatDate(booking.checkOut)),
          _buildTableRow(context, 'Nights', booking.nights.toString()),
          _buildTableRow(context, 'Rooms', booking.rooms.toString()),
          _buildTableRow(context, 'Guests', booking.guests.toString()),
          // _buildTableRow(context, 'Adults', booking.adults.toString()),
          _buildTableRow(context, 'Children', booking.children.toString()),
          _buildTableRow(context, 'Payment Mode', "Online"),
          // _buildTableRow(context, 'Payment Mode', booking.paymentMode),
          // Total Row
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(10),
              vertical: context.h(8),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0077CC)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(context.r(8)),
                bottomRight: Radius.circular(context.r(8)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${booking.currency} ${booking.totalFare}',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailText(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(6)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(14),
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _billingRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black,
            fontSize: context.fs(11),
          ),
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            TextSpan(
              text: " $value",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(
      BuildContext context,
      String title,
      String value, {
        bool big = false,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: big ? context.fs(18) : context.fs(13),
              color: big ? const Color(0xff293241) : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: big ? context.fs(18) : context.fs(13),
              color: big ? const Color(0xff293241) : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _todayDate() {
    final d = DateTime.now();
    return "${d.day}/${d.month}/${d.year}";
  }

  String _formatDate(String date) {
    if (date.isEmpty) return "-";
    try {
      final dt = DateTime.parse(date);
      return "${dt.day} ${_month(dt.month)}'${dt.year.toString().substring(2)}";
    } catch (_) {
      return date;
    }
  }

  String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[m - 1];
  }
}