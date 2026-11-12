import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logoWithoutShimmer.dart';
import '../../../../core/resources/app_colours.dart';
import '../../Insurance/domain/entity/InsuranceBookingEntity.dart';

class InsuranceTicketWidget extends StatelessWidget {
  final InsuranceBookingEntity booking;

  const InsuranceTicketWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(context.w(12)),
        child: Column(
          children: [
            // _buildHeader(context),
            // SizedBox(height: context.h(10)),
            _buildConfirmationCard(context),
            SizedBox(height: context.h(12)),
            _buildPolicyDetailsCard(context),
            SizedBox(height: context.h(10)),
            _buildCoverageCard(context),
            SizedBox(height: context.h(10)),
            _buildPaymentSummary(context),
            SizedBox(height: context.h(10)),
            _buildBookingInformation(context),
            SizedBox(height: context.h(10)),
            _buildContactInformation(context),
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
        const Expanded(child: Logo(scaleFactor: 0.6)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "INSURANCE",
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: context.letterSpacingWider,
                ),
              ),
              Text(
                "POLICY",
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

  Widget _buildConfirmationCard(BuildContext context) {
    final status = booking.status.toLowerCase();
    final isPending = status.contains('pending');
    final isCancelled = status.contains('cancelled') || status.contains('cancel');
    final Color statusColor = isPending
        ? Colors.orange
        : (isCancelled ? Colors.red : Colors.green);
    final IconData statusIcon = isPending
        ? Icons.hourglass_empty_rounded
        : (isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded);
    final String title = isPending
        ? 'Policy is Pending'
        : (isCancelled ? 'Policy Cancelled' : 'Policy Confirmed');
    final String subtitle = isPending
        ? 'Your policy is being processed'
        : (isCancelled ? 'This policy has been cancelled' : 'Thank you for choosing us');

    return Container(
      padding: EdgeInsets.all(context.w(4)),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.w(15),
            backgroundColor: statusColor,
            child: Icon(statusIcon, color: Colors.white, size: context.w(18)),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (booking.policyNumber.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Policy No",
                  style: TextStyle(fontSize: context.fs(8), color: AppColors.textLight),
                ),
                Text(
                  booking.policyNumber,
                  style: TextStyle(
                    fontSize: context.fs(14),
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

  Widget _buildPolicyDetailsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.w(52),
                height: context.w(52),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Icon(
                  Icons.shield_moon_outlined,
                  color: AppColors.primary,
                  size: context.w(24),
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.planName.isNotEmpty ? booking.planName : 'Insurance Policy',
                      style: TextStyle(
                        fontSize: context.fs(16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (booking.providerName.isNotEmpty) ...[
                      SizedBox(height: context.h(2)),
                      Text(
                        booking.providerName,
                        style: TextStyle(
                          fontSize: context.fs(11),
                          color: AppColors.textSecondary,
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
                child: _dateBox(context, "START DATE", _formatDate(booking.startDate), AppColors.primary),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: _dateBox(context, "END DATE", _formatDate(booking.endDate), const Color(0xFFEE7330)),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          Row(
            children: [
              Expanded(child: _infoBox(context, "DESTINATION", booking.destination)),
              Expanded(child: _infoBox(context, "TRAVELLERS", booking.travellers.toString())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageCard(BuildContext context) {
    return _sectionCard(context, "COVERAGE DETAILS", [
      _infoRow(context, "Plan", booking.planName),
      _infoRow(context, "Provider", booking.providerName),
      _infoRow(context, "Destination", booking.destination),
      _infoRow(context, "Coverage Period",
          '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}'),
      _infoRow(context, "No. of Travellers", booking.travellers.toString()),
    ]);
  }

  Widget _buildPaymentSummary(BuildContext context) {
    final hasBase = booking.basePremium != null && booking.basePremium!.isNotEmpty;
    final taxVal = double.tryParse(booking.tax ?? '') ?? 0;
    final taxIsZero = booking.tax == null || taxVal == 0;

    return _sectionCard(context, "PAYMENT SUMMARY", [
      if (hasBase)
        _fareRow(context, "Base Premium", "${booking.currency} ${booking.basePremium}"),
      if (hasBase) SizedBox(height: context.h(4)),
      _fareRow(
        context,
        "Tax",
        taxIsZero ? "Included" : "${booking.currency} ${booking.tax}",
      ),
      Divider(height: context.h(16), color: AppColors.divider),
      _fareRow(context, "Total Paid", "${booking.currency} ${booking.totalAmount}", big: true),
    ]);
  }

  Widget _buildBookingInformation(BuildContext context) {
    return _sectionCard(context, "BOOKING INFORMATION", [
      if (booking.policyNumber.isNotEmpty) _infoRow(context, "Policy Number", booking.policyNumber),
      _infoRow(context, "Transaction ID", booking.transactionId),
      _infoRow(context, "Payment Method", booking.paymentMethod),
      _infoRow(context, "Status", booking.status),
      _infoRow(context, "Booking Date", _formatDate(booking.created)),
    ]);
  }

  Widget _buildContactInformation(BuildContext context) {
    return _sectionCard(context, "CONTACT INFORMATION", [
      _infoRow(context, "Holder Name", booking.holderName),
      _infoRow(context, "Email", booking.email),
      _infoRow(context, "Phone", booking.phone),
    ]);
  }

  Widget _buildFooter(BuildContext context) {
    return _sectionCard(context, "IMPORTANT INFORMATION", [
      _bulletPoint(context, "Keep this policy document handy during your travel."),
      _bulletPoint(context, "Carry a valid government-issued ID proof."),
      _bulletPoint(context, "In case of emergency, contact the insurance provider directly."),
      _bulletPoint(context, "Claims must be filed within the policy coverage period."),
      _bulletPoint(context, "Cancellation policy applies as per booking terms."),
    ]);
  }

  Widget _dateBox(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
          value.isNotEmpty ? value : 'N/A',
          style: TextStyle(
            fontSize: context.fs(11),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
        ),
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

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateString);
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
