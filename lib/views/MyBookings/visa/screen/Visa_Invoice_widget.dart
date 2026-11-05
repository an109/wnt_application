import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';
import '../../../UpcomingTrips/data/models/tripModel.dart';

class VisaInvoiceWidget extends StatelessWidget {
  final TripItem trip;

  const VisaInvoiceWidget({super.key, required this.trip});

  bool get _isPending => trip.status.toLowerCase().contains('pending');
  bool get _isCancelled => trip.status.toLowerCase().contains('cancelled');

  Color get _statusColor => _isPending
      ? const Color(0xFFF59E0B)
      : (_isCancelled ? const Color(0xFFEF4444) : const Color(0xFF10B981));

  Color get _statusBg => _isPending
      ? const Color(0xFFFFF7ED)
      : (_isCancelled ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Column(
        children: [
          _buildStatusHeader(context),
          SizedBox(height: context.h(12)),
          _buildDetailsCard(context),
          SizedBox(height: context.h(12)),
          _buildPricingCard(context),
          SizedBox(height: context.h(12)),
          _buildBillingCard(context),
          SizedBox(height: context.h(12)),
          _buildTermsCard(context),
          SizedBox(height: context.h(16)),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [BoxShadow(color: const Color(0x08000000), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: context.w(48),
            height: context.w(48),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(context.r(12)),
            ),
            child: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: context.w(24)),
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice ${trip.bookingId}',
                  style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  trip.bookedDate.isNotEmpty ? trip.bookedDate : 'N/A',
                  style: TextStyle(fontSize: context.fs(12), color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(6)),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(context.r(20)),
            ),
            child: Text(
              trip.status.isNotEmpty ? trip.status : 'N/A',
              style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w600, color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [BoxShadow(color: const Color(0x08000000), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.w(16), context.h(16), context.w(16), context.h(12)),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: context.w(18), color: AppColors.primary),
                SizedBox(width: context.w(8)),
                Text(
                  'Application Details',
                  style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: const Color(0xFFF3F4F6)),
          _row(context, 'Service Type', 'Visa Application'),
          _row(context, 'Category', trip.category.isNotEmpty ? trip.category : 'N/A'),
          _row(context, 'Country', trip.destination.isNotEmpty ? trip.destination : 'N/A'),
          _row(context, 'Visa Type', trip.type.isNotEmpty ? trip.type : 'N/A'),
          _row(context, 'Applicants', trip.applicantCount.isNotEmpty ? trip.applicantCount : 'N/A'),
          _row(context, 'Booked Date', trip.bookedDate.isNotEmpty ? trip.bookedDate : 'N/A'),
          _row(context, 'Reference', trip.refId.isNotEmpty ? trip.refId : 'N/A', isLast: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: const Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontSize: context.fs(13), color: const Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w500, color: const Color(0xFF111827)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [BoxShadow(color: const Color(0x08000000), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.w(16), context.h(16), context.w(16), context.h(12)),
            child: Row(
              children: [
                Icon(Icons.payments_outlined, size: context.w(18), color: AppColors.primary),
                SizedBox(width: context.w(8)),
                Text(
                  'Payment Summary',
                  style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: const Color(0xFFF3F4F6)),
          _priceRow(context, 'Visa Fee', trip.getFormattedPrice()),
          _priceRow(context, 'Tax & Fees', '${trip.getPreferredCurrencyCode()} 0.00'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            child: Divider(height: 1, color: const Color(0xFFE5E7EB)),
          ),
          Container(
            padding: EdgeInsets.all(context.w(16)),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(context.r(14)),
                bottomRight: Radius.circular(context.r(14)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                ),
                Text(
                  trip.getFormattedPrice(),
                  style: TextStyle(fontSize: context.fs(17), fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: context.fs(13), color: const Color(0xFF6B7280))),
          Text(value, style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w500, color: const Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _buildBillingCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [BoxShadow(color: const Color(0x08000000), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_outlined, size: context.w(18), color: AppColors.primary),
              SizedBox(width: context.w(8)),
              Text(
                'Billing Information',
                style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          _billingItem(context, 'Billed by', trip.destination.isNotEmpty ? '${trip.destination} Visa' : 'N/A'),
          _billingItem(context, 'Issued by', 'WANDER NOVA'),
          _billingItem(context, 'Billing Cycle', 'Immediate'),
          _billingItem(context, 'Payment Basis', 'Invoice Date'),
          _billingItem(context, 'Invoice Status', trip.status.isNotEmpty ? trip.status.toUpperCase() : 'N/A'),
        ],
      ),
    );
  }

  Widget _billingItem(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.w(110),
            child: Text(label, style: TextStyle(fontSize: context.fs(12), color: const Color(0xFF9CA3AF))),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [BoxShadow(color: const Color(0x08000000), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, size: context.w(16), color: const Color(0xFF9CA3AF)),
              SizedBox(width: context.w(8)),
              Text(
                'Terms and Conditions',
                style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Text(
            'Visa processing fees are non-refundable once the application is submitted. '
            'All visa applications are subject to approval by the respective embassy/consulate. '
            'We recommend applying well in advance of your travel date. '
            'For any queries or support, please contact our visa assistance team.',
            style: TextStyle(fontSize: context.fs(11), color: const Color(0xFF9CA3AF), height: 1.6),
          ),
        ],
      ),
    );
  }
}
