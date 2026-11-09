import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../Hotels/domain/entity/HotelBookingEntity.dart';
import 'trip_card.dart' show TripDashedLine, TripIconTile, TripStatus;

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF757575);
const Color _kLine = Color(0xFFCCCCCC);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _fmtDate(DateTime? dt) {
  if (dt == null) return '';
  final d = dt.toLocal();
  final day = _days[d.weekday - 1];
  return "$day, ${d.day} ${_months[d.month - 1]}'${d.year.toString().substring(2)}";
}

class HotelBookingCard extends StatelessWidget {
  final HotelBookingListEntity hotel;
  final TripStatus status;
  final VoidCallback onDetails;

  const HotelBookingCard({
    super.key,
    required this.hotel,
    required this.status,
    required this.onDetails,
  });

  String get _title => hotel.hotelName.isNotEmpty ? hotel.hotelName : 'Hotel Stay';

  String get _locationSubtitle {
    final parts = <String>[];
    if (hotel.hotelCity.isNotEmpty) parts.add(hotel.hotelCity);
    if (hotel.hotelCountry.isNotEmpty) parts.add(hotel.hotelCountry);
    final location = parts.join(', ');
    final duration = <String>[];
    if (hotel.nights > 0) duration.add('${hotel.nights} Nights & ${hotel.nights + 1} Days');
    return [location, ...duration].where((s) => s.isNotEmpty).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = DateTime.tryParse(hotel.checkIn);
    final checkOut = DateTime.tryParse(hotel.checkOut);

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
            _hotelImage(context),
            SizedBox(height: context.h(12)),
            _dateColumns(context, checkIn, checkOut),
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
          'HOLIDAY BOOKING',
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
          const TripIconTile(icon: Icons.holiday_village_rounded),
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

  Widget _hotelImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.r(8)),
      child: SizedBox(
        width: double.infinity,
        height: context.h(110),
        child: hotel.hotelImage.isNotEmpty
            ? Image.network(
                hotel.hotelImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF0F0F0),
                  child: Icon(Icons.hotel, size: context.w(40), color: _kMuted),
                ),
              )
            : Container(
                color: const Color(0xFFF0F0F0),
                child: Icon(Icons.hotel, size: context.w(40), color: _kMuted),
              ),
      ),
    );
  }

  Widget _dateColumns(BuildContext context, DateTime? checkIn, DateTime? checkOut) {
    return Row(
      children: [
        Expanded(
          child: _dateColumn(context, 'TRAVEL DATE', checkIn),
        ),
        Container(
          width: 0.5,
          height: context.h(40),
          color: _kLine,
          margin: EdgeInsets.symmetric(horizontal: context.w(12)),
        ),
        Expanded(
          child: _dateColumn(context, 'TRAVEL END', checkOut),
        ),
      ],
    );
  }

  Widget _dateColumn(BuildContext context, String label, DateTime? dt) {
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
          _fmtDate(dt),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: context.fs(12),
            fontWeight: FontWeight.w500,
            color: _kInk,
          ),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    final nights = hotel.nights > 0
        ? hotel.nights
        : (DateTime.tryParse(hotel.checkIn) != null && DateTime.tryParse(hotel.checkOut) != null
            ? DateTime.parse(hotel.checkOut).difference(DateTime.parse(hotel.checkIn)).inDays
            : 0);
    final guestParts = <String>[];
    if (hotel.adults > 0) guestParts.add('${hotel.adults} Adult');
    if (hotel.children > 0) guestParts.add('${hotel.children} Child');
    final guestStr = guestParts.join(', ');

    return Padding(
      padding: EdgeInsets.only(top: context.h(12)),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (nights > 0)
                  _footerFact(context, Icons.bed_rounded, '$nights Nights'),
                if (guestStr.isNotEmpty)
                  _footerFact(context, Icons.person, guestStr, hasBorder: false),
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

  Widget _footerFact(BuildContext context, IconData icon, String text, {bool hasBorder = true}) {
    return Container(
      padding: EdgeInsets.only(right: context.w(16)),
      decoration: hasBorder
          ? BoxDecoration(
              border: Border(right: BorderSide(color: _kLine, width: 0.2)),
            )
          : null,
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
