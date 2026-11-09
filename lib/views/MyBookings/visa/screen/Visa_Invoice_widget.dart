import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';
import '../../../UpcomingTrips/data/models/tripModel.dart';

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF6B7280);
const Color _kLine = Color(0xFFE5E7EB);
const Color _kOrange = Color(0xFFEE7330);
const Color _kGreen = Color(0xFF34A853);

class VisaInvoiceWidget extends StatelessWidget {
  final TripItem trip;

  const VisaInvoiceWidget({super.key, required this.trip});

  bool get _isPending => trip.status.toLowerCase().contains('pending');
  bool get _isCancelled => trip.status.toLowerCase().contains('cancelled');

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.fx(16));
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.fx(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context),
          gap,
          _buildApplicationCard(context),
          gap,
          _buildApplicantDetails(context),
          gap,
          _buildFareDetails(context),
          gap,
          _buildBaggageAndInfo(context),
          gap,
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: context.fx(100),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8CC8F2), Color(0xFFD8EEFC), Colors.white],
              ),
            ),
          ),
          Positioned(
            left: -context.fx(40),
            right: -context.fx(40),
            bottom: -context.fx(36),
            child: Image.asset('assets/home/footer_clouds.png', height: context.fx(90), fit: BoxFit.cover),
          ),
          Positioned(
            left: context.fx(16),
            top: context.fx(20),
            child: Container(
              width: context.fx(56),
              height: context.fx(56),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.fx(10)),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))],
                color: const Color(0xFFE9F6FD),
              ),
              child: Icon(Icons.description_rounded, size: context.fx(28), color: AppColors.AppBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context) {
    final (statusLabel, statusColor) = _isPending
        ? ('Pending', const Color(0xFFE59400))
        : (_isCancelled
            ? ('Cancelled', const Color(0xFFE53935))
            : ('Approved', _kGreen));
    final corner = _isCancelled
        ? ('Cancelled', const Color(0xFFE53935))
        : (_isPending ? ('Pending', const Color(0xFFE59400)) : null);

    return _Section(
      padding: EdgeInsets.fromLTRB(context.fx(14), context.fx(14), context.fx(14), context.fx(12)),
      cornerTag: corner,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: context.fx(56),
                height: context.fx(56),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.fx(10)),
                  color: const Color(0xFFE9F6FD),
                ),
                child: Icon(Icons.public_rounded, size: context.fx(28), color: AppColors.AppBlue),
              ),
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.destination.isNotEmpty ? trip.destination : 'Visa Application',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600, color: _kInk),
                    ),
                    if (trip.type.isNotEmpty)
                      Text(
                        trip.type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.ffs(11), color: _kMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(14)),
          _Inset(
            child: Column(
              children: [
                _kv(context, 'Service Type', 'Visa Application'),
                _kv(context, 'Category', trip.category.isNotEmpty ? trip.category : 'N/A'),
                _kv(context, 'Country', trip.destination.isNotEmpty ? trip.destination : 'N/A'),
                _kv(context, 'Visa Type', trip.type.isNotEmpty ? trip.type : 'N/A'),
                _kv(context, 'Reference', trip.refId.isNotEmpty ? trip.refId : 'N/A'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.fx(12)),
            child: const Divider(height: 1, color: Color(0xFFF0F1F4)),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _Stat(icon: Icons.person_rounded, label: 'Applicants', value: trip.applicantCount.isNotEmpty ? trip.applicantCount : '—')),
                const VerticalDivider(width: 12, color: _kLine),
                Expanded(child: _Stat(icon: Icons.calendar_today_rounded, label: 'Booked', value: trip.bookedDate.isNotEmpty ? trip.bookedDate : '—')),
                const VerticalDivider(width: 12, color: _kLine),
                Expanded(child: _Stat(icon: Icons.verified_rounded, label: 'Status', value: statusLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantDetails(BuildContext context) {
    final names = trip.travellerNames;
    return _Section(
      title: 'Applicant Details',
      icon: Icons.groups_rounded,
      iconColor: AppColors.AppBlue,
      child: names.isEmpty
          ? Text(
              '${trip.applicantCount.isNotEmpty ? trip.applicantCount : '—'} applicant(s)',
              style: TextStyle(fontSize: context.ffs(12.5), color: _kMuted),
            )
          : Column(
              children: [
                for (var i = 0; i < names.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == names.length - 1 ? 0 : context.fx(10)),
                    child: Container(
                      padding: EdgeInsets.all(context.fx(12)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.fx(12)),
                        border: Border.all(color: _kLine),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              names[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: context.ffs(13.5), fontWeight: FontWeight.w600, color: _kInk),
                            ),
                          ),
                          Text(
                            'Applicant ${i + 1}',
                            style: TextStyle(fontSize: context.ffs(11), color: _kMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFareDetails(BuildContext context) {
    final formattedPrice = trip.getFormattedPrice();
    final currencyCode = trip.getPreferredCurrencyCode();
    return _Section(
      title: 'Fare Details',
      icon: Icons.description_rounded,
      iconColor: _kOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Inset(
            child: Column(
              children: [
                _kv(context, 'Visa Fee (${trip.applicantCount.isNotEmpty ? trip.applicantCount : '1'} Applicant${(int.tryParse(trip.applicantCount) ?? 1) > 1 ? 's' : ''})', formattedPrice, muted: true),
                _kv(context, 'Taxes & Fees', '$currencyCode 0.00', muted: true),
                _kv(context, 'Convenience Fee', '$currencyCode 0.00', muted: true),
                Divider(height: context.fx(20), color: _kLine),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total Paid', style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w500, color: _kInk)),
                    ),
                    Text(
                      formattedPrice,
                      style: TextStyle(fontSize: context.ffs(17), fontWeight: FontWeight.w600, color: AppColors.AppBlue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: context.fx(12)),
          _Inset(
            tinted: true,
            title: 'Payment Details',
            titleIcon: Icons.credit_card_rounded,
            child: Column(
              children: [
                _kvChip(context, 'Payment Status', _isCancelled ? ('Cancelled', const Color(0xFFE53935)) : ('Success', _kGreen)),
                _kv(context, 'Payment Method', 'Online'),
                _kv(context, 'Payment Date', trip.bookedDate.isNotEmpty ? trip.bookedDate : 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaggageAndInfo(BuildContext context) {
    return _Section(
      title: 'Important Info',
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF6B6B6B),
      compact: true,
      child: Text(
        'Valid passport and visa required for travel.\n'
        'Visa processing time may vary by country and type.\n'
        'Ensure all documents are submitted as per requirements.\n'
        'For any queries, contact our visa assistance team.',
        style: TextStyle(fontSize: context.ffs(11), height: 1.45, color: const Color(0xFF4B5563)),
      ),
    );
  }

  Widget _kv(BuildContext context, String label, String value, {bool muted = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.fx(5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: context.ffs(12.5), color: muted ? _kMuted : const Color(0xFF4B5563)),
            ),
          ),
          SizedBox(width: context.fx(8)),
          Flexible(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: context.ffs(12.5), fontWeight: FontWeight.w500, color: _kInk),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvChip(BuildContext context, String label, (String, Color) chip) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.fx(5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: context.ffs(12.5), color: const Color(0xFF4B5563)),
            ),
          ),
          SizedBox(width: context.fx(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(3)),
            decoration: BoxDecoration(
              color: chip.$2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.fx(20)),
            ),
            child: Text(chip.$1, style: TextStyle(fontSize: context.ffs(11.5), color: chip.$2)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Color? iconColor;
  final Widget child;
  final EdgeInsets? padding;
  final (String, Color)? cornerTag;
  final bool compact;

  const _Section({
    this.title,
    this.icon,
    this.iconColor,
    required this.child,
    this.padding,
    this.cornerTag,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(context.fx(compact ? 12 : 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(14)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(icon, size: context.fx(compact ? 16 : 18), color: iconColor),
                SizedBox(width: context.fx(8)),
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: context.ffs(compact ? 13 : 14.5),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111527),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.fx(12)),
          ],
          child,
        ],
      ),
    );
    if (cornerTag == null) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -1,
          right: context.fx(10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(3)),
            decoration: BoxDecoration(
              color: cornerTag!.$2,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.fx(8))),
            ),
            child: Text(
              cornerTag!.$1,
              style: TextStyle(fontSize: context.ffs(10.5), fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _Inset extends StatelessWidget {
  final Widget child;
  final bool tinted;
  final String? title;
  final IconData? titleIcon;

  const _Inset({required this.child, this.tinted = false, this.title, this.titleIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: BoxDecoration(
        color: tinted ? const Color(0xFFF3FAFE) : Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: tinted ? const Color(0xFFD6ECF8) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(titleIcon, size: context.fx(16), color: const Color(0xFF34A853)),
                SizedBox(width: context.fx(8)),
                Text(title!, style: TextStyle(fontSize: context.ffs(12.5), fontWeight: FontWeight.w600, color: const Color(0xFF111527))),
              ],
            ),
            SizedBox(height: context.fx(6)),
          ],
          child,
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: context.fx(30),
          height: context.fx(30),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(context.fx(6)),
          ),
          child: Icon(icon, size: context.fx(17), color: const Color(0xFF3B9BE0)),
        ),
        SizedBox(width: context.fx(6)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: context.ffs(10.5), color: const Color(0xFF6B7280))),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.ffs(13), fontWeight: FontWeight.w600, color: const Color(0xFF111527)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
