import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../UI_helper/currency_converter.dart';
import '../../../core/resources/app_colours.dart';
import '../../../core/utils/storage/shared_preference.dart';
import '../../../injection_container.dart';
import '../Transport/domain/entity/MyBooking_entity.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingEntity booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  String _displayCurrency = 'USD';
  bool _currencyInitialized = false;

  @override
  void initState() {
    super.initState();
    _displayCurrency = CurrencyConverter.getPreferredCurrency();
    _currencyInitialized = true;
  }

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
                    _buildTripInfoCard(booking),
                    SizedBox(height: context.h(16)),
                    _buildPassengerCard(booking),
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
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: context.w(18),
            color: const Color(0xFF1A1A2E)
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Booking Details',
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
  Widget _buildHeaderCard(BookingEntity booking, Color statusColor) {
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
                  booking.destination,
                  style: TextStyle(
                    fontSize: context.fs(20),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  booking.type,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: context.h(12)),
                Divider(
                  height: context.h(1),
                  color: const Color(0xFFE5E7EB),
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.calendar_today_rounded,
                      'Booked',
                      booking.bookedDate,
                    ),
                    SizedBox(width: context.w(12)),
                    _buildInfoChip(
                      Icons.people_rounded,
                      'Travelers',
                      '${booking.applicantCount}',
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

  // --- TRIP INFO CARD ---
  Widget _buildTripInfoCard(BookingEntity booking) {
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
            Icons.location_on_rounded,
            'Pickup',
            booking.startAddress.isNotEmpty ? booking.startAddress : 'N/A',
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.flag_rounded,
            'Drop-off',
            booking.endAddress.isNotEmpty ? booking.endAddress : 'N/A',
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.access_time_rounded,
            'Pickup Time',
            _formatDateTime(booking.pickupDatetime),
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            booking.category == 'Flight'
                ? Icons.flight_takeoff_rounded
                : Icons.directions_car_rounded,
            booking.category == 'Flight' ? 'Flight' : 'Vehicle',
            booking.category == 'Flight'
                ? (booking.flightNumber.isNotEmpty ? booking.flightNumber : 'N/A')
                : (booking.vehicleName.isNotEmpty ? booking.vehicleName : 'N/A'),
          ),
        ],
      ),
    );
  }

  // --- PASSENGER CARD ---
  Widget _buildPassengerCard(BookingEntity booking) {
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
            'Name',
            '${booking.firstName} ${booking.lastName}',
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.email_outlined,
            'Email',
            booking.email,
          ),
          SizedBox(height: context.h(12)),
          _buildDetailRow(
            Icons.phone_outlined,
            'Phone',
            booking.phoneNumber,
          ),
        ],
      ),
    );
  }

  // --- PAYMENT CARD ---
  Widget _buildPaymentCard(BookingEntity booking) {
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
                _getConvertedAmountText(booking),
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
          _buildPaymentRow('Original', '${booking.currency} ${booking.totalPrice}'),
          SizedBox(height: context.h(6)),
          _buildPaymentRow(
            'Provider',
            booking.providerName.isNotEmpty ? booking.providerName : 'N/A',
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
  Widget _buildBottomActionBar(BookingEntity booking, bool isCancelled) {
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
            if (booking.canCancel && !isCancelled) ...[
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
          'Are you sure you want to cancel this booking? This action cannot be undone.',
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
    if (!_currencyInitialized) {
      return '${CurrencyConverter.getSymbol(booking.currency)} ${booking.totalPrice}';
    }

    try {
      final originalAmount = double.tryParse(booking.totalPrice) ?? 0.0;
      final originalCurrency = booking.currency.toUpperCase();
      final targetCurrency = _displayCurrency;

      if (originalAmount == 0 && double.tryParse(booking.rawTotalPrice) != null) {
        final fallbackAmount = double.tryParse(booking.rawTotalPrice) ?? 0.0;
        final fallbackCurrency = booking.rawCurrency.toUpperCase();

        if (fallbackAmount > 0) {
          if (fallbackCurrency == targetCurrency) {
            return '${CurrencyConverter.getSymbol(targetCurrency)} ${fallbackAmount.toStringAsFixed(0)}';
          }
          final convertedAmount = CurrencyConverter.convert(
            amount: fallbackAmount,
            fromCurrency: fallbackCurrency,
            toCurrency: targetCurrency,
          );
          return '${CurrencyConverter.getSymbol(targetCurrency)} ${convertedAmount.toStringAsFixed(0)}';
        }
      }

      if (originalCurrency == targetCurrency) {
        return '${CurrencyConverter.getSymbol(originalCurrency)} ${originalAmount.toStringAsFixed(0)}';
      }

      final convertedAmount = CurrencyConverter.convert(
        amount: originalAmount,
        fromCurrency: originalCurrency,
        toCurrency: targetCurrency,
      );
      return '${CurrencyConverter.getSymbol(targetCurrency)} ${convertedAmount.toStringAsFixed(0)}';
    } catch (e) {
      print('Currency conversion error: $e');
      final fallbackAmount = double.tryParse(booking.rawTotalPrice) ?? double.tryParse(booking.totalPrice) ?? 0.0;
      final fallbackCurrency = booking.rawCurrency.isNotEmpty ? booking.rawCurrency : booking.currency;
      return '${CurrencyConverter.getSymbol(fallbackCurrency)} ${fallbackAmount.toStringAsFixed(0)}';
    }
  }
}