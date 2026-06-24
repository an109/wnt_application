import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/logoWithoutShimmer.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../UpcomingTrips/data/models/tripModel.dart';

class VisaInvoiceWidget extends StatelessWidget {
  final TripItem trip;

  const VisaInvoiceWidget({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    bool isPending = trip.status.toLowerCase().contains('pending');
    bool isCancelled = trip.status.toLowerCase().contains('cancelled');
    Color statusColor = isPending
        ? const Color(0xFFFFA726)
        : (isCancelled ? const Color(0xFFE53935) : const Color(0xFF4CAF50));

    return Container(
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
                      "INVOICE ${trip.refId}",
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
            "Visa Application",
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.h(10)),
          _detailText(
            context,
            "Date: ${trip.bookedDate}",
          ),
          _detailText(
            context,
            "Destination: ${trip.destination}",
          ),
          _detailText(
            context,
            "Applicants: ${trip.applicantCount}",
          ),
          _detailText(
            context,
            "Status: ${trip.status}",
          ),
          SizedBox(height: context.h(16)),
          Divider(color: Colors.grey[300]),
          SizedBox(height: context.h(16)),

          /// TABLE SECTION
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
                      "Billed by:",
                      "${trip.destination} Visa",
                    ),
                    _billingRow(
                      "Issued by:",
                      "WANDER NOVA",
                    ),
                    _billingRow(
                      "Billing Cycle:",
                      "Immediate",
                    ),
                    _billingRow(
                      "Payment Basis:",
                      "Invoice Date",
                    ),
                    _billingRow(
                      "Invoice Status:",
                      trip.status.toUpperCase(),
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
                      "VISA \nFEE",
                      trip.getFormattedPrice(),
                    ),
                    _amountRow(
                      context,
                      "TAX & FEES",
                      "0",
                    ),
                    Divider(color: Colors.grey[300]),
                    SizedBox(height: context.h(8)),
                    _amountRow(
                      context,
                      "TOTAL",
                      trip.getFormattedPrice(),
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
              fontSize: context.fs(14),
              fontWeight: FontWeight.w700,
              color: const Color(0xff293241),
            ),
          ),
          SizedBox(height: context.h(10)),
          Text(
            "Visa processing fees are non-refundable once the application is submitted. All visa applications are subject to approval by the respective embassy/consulate. We recommend applying well in advance of your travel date. For any queries or support, please contact our visa assistance team.",
            style: TextStyle(
              fontSize: context.fs(10),
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
          /// Table Header
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
          /// Table Rows
          _buildTableRow(context, 'Service Type', 'Visa Application'),
          _buildTableRow(context, 'Category', trip.category),
          _buildTableRow(context, 'Country', trip.destination),
          _buildTableRow(context, 'Visa Type', trip.type),
          _buildTableRow(context, 'Applicants', trip.applicantCount.toString()),
          _buildTableRow(context, 'Status', trip.status),
          _buildTableRow(context, 'Booked Date', trip.bookedDate),
          _buildTableRow(context, 'Reference', trip.refId),

          /// Total Row
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
                    trip.getFormattedPrice(),
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
              value.isEmpty ? 'N/A' : value,
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
          fontSize: context.fs(12),
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _billingRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
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
              fontSize: big ? context.fs(16) : context.fs(11),
              color: big ? const Color(0xff293241) : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: big ? context.fs(17) : context.fs(12),
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
}