import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

enum _PickTarget { departure, returnDate }

/// Full-screen departure/return date picker for the flight [SearchCard],
/// styled after the Figma reference (scrollable multi-month calendar,
/// Departure/Return summary pills, "+ Add Return Date", Done button).
///
/// Separate from the generic `CompactDatePickerDialog` used elsewhere in
/// the app (hotel search, multi-city legs, etc.) — that one is left
/// untouched so nothing else changes behaviour.
class FlightCalendarScreen extends StatefulWidget {
  final DateTime? initialDeparture;
  final DateTime? initialReturn;
  final bool isRoundTrip;
  final bool startWithReturn;
  final DateTime firstDate;
  final DateTime lastDate;

  const FlightCalendarScreen({
    super.key,
    this.initialDeparture,
    this.initialReturn,
    this.isRoundTrip = false,
    this.startWithReturn = false,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<FlightCalendarScreen> createState() => _FlightCalendarScreenState();
}

class _FlightCalendarScreenState extends State<FlightCalendarScreen> {
  static const Color _orange = Color(0xffF97316);

  late _PickTarget _picking;
  DateTime? _departure;
  DateTime? _return;
  late bool _roundTrip;

  @override
  void initState() {
    super.initState();
    _departure = widget.initialDeparture != null
        ? DateUtils.dateOnly(widget.initialDeparture!)
        : null;
    _return = widget.initialReturn != null
        ? DateUtils.dateOnly(widget.initialReturn!)
        : null;
    _roundTrip = widget.isRoundTrip;
    _picking = widget.startWithReturn
        ? _PickTarget.returnDate
        : _PickTarget.departure;
  }

  void _selectDay(DateTime day) {
    setState(() {
      if (_picking == _PickTarget.departure) {
        _departure = day;
        if (_return != null && _return!.isBefore(day)) _return = null;
        // Guided flow: after picking departure on a round trip, move
        // straight to picking the return date.
        if (_roundTrip) _picking = _PickTarget.returnDate;
      } else {
        _return = day;
      }
    });
  }

  bool get _canFinish => _departure != null && (!_roundTrip || _return != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(4),
                context.h(4),
                context.w(16),
                context.h(4),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Image.asset(
                      'assets/NewIcons/arrowBack.png',
                      width: context.w(17),
                      height: context.w(17),
                    ),
                  ),
                  Text(
                    _picking == _PickTarget.departure
                        ? 'Select Departure Date'
                        : 'Select Return Date',
                    style: TextStyle(
                      fontSize: context.fs(20),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryPill(
                      label: 'Departure',
                      date: _departure,
                      active: _picking == _PickTarget.departure,
                      onTap: () =>
                          setState(() => _picking = _PickTarget.departure),
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  if (_roundTrip)
                    Expanded(
                      child: _summaryPill(
                        label: 'Return',
                        date: _return,
                        active: _picking == _PickTarget.returnDate,
                        onTap: () =>
                            setState(() => _picking = _PickTarget.returnDate),
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _roundTrip = true;
                        _picking = _PickTarget.returnDate;
                      }),
                      icon: Icon(
                        Icons.add,
                        size: context.w(16),
                        color: AppColors.blue,
                      ),
                      label: Text(
                        'Add Return Date',
                        style: TextStyle(
                          fontSize: context.fs(13),
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: context.h(12)),
            _weekHeader(context),
            SizedBox(height: context.h(4)),
            Divider(height: 1, color: AppColors.fieldBorder),

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(8),
                ),
                itemCount: _monthCount,
                itemBuilder: (context, index) => _monthSection(context, index),
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(16),
                  context.h(8),
                  context.w(16),
                  context.h(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: context.h(48),
                  child: ElevatedButton(
                    onPressed: _canFinish
                        ? () => Navigator.of(context).pop({
                            'departure': _departure,
                            'return': _return,
                            'isRoundTrip': _roundTrip,
                          })
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      disabledBackgroundColor: _orange.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(14)),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryPill({
    required String label,
    required DateTime? date,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(10)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(8),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? _orange : AppColors.fieldBorder,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(context.r(10)),
          color: active ? _orange.withValues(alpha: 0.06) : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            SizedBox(height: context.h(2)),
            Text(
              date != null
                  ? DateFormat('dd/MM/yyyy').format(date)
                  : 'Select date',
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w700,
                color: date != null ? AppColors.navy : const Color(0xff9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekHeader(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Row(
        children: labels
            .map(
              (label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  int get _monthCount {
    final first = DateTime(widget.firstDate.year, widget.firstDate.month);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month);
    return (last.year - first.year) * 12 + (last.month - first.month) + 1;
  }

  Widget _monthSection(BuildContext context, int index) {
    final month = DateTime(
      widget.firstDate.year,
      widget.firstDate.month + index,
    );
    final days = _buildCalendarDays(month);
    final activeDate = _picking == _PickTarget.departure ? _departure : _return;

    return Padding(
      padding: EdgeInsets.only(bottom: context.h(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: context.h(8)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: context.h(4),
              crossAxisSpacing: context.w(4),
              childAspectRatio: 1.1,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final date = days[i];
              if (date == null) return const SizedBox.shrink();

              final disabled =
                  date.isBefore(widget.firstDate) ||
                  date.isAfter(widget.lastDate) ||
                  (_picking == _PickTarget.returnDate &&
                      _departure != null &&
                      date.isBefore(_departure!));
              final selected =
                  activeDate != null && DateUtils.isSameDay(date, activeDate);

              return InkWell(
                borderRadius: BorderRadius.circular(context.r(18)),
                onTap: disabled ? null : () => _selectDay(date),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _orange : Colors.transparent,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: disabled
                          ? const Color(0xffCBD5E1)
                          : selected
                          ? Colors.white
                          : AppColors.navy,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<DateTime?> _buildCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Monday-first week (matches the Figma reference): weekday is
    // 1=Mon..7=Sun, so shift blanks by (weekday - 1).
    final leadingBlanks = firstDay.weekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return List.generate(totalCells, (index) {
      final day = index - leadingBlanks + 1;
      if (day < 1 || day > daysInMonth) return null;
      return DateTime(month.year, month.month, day);
    });
  }
}
