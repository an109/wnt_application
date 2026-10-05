import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/models/diy_models.dart';
import 'diy_common.dart';
import 'diy_trip_day_card.dart';

/// The "Summary" block under the itinerary: a blue band with the stay and
/// the plan length, then a timeline — the arrival transfer, one card per day
/// (check-in, meals, checkout), and the drop back to the airport.
///
/// Built entirely from the trip's own rows; a day with nothing to say is left
/// out rather than given an invented line.
class DiyTripSummary extends StatefulWidget {
  final List<DiyDay> days;
  final List<DiyStop> stops;

  const DiyTripSummary({super.key, required this.days, required this.stops});

  @override
  State<DiyTripSummary> createState() => _DiyTripSummaryState();
}

class _DiyTripSummaryState extends State<DiyTripSummary> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final steps = _steps();
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(8)),
            child: Row(
              children: [
                Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w600,
                    color: DiyTokens.blue,
                  ),
                ),
                const Spacer(),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: context.w(18),
                  color: DiyTokens.blue,
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          SizedBox(height: context.h(4)),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(12)),
              border: Border.all(color: DiyTripStyle.border, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _band(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(12),
                    context.h(16),
                    context.w(12),
                    context.h(16),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < steps.length; i++)
                        _stepTile(steps[i], last: i == steps.length - 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _band() {
    final nights = widget.stops.fold<int>(0, (sum, s) => sum + s.nights);
    final places = widget.stops.map((s) => s.destination).toSet().join(' · ');
    final label = places.isNotEmpty
        ? places
        : (widget.days.isNotEmpty ? widget.days.first.destination : '');

    return Container(
      height: context.h(48),
      padding: EdgeInsets.symmetric(horizontal: context.w(12)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00A1E4), Color(0xFF5CC6F2)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (nights > 0)
                    TextSpan(
                      text: ' ($nights Night${nights == 1 ? '' : 's'} Stay)',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${widget.days.length} Days Plan',
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- steps

  List<_Step> _steps() {
    final days = widget.days;
    if (days.isEmpty) return const [];
    final out = <_Step>[];

    final arrival = days.first.rows
        .where((r) => r.kind == 'TRANSFER' && r.transferKind == 'AIRPORT')
        .firstOrNull;
    if (arrival != null) {
      out.add(_Step.transfer(title: arrival.title));
    }

    var hotel = '';
    var hotelNote = '';
    for (final day in days) {
      final rows = day.rows;
      final checkIn = rows.where((r) => r.kind == 'HOTEL').firstOrNull;
      final meal = rows.where((r) => r.kind == 'MEAL').firstOrNull;
      final checkout =
          rows.where((r) => r.kind == 'HOTEL_CHECKOUT').firstOrNull;
      final mealName = meal?.title.split(' in ').first ?? '';
      final dated = _dayLabel(day);

      if (checkout != null) {
        out.add(_Step.day(
          kind: _StepKind.checkout,
          dayLabel: dated,
          note: 'Checkout',
          noteColor: DiyTripStyle.orange,
          title: meal != null ? 'Day Meals: $mealName' : 'Hotel Checkout',
          subtitle: hotel.isNotEmpty ? 'At $hotel' : '',
        ));
      }
      if (checkIn != null) {
        hotel = checkIn.hotelName.isNotEmpty ? checkIn.hotelName : checkIn.title;
        final stars = (double.tryParse(checkIn.starRating) ?? 0).round();
        hotelNote = [
          if (checkIn.location.isNotEmpty) checkIn.location,
          if (stars > 0) '$stars Star',
        ].join(', ');
        final time = (checkIn.detail['check_in_time'] ?? '').toString();
        out.add(_Step.day(
          kind: _StepKind.checkIn,
          dayLabel: dated,
          note: time.isNotEmpty ? '$time Check-in' : 'Check-in',
          noteColor: DiyTripStyle.grey,
          title: 'Check-in at $hotel',
          subtitle: hotelNote,
        ));
      } else if (meal != null && checkout == null) {
        out.add(_Step.day(
          kind: _StepKind.meal,
          dayLabel: dated,
          note: 'Include',
          noteColor: DiyTripStyle.green,
          title: 'Day Meals: $mealName',
          subtitle: hotel.isNotEmpty ? 'At $hotel' : '',
        ));
      }
    }

    final drop = days.last.rows
        .where((r) => r.kind == 'TRANSFER' && r.transferKind == 'AIRPORT')
        .lastOrNull;
    if (drop != null && days.length > 1) {
      out.add(_Step.drop(
        title: drop.title,
        subtitle: hotel.isNotEmpty
            ? 'Scheduled private vehicle transfer from $hotel to Airport.'
            : '',
      ));
    }
    return out;
  }

  /// "DAY 1 • OCT 9, FRI".
  String _dayLabel(DiyDay day) {
    final d = diyParseDate(day.date);
    final date = d == null
        ? ''
        : ' • ${DateFormat('MMM d, EEE').format(d).toUpperCase()}';
    return 'DAY ${day.day}$date';
  }

  // ------------------------------------------------------------------ tile

  Widget _stepTile(_Step step, {required bool last}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: context.w(28),
            child: Column(
              children: [
                _marker(step),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: context.h(4)),
                      color: DiyTripStyle.divider,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : context.h(16)),
              child: step.isDay ? _dayCard(step) : _transferText(step),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marker(_Step step) {
    final size = context.w(28);
    switch (step.kind) {
      case _StepKind.arrival:
      case _StepKind.drop:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step.kind == _StepKind.drop
                ? DiyTripStyle.orange
                : DiyTokens.blue,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            DiyTripStyle.carWhite,
            width: context.w(16),
            height: context.w(16),
          ),
        );
      case _StepKind.checkIn:
      case _StepKind.meal:
      case _StepKind.checkout:
        final icon = switch (step.kind) {
          _StepKind.meal => Icon(Icons.restaurant_rounded,
              size: context.w(13), color: DiyTripStyle.grey),
          _StepKind.checkout => Icon(Icons.logout_rounded,
              size: context.w(13), color: DiyTripStyle.grey),
          _ => SvgPicture.asset(
              DiyTripStyle.buildingOutline,
              width: context.w(12),
              height: context.w(12),
            ),
        };
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: DiyTripStyle.border),
          ),
          alignment: Alignment.center,
          child: icon,
        );
    }
  }

  Widget _transferText(_Step step) {
    final drop = step.kind == _StepKind.drop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.h(4)),
        Row(
          children: [
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w700,
                  color: drop ? DiyTripStyle.orange : Colors.black,
                ),
              ),
            ),
            if (drop)
              Text(
                'Drop Included',
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w500,
                  color: DiyTripStyle.red,
                ),
              ),
          ],
        ),
        if (step.subtitle.isNotEmpty) ...[
          SizedBox(height: context.h(4)),
          Text(
            step.subtitle,
            style: TextStyle(
              fontSize: context.fs(10),
              color: DiyTripStyle.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _dayCard(_Step step) {
    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(context.r(6)),
        border: Border.all(color: DiyTripStyle.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step.dayLabel,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.blue,
                  ),
                ),
              ),
              Text(
                step.note,
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w500,
                  color: step.noteColor,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(2)),
          Text(
            step.title,
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (step.subtitle.isNotEmpty) ...[
            SizedBox(height: context.h(2)),
            Text(
              step.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(10),
                color: DiyTripStyle.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _StepKind { arrival, checkIn, meal, checkout, drop }

class _Step {
  final _StepKind kind;
  final String dayLabel;
  final String note;
  final Color noteColor;
  final String title;
  final String subtitle;

  const _Step._({
    required this.kind,
    this.dayLabel = '',
    this.note = '',
    this.noteColor = Colors.transparent,
    required this.title,
    this.subtitle = '',
  });

  factory _Step.transfer({required String title}) =>
      _Step._(kind: _StepKind.arrival, title: title);

  factory _Step.drop({required String title, required String subtitle}) =>
      _Step._(kind: _StepKind.drop, title: title, subtitle: subtitle);

  factory _Step.day({
    required _StepKind kind,
    required String dayLabel,
    required String note,
    required Color noteColor,
    required String title,
    required String subtitle,
  }) =>
      _Step._(
        kind: kind,
        dayLabel: dayLabel,
        note: note,
        noteColor: noteColor,
        title: title,
        subtitle: subtitle,
      );

  bool get isDay =>
      kind == _StepKind.checkIn ||
      kind == _StepKind.meal ||
      kind == _StepKind.checkout;
}
