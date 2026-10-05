import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/diy_origins.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_rooms_sheet.dart';
import '../widgets/diy_trip_day_card.dart';
import 'diy_calendar_screen.dart';
import 'diy_origin_search_screen.dart';

/// What MODIFY hands back: the edited search and the trip priced on it.
class DiyModifiedBooking {
  final DiySearchQuery query;
  final DiyTrip trip;

  const DiyModifiedBooking({required this.query, required this.trip});
}

/// "Select Booking Details" — MODIFY on the trip: the city flown from, the
/// start date, and the rooms and guests.
///
/// APPLY prices the same package again on the new details (**POST
/// /packages/{share_id}/price/**) — live flights from the new city when the
/// trip has them — and pops a [DiyModifiedBooking] for the trip screen to
/// swap in. Nothing changed, nothing is priced.
class DiyModifyBookingScreen extends StatefulWidget {
  final DiySearchQuery query;
  final String shareId;
  final bool withFlight;

  const DiyModifyBookingScreen({
    super.key,
    required this.query,
    required this.shareId,
    required this.withFlight,
  });

  @override
  State<DiyModifyBookingScreen> createState() => _DiyModifyBookingScreenState();
}

class _DiyModifyBookingScreenState extends State<DiyModifyBookingScreen> {
  late DiySearchQuery _query = widget.query;
  bool _pricing = false;

  bool get _changed =>
      _query.origin.slug != widget.query.origin.slug ||
      _query.departureDate != widget.query.departureDate ||
      _query.rooms != widget.query.rooms ||
      _query.adults != widget.query.adults ||
      _query.children != widget.query.children ||
      _query.childAgesFilled.join(',') !=
          widget.query.childAgesFilled.join(',');

  Future<void> _pickOrigin() async {
    final picked = await Navigator.of(context).push<DiyOrigin>(
      MaterialPageRoute(
        builder: (_) => DiyOriginSearchScreen(initial: _query.origin),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _query = _query.copyWith(origin: picked));
    }
  }

  Future<void> _pickDate() async {
    final picked = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => DiyCalendarScreen(initialDate: _query.departureDate),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _query = _query.copyWith(departureDate: picked));
    }
  }

  Future<void> _pickGuests() async {
    final edited = await showDiyRoomsSheet(context, query: _query);
    if (edited != null && mounted) setState(() => _query = edited);
  }

  Future<void> _apply() async {
    if (!_changed) {
      Navigator.of(context).pop();
      return;
    }
    final date = _query.departureDate;
    if (date == null) {
      diySnack(context, 'Pick a starting date first', isError: true);
      return;
    }
    setState(() => _pricing = true);
    try {
      final trip = await sl<DiyHolidayApi>().priceForDates(
        shareId: widget.shareId,
        departureDate: date,
        adults: _query.adults,
        children: _query.children,
        rooms: _query.roomsPayload,
        origin: _query.origin.slug,
        withFlight: widget.withFlight,
      );
      if (!mounted) return;
      Navigator.of(context).pop(DiyModifiedBooking(query: _query, trip: trip));
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _pricing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _query.departureDate;
    final guests = [
      '${_query.adults} Adult${_query.adults == 1 ? '' : 's'}',
      if (_query.children > 0)
        '${_query.children} Child${_query.children == 1 ? '' : 'ren'}',
    ].join(', ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: context.w(24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Select Booking Details',
          style: TextStyle(
            fontSize: context.fs(18),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _pricing
          ? DiyLoading(
              message: widget.withFlight
                  ? 'Searching live flights from ${_query.origin.name}…'
                  : 'Repricing your package…',
              hint: widget.withFlight
                  ? 'Flight pricing takes a few seconds.'
                  : null,
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                context.w(20),
                context.h(36),
                context.w(20),
                context.h(24),
              ),
              children: [
                _field(
                  'FROM',
                  Text(_query.origin.name, style: _value),
                  _pickOrigin,
                ),
                _field(
                  'STARTING ON',
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: d == null
                              ? 'Pick a date'
                              : DateFormat('dd MMM yyyy').format(d),
                          style: _value,
                        ),
                        if (d != null)
                          TextSpan(
                            text: '  ${DateFormat('EEEE').format(d)}',
                            style: TextStyle(
                              fontSize: context.fs(12),
                              color: DiyTripStyle.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _pickDate,
                ),
                _field(
                  'ROOM & GUESTS',
                  Text(
                    '$guests in ${_query.rooms} Room${_query.rooms == 1 ? '' : 's'}',
                    style: _value,
                  ),
                  _pickGuests,
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          context.w(20),
          context.h(14),
          context.w(20),
          context.h(14) + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: context.w(10),
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: context.h(50),
          child: ElevatedButton(
            onPressed: _pricing ? null : _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: DiyTripStyle.orange,
              disabledBackgroundColor: const Color(0xFFFFC299),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
            ),
            child: Text(
              'APPLY',
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _value => TextStyle(
    fontSize: context.fs(13),
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  Widget _field(String label, Widget value, VoidCallback onChange) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(16)),
      child: InkWell(
        onTap: onChange,
        borderRadius: BorderRadius.circular(context.r(8)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(20),
            vertical: context.h(12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(8)),
            border: Border.all(color: DiyTripStyle.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(9),
                  color: DiyTripStyle.grey,
                ),
              ),
              SizedBox(height: context.h(4)),
              Row(
                children: [
                  Expanded(child: value),
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: context.fs(13),
                      color: DiyTokens.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
