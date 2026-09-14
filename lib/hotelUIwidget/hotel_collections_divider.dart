import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

/// Decorative dashed gold divider with three small star accents — Figma's
/// "Collections" section uses this above and below the image grid.
/// Purely decorative, so it's a tiny stateless widget rather than anything
/// tied to data.
class HotelCollectionsDivider extends StatelessWidget {
  const HotelCollectionsDivider({super.key});

  static const _gold = Color(0xFFE0B84B);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.h(14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(double.infinity, 1),
            painter: _DashedLinePainter(color: _gold.withOpacity(0.6)),
          ),
          Align(
            alignment: const Alignment(-0.55, 0),
            child: Icon(Icons.star_rounded, size: context.w(10), color: _gold),
          ),
          Align(
            alignment: Alignment.center,
            child: Icon(Icons.star_rounded, size: context.w(10), color: _gold),
          ),
          Align(
            alignment: const Alignment(0.55, 0),
            child: Icon(Icons.star_rounded, size: context.w(10), color: _gold),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
