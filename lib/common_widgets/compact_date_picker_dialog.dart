import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

/// Compact, custom-styled date picker (same layout/size used across the app —
/// flight, hotel, etc.). Pass [accentColor] to match the host screen's theme.
class CompactDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color accentColor;

  const CompactDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.accentColor = const Color(0xff1663F7),
  });

  @override
  State<CompactDatePickerDialog> createState() =>
      _CompactDatePickerDialogState();
}

class _CompactDatePickerDialogState extends State<CompactDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  static const Color _ink = Color(0xff07163B);

  Color get _accent => widget.accentColor;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate);
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _changeMonth(int offset) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    final minMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final maxMonth = DateTime(widget.lastDate.year, widget.lastDate.month);

    if (next.isBefore(minMonth) || next.isAfter(maxMonth)) return;
    setState(() => _visibleMonth = next);
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays();
    final canGoBack = DateTime(
      _visibleMonth.year,
      _visibleMonth.month - 1,
    ).isAfter(DateTime(widget.firstDate.year, widget.firstDate.month - 1));
    final canGoNext = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
    ).isBefore(DateTime(widget.lastDate.year, widget.lastDate.month + 1));

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: context.w(28)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          context.w(18),
          context.h(16),
          context.w(18),
          context.h(14),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: context.w(28),
              offset: Offset(0, context.h(14)),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Select date",
                  style: TextStyle(
                    color: _ink,
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(context.r(14)),
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: EdgeInsets.all(context.w(4)),
                    child: Icon(
                      Icons.close,
                      color: const Color(0xff4B5563),
                      size: context.w(18),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(14)),
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: const Color(0xff9CA3AF),
                  size: context.w(20),
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Text(
                    DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                    style: TextStyle(
                      color: _ink,
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.edit_outlined, color: _ink, size: context.w(18)),
              ],
            ),
            SizedBox(height: context.h(12)),
            Divider(height: 1, color: const Color(0xffE5E7EB)),
            SizedBox(height: context.h(12)),
            Row(
              children: [
                _monthButton(
                  icon: Icons.chevron_left,
                  enabled: canGoBack,
                  onTap: () => _changeMonth(-1),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_visibleMonth),
                      style: TextStyle(
                        color: _ink,
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _monthButton(
                  icon: Icons.chevron_right,
                  enabled: canGoNext,
                  onTap: () => _changeMonth(1),
                ),
              ],
            ),
            SizedBox(height: context.h(12)),
            _weekHeader(context),
            SizedBox(height: context.h(6)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: context.h(4),
                crossAxisSpacing: context.w(4),
                childAspectRatio: 1.12,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                if (date == null) return const SizedBox.shrink();

                final disabled =
                    date.isBefore(widget.firstDate) ||
                    date.isAfter(widget.lastDate);
                final selected = DateUtils.isSameDay(date, _selectedDate);

                return InkWell(
                  borderRadius: BorderRadius.circular(context.r(18)),
                  onTap: disabled
                      ? null
                      : () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? _accent : Colors.transparent,
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: disabled
                            ? const Color(0xffCBD5E1)
                            : selected
                            ? Colors.white
                            : Colors.black,
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: context.h(12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: _accent,
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: context.w(8)),
                SizedBox(
                  height: context.h(38),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: context.w(22)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(10)),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.r(14)),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.all(context.w(4)),
        child: Icon(
          icon,
          color: enabled ? _ink : const Color(0xffCBD5E1),
          size: context.w(22),
        ),
      ),
    );
  }

  Widget _weekHeader(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xff6B7280),
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  List<DateTime?> _buildCalendarDays() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final leadingBlanks = firstDay.weekday % 7;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return List.generate(totalCells, (index) {
      final day = index - leadingBlanks + 1;
      if (day < 1 || day > daysInMonth) return null;
      return DateTime(_visibleMonth.year, _visibleMonth.month, day);
    });
  }
}
