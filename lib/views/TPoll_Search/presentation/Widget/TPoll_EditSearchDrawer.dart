import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../T_location/presentation/screen/booking_card.dart';

/// Top drawer with the transfer search form (same form as the Transfer screen,
/// without the hero image). Slides down from the top; a circular × floats
/// outside the drawer, below it, at bottom-centre.
///
/// On MODIFY SEARCH the form closes the drawer and replaces the results screen
/// with the new search (see `TransportBookingCard.editMode`).
Future<void> showTpollEditSearchDrawer(
  BuildContext context, {
  required bool isOneWay,
  required DateTime pickupDate,
  required TimeOfDay pickupTime,
  DateTime? returnDate,
  TimeOfDay? returnTime,
  required int passengers,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Edit search',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => _EditSearchDrawer(
      isOneWay: isOneWay,
      pickupDate: pickupDate,
      pickupTime: pickupTime,
      returnDate: returnDate,
      returnTime: returnTime,
      passengers: passengers,
    ),
    transitionBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: child,
      );
    },
  );
}

class _EditSearchDrawer extends StatefulWidget {
  final bool isOneWay;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime? returnDate;
  final TimeOfDay? returnTime;
  final int passengers;

  const _EditSearchDrawer({
    required this.isOneWay,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.passengers,
  });

  @override
  State<_EditSearchDrawer> createState() => _EditSearchDrawerState();
}

class _EditSearchDrawerState extends State<_EditSearchDrawer> {
  late bool _isOneWay = widget.isOneWay;
  late DateTime _date = widget.pickupDate;
  late TimeOfDay _time = widget.pickupTime;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(context.r(24));

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.only(bottomLeft: radius, bottomRight: radius),
                ),
                clipBehavior: Clip.antiAlias,
                child: TransportBookingCard(
                  editMode: true,
                  isOneWay: _isOneWay,
                  selectedDate: _date,
                  selectedTime: _time,
                  initialPickupDate: widget.pickupDate,
                  initialReturnDate: widget.returnDate,
                  initialReturnTime: widget.returnTime,
                  initialPassengerCount: widget.passengers,
                  onTripTypeChanged: (v) => setState(() => _isOneWay = v),
                  onDateChanged: (d) => setState(() => _date = d),
                  onTimeChanged: (t) => setState(() => _time = t),
                ),
              ),
              SizedBox(height: context.h(14)),
              // Close — floating outside the drawer, bottom centre.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: context.w(34),
                  height: context.w(34),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      size: context.w(20), color: Colors.black87),
                ),
              ),
              SizedBox(height: context.h(16)),
            ],
          ),
        ),
      ),
    );
  }
}
