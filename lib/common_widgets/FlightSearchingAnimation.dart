import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FlightSearchingAnimation extends StatefulWidget {
  const FlightSearchingAnimation({super.key});

  @override
  State<FlightSearchingAnimation> createState() =>
      _FlightSearchingAnimationState();
}

class _FlightSearchingAnimationState extends State<FlightSearchingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final planeX =
                20 + ((width - 40) * _controller.value);

            final planeY =
                95 + (15 *
                    (0.5 -
                        (0.5 -
                            (_controller.value - 0.5).abs())
                            .abs()));

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: FlightPathPainter(),
                  ),
                ),

                Positioned(
                  left: planeX - 18,
                  top: planeY,
                  child: Transform.rotate(
                    angle: 0.15,
                    child: const Icon(
                      Icons.airplanemode_active_rounded,
                      size: 36,
                      color: Color(0xFF0054A0),
                    ),
                  ),
                ),

                Positioned(
                  left: 10,
                  top: 95,
                  child: _buildPulseDot(),
                ),

                Positioned(
                  right: 10,
                  top: 95,
                  child: _buildPulseDot(),
                ),

                Positioned(
                  top: 35,
                  left: width * 0.25,
                  child: const Text(
                    "☁️",
                    style: TextStyle(fontSize: 24),
                  ),
                ),

                Positioned(
                  top: 55,
                  right: width * 0.20,
                  child: const Text(
                    "☁️",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPulseDot() {
    final scale = 0.8 + (_controller.value * 0.4);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFF0054A0),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class FlightPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(20, 100);

    path.quadraticBezierTo(
      size.width / 2,
      30,
      size.width - 20,
      100,
    );

    const dashWidth = 10.0;
    const dashSpace = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final extract = metric.extractPath(
          distance,
          distance + dashWidth,
        );

        canvas.drawPath(extract, paint);

        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}