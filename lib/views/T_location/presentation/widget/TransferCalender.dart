import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../newUIWidgets/sheetActionButtons.dart';


enum _PickTarget { departure, returnDate }

class TransferCalendarScreen extends StatefulWidget {
  final DateTime? initialDeparture;
  final DateTime? initialReturn;
  final bool isRoundTrip;
  final bool startWithReturn;
  final DateTime firstDate;
  final DateTime lastDate;

  final String startLabel;
  final String endLabel;
  final String startEmptyText;
  final String endEmptyText;

  const TransferCalendarScreen({
    super.key,
    this.initialDeparture,
    this.initialReturn,
    this.isRoundTrip = false,
    this.startWithReturn = false,
    required this.firstDate,
    required this.lastDate,
    this.startLabel = 'Departure',
    this.endLabel = 'Return',
    this.startEmptyText = 'Select date',
    this.endEmptyText = 'Add Return Date',
  });

  @override
  State<TransferCalendarScreen> createState() => _TransferCalendarScreenState();
}

class _TransferCalendarScreenState extends State<TransferCalendarScreen> {
  static const Color _orange = AppColors.OrangeColor;
  static const Color _selectedBlue = AppColors.AppBlue; // Blue from image
  static const Color _textDark = AppColors.black;
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _dividerColor = AppColors.lightsubhead;

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
        if (_roundTrip) _picking = _PickTarget.returnDate;
      } else {
        _return = day;
      }
    });
  }

  bool get _canFinish => _departure != null && (!_roundTrip || _return != null);

  DateTime? get _activeDate =>
      _picking == _PickTarget.departure ? _departure : _return;

  int get _monthCount {
    final first = DateTime(widget.firstDate.year, widget.firstDate.month);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month);
    return (last.year - first.year) * 12 + (last.month - first.month) + 1;
  }

  @override
  Widget build(BuildContext context) {
    // Determine text to show in the big header based on current selection
    String headerDateText = "Select date";
    if (_activeDate != null) {
      headerDateText = DateFormat('EEE, MMM d').format(_activeDate!);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- HEADER SECTION (Left Aligned with Bottom Divider) ---
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(20),
                  context.h(16),
                  context.w(20),
                  context.h(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select date",
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: _textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      headerDateText,
                      style: TextStyle(
                        fontSize: context.fs(28),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- VERTICAL SCROLLABLE CALENDAR ---
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                top: context.h(10),
                bottom: context.h(20),
              ),
              itemCount: _monthCount,
              itemBuilder: (context, index) {
                final month = DateTime(
                  widget.firstDate.year,
                  widget.firstDate.month + index,
                );
                return _buildMonthSection(context, month);
              },
            ),
          ),

          // --- BOTTOM ACTION BUTTONS ---
          SheetActionButtons(
            primaryLabel: 'SELECT TIME',
            secondaryLabel: 'RESET',
            onPrimary: _canFinish
                ? () => Navigator.of(context).pop({
              'departure': _departure,
              'return': _return,
              'isRoundTrip': _roundTrip,
            })
                : () {},
            onSecondary: () {
              setState(() {
                _departure = null;
                _return = null;
                _picking = _PickTarget.departure;
              });
            },
            primaryColor: _orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(BuildContext context, DateTime month) {
    final days = _buildCalendarDays(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Header Row
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(20),
            vertical: context.h(16),
          ),
          child: Row(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  color: _textLight,
                ),
              ),
              SizedBox(width: context.w(4)),
              Icon(Icons.arrow_drop_down, color: _textLight, size: context.w(20)),
            ],
          ),
        ),

        // Weekday Labels (S M T W T F S)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (label) => SizedBox(
                width: context.w(36),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w500,
                      color: _textLight,
                    ),
                  ),
                ),
              ),
            )
                .toList(),
          ),
        ),

        SizedBox(height: context.h(10)),

        // Days Grid
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: context.h(12),
              crossAxisSpacing: context.w(8),
              childAspectRatio: 1.0,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final date = days[i];
              if (date == null) return const SizedBox.shrink();

              // Disable logic
              final disabled = date.isBefore(DateUtils.dateOnly(widget.firstDate)) ||
                  date.isAfter(DateUtils.dateOnly(widget.lastDate)) ||
                  (_picking == _PickTarget.returnDate &&
                      _departure != null &&
                      date.isBefore(_departure!));

              // Selection logic
              final isSelected = _activeDate != null &&
                  DateUtils.isSameDay(date, _activeDate);

              return GestureDetector(
                onTap: disabled ? null : () => _selectDay(date),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _selectedBlue : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w500,
                      color: disabled
                          ? _textLight.withOpacity(0.5)
                          : isSelected
                          ? Colors.white
                          : _textDark,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<DateTime?> _buildCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // weekday: 1 = Mon, 7 = Sun. We need S(0) to S(6).
    // Flutter DateTime.weekday: Monday = 1, Sunday = 7.
    // If we want Sunday first: Sun(7)->0, Mon(1)->1.
    int leadingBlanks = firstDay.weekday % 7;

    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return List.generate(totalCells, (index) {
      final day = index - leadingBlanks + 1;
      if (day < 1 || day > daysInMonth) return null;
      return DateTime(month.year, month.month, day);
    });
  }
}