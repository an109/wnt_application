import 'dart:math' as math;
import 'package:flutter/material.dart';

class ShimmerBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final double baseBorderWidth;
  final Duration duration;
  final List<Color> colors;

  const ShimmerBorder({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.borderWidth = 2.0,
    this.baseBorderWidth = 1.0,
    this.duration = const Duration(milliseconds: 2500),
    this.colors = const [
      Color(0xFFCCCCCC),
      Color(0xFF00A1E4),
      Color(0xFF7B61FF),
      Color(0xFF00A1E4),
      Color(0xFFCCCCCC),
    ],
  });

  @override
  State<ShimmerBorder> createState() => _ShimmerBorderState();
}

class _ShimmerBorderState extends State<ShimmerBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ShimmerBorderPainter(
            progress: _controller.value,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
            baseBorderWidth: widget.baseBorderWidth,
            colors: widget.colors,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ShimmerBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double borderWidth;
  final double baseBorderWidth;
  final List<Color> colors;

  _ShimmerBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
    required this.baseBorderWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final angle = progress * 2 * math.pi;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.8;
    final shaderRect = Rect.fromCircle(center: center, radius: radius);

    // 1) Thin base border (the grey/muted portion).
    final baseRect = Rect.fromLTWH(
      baseBorderWidth / 2,
      baseBorderWidth / 2,
      size.width - baseBorderWidth,
      size.height - baseBorderWidth,
    );
    final baseRRect = RRect.fromRectAndRadius(baseRect, Radius.circular(borderRadius));
    final basePaint = Paint()
      ..color = colors.first
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseBorderWidth;
    canvas.drawRRect(baseRRect, basePaint);

    // 2) Thick highlight sweep (blue/purple) on top — the grey stops are
    //    made transparent so only the colourful arc draws at full width.
    final highlightColors = colors.map((c) {
      final r = (c.r * 255).round();
      final g = (c.g * 255).round();
      final b = (c.b * 255).round();
      final grey = r == g && g == b && r >= 0xC0;
      return grey ? c.withValues(alpha: 0) : c;
    }).toList();

    final highlightGradient = SweepGradient(
      colors: highlightColors,
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      transform: GradientRotation(angle),
    );

    final highlightRect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final highlightRRect = RRect.fromRectAndRadius(highlightRect, Radius.circular(borderRadius));
    final highlightPaint = Paint()
      ..shader = highlightGradient.createShader(shaderRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(highlightRRect, highlightPaint);
  }

  @override
  bool shouldRepaint(_ShimmerBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
