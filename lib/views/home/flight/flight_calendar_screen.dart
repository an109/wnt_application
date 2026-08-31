import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

enum _PickTarget { departure, returnDate }

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
  static const Color _orange = Color(0xFFFF6600);

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
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.h(18)),

            // Floating Label Date Pickers
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: Row(
                children: [
                  Expanded(
                    child: _floatingLabelDatePicker(
                      label: 'Departure',
                      date: _departure,
                      isActive: _picking == _PickTarget.departure,
                      onTap: () =>
                          setState(() => _picking = _PickTarget.departure),
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: _roundTrip
                        ? _floatingLabelDatePicker(
                      label: 'Return',
                      date: _return,
                      isActive: _picking == _PickTarget.returnDate,
                      onTap: () => setState(
                              () => _picking = _PickTarget.returnDate),
                    )
                        : _addReturnDateButton(),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.h(18)),
            _weekHeader(context),
            SizedBox(height: context.h(10)),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: context.h(8),
                    offset: Offset(0, context.h(4)),
                  ),
                ],
              ),
              child: ClipRect(
                clipper: BottomShadowClipper(),
                child: Container(
                  height: 1,
                  color: AppColors.fieldBorder,
                ),
              ),
            ),
            SizedBox(height: context.h(8)),

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

            Container(
              height: context.h(15), // Adjust height for shadow strength
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0), // Transparent at top
                    Colors.black.withOpacity(0.08), // Fade to shadow color at bottom
                  ],
                ),
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
                      backgroundColor: AppColors.OrangeColor,
                      disabledBackgroundColor: _orange.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(12)),
                      ),
                    ),
                    child: Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.bold,
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

  // EXACT FLOATING LABEL DESIGN FROM FIGMA
  Widget _floatingLabelDatePicker({
    required String label,
    required DateTime? date,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: context.h(50),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? AppColors.AppBlue : const Color(0xFFE5E7EB),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main content
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.only(
                  left: context.w(14),
                  top: context.h(12),
                  right: context.w(14),
                  bottom: context.h(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (date != null)
                      Row(
                        children: [
                          Image.asset(
                            'assets/NewIcons/calender.png',
                            width: context.w(14),
                            height: context.h(14),
                          ),
                          SizedBox(width: context.w(8)),
                          // Day and Month (Bold, Black)
                          Text(
                            DateFormat('dd MMM').format(date),
                            style: TextStyle(
                              fontSize: context.fs(12),
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(width: context.w(4)),
                          // Day of Week, Month and Year (Small, Grey)
                          Text(
                            DateFormat('EEE, yyyy').format(date),
                            style: TextStyle(
                              fontSize: context.fs(8),
                              fontWeight: FontWeight.w600,
                              color: AppColors.subhead,
                            ),
                          ),
                        ],
                      )
                    else
                    // Empty state layout
                      Text(
                        label == 'Return' ? 'Add Return Date' : 'Select date',
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Floating label
            Positioned(
              left: context.w(10),
              top: -context.h(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(8),
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.AppBlue : AppColors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addReturnDateButton() {
    return GestureDetector(
      onTap: () => setState(() {
        _roundTrip = true;
        _picking = _PickTarget.returnDate;
      }),
      child: Container(
        height: context.h(50),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.only(
                  left: context.w(14),
                  top: context.h(12),
                  right: context.w(14),
                  bottom: context.h(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      size: context.w(12),
                      color: AppColors.grey,
                    ),
                    SizedBox(width: context.w(8)),
                    Text(
                      'Add Return Date',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: context.w(10),
              top: -context.h(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
                child: Text(
                  'Return',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
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
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
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
    // final activeDate = _picking == _PickTarget.departure ? _departure : _return;
    bool isSelected;

    return Padding(
      padding: EdgeInsets.only(bottom: context.h(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('MMMM').format(month),
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
              SizedBox(width: context.w(6)),
              Text(
                DateFormat('yyyy').format(month),
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(12)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: context.h(16),
              crossAxisSpacing: context.w(0.001),
              childAspectRatio: 1.5,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final date = days[i];
              if (date == null) return const SizedBox.shrink();

              final disabled = date.isBefore(widget.firstDate) ||
                  date.isAfter(widget.lastDate) ||
                  (_picking == _PickTarget.returnDate &&
                      _departure != null &&
                      date.isBefore(_departure!));

              // final isSelected = activeDate != null &&
              //     DateUtils.isSameDay(date, activeDate);

              final isInRange = _departure != null &&
                  _return != null &&
                  date.isAfter(_departure!) &&
                  date.isBefore(_return!);

              if (_picking == _PickTarget.returnDate) {
                // Both departure and return dates are highlighted when selecting return
                isSelected = (_departure != null && DateUtils.isSameDay(date, _departure!)) ||
                    (_return != null && DateUtils.isSameDay(date, _return!));
              } else {
                // Only the date being picked is highlighted
                final activeDate = _picking == _PickTarget.departure ? _departure : _return;
                isSelected = activeDate != null && DateUtils.isSameDay(date, activeDate);
              }



              return GestureDetector(
                onTap: disabled ? null : () => _selectDay(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.OrangeColor
                        : isInRange
                        ? AppColors.OrangeColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    // borderRadius: BorderRadius.circular(context.r(4)),
                    borderRadius: isInRange
                        ? BorderRadius.zero  // No border radius for range
                        : BorderRadius.circular(context.r(4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w500,
                      color: disabled
                          ? const Color(0xFFE5E7EB)
                          : isSelected
                          ? Colors.white
                          : isInRange
                          ? AppColors.OrangeColor
                          : Color(0xFF9CA3AF),
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
    final leadingBlanks = firstDay.weekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return List.generate(totalCells, (index) {
      final day = index - leadingBlanks + 1;
      if (day < 1 || day > daysInMonth) return null;
      return DateTime(month.year, month.month, day);
    });
  }
}

class BottomShadowClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    // Keep only bottom half to show shadow below
    return Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.9);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
