import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../AKHotelRetrieveBooking/domain/entity/AKHotelRetrieveBooking_entity.dart';

/// Final confirmation screen, reached only after StartPay reports the room
/// as actually booked (BookStatus "B0"). [booking] is the RetrieveBooking
/// read-back — best-effort enrichment (guests, rates, cancellation policy);
/// StartPay's own CRSPNR/transactionId are shown regardless of whether that
/// read-back succeeded.
class AkHotelBookingConfirmedScreen extends StatelessWidget {
  final String hotelName;
  final String transactionId;
  final String crsPnr;
  final String checkIn;
  final String checkOut;
  final AkHotelRetrieveBookingEntity? booking;

  const AkHotelBookingConfirmedScreen({
    super.key,
    required this.hotelName,
    required this.transactionId,
    required this.crsPnr,
    required this.checkIn,
    required this.checkOut,
    this.booking,
  });

  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _green = Color(0xFF16A34A);
  static const _pageBg = Color(0xFFF3F6FC);
  static const _border = Color(0xFFE2E7F0);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: _pageBg,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: context.hp(4)),
              Center(
                child: Container(
                  width: context.w(64),
                  height: context.w(64),
                  decoration: const BoxDecoration(color: Color(0xffEAFBF1), shape: BoxShape.circle),
                  child: Icon(Icons.check_circle, color: _green, size: context.w(36)),
                ),
              ),
              SizedBox(height: context.h(14)),
              Center(
                child: Text('Booking Confirmed', style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w900, color: _navy)),
              ),
              SizedBox(height: context.h(6)),
              Center(
                child: Text(hotelName, textAlign: TextAlign.center, style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade600)),
              ),
              SizedBox(height: context.hp(3)),
              Container(
                padding: EdgeInsets.all(context.w(14)),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.r(14)), border: Border.all(color: _border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(context, 'Booking Reference', crsPnr.isEmpty ? transactionId : crsPnr, emphasize: true),
                    SizedBox(height: context.h(10)),
                    _row(context, 'Transaction ID', transactionId),
                    SizedBox(height: context.h(10)),
                    _row(context, 'Check-in', checkIn),
                    SizedBox(height: context.h(10)),
                    _row(context, 'Check-out', checkOut),
                    if (b != null) ...[
                      SizedBox(height: context.h(10)),
                      _row(context, 'Net Fare', b.netFare.toStringAsFixed(2)),
                    ],
                  ],
                ),
              ),
              if (b != null && b.rooms.isNotEmpty) ...[
                SizedBox(height: context.hp(3)),
                Text('Room & Guest Details', style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w800, color: _navy)),
                SizedBox(height: context.h(10)),
                for (final room in b.rooms) _roomCard(context, room),
              ],
              SizedBox(height: context.hp(3)),
              SizedBox(
                height: context.buttonHeight + 10,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(18))),
                  ),
                  child: Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: context.bodyLarge)),
                ),
              ),
              SizedBox(height: context.hp(2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roomCard(BuildContext context, AkHotelBookingRoomEntity room) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.r(12)), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room.name, style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w800, color: _navy)),
          if (room.guests.isNotEmpty) ...[
            SizedBox(height: context.h(6)),
            Text(
              room.guests.map((g) => '${g.title} ${g.firstName} ${g.lastName}'.trim()).join(', '),
              style: TextStyle(fontSize: context.fs(12), color: _muted),
            ),
          ],
          if (room.cancellationPolicyTexts.isNotEmpty) ...[
            SizedBox(height: context.h(8)),
            Text(room.cancellationPolicyTexts.first, style: TextStyle(fontSize: context.fs(11), color: _muted)),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: context.fs(12))),
        Flexible(
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: TextStyle(color: _navy, fontSize: context.fs(emphasize ? 14 : 12), fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
