import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/diy_dates.dart';
import '../widgets/diy_common.dart';

/// "Select Date" — Figma `holiday starting date`.
///
/// A scrolling month grid rather than the platform dialog, matching the
/// frame: a summary field at the top, fixed weekday header, one section per
/// month and a DONE bar pinned to the bottom.
class DiyCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;
  final int monthsAhead;

  const DiyCalendarScreen({super.key, this.initialDate, this.monthsAhead = 12});

  @override
  State<DiyCalendarScreen> createState() => _DiyCalendarScreenState();
}

class _DiyCalendarScreenState extends State<DiyCalendarScreen> {
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  late DateTime _today;
  late DateTime _thisMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    // `_today` is the earliest *selectable* day, which is tomorrow: the
    // price API refuses a departure that is not in the future.
    _thisMonth = DateUtils.dateOnly(DateTime.now());
    _today = DiyDates.earliestDeparture();
    final initial = widget.initialDate == null
        ? DiyDates.defaultDeparture()
        : DateUtils.dateOnly(widget.initialDate!);
    _selected = initial.isBefore(_today) ? _today : initial;
  }

  List<DateTime> get _months {
    final first = DateTime(_thisMonth.year, _thisMonth.month);
    return List.generate(
      widget.monthsAhead,
      (i) => DateTime(first.year, first.month + i),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: diyAppBar(context, title: 'Select Date'),
      body: Column(
        children: [
          _summaryField(),
          SizedBox(height: context.h(10)),
          _weekdayHeader(),
          const Divider(height: 1, color: DiyTokens.line),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: context.h(20)),
              itemCount: _months.length,
              itemBuilder: (context, i) => _monthSection(_months[i]),
            ),
          ),
          _doneBar(),
        ],
      ),
    );
  }

  Widget _summaryField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(10),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: DiyTokens.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Starting Date',
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w600,
                color: DiyTokens.blue,
              ),
            ),
            SizedBox(height: context.h(4)),
            Row(
              children: [
                Image.asset(
                  'assets/NewIcons/departureCalendar.png',
                  width: context.w(18),
                  height: context.w(18),
                ),
                SizedBox(width: context.w(10)),
                Text(
                  DateFormat('dd MMM').format(_selected),
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
                SizedBox(width: context.w(6)),
                Text(
                  DateFormat('EEE, yyyy').format(_selected),
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(6),
      ),
      child: Row(
        children: [
          for (final d in _weekdays)
            Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                    color: DiyTokens.navy,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _monthSection(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Monday-first grid: weekday 1 = Mon … 7 = Sun.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(16),
            context.h(18),
            context.w(16),
            context.h(8),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${DateFormat('MMMM').format(month)} ',
                  style: TextStyle(
                    fontSize: context.fs(18),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
                TextSpan(
                  text: '${month.year}',
                  style: TextStyle(
                    fontSize: context.fs(18),
                    fontWeight: FontWeight.w400,
                    color: DiyTokens.labelGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(12)),
          child: Column(
            children: [
              for (var row = 0; row < rows; row++)
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: _dayCell(
                          month,
                          (row * 7 + col) - leadingBlanks + 1,
                          daysInMonth,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayCell(DateTime month, int dayNumber, int daysInMonth) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return SizedBox(height: context.h(48));
    }

    final date = DateTime(month.year, month.month, dayNumber);
    final isPast = date.isBefore(_today);
    final isSelected = DateUtils.isSameDay(date, _selected);

    return GestureDetector(
      onTap: isPast ? null : () => setState(() => _selected = date),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: context.h(48),
        child: Center(
          child: Container(
            width: context.w(38),
            height: context.w(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? DiyTokens.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
            child: Text(
              dayNumber.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : isPast
                    ? const Color(0xFFD8DDE5)
                    : DiyTokens.subGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _doneBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(12),
        context.w(16),
        context.h(12) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: DiyTokens.line)),
      ),
      child: DiyPrimaryButton(
        label: 'DONE',
        onPressed: () => Navigator.of(context).pop(_selected),
      ),
    );
  }
}
