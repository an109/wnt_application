import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../core/resources/app_colours.dart';

/// Compact analog-clock time picker (drag or tap an hour on the dial),
/// styled to match [CompactDatePickerDialog]'s card treatment. The Figma
/// this matches only shows a 12-number dial with no AM/PM control, but a
/// dial alone can only reach 12 of the 24 hours a transport pickup might
/// need — the small AM/PM toggle below the digital readout is the minimum
/// addition needed to keep every hour reachable without changing the rest
/// of the design.
class CompactTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final Color accentColor;

  const CompactTimePickerDialog({
    super.key,
    required this.initialTime,
    this.accentColor = AppColors.AppBlue,
  });

  @override
  State<CompactTimePickerDialog> createState() =>
      _CompactTimePickerDialogState();
}

class _CompactTimePickerDialogState extends State<CompactTimePickerDialog> {
  static Color _ink = AppColors.AppBlue;
  static const Color _muted = AppColors.subhead;
  static const Color _stroke = AppColors.lightsubhead;

  final GlobalKey _dialKey = GlobalKey();

  late int _hour12; // 1-12, dial value
  late bool _isPm;
  late int _minute;

  Color get _accent => widget.accentColor;

  @override
  void initState() {
    super.initState();
    _applyTime(widget.initialTime);
  }

  void _applyTime(TimeOfDay time) {
    _isPm = time.hour >= 12;
    _hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    _minute = time.minute;
  }

  int get _hour24 {
    if (_hour12 == 12) return _isPm ? 12 : 0;
    return _isPm ? _hour12 + 12 : _hour12;
  }

  void _updateFromGlobal(Offset globalPosition) {
    final box = _dialKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final center = Offset(box.size.width / 2, box.size.height / 2);
    final v = local - center;
    var angle = math.atan2(v.dx, -v.dy);
    if (angle < 0) angle += 2 * math.pi;
    final hour = (angle / (2 * math.pi) * 12).round() % 12;
    setState(() => _hour12 = hour == 0 ? 12 : hour);
  }

  void _reset() => setState(() => _applyTime(widget.initialTime));

  void _done() =>
      Navigator.of(context).pop(TimeOfDay(hour: _hour24, minute: _minute));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select time',
          style: TextStyle(
            fontSize: context.fs(12),
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
        SizedBox(height: context.h(18)),
        Center(child: _clockFace(context)),
        SizedBox(height: context.h(20)),
        Center(child: _digitalReadout(context)),
        SizedBox(height: context.h(14)),
        Center(child: _amPmToggle(context)),
        SizedBox(height: context.h(18)),
        Divider(height: 1, color: _stroke),
        SizedBox(height: context.h(14)),
        _footerButtons(context),
      ],
    );
  }

  // ------------------------------------------------------------ CLOCK DIAL

  Widget _clockFace(BuildContext context) {
    final size = context.w(220);
    return GestureDetector(
      key: _dialKey,
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => _updateFromGlobal(details.globalPosition),
      onTapDown: (details) => _updateFromGlobal(details.globalPosition),
      child: Container(
        width: size,
        height: size,
        decoration:  BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.lightblue.withValues(alpha: 0.4),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var hour = 1; hour <= 12; hour++)
              _hourLabel(context, hour, size),
            _hand(context, size),
            Container(
              width: context.w(6),
              height: context.w(6),
              decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Offset _pointForHour(int hour, double radius) {
    final angle = (hour % 12) * (math.pi / 6);
    return Offset(radius * math.sin(angle), -radius * math.cos(angle));
  }

  Widget _hourLabel(BuildContext context, int hour, double size) {
    final point = _pointForHour(hour, size / 2 - context.w(23));
    final selected = hour == _hour12;
    return Positioned(
      left: size / 2 + point.dx - context.w(12),
      top: size / 2 + point.dy - context.w(12),
      child: IgnorePointer(
        child: Container(
          width: context.w(24),
          height: context.w(24),
          alignment: Alignment.center,
          child: Text(
            '$hour',
            style: TextStyle(
              color: selected ? Colors.transparent : AppColors.subhead,
              fontWeight: FontWeight.w400,
              fontSize: context.fs(13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hand(BuildContext context, double size) {
    final radius = size / 2 - context.w(30);
    final point = _pointForHour(_hour12, radius);
    return IgnorePointer(
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _HandPainter(offset: point, color: _accent),
          ),
          Positioned(
            left: size / 2 + point.dx - context.w(14),
            top: size / 2 + point.dy - context.w(14),
            child: Container(
              width: context.w(42),
              height: context.w(42),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
              child: Text(
                '$_hour12',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: context.fs(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- DIGITAL READOUT

  Widget _digitalReadout(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _digitBox(
          context,
          text: _hour24.toString().padLeft(2, '0'),
          active: true,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(8)),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: context.fs(22),
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
        GestureDetector(
          // Minutes aren't on the dial — tap to step by 15, matching the
          // dial's own granularity rather than adding a second control.
          onTap: () => setState(() => _minute = (_minute + 15) % 60),
          child: _digitBox(
            context,
            text: _minute.toString().padLeft(2, '0'),
            active: false,
          ),
        ),
      ],
    );
  }

  Widget _digitBox(
    BuildContext context, {
    required String text,
    required bool active,
  }) {
    return Container(
      width: context.w(64),
      height: context.h(56),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? _accent.withValues(alpha: 0.08)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(26),
          fontWeight: FontWeight.w700,
          color: active ? _accent : const Color(0xff9CA3AF),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- AM / PM

  Widget _amPmToggle(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(3)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(context.r(4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _amPmSegment(
            context,
            label: 'AM',
            selected: !_isPm,
            onTap: () => setState(() => _isPm = false),
          ),
          _amPmSegment(
            context,
            label: 'PM',
            selected: _isPm,
            onTap: () => setState(() => _isPm = true),
          ),
        ],
      ),
    );
  }

  Widget _amPmSegment(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(6),
        ),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(context.r(4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.fs(11),
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _muted,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- FOOTER

  Widget _footerButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _reset,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _stroke),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
            ),
            child: Text(
              'RESET',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                fontSize: context.fs(12),
              ),
            ),
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: ElevatedButton(
            onPressed: _done,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffF97316),
              padding: EdgeInsets.symmetric(vertical: context.h(12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
            ),
            child: Text(
              'DONE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: context.fs(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HandPainter extends CustomPainter {
  final Offset offset;
  final Color color;

  _HandPainter({required this.offset, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + offset, paint);
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) =>
      oldDelegate.offset != offset || oldDelegate.color != color;
}
