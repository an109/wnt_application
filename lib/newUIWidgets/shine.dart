import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A pill-shaped button wrapper that draws a rotating "shine" stroke
/// around its border while keeping the child visually identical.
///
/// - [borderRadius] should match the child's own radius so the shine hugs it.
/// - [borderWidth] is the thickness of the shine outline.
/// - [shineColor] is the bright color of the sweep. Default is a warm white
///   that pops on the orange button, but you can pass your brand color.
/// - [duration] controls how fast the shine travels around.
class ShineBorderButton extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color shineColor;
  final Duration duration;
  final bool enabled;

  const ShineBorderButton({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.borderWidth = 2.5,
    this.shineColor = const Color(0xFFFFE0B2), // warm glow on orange
    this.duration = const Duration(seconds: 2, milliseconds: 500),
    this.enabled = true,
  });

  @override
  State<ShineBorderButton> createState() => _ShineBorderButtonState();
}

class _ShineBorderButtonState extends State<ShineBorderButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    if (!widget.enabled) {
      // No shine while disabled (e.g. during search) — just show the child.
      return widget.child;
    }

    final radius = BorderRadius.circular(widget.borderRadius);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          // The padding pushes the child inward, leaving room for the
          // shine stroke to sit on the original edge without shifting layout.
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: SweepGradient(
              startAngle: 0,
              endAngle: math.pi * 2,
              transform: GradientRotation(_controller.value * math.pi * 2),
              colors: [
                Colors.transparent,
                Colors.transparent,
                widget.shineColor.withOpacity(0.15),
                widget.shineColor,
                Colors.white,
                widget.shineColor,
                widget.shineColor.withOpacity(0.15),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [
                0.00,
                0.60,
                0.72,
                0.82,
                0.88,
                0.94,
                0.98,
                0.995,
                1.00,
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}