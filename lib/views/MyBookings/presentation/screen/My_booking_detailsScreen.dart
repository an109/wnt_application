
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../UI_helper/currency_converter.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../domain/entity/MyBooking_entity.dart';

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
    Color statusColor = isPending ? const Color(0xFFFFA726) : (isCancelled ? const Color(0xFFE53935) : const Color(0xFF4CAF50));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: context.w(20), color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Booking Details', style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(booking, statusColor),
                  _buildSectionTitle('Trip Information'),
                  _buildTripInfoCard(booking),
                  _buildSectionTitle('Passenger Details'),
                  _buildPassengerCard(booking),
                  _buildSectionTitle('Payment Details'),
                  _buildPaymentCard(booking),
                  SizedBox(height: context.h(100)), // Space for bottom bar
                ],
              ),
            ),
          ),
          _buildBottomActionBar(booking, isCancelled),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeaderCard(BookingEntity booking, Color statusColor) {
    return Container(
      margin: EdgeInsets.fromLTRB(context.w(16), context.h(16), context.w(16), 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.w(10), offset: Offset(0, context.h(4)))],
      ),
      child: Column(
        children: [
          Container(
            height: context.h(6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(context.r(16)), topRight: Radius.circular(context.r(16))),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(4)),
                      decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(context.r(8))),
                      child: Text(booking.confirmationNumber, style: TextStyle(color: Colors.grey[700], fontSize: context.fs(11), fontWeight: FontWeight.w600)),
                    ),
                    _buildStatusBadge(booking.status, statusColor),
                  ],
                ),
                SizedBox(height: context.h(12)),
                Text(booking.destination, style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                SizedBox(height: context.h(4)),
                Text(booking.type, style: TextStyle(fontSize: context.fs(13), color: Colors.grey[600])),
                SizedBox(height: context.h(16)),
                Divider(height: 1, color: Colors.grey[200]),
                SizedBox(height: context.h(16)),
                Row(
                  children: [
                    _buildInfoChip(Icons.calendar_today_rounded, 'Booked', booking.bookedDate),
                    SizedBox(width: context.w(16)),
                    _buildInfoChip(Icons.people_rounded, 'Travelers', '${booking.applicantCount}'),
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
      padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(context.r(8))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPending ? Icons.hourglass_empty_rounded : (isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded), size: context.w(12), color: color),
          SizedBox(width: context.w(4)),
          Text(status, style: TextStyle(color: color, fontSize: context.fs(11), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: context.w(16), color: const Color(0xFFD32F2F)),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: context.fs(10), color: Colors.grey[500])),
                Text(value, style: TextStyle(fontSize: context.fs(13), color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(20), context.w(16), context.h(10)),
      child: Text(title, style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
    );
  }

  Widget _buildTripInfoCard(BookingEntity booking) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(16)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: context.w(8), offset: Offset(0, context.h(2)))],
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.location_on_rounded, 'Pickup Location', booking.startAddress.isNotEmpty ? booking.startAddress : 'N/A'),
          SizedBox(height: context.h(16)),
          _buildDetailRow(Icons.flag_rounded, 'Drop-off Location', booking.endAddress.isNotEmpty ? booking.endAddress : 'N/A'),
          SizedBox(height: context.h(16)),
          _buildDetailRow(Icons.access_time_rounded, 'Pickup Time', _formatDateTime(booking.pickupDatetime)),
          SizedBox(height: context.h(16)),
          _buildDetailRow(
              booking.category == 'Flight' ? Icons.flight_takeoff_rounded : Icons.directions_car_rounded,
              booking.category == 'Flight' ? 'Flight Number' : 'Vehicle Type',
              booking.category == 'Flight' ? (booking.flightNumber.isNotEmpty ? booking.flightNumber : 'N/A') : (booking.vehicleName.isNotEmpty ? booking.vehicleName : 'N/A')
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(BookingEntity booking) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(16)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: context.w(8), offset: Offset(0, context.h(2)))],
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.person_outline_rounded, 'Full Name', '${booking.firstName} ${booking.lastName}'),
          SizedBox(height: context.h(16)),
          _buildDetailRow(Icons.email_outlined, 'Email Address', booking.email),
          SizedBox(height: context.h(16)),
          _buildDetailRow(Icons.phone_outlined, 'Phone Number', booking.phoneNumber),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BookingEntity booking) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(16)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: context.w(8), offset: Offset(0, context.h(2)))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Paid', style: TextStyle(fontSize: context.fs(14), color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Text(_getConvertedAmountText(booking), style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
            ],
          ),
          SizedBox(height: context.h(12)),
          Divider(height: 1, color: Colors.grey[200]),
          SizedBox(height: context.h(12)),
          _buildPaymentRow('Original Amount', '${booking.currency} ${booking.totalPrice}'),
          SizedBox(height: context.h(8)),
          _buildPaymentRow('Provider', booking.providerName.isNotEmpty ? booking.providerName : 'N/A'),
          SizedBox(height: context.h(8)),
          _buildPaymentRow('Payment Status', booking.status),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(12), color: Colors.grey[500])),
        Flexible(child: Text(value, style: TextStyle(fontSize: context.fs(12), color: Colors.black87, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(context.w(8)),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(context.r(8))),
          child: Icon(icon, size: context.w(18), color: const Color(0xFFD32F2F)),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: context.fs(11), color: Colors.grey[500], fontWeight: FontWeight.w500)),
              SizedBox(height: context.h(2)),
              Text(value, style: TextStyle(fontSize: context.fs(13), color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BookingEntity booking, bool isCancelled) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(12), context.w(16), context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.w(10), offset: Offset(0, -context.h(2)))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (booking.canCancel && !isCancelled) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                    padding: EdgeInsets.symmetric(vertical: context.h(14)),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.red[400], fontSize: context.fs(14), fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(width: context.w(12)),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement contact support logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.OrangeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                  padding: EdgeInsets.symmetric(vertical: context.h(14)),
                  elevation: 0,
                ),
                child: Text('Contact Support', style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(16))),
        title: Text('Cancel Booking', style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this booking? This action cannot be undone.', style: TextStyle(fontSize: context.fs(14), color: Colors.grey[600])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('No, Keep It', style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white))),
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
    if (!_currencyInitialized) return '${booking.currency} ${booking.totalPrice}';
    try {
      final originalAmount = double.tryParse(booking.totalPrice.toString()) ?? 0.0;
      final originalCurrency = booking.currency.toUpperCase();
      final targetCurrency = _displayCurrency;

      if (originalCurrency == targetCurrency) {
        return '${CurrencyConverter.getSymbol(originalCurrency)} ${originalAmount.toStringAsFixed(0)}';
      }

      final prefs = sl<PreferencesManager>();
      final rates = prefs.getCachedExchangeRates();

      if (rates != null && rates.containsKey(originalCurrency) && rates.containsKey(targetCurrency)) {
        final convertedAmount = CurrencyConverter.convert(amount: originalAmount, fromCurrency: originalCurrency, toCurrency: targetCurrency);
        return '${CurrencyConverter.getSymbol(targetCurrency)} ${convertedAmount.toStringAsFixed(0)}';
      }
      return '${booking.currency} ${booking.totalPrice}';
    } catch (e) {
      return '${booking.currency} ${booking.totalPrice}';
    }
  }
}