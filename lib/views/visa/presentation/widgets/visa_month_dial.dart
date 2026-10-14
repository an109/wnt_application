import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../utils/visa_theme.dart';

/// Rotary month picker of the "Flexible Date" design: drag the dial, the
/// month under the orange pointer is selected.
class VisaMonthDial extends StatefulWidget {
  final List<DateTime> months;
  final int selected;
  final ValueChanged<int> onChanged;

  const VisaMonthDial({super.key, required this.months, required this.selected, required this.onChanged});

  @override
  State<VisaMonthDial> createState() => _VisaMonthDialState();
}

class _VisaMonthDialState extends State<VisaMonthDial> {
  static const _step = math.pi / 6; // 30° per month
  late double _rotation = widget.selected * _step;

  void _drag(DragUpdateDetails d, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);
    final before = d.localPosition - d.delta - center;
    final after = d.localPosition - center;
    var delta = after.direction - before.direction;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    setState(() {
      _rotation = (_rotation - delta).clamp(0.0, (widget.months.length - 1) * _step);
    });
    final index = (_rotation / _step).round();
    if (index != widget.selected) widget.onChanged(index);
  }

  void _settle() => setState(() => _rotation = widget.selected * _step);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final size = Size(c.maxWidth, 300);
      return GestureDetector(
        onPanUpdate: (d) => _drag(d, size),
        onPanEnd: (_) => _settle(),
        child: CustomPaint(
          size: size,
          painter: _DialPainter(months: widget.months, rotation: _rotation, selected: widget.selected),
        ),
      );
    });
  }
}

class _DialPainter extends CustomPainter {
  final List<DateTime> months;
  final double rotation;
  final int selected;

  _DialPainter({required this.months, required this.rotation, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);
    final outer = size.width * 0.46;
    final ring = outer * 0.74;

    // Outer faint disc and the light-blue ring.
    canvas.drawCircle(center, outer, Paint()..color = const Color(0xFFF4FAFE));
    canvas.drawCircle(
      center,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xFFCDEBF8),
    );
    canvas.drawCircle(center, ring * 0.72, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      ring * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFE5F3FA),
    );

    // Ticks: one long tick per month, small ones between.
    const step = math.pi / 6;
    for (var i = 0; i < months.length * 5; i++) {
      final a = -math.pi / 2 + i * step / 5 - rotation;
      final major = i % 5 == 0;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (outer - (major ? 14 : 8));
      final p2 = center + Offset(math.cos(a), math.sin(a)) * (outer - 2);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = major ? VisaColors.primary : const Color(0xFF9BD8F3)
          ..strokeWidth = major ? 1.6 : 1,
      );
    }

    // Month labels.
    for (var i = 0; i < months.length; i++) {
      final a = -math.pi / 2 + i * step - rotation;
      final pos = center + Offset(math.cos(a), math.sin(a)) * (outer + 14);
      final isSel = i == selected;
      final tp = TextPainter(
        text: TextSpan(
          text: DateFormat('MMM').format(months[i]).toUpperCase(),
          style: visaText(isSel ? 12 : 10,
              weight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? VisaColors.title : VisaColors.text),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Orange pointer up to the selected month.
    final tip = center + Offset(0, -(outer + 2));
    final pointer = Paint()
      ..color = VisaColors.cta
      ..strokeWidth = 2;
    canvas.drawLine(center + Offset(0, -ring * 0.45), tip, pointer);
    final head = Path()
      ..moveTo(tip.dx, tip.dy - 8)
      ..lineTo(tip.dx - 6, tip.dy + 4)
      ..lineTo(tip.dx + 6, tip.dy + 4)
      ..close();
    canvas.drawPath(head, Paint()..color = VisaColors.cta);

    // Centre knob.
    final knob = ring * 0.42;
    canvas.drawCircle(
      center,
      knob,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF6CC7F0), Color(0xFFF07A2D)],
          stops: [0.0, 0.75],
        ).createShader(Rect.fromCircle(center: center, radius: knob)),
    );
    canvas.drawCircle(center - Offset(knob * 0.3, knob * 0.3), knob * 0.18, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.rotation != rotation || old.selected != selected;
}
