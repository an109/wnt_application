import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';
import '../Hotels/domain/entity/HotelBookingEntity.dart';

class HotelBookingDetailsScreen extends StatefulWidget {
  final HotelBookingListEntity booking;

  const HotelBookingDetailsScreen({super.key, required this.booking});

  @override
  State<HotelBookingDetailsScreen> createState() => _HotelBookingDetailsScreenState();
}

class _HotelBookingDetailsScreenState extends State<HotelBookingDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    bool isPending = booking.status.toLowerCase().contains('pending');
    bool isCancelled = booking.status.toLowerCase().contains('cancelled');
    Color statusColor = isPending
        ? const Color(0xFFFFA726)
        : (isCancelled ? const Color(0xFFE53935) : const Color(0xFF4CAF50));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.h(12)),
                    _buildHeaderCard(booking, statusColor),
                    SizedBox(height: context.h(16)),
                    _buildHotelInfoCard(booking),
                    SizedBox(height: context.h(16)),
                    _buildRoomDetailsCard(booking),
                    SizedBox(height: context.h(16)),
                    _buildGuestCard(booking),
                    SizedBox(height: context.h(16)),
                    _buildPaymentCard(booking),
                    SizedBox(height: context.h(80)),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActionBar(booking, isCancelled),
        ],
      ),
    );
  }

  // --- APP BAR ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: context.w(18),
          color: const Color(0xFF1A1A2E),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Hotel Details',
        style: TextStyle(
          fontSize: context.fs(16),
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A2E),
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  // --- HEADER CARD ---
  Widget _buildHeaderCard(HotelBookingListEntity booking, Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(2)),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            height: context.h(3),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.r(14)),
                topRight: Radius.circular(context.r(14)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.w(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(3),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(context.r(6)),
                      ),
                      child: Text(
                        booking.confirmationNumber,
                        style: TextStyle(
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    _buildStatusBadge(booking.status, statusColor),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Text(
                  booking.hotelName.isNotEmpty ? booking.hotelName : 'Unknown Hotel',
                  style: TextStyle(
                    fontSize: context.fs(20),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
                if (booking.hotelAddress.isNotEmpty) ...[
                  SizedBox(height: context.h(2)),
                  Text(
                    booking.hotelAddress,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                SizedBox(height: context.h(12)),
                Divider(
                  height: context.h(1),
                  color: const Color(0xFFE5E7EB),
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.login_rounded,
                      'Check-in',
                      _formatDate(booking.checkIn),
                    ),
                    SizedBox(width: context.w(12)),
                    _buildInfoChip(
                      Icons.logout_rounded,
                      'Check-out',
                      _formatDate(booking.checkOut),
                    ),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.nights_stay_rounded,
                      'Nights',
                      '${booking.nights}',
                    ),
                    SizedBox(width: context.w(12)),
                    _buildInfoChip(
                      Icons.people_rounded,
                      'Guests',
                      '${booking.guests}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    bool isPending = status.toLowerCase().contains('pending');
    bool isCancelled = status.toLowerCase().contains('cancelled');
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(6),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(context.r(6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPending ? Icons.hourglass_empty_rounded :
            (isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded),
            size: context.w(10),
            color: color,
          ),
          SizedBox(width: context.w(3)),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: context.fs(10),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: context.w(14),
            color: const Color(0xFFD32F2F),
          ),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(9),
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: const Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HOTEL INFO CARD ---
  Widget _buildHotelInfoCard(HotelBookingListEntity booking) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(2)),
          )
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.hotel_rounded,
            'Hotel',
            booking.hotelName.isNotEmpty ? booking.hotelName : 'N/A',
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.location_on_rounded,
            'Address',
            booking.hotelAddress.isNotEmpty ? booking.hotelAddress : 'N/A',
          ),
          if (booking.hotelCity.isNotEmpty) ...[
            SizedBox(height: context.h(12)),
            _buildDetailRow(
              Icons.location_city_rounded,
              'City',
              booking.hotelCity,
            ),
          ],
          if (booking.hotelStars > 0) ...[
            SizedBox(height: context.h(12)),
            _buildDetailRow(
              Icons.star_rounded,
              'Rating',
              '${booking.hotelStars} Stars',
            ),
          ],
        ],
      ),
    );
  }

  // --- ROOM DETAILS CARD ---
  Widget _buildRoomDetailsCard(HotelBookingListEntity booking) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(2)),
          )
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.bed_rounded,
            'Room Type',
            booking.roomType.isNotEmpty ? booking.roomType : 'N/A',
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.meeting_room_rounded,
            'Rooms',
            '${booking.rooms}',
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.person_rounded,
            'Adults',
            '${booking.adults}',
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.child_care_rounded,
            'Children',
            '${booking.children}',
          ),
        ],
      ),
    );
  }

  // --- GUEST CARD ---
  Widget _buildGuestCard(HotelBookingListEntity booking) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(2)),
          )
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.person_outline_rounded,
            'Guest',
            booking.guestName.isNotEmpty ? booking.guestName : 'N/A',
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.email_outlined,
            'Email',
            booking.email.isNotEmpty ? booking.email : 'N/A',
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.phone_outlined,
            'Phone',
            booking.phone.isNotEmpty ? booking.phone : 'N/A',
          ),
        ],
      ),
    );
  }

  // --- PAYMENT CARD ---
  Widget _buildPaymentCard(HotelBookingListEntity booking) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(2)),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${booking.currency} ${booking.totalFare}',
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Divider(
            height: context.h(1),
            color: const Color(0xFFE5E7EB),
          ),
          SizedBox(height: context.h(10)),
          _buildPaymentRow('Base Fare', '${booking.currency} ${booking.totalFare}'),
          SizedBox(height: context.h(6)),
          _buildPaymentRow('Tax', '${booking.currency} ${booking.tax}'),
          SizedBox(height: context.h(6)),
          _buildPaymentRow(
            'Payment Mode',
            booking.paymentMode.isNotEmpty ? booking.paymentMode : 'N/A',
          ),
          SizedBox(height: context.h(6)),
          _buildPaymentRow('Status', booking.status),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.fs(11),
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w400,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: context.fs(11),
              color: const Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // --- DETAIL ROW ---
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(context.w(6)),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(context.r(6)),
          ),
          child: Icon(
            icon,
            size: context.w(14),
            color: const Color(0xFFD32F2F),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: context.h(1)),
              Text(
                value,
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: const Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- BOTTOM ACTION BAR ---
  Widget _buildBottomActionBar(HotelBookingListEntity booking, bool isCancelled) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(10),
        context.w(16),
        context.h(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.w(8),
            offset: Offset(0, -context.h(2)),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isCancelled) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFE53935).withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                    padding: EdgeInsets.symmetric(vertical: context.h(12)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: const Color(0xFFE53935),
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.w(10)),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement contact support logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.OrangeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: context.h(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG ---
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(14)),
        ),
        title: Text(
          'Cancel Booking',
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this hotel booking? This action cannot be undone.',
          style: TextStyle(
            fontSize: context.fs(13),
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep It',
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: context.fs(13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.fs(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateString);
      List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (e) {
      return dateString;
    }
  }
}