import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/models/diy_models.dart';
import 'diy_common.dart';

/// Day-by-day itinerary, shared by the package view (**API 4**) and the live
/// trip (**API 6**) since both return the same `days[] → rows[]` shape.
///
/// [onChangeFlight] / [onChangeHotel] are only supplied once a trip exists —
/// on the read-only package view the rows render without action buttons.
class DiyItinerary extends StatelessWidget {
  final List<DiyDay> days;

  /// Called with `true` for the outbound flight row, `false` for the return.
  final void Function(bool outbound)? onChangeFlight;

  /// Called with the destination of the hotel row, so the caller can map it
  /// to the matching `stop_id` from the trip.
  final void Function(String destination)? onChangeHotel;

  final void Function(DiyRow row)? onRemoveActivity;

  const DiyItinerary({
    super.key,
    required this.days,
    this.onChangeFlight,
    this.onChangeHotel,
    this.onRemoveActivity,
  });

  @override
  Widget build(BuildContext context) {
    // The first FLIGHT row of the whole trip is the outbound leg, any later
    // one is the return — the rows themselves carry no direction.
    var flightSeen = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day in days) ...[
          _dayHeader(context, day),
          for (final row in day.rows)
            _row(
              context,
              row,
              outbound: row.kind == 'FLIGHT' ? (flightSeen++ == 0) : true,
            ),
          SizedBox(height: context.h(8)),
        ],
      ],
    );
  }

  Widget _dayHeader(BuildContext context, DiyDay day) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, context.h(14), 0, context.h(8)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(10),
              vertical: context.h(4),
            ),
            decoration: BoxDecoration(
              color: DiyTokens.blue,
              borderRadius: BorderRadius.circular(context.r(20)),
            ),
            child: Text(
              'DAY ${day.day}',
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              day.label.isNotEmpty ? day.label : day.destination,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w700,
                color: DiyTokens.navy,
              ),
            ),
          ),
          Text(
            diyDayDate(day.date),
            style: TextStyle(
              fontSize: context.fs(11),
              color: DiyTokens.subGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, DiyRow row, {required bool outbound}) {
    switch (row.kind) {
      case 'FLIGHT':
        return _flightRow(context, row, outbound);
      case 'HOTEL':
        return _hotelRow(context, row);
      case 'ACTIVITY':
        return _activityRow(context, row);
      case 'SIGHTSEEING':
        return _sightseeingRow(context, row);
      case 'TRANSFER':
        return _simpleRow(context, row, Icons.directions_car_filled_rounded);
      case 'MEAL':
        return _simpleRow(context, row, Icons.restaurant_rounded);
      case 'HOTEL_CHECKOUT':
        return _simpleRow(context, row, Icons.logout_rounded);
      default:
        return _simpleRow(context, row, Icons.circle_outlined);
    }
  }

  Widget _shell(BuildContext context, {required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(12)),
          border: Border.all(color: DiyTokens.line),
        ),
        child: child,
      ),
    );
  }

  Widget _simpleRow(BuildContext context, DiyRow row, IconData icon) {
    return _shell(
      context,
      child: Row(
        children: [
          Icon(icon, size: context.w(17), color: DiyTokens.blue),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              row.title,
              style: TextStyle(
                fontSize: context.fs(12.5),
                color: DiyTokens.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flightRow(BuildContext context, DiyRow row, bool outbound) {
    return _shell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                outbound
                    ? Icons.flight_takeoff_rounded
                    : Icons.flight_land_rounded,
                size: context.w(17),
                color: DiyTokens.blue,
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Text(
                  row.title,
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
              ),
              if (onChangeFlight != null)
                _changeButton(
                  context,
                  onTap: () => onChangeFlight!(outbound),
                ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              _timeBlock(context, diyTime(row.departureAt), 'Departs'),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      diyDuration(row.flightDurationMinutes),
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.h(3)),
                      child: const Divider(height: 1, color: DiyTokens.line),
                    ),
                    Text(
                      row.stops == 0 ? 'Non-stop' : '${row.stops} stop',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
              _timeBlock(context, diyTime(row.arrivalAt), 'Arrives'),
            ],
          ),
          SizedBox(height: context.h(8)),
          Text(
            [
              row.carrierName,
              row.flightNumber,
              if (row.baggageChecked.isNotEmpty) '${row.baggageChecked} baggage',
            ].where((s) => s.isNotEmpty).join(' · '),
            style: TextStyle(
              fontSize: context.fs(11),
              color: DiyTokens.subGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBlock(BuildContext context, String time, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: context.fs(15),
            fontWeight: FontWeight.w700,
            color: DiyTokens.navy,
          ),
        ),
        Text(
          caption,
          style: TextStyle(
            fontSize: context.fs(10),
            color: DiyTokens.labelGrey,
          ),
        ),
      ],
    );
  }

  Widget _hotelRow(BuildContext context, DiyRow row) {
    return _shell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiyImage(
                url: row.heroImage,
                width: context.w(72),
                height: context.w(66),
                radius: BorderRadius.circular(context.r(10)),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.hotelName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color: DiyTokens.navy,
                      ),
                    ),
                    SizedBox(height: context.h(3)),
                    Row(
                      children: [
                        if (row.starRating.isNotEmpty) ...[
                          Icon(
                            Icons.star_rounded,
                            size: context.w(13),
                            color: const Color(0xFFFFC107),
                          ),
                          SizedBox(width: context.w(3)),
                          Text(
                            row.starRating,
                            style: TextStyle(
                              fontSize: context.fs(11),
                              color: DiyTokens.subGrey,
                            ),
                          ),
                          SizedBox(width: context.w(8)),
                        ],
                        Expanded(
                          child: Text(
                            row.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(11),
                              color: DiyTokens.subGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(3)),
                    Text(
                      [
                        if (row.nights > 0)
                          '${row.nights} night${row.nights == 1 ? '' : 's'}',
                        if (row.roomName.isNotEmpty) row.roomName,
                        if (row.boardBasis.isNotEmpty) row.boardBasis,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(10.5),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onChangeHotel != null) ...[
            SizedBox(height: context.h(8)),
            Align(
              alignment: Alignment.centerRight,
              child: _changeButton(
                context,
                label: 'Change hotel',
                onTap: () => onChangeHotel!(row.destination),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _activityRow(BuildContext context, DiyRow row) {
    return _shell(
      context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_activity_rounded,
            size: context.w(17),
            color: DiyTokens.orange,
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: TextStyle(
                    fontSize: context.fs(12.5),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
                if (row.durationMinutes > 0 || row.complimentary)
                  Text(
                    [
                      if (row.durationMinutes > 0)
                        diyDuration(row.durationMinutes),
                      if (row.complimentary) 'Complimentary',
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: context.fs(10.5),
                      color: DiyTokens.subGrey,
                    ),
                  ),
              ],
            ),
          ),
          if (onRemoveActivity != null)
            GestureDetector(
              onTap: () => onRemoveActivity!(row),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(left: context.w(8)),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: context.w(18),
                  color: Colors.red.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sightseeingRow(BuildContext context, DiyRow row) {
    return _shell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera_back_rounded,
                size: context.w(17),
                color: DiyTokens.blue,
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Text(
                  row.title,
                  style: TextStyle(
                    fontSize: context.fs(12.5),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
              ),
              if (row.durationMinutes > 0)
                Text(
                  diyDuration(row.durationMinutes),
                  style: TextStyle(
                    fontSize: context.fs(10.5),
                    color: DiyTokens.subGrey,
                  ),
                ),
            ],
          ),
          if (row.pois.isNotEmpty) ...[
            SizedBox(height: context.h(10)),
            SizedBox(
              height: context.h(78),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: row.pois.length,
                separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
                itemBuilder: (context, i) {
                  final poi = row.pois[i];
                  return SizedBox(
                    width: context.w(96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DiyImage(
                          url: poi.image,
                          width: context.w(96),
                          height: context.h(50),
                          radius: BorderRadius.circular(context.r(8)),
                        ),
                        SizedBox(height: context.h(3)),
                        Expanded(
                          child: Text(
                            poi.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(9.5),
                              color: DiyTokens.subGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else if (row.places.isNotEmpty) ...[
            SizedBox(height: context.h(5)),
            Text(
              row.places,
              style: TextStyle(
                fontSize: context.fs(11),
                color: DiyTokens.subGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _changeButton(
    BuildContext context, {
    String label = 'Change',
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(10),
          vertical: context.h(5),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(color: DiyTokens.blue),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.fs(11),
            fontWeight: FontWeight.w700,
            color: DiyTokens.blue,
          ),
        ),
      ),
    );
  }
}
