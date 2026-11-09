import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import 'trip_card.dart' show TripDashedLine, TripIconTile, TripStatus;

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF757575);
const Color _kLine = Color(0xFFCCCCCC);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _fmtDateTime(DateTime? dt) {
  if (dt == null) return '';
  final d = dt.toLocal();
  final day = _days[d.weekday - 1];
  final hr = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  return "$day, ${d.day} ${_months[d.month - 1]} '${d.year.toString().substring(2)}, $hr $ampm";
}

class TransferBookingCard extends StatelessWidget {
  final String vehicleName;
  final String destination;
  final String startAddress;
  final String endAddress;
  final String? imageUrl;
  final DateTime? pickupTime;
  final DateTime? dropoffTime;
  final int passengers;
  final String category;
  final TripStatus status;
  final VoidCallback onDetails;

  const TransferBookingCard({
    super.key,
    required this.vehicleName,
    required this.destination,
    required this.startAddress,
    required this.endAddress,
    this.imageUrl,
    this.pickupTime,
    this.dropoffTime,
    required this.passengers,
    required this.category,
    required this.status,
    required this.onDetails,
  });

  String get _title {
    if (vehicleName.isNotEmpty && destination.isNotEmpty) {
      return '$vehicleName - $destination';
    }
    if (vehicleName.isNotEmpty) return vehicleName;
    if (destination.isNotEmpty) return 'Transfer - $destination';
    return 'Transfer';
  }

  String get _locationSubtitle {
    final parts = <String>[];
    if (startAddress.isNotEmpty) parts.add(startAddress.trim());
    if (endAddress.isNotEmpty) parts.add(endAddress.trim());
    return parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetails,
      child: Container(
        margin: EdgeInsets.only(bottom: context.h(12)),
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(12)),
          border: Border.all(color: _kLine, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4.95,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            _titleRow(context),
            SizedBox(height: context.h(16)),
            _imageAndColumns(context),
            SizedBox(height: context.h(16)),
            const TripDashedLine(color: _kLine),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TRANSFER BOOKING',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: context.fs(11),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF00A1E4),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(8),
            vertical: context.h(4),
          ),
          decoration: BoxDecoration(
            color: status.background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.w(4)),
              Text(
                status.label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w500,
                  color: status.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _titleRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: context.h(8), bottom: context.h(8)),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kLine, width: 0.2)),
      ),
      child: Row(
        children: [
          const TripIconTile(icon: Icons.directions_car_rounded),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_locationSubtitle.isNotEmpty) ...[
                  SizedBox(height: context.h(4)),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: context.w(8), color: _kMuted),
                      SizedBox(width: context.w(2)),
                      Expanded(
                        child: Text(
                          _locationSubtitle,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: context.fs(6),
                            fontWeight: FontWeight.w500,
                            color: _kMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageAndColumns(BuildContext context) {
    return Row(
      children: [
        if (imageUrl != null && imageUrl!.isNotEmpty)
          Container(
            width: context.w(100),
            height: context.h(52),
            margin: EdgeInsets.only(right: context.w(12)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(context.r(4)),
                  child: Image.network(
                    imageUrl!,
                    width: context.w(98),
                    height: context.h(52),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.directions_car,
                      size: context.w(32),
                      color: _kMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _column(context, 'PICKUP', startAddress, pickupTime)),
              Container(
                width: 0.5,
                height: context.h(60),
                color: _kLine,
                margin: EdgeInsets.symmetric(horizontal: context.w(12)),
              ),
              Expanded(child: _column(context, 'DROP - OFF', endAddress, dropoffTime)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _column(BuildContext context, String label, String address, DateTime? dt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: context.fs(8),
            fontWeight: FontWeight.w600,
            color: _kMuted,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: context.h(8)),
        Text(
          address.isNotEmpty ? address : label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: context.fs(12),
            fontWeight: FontWeight.w500,
            color: _kInk,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: context.h(8)),
        Row(
          children: [
            Icon(Icons.access_time_filled_outlined, size: context.w(11), color: _kMuted),
            SizedBox(width: context.w(4)),
            Expanded(
              child: Text(
                _fmtDateTime(dt),
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: context.fs(9),
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.h(12)),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (passengers > 0)
                  _footerFact(context, Icons.person, '$passengers Adult'),
                if (category.isNotEmpty)
                  _footerFact(context, Icons.directions_car, category),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDetails,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View details',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00A1E4),
                  ),
                ),
                SizedBox(width: context.w(4)),
                Icon(
                  Icons.chevron_right,
                  size: context.w(12),
                  color: const Color(0xFF00A1E4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerFact(BuildContext context, IconData icon, String text) {
    return Container(
      padding: EdgeInsets.only(right: context.w(16)),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: _kLine, width: 0.2)),
      ),
      margin: EdgeInsets.only(right: context.w(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.w(12), color: _kMuted),
          SizedBox(width: context.w(4)),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: context.fs(11),
              fontWeight: FontWeight.w500,
              color: _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}
