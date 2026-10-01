import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';

/// What the calendar hands back.
class InsDateRange {
  final DateTime start;
  final DateTime? end;

  const InsDateRange(this.start, this.end);
}

/// "Select Start Date" / "Select End Date" — Figma `Start date insurance`
/// and `End date insurance`.
///
/// One continuously scrolling calendar rather than two separate pickers:
/// the two chips at the top say which end of the range the next tap sets,
/// and the range between them is filled in blue.
class InsDateScreen extends StatefulWidget {
  final DateTime start;
  final DateTime? end;

  /// False for a STUDENT policy, whose end date is derived from the tenure —
  /// the end chip is then shown read-only and taps only move the start.
  final bool editEndDate;

  /// Open with the end chip active (the traveller tapped "END DATE").
  final bool focusEnd;

  /// How far ahead the calendar runs. A year of months covers every policy
  /// the provider sells from today.
  final int monthsAhead;

  const InsDateScreen({
    super.key,
    required this.start,
    required this.end,
    this.editEndDate = true,
    this.focusEnd = false,
    this.monthsAhead = 14,
  });

  static Future<InsDateRange?> pick(
    BuildContext context, {
    required DateTime start,
    required DateTime? end,
    bool editEndDate = true,
    bool focusEnd = false,
  }) {
    return Navigator.of(context).push<InsDateRange>(
      MaterialPageRoute(
        builder: (_) => InsDateScreen(
          start: start,
          end: end,
          editEndDate: editEndDate,
          focusEnd: focusEnd,
        ),
      ),
    );
  }

  @override
  State<InsDateScreen> createState() => _InsDateScreenState();
}

class _InsDateScreenState extends State<InsDateScreen> {
  late DateTime _start = widget.start;
  late DateTime? _end = widget.end;

  /// Which chip the next tap fills in.
  late bool _pickingEnd = widget.focusEnd && widget.editEndDate;

  /// The first of each month the calendar renders, from this month forward.
  late final List<DateTime> _months = () {
    final first = DateTime(DateTime.now().year, DateTime.now().month);
    return [
      for (int i = 0; i < widget.monthsAhead; i++)
        DateTime(first.year, first.month + i),
    ];
  }();

  DateTime get _today => DateUtilsX.today();

  void _tap(DateTime day) {
    setState(() {
      if (!_pickingEnd) {
        _start = day;
        // Picking a start after the current end invalidates the end.
        if (_end != null && _end!.isBefore(day)) _end = null;
        // Move straight on to the end date, which is what the traveller is
        // going to want next.
        if (widget.editEndDate) _pickingEnd = true;
      } else {
        if (day.isBefore(_start)) {
          // Tapping before the start re-anchors the range instead of
          // rejecting the tap.
          _start = day;
          _end = null;
        } else {
          _end = day;
        }
      }
    });
  }

  void _reset() {
    setState(() {
      _start = _today;
      _end = null;
      _pickingEnd = false;
    });
  }

  void _done() {
    if (widget.editEndDate && _end == null) {
      insSnack(context, 'Select an end date', isError: true);
      return;
    }
    Navigator.of(context).pop(InsDateRange(_start, _end));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: insAppBar(
        context,
        title: _pickingEnd ? 'Select End Date' : 'Select Start Date',
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(
              'Reset',
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w600,
                color: InsTokens.blue,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: context.h(15),),
          _chips(context),
          _weekdayHeader(context),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: context.h(20)),
              itemCount: _months.length,
              itemBuilder: (_, i) => _month(context, _months[i]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // Shadow cast UP onto the calendar above.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: context.r(8),
              offset: Offset(0, -context.h(4)),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          context.w(18),
          context.h(10),
          context.w(18),
          context.h(4),
        ),
        child: SafeArea(
          top: false,
          child: InsPrimaryButton(label: 'DONE', onPressed: _done),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- chips

  Widget _chips(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(4),
        context.w(14),
        context.h(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _chip(
              context,
              label: 'Start Date',
              date: _start,
              active: !_pickingEnd,
              onTap: () => setState(() => _pickingEnd = false),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: _chip(
              context,
              label: 'End Date',
              date: _end,
              active: _pickingEnd,
              enabled: widget.editEndDate,
              onTap: widget.editEndDate
                  ? () => setState(() => _pickingEnd = true)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, {
        required String label,
        required DateTime? date,
        required bool active,
        bool enabled = true,
        VoidCallback? onTap,
      }) {
    final borderColor = active ? InsTokens.blue : InsTokens.line;
    final labelColor = active
        ? InsTokens.blue
        : (enabled ? InsTokens.subGrey : InsTokens.labelGrey);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: InputDecorator(
        isFocused: active,
        isEmpty: date == null,
        decoration: InputDecoration(
          // ---- Floating label sits ON the top border (notched) ----

          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            fontSize: context.fs(11),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: labelColor,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: context.fs(11),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: labelColor,
          ),

          // ---- Border ----
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(8)),
            borderSide: BorderSide(
              color: borderColor,
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(8)),
            borderSide: const BorderSide(color: InsTokens.blue, width: 0.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(10)),
            borderSide: BorderSide(color: borderColor),
          ),
        ),

        // ---- Content inside the chip ----
        child: Row(
          children: [
            Image.asset(
              'assets/NewIcons/calender.png',
              width: context.w(14),
              height: context.w(14),
              color: active
                  ? InsTokens.blue
                  : (enabled ? InsTokens.subGrey : InsTokens.labelGrey),
            ),
            SizedBox(width: context.w(9)),
            Expanded(
              child: date == null
                  ? Text(
                'Select',
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: InsTokens.labelGrey,
                ),
              )
                  : RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: DateFormat('d MMM').format(date),
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w600,
                    color: InsTokens.navy,
                  ),
                  children: [
                    TextSpan(
                      text: '  ${DateFormat('E, y').format(date)}',
                      style: TextStyle(
                        fontSize: context.fs(8),
                        fontWeight: FontWeight.w600,
                        color: InsTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------- grid

  Widget _weekdayHeader(BuildContext context) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white, // ← needed, otherwise the shadow shows through
        border: const Border(
          // top: BorderSide(color: InsTokens.line),
          bottom: BorderSide(color: AppColors.white),
        ),
        // Shadow cast DOWN onto the calendar below.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: context.r(8),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final n in names)
            Expanded(
              child: Text(
                n,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w400,
                  color: InsTokens.navy,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _month(BuildContext context, DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first offset: DateTime.weekday is 1 (Mon) … 7 (Sun).
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(18),
            context.h(22),
            context.w(18),
            context.h(10),
          ),
          child: RichText(
            text: TextSpan(
              text: DateFormat('MMMM').format(month),
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w500,
                color: InsTokens.navy,
              ),
              children: [
                TextSpan(
                  text: '  ${month.year}',
                  style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w400,
                    color: InsTokens.subGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (int r = 0; r < rows; r++)
          Row(
            children: [
              for (int c = 0; c < 7; c++)
                Expanded(child: _cell(context, month, r * 7 + c - leading + 1)),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, DateTime month, int day) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    if (day < 1 || day > daysInMonth) {
      return SizedBox(height: context.h(52));
    }

    final date = DateTime(month.year, month.month, day);
    final past = date.isBefore(_today);
    final isStart = DateUtilsX.sameDay(date, _start);
    final end = _end;
    final isEnd = end != null && DateUtilsX.sameDay(date, end);
    final inRange =
        end != null && date.isAfter(_start) && date.isBefore(end);
    final selected = isStart || isEnd;

    // The blue bar runs edge to edge through the middle of a range, and is
    // rounded off at whichever end it stops.
    final radius = BorderRadius.horizontal(
      left: Radius.circular(isStart || end == null ? context.r(10) : 0),
      right: Radius.circular(isEnd || end == null ? context.r(10) : 0),
    );

    return GestureDetector(
      onTap: past ? null : () => _tap(date),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: context.h(52),
        child: Center(
          child: Container(
            height: context.h(40),
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? InsTokens.blue
                  : inRange
                      ? InsTokens.blue.withOpacity(0.92)
                      : Colors.transparent,
              borderRadius: radius,
            ),
            child: Text(
              day.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w500,
                color: selected || inRange
                    ? Colors.white
                    : past
                        ? const Color(0xFFD6DAE1)
                        : InsTokens.subGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
