import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/visa_theme.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Month grid used by every visa calendar. Shows a selected range as a light
/// blue band with solid blue ends (Holiday / Visa Validity designs) or a
/// single solid blue circle (Date picker design).
class VisaMonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? start;
  final DateTime? end;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool mondayFirst;
  final bool circleSelection;
  final bool showHeaders;
  final ValueChanged<DateTime> onTap;

  const VisaMonthGrid({
    super.key,
    required this.month,
    required this.onTap,
    this.start,
    this.end,
    this.firstDate,
    this.lastDate,
    this.mondayFirst = true,
    this.circleSelection = false,
    this.showHeaders = true,
  });

  @override
  Widget build(BuildContext context) {
    final headers = mondayFirst
        ? const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final first = DateTime(month.year, month.month, 1);
    final lead = mondayFirst ? first.weekday - 1 : first.weekday % 7;
    final gridStart = first.subtract(Duration(days: lead));
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final rows = ((lead + daysInMonth) / 7).ceil();
    final today = _day(DateTime.now());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeaders) ...[
          Row(
            children: [
              for (final h in headers)
                Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: visaText(
                        11,
                        weight: FontWeight.w500,
                        color: VisaColors.text,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _cell(
                      gridStart.add(Duration(days: r * 7 + c)),
                      today,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(DateTime date, DateTime today) {
    final d = _day(date);
    final inMonth = d.month == month.month;
    final disabled =
        !inMonth ||
        (firstDate != null && d.isBefore(_day(firstDate!))) ||
        (lastDate != null && d.isAfter(_day(lastDate!)));
    final s = start == null ? null : _day(start!);
    final e = end == null ? null : _day(end!);
    final isStart = s != null && d == s;
    final isEnd = e != null && d == e;
    final inRange = s != null && e != null && d.isAfter(s) && d.isBefore(e);
    final selected = isStart || isEnd;

    final label = DateFormat('dd').format(d);
    final textColor = selected
        ? Colors.white
        : disabled
        ? const Color(0xFFBDBDBD)
        : (inRange ? VisaColors.primary : VisaColors.title);

    if (circleSelection) {
      final isToday = d == today && inMonth;
      return GestureDetector(
        onTap: disabled ? null : () => onTap(d),
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? VisaColors.primary : null,
              border: isToday && !selected
                  ? Border.all(color: VisaColors.primary)
                  : null,
            ),
            child: Text(
              inMonth ? '${d.day}' : '',
              style: visaText(
                12,
                weight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isToday ? VisaColors.primary : textColor),
              ),
            ),
          ),
        ),
      );
    }

    final bandColor = VisaColors.primarySoft;
    final hasBand =
        inRange ||
        (isStart && e != null && e != s) ||
        (isEnd && s != null && e != s);
    return GestureDetector(
      onTap: disabled ? null : () => onTap(d),
      child: SizedBox(
        height: 30,
        child: Stack(
          children: [
            if (hasBand)
              Positioned.fill(
                left: isStart ? 16 : 0,
                right: isEnd ? 16 : 0,
                child: ColoredBox(color: bandColor),
              ),
            Center(
              child: Container(
                width: selected ? 30 : null,
                height: 30,
                alignment: Alignment.center,
                decoration: selected
                    ? BoxDecoration(
                        color: VisaColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                child: Text(
                  label,
                  style: visaText(
                    12,
                    weight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "‹ December, 2026 ›" month switcher.
class VisaMonthSwitcher extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstMonth;
  final bool centered;

  const VisaMonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
    this.firstMonth,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final canGoBack =
        firstMonth == null ||
        DateTime(
          month.year,
          month.month,
        ).isAfter(DateTime(firstMonth!.year, firstMonth!.month));
    final title = Text(
      DateFormat(centered ? 'MMMM, yyyy' : 'MMMM yyyy').format(month),
      style: visaText(
        centered ? 15 : 14,
        weight: FontWeight.w700,
        color: VisaColors.title,
      ),
    );
    final back = IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: canGoBack
          ? () => onChanged(DateTime(month.year, month.month - 1))
          : null,
      icon: const Icon(Icons.chevron_left, size: 20),
    );
    final next = IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
      icon: const Icon(Icons.chevron_right, size: 20),
    );
    if (centered) {
      return Row(
        children: [
          back,
          Expanded(child: Center(child: title)),
          next,
        ],
      );
    }
    return Row(children: [title, const Spacer(), back, next]);
  }
}
