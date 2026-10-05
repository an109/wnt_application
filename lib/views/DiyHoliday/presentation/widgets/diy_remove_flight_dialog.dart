import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import 'diy_common.dart';
import 'diy_trip_day_card.dart';

/// "Removing this Flight?" — the confirmation the design shows before a leg
/// is dropped. Resolves true on YES, REMOVE and false otherwise.
///
/// The line under the title says what actually happens here: the leg goes,
/// the customer makes their own way for it, and the price updates. Road
/// transfers and sightseeing are kept — they are part of the land package,
/// not of the flight.
Future<bool> showDiyRemoveFlightDialog(
  BuildContext context, {
  required bool outbound,
}) => showDiyRemoveDialog(
  context,
  icon: Icons.flight_rounded,
  title: 'Removing this\nFlight?',
  message: outbound
      ? 'You will need to reach the destination on your own. '
            'The package price updates straight away.'
      : 'You will need to make your own way back. '
            'The package price updates straight away.',
);

/// "Removing this Transfer?" — the cab goes, and every transfer and
/// sightseeing drive with it, since they all run in the one car.
Future<bool> showDiyRemoveTransferDialog(BuildContext context) =>
    showDiyRemoveDialog(
      context,
      icon: Icons.directions_car_filled_rounded,
      title: 'Removing this\nTransfer?',
      message:
          'All road transfers including sightseeing will be removed '
          'from this package. The price updates straight away.',
    );

/// The design's remove confirmation, for anything the trip can drop.
Future<bool> showDiyRemoveDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => _RemoveDialog(icon: icon, title: title, message: message),
  );
  return ok ?? false;
}

class _RemoveDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _RemoveDialog({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              context.w(18),
              context.h(28),
              context.w(18),
              context.h(28),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: context.w(50),
                  height: context.w(50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8FD3F4), Color(0xFF00A1E4)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DiyTokens.blue.withValues(alpha: 0.3),
                        blurRadius: context.w(12),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: icon == Icons.flight_rounded ? 0.785 : 0,
                    child: Icon(icon, size: context.w(26), color: Colors.white),
                  ),
                ),
                SizedBox(height: context.h(16)),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(18),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: context.h(8)),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: DiyTripStyle.grey,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: context.h(22)),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: context.h(48),
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: DiyTripStyle.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.r(10),
                              ),
                            ),
                          ),
                          child: Text(
                            "DON'T REMOVE",
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w600,
                              color: DiyTripStyle.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(14)),
                    Expanded(
                      child: SizedBox(
                        height: context.h(48),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DiyTripStyle.orange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.r(10),
                              ),
                            ),
                          ),
                          child: Text(
                            'YES, REMOVE',
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: context.w(14),
            top: -context.w(46),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(false),
              child: Container(
                width: context.w(36),
                height: context.w(36),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: context.w(20),
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
