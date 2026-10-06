import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../UI_helper/navigation_queue.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// The blue ring-and-tick confirmation the design plays once a login or
/// signup lands, before the app moves on.
class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({super.key, this.isGate = false});

  /// True when the auth flow started at the splash gate: there is nothing
  /// behind this screen to go back to, so it opens the home screen itself.
  final bool isGate;

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    unawaited(_moveOn());
  }

  Future<void> _moveOn() async {
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;

    // Something was waiting on this login (a booking, a visa form, …) —
    // resume it and step back out of the auth screens.
    if (NavigationQueueService().hasPendingNavigation) {
      NavigationQueueService().executePendingNavigation(context);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      _popBack();
      return;
    }

    if (widget.isGate) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    _popBack();
  }

  /// Closes this screen and the login screen beneath it.
  void _popBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
    if (navigator.canPop()) navigator.pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );
    final tick = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    );

    final size = context.w(132);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: ring.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.7 + (ring.value.clamp(0.0, 1.0) * 0.3),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _SuccessTickPainter(
                      progress: tick.value.clamp(0.0, 1.0),
                      color: AppColors.AppBlue,
                      strokeWidth: context.w(4),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuccessTickPainter extends CustomPainter {
  const _SuccessTickPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final radius = (size.shortestSide - strokeWidth) / 2;
    canvas.drawCircle(size.center(Offset.zero), radius, paint);

    if (progress <= 0) return;

    final w = size.width, h = size.height;
    final tick = Path()
      ..moveTo(w * 0.30, h * 0.52)
      ..lineTo(w * 0.44, h * 0.66)
      ..lineTo(w * 0.71, h * 0.37);

    canvas.drawPath(_partial(tick, progress), paint);
  }

  /// The leading [t] fraction of [path], so the tick strokes itself on.
  Path _partial(Path path, double t) {
    if (t >= 1) return path;
    final out = Path();
    for (final metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    return out;
  }

  @override
  bool shouldRepaint(_SuccessTickPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
