import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';
import '../domain/entity/MyBooking_entity.dart';

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF6B7280);
const Color _kLine = Color(0xFFE5E7EB);
const Color _kOrange = Color(0xFFEE7330);
const Color _kGreen = Color(0xFF34A853);

class BookingInvoiceWidget extends StatelessWidget {
  final BookingEntity booking;

  const BookingInvoiceWidget({super.key, required this.booking});

  bool get _isPending => booking.status.toLowerCase().contains('pending');
  bool get _isCancelled =>
      booking.status.toLowerCase().contains('cancel') || booking.cancelled;

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
          _buildBookingCard(context),
          gap,
          _buildPassengerDetails(context),
          gap,
          _buildFareDetails(context),
          gap,
          _buildImportantInfo(context),
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
            child: Image.asset('assets/home/footer_clouds.png',
                height: context.fx(90), fit: BoxFit.cover),
          ),
          Positioned(
            left: context.fx(16),
            top: context.fx(20),
            child: Container(
              width: context.fx(56),
              height: context.fx(56),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.fx(10)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 10,
                      offset: Offset(0, 3))
                ],
                color: const Color(0xFFE9F6FD),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: context.fx(28), color: AppColors.AppBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context) {
    final (statusLabel, _) = _isPending
        ? ('Pending', const Color(0xFFE59400))
        : (_isCancelled
            ? ('Cancelled', const Color(0xFFE53935))
            : ('Confirmed', _kGreen));
    final corner = _isCancelled
        ? ('Cancelled', const Color(0xFFE53935))
        : (_isPending ? ('Pending', const Color(0xFFE59400)) : null);

    return _Section(
      padding: EdgeInsets.fromLTRB(
          context.fx(14), context.fx(14), context.fx(14), context.fx(12)),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF8C42), Color(0xFFFF6600)],
                  ),
                  borderRadius: BorderRadius.circular(context.fx(10)),
                ),
                child: Icon(Icons.directions_car_rounded,
                    size: context.fx(28), color: Colors.white),
              ),
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.vehicleName.isNotEmpty
                          ? booking.vehicleName
                          : 'Transfer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.ffs(15),
                          fontWeight: FontWeight.w600,
                          color: _kInk),
                    ),
                    if (booking.providerName.isNotEmpty)
                      Text(
                        booking.providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.ffs(11), color: _kMuted),
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
                _kv(context, 'Service Type', booking.type.isNotEmpty ? booking.type : 'Transfer'),
                _kv(context, 'Category', booking.category.isNotEmpty ? booking.category : 'N/A'),
                _kv(context, 'Pickup', booking.startAddress.isNotEmpty ? booking.startAddress : 'N/A'),
                _kv(context, 'Drop-off', booking.endAddress.isNotEmpty ? booking.endAddress : 'N/A'),
                _kv(context, 'Pickup Time', _formatDateTime(booking.pickupDatetime)),
                _kv(context, 'Confirmation', booking.confirmationNumber.isNotEmpty ? booking.confirmationNumber : 'N/A'),
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
                Expanded(
                    child: _Stat(
                        icon: Icons.person_rounded,
                        label: 'Passengers',
                        value: booking.applicantCount > 0
                            ? '${booking.applicantCount}'
                            : '—')),
                const VerticalDivider(width: 12, color: _kLine),
                Expanded(
                    child: _Stat(
                        icon: Icons.calendar_today_rounded,
                        label: 'Booked',
                        value: booking.bookedDate.isNotEmpty
                            ? booking.bookedDate
                            : '—')),
                const VerticalDivider(width: 12, color: _kLine),
                Expanded(
                    child: _Stat(
                        icon: Icons.verified_rounded,
                        label: 'Status',
                        value: statusLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerDetails(BuildContext context) {
    final name = '${booking.firstName} ${booking.lastName}'.trim();
    return _Section(
      title: 'Passenger Details',
      icon: Icons.groups_rounded,
      iconColor: AppColors.AppBlue,
      child: Container(
        padding: EdgeInsets.all(context.fx(12)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.fx(12)),
          border: Border.all(color: _kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty)
              Text(name,
                  style: TextStyle(
                      fontSize: context.ffs(13.5),
                      fontWeight: FontWeight.w600,
                      color: _kInk)),
            if (booking.email.isNotEmpty) ...[
              SizedBox(height: context.fx(4)),
              Row(
                children: [
                  Icon(Icons.email_rounded,
                      size: context.fx(14), color: _kMuted),
                  SizedBox(width: context.fx(6)),
                  Expanded(
                      child: Text(booking.email,
                          style: TextStyle(
                              fontSize: context.ffs(12), color: _kMuted))),
                ],
              ),
            ],
            if (booking.phoneNumber.isNotEmpty) ...[
              SizedBox(height: context.fx(4)),
              Row(
                children: [
                  Icon(Icons.phone_rounded,
                      size: context.fx(14), color: _kMuted),
                  SizedBox(width: context.fx(6)),
                  Text(booking.phoneNumber,
                      style: TextStyle(
                          fontSize: context.ffs(12), color: _kMuted)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFareDetails(BuildContext context) {
    final amount = booking.totalPrice.isNotEmpty
        ? booking.totalPrice
        : booking.rawTotalPrice;
    final currency = booking.currency;
    final formatted = '$currency $amount';

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
                _kv(context, 'Service Charge', formatted, muted: true),
                _kv(context, 'Taxes & Fees', '$currency 0.00', muted: true),
                Divider(height: context.fx(20), color: _kLine),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total Paid',
                          style: TextStyle(
                              fontSize: context.ffs(15),
                              fontWeight: FontWeight.w500,
                              color: _kInk)),
                    ),
                    Text(
                      formatted,
                      style: TextStyle(
                          fontSize: context.ffs(17),
                          fontWeight: FontWeight.w600,
                          color: AppColors.AppBlue),
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
                _kvChip(
                    context,
                    'Payment Status',
                    _isCancelled
                        ? ('Cancelled', const Color(0xFFE53935))
                        : ('Success', _kGreen)),
                _kv(context, 'Payment Method', booking.type.isNotEmpty ? booking.type : 'Online'),
                _kv(context, 'Invoice Status', booking.status.isNotEmpty ? booking.status : 'N/A'),
                _kv(context, 'Booked Date',
                    booking.bookedDate.isNotEmpty ? booking.bookedDate : 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantInfo(BuildContext context) {
    return _Section(
      title: 'Terms & Conditions',
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF6B6B6B),
      compact: true,
      child: Text(
        'Payment is due within 30 days of invoice date.\n'
        'All bookings are subject to our terms and conditions.\n'
        'Cancellations must be made at least 24 hours before departure.\n'
        'For any queries, please contact our support team.',
        style: TextStyle(
            fontSize: context.ffs(11),
            height: 1.45,
            color: const Color(0xFF4B5563)),
      ),
    );
  }

  // ─────────────────────────────────────────────────── helpers
  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $time';
    } catch (_) {
      return isoString;
    }
  }

  Widget _kv(BuildContext context, String label, String value,
      {bool muted = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.fx(5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style: TextStyle(
                    fontSize: context.ffs(12.5),
                    color: muted ? _kMuted : const Color(0xFF4B5563))),
          ),
          SizedBox(width: context.fx(8)),
          Flexible(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: context.ffs(12.5),
                      fontWeight: FontWeight.w500,
                      color: _kInk)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvChip(
      BuildContext context, String label, (String, Color) chip) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.fx(5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style: TextStyle(
                    fontSize: context.ffs(12.5),
                    color: const Color(0xFF4B5563))),
          ),
          SizedBox(width: context.fx(8)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.fx(10), vertical: context.fx(3)),
            decoration: BoxDecoration(
              color: chip.$2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.fx(20)),
            ),
            child: Text(chip.$1,
                style: TextStyle(
                    fontSize: context.ffs(11.5), color: chip.$2)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════ shared widgets

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
      padding:
          padding ?? EdgeInsets.all(context.fx(compact ? 12 : 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(14)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(icon,
                    size: context.fx(compact ? 16 : 18),
                    color: iconColor),
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
            padding: EdgeInsets.symmetric(
                horizontal: context.fx(10), vertical: context.fx(3)),
            decoration: BoxDecoration(
              color: cornerTag!.$2,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(context.fx(8))),
            ),
            child: Text(
              cornerTag!.$1,
              style: TextStyle(
                  fontSize: context.ffs(10.5),
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
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

  const _Inset(
      {required this.child,
      this.tinted = false,
      this.title,
      this.titleIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: BoxDecoration(
        color: tinted ? const Color(0xFFF3FAFE) : Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(
            color: tinted
                ? const Color(0xFFD6ECF8)
                : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(titleIcon,
                    size: context.fx(16),
                    color: const Color(0xFF34A853)),
                SizedBox(width: context.fx(8)),
                Text(title!,
                    style: TextStyle(
                        fontSize: context.ffs(12.5),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111527))),
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

  const _Stat(
      {required this.icon, required this.label, required this.value});

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
          child: Icon(icon,
              size: context.fx(17), color: const Color(0xFF3B9BE0)),
        ),
        SizedBox(width: context.fx(6)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.ffs(10.5),
                      color: const Color(0xFF6B7280))),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: context.ffs(13),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111527)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
