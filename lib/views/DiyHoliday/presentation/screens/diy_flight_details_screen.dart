import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';

import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_flight_parts.dart';
import '../widgets/diy_trip_day_card.dart';

/// What the customer asked for from the details screen. The trip screen owns
/// both actions, so this only reports the choice back.
enum DiyFlightAction { remove, change }

/// "Flight Details" — one leg of the trip in full: the route card with
/// Remove | Change, then each flight with its codes, times, the arc and the
/// baggage allowance, and the layover between connecting flights.
class DiyFlightDetailsScreen extends StatelessWidget {
  final List<DiyRow> flights;
  final bool outbound;
  final int adults;
  final int children;
  final bool canRemove;

  const DiyFlightDetailsScreen({
    super.key,
    required this.flights,
    required this.outbound,
    required this.adults,
    required this.children,
    this.canRemove = true,
  });

  /// The route as a whole, first departure to last arrival.
  (String, String) get _ends {
    if (flights.isEmpty) return ('', '');
    return (
      diyRouteCodes(flights.first.title).$1,
      diyRouteCodes(flights.last.title).$2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = flights.isNotEmpty ? flights.first : null;
    final date = first == null ? null : diyParseDate(first.departureAt);
    final party = [
      '$adults Adult${adults == 1 ? '' : 's'}',
      if (children > 0) '$children Child${children == 1 ? '' : 'ren'}',
    ].join(', ');
    final (from, to) = _ends;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: context.w(24)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flight Details',
              style: TextStyle(
                fontSize: context.fs(18),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              [
                if (date != null) DateFormat('MMM dd').format(date),
                party,
              ].join(', '),
              style: TextStyle(
                fontSize: context.fs(11),
                color: DiyTripStyle.grey,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(24),
          context.w(16),
          context.h(32),
        ),
        children: [
          _routeCard(context, from, to),
          SizedBox(height: context.h(28)),
          Text(
            outbound ? 'Departure Flights' : 'Return Flights',
            style: TextStyle(
              fontSize: context.fs(15),
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(12)),
          Container(
            padding: EdgeInsets.all(context.w(14)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.r(12)),
              border: Border.all(color: DiyTripStyle.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${diyAirportCity(from)} to ${diyAirportCity(to)}'
                  '${date == null ? '' : ' I ${DateFormat('EEE MMM d').format(date)}'}',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: context.h(12)),
                for (var i = 0; i < flights.length; i++) ...[
                  if (i > 0)
                    DiyLayoverBand.rows(
                      arriving: flights[i - 1],
                      leaving: flights[i],
                    ),
                  _flight(context, flights[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(BuildContext context, String from, String to) {
    Widget link(String text, DiyFlightAction action) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(action),
          child: Text(
            text,
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w600,
              color: DiyTokens.blue,
            ),
          ),
        );

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(14),
        context.w(14),
        context.h(16),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(10)),
        gradient: const LinearGradient(
          colors: [Color(0xFFCBEBFA), Color(0xFFEFF9FE)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flight from',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: DiyTripStyle.grey,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  '${diyAirportCity(from)} - ${diyAirportCity(to)}',
                  style: TextStyle(
                    fontSize: context.fs(17),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (canRemove) link('Remove', DiyFlightAction.remove),
          if (canRemove)
            Container(
              width: 1,
              height: context.h(18),
              margin: EdgeInsets.symmetric(horizontal: context.w(8)),
              color: DiyTripStyle.border,
            ),
          link('Change', DiyFlightAction.change),
        ],
      ),
    );
  }

  Widget _flight(BuildContext context, DiyRow f) {
    final (from, to) = diyRouteCodes(f.title);
    final dep = diyParseDate(f.departureAt);
    final arr = diyParseDate(f.arrivalAt);
    String day(DateTime? d) =>
        d == null ? '' : DateFormat('EEE, dd MMM').format(d);

    Widget end(String code, String time, String date, String city,
        CrossAxisAlignment align) {
      return SizedBox(
        width: context.w(96),
        child: Column(
          crossAxisAlignment: align,
          children: [
            Text(code,
                style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black)),
            Text(time,
                style: TextStyle(
                    fontSize: context.fs(24),
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
            SizedBox(height: context.h(4)),
            Text(date,
                style: TextStyle(
                    fontSize: context.fs(12), color: DiyTripStyle.grey)),
            Text(city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: context.fs(12), color: DiyTripStyle.grey)),
          ],
        ),
      );
    }

    final cabin = f.baggageCabin;
    final checked = f.baggageChecked;
    TextSpan label(String text) => TextSpan(
          text: text,
          style: TextStyle(fontSize: context.fs(13), color: DiyTripStyle.grey),
        );
    TextSpan value(String text) => TextSpan(
          text: text,
          style: TextStyle(
            fontSize: context.fs(13),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AirlineLogo(
              code: f.carrier,
              name: f.carrierName,
              size: context.w(34),
              borderRadius: BorderRadius.circular(context.r(4)),
            ),
            SizedBox(width: context.w(10)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.carrierName.isNotEmpty ? f.carrierName : f.carrier,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  f.flightNumber,
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: DiyTripStyle.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: context.h(18)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            end(from, diyTime(f.departureAt), day(dep), diyAirportCity(from),
                CrossAxisAlignment.start),
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: context.h(14)),
                  const DiyFlightArc(),
                  Text(
                    f.flightDurationMinutes > 0
                        ? diyDuration(f.flightDurationMinutes)
                        : '',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w600,
                      color: DiyTripStyle.slate,
                    ),
                  ),
                ],
              ),
            ),
            end(to, diyTime(f.arrivalAt), day(arr), diyAirportCity(to),
                CrossAxisAlignment.end),
          ],
        ),
        if (cabin.isNotEmpty || checked.isNotEmpty) ...[
          SizedBox(height: context.h(18)),
          Text(
            'Flight Baggage',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(8)),
          Text(
            'Adult',
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(4)),
          Text.rich(
            TextSpan(
              children: [
                if (cabin.isNotEmpty) ...[
                  label('Cabin : '),
                  value(cabin),
                ],
                if (cabin.isNotEmpty && checked.isNotEmpty) label('  •  '),
                if (checked.isNotEmpty) ...[
                  label('Check-in : '),
                  value(checked),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
