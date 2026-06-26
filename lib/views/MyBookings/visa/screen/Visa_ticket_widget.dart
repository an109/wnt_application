import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/logoWithoutShimmer.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../UpcomingTrips/data/models/tripModel.dart';

class VisaTicketWidget extends StatelessWidget {
  final TripItem trip;

  const VisaTicketWidget({
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
            _buildVisaDetailsCard(context),
            SizedBox(height: context.h(12)),
            _buildApplicantCard(context),
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
                "VISA",
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
    bool isPending = trip.status.toLowerCase().contains('pending');
    bool isCancelled = trip.status.toLowerCase().contains('cancelled');
    IconData statusIcon = isPending
        ? Icons.hourglass_empty_rounded
        : (isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded);

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
                  isPending
                      ? "Visa Application is Pending"
                      : (isCancelled
                      ? "Visa Application Cancelled"
                      : "Visa Application Approved"),
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                Text(
                  isPending
                      ? "Your visa application is being processed"
                      : (isCancelled
                      ? "This visa application has been cancelled"
                      : "Your visa apploication is under processing"),
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
                "Reference No",
                style: TextStyle(
                  fontSize: context.fs(8),
                  color: AppColors.textLight,
                ),
              ),
              Text(
                trip.refId,
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

  Widget _buildVisaDetailsCard(BuildContext context) {
    return _sectionCard(
      context,
      "VISA DETAILS",
      [
        _infoRow(context, "Country", trip.destination),
        _infoRow(context, "Visa Type", trip.type),
        _infoRow(context, "Category", trip.category),
        // _infoRow(context, "Service Type", trip.type),
        _infoRow(context, "Processing Time", _getProcessingTime()),
      ],
    );
  }

  Widget _buildApplicantCard(BuildContext context) {
    return _sectionCard(
      context,
      "APPLICANT INFORMATION",
      [
        _infoRow(
          context,
          "Total Applicants",
          trip.applicantCount.toString(),
        ),
        _infoRow(
          context,
          "Application Date",
          trip.bookedDate,
        ),
        _infoRow(context, "Status", trip.status),
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
          "Visa Fee",
          trip.getFormattedPrice(),
        ),
        _fareRow(
          context,
          "Service Fee",
          _formatPrice(0),
        ),
        _fareRow(
          context,
          "Tax & Charges",
          _formatPrice(0),
        ),
        Divider(height: context.h(16), color: AppColors.divider),
        _fareRow(
          context,
          "Total Paid",
          trip.getFormattedPrice(),
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
        _infoRow(context, "Reference No", trip.refId),
        _infoRow(context, "Service Type", trip.type),
        _infoRow(context, "Category", trip.category),
        _infoRow(context, "Status", trip.status),
        _infoRow(context, "Booked Date", trip.bookedDate),
        _infoRow(context, "Destination", trip.destination),
      ],
    );
  }

  Widget _buildImportantInfo(BuildContext context) {
    return _sectionCard(
      context,
      "IMPORTANT INFORMATION",
      [
        _bulletPoint(
          context,
          "Please carry a valid passport with at least 6 months validity from the date of travel.",
        ),
        _bulletPoint(
          context,
          "Carry a printout of this visa voucher for verification.",
        ),
        _bulletPoint(
          context,
          "Visa processing time may vary depending on the country and type of visa.",
        ),
        _bulletPoint(
          context,
          "Ensure all documents are submitted as per the requirements.",
        ),
        _bulletPoint(
          context,
          "Cancellation policy applies as per visa terms and conditions.",
        ),
      ],
    );
  }

  Widget _sectionCard(
      BuildContext context,
      String title,
      List<Widget> children,
      ) {
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

  Widget _fareRow(
      BuildContext context,
      String title,
      String value, {
        bool big = false,
      }) {
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

  String _getProcessingTime() {
    // You can add logic here based on visa type
    return "5-10 Business Days";
  }

  String _formatPrice(double amount) {
    return '0';
    // return '${trip.price} ${amount.toStringAsFixed(0)}';
  }
}