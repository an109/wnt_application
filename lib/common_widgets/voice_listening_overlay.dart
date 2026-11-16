import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

/// MMT-style animated voice listening overlay shown as a bottom sheet.
///
/// Shows pulsing ripple rings around a mic icon, animated sound-wave bars,
/// and live transcription text. Call [VoiceListeningOverlay.show] to present
/// it; the returned future completes with the final recognized text (or null
/// if dismissed).
class VoiceListeningOverlay extends StatefulWidget {
  final String recognizedText;
  final VoidCallback onCancel;

  const VoiceListeningOverlay({
    super.key,
    required this.recognizedText,
    required this.onCancel,
  });

  @override
  State<VoiceListeningOverlay> createState() => _VoiceListeningOverlayState();
}

class _VoiceListeningOverlayState extends State<VoiceListeningOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ripple;
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ripple.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.fx(24),
        context.fx(32),
        context.fx(24),
        context.fx(24) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: context.fx(40),
            height: context.fx(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: context.fx(28)),

          // Pulsing mic with ripples
          SizedBox(
            width: context.fx(120),
            height: context.fx(120),
            child: AnimatedBuilder(
              animation: _ripple,
              builder: (_, __) => CustomPaint(
                painter: _RipplePainter(
                  progress: _ripple.value,
                  color: AppColors.AppBlue,
                ),
                child: Center(
                  child: Container(
                    width: context.fx(56),
                    height: context.fx(56),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.AppBlue,
                          AppColors.AppBlue.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.AppBlue.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: context.fx(28),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: context.fx(20)),

          // Sound wave bars
          SizedBox(
            height: context.fx(32),
            child: AnimatedBuilder(
              animation: _wave,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (i) {
                  final phase = (i - 3).abs() / 3.0;
                  final t = (_wave.value + phase * 0.3) % 1.0;
                  final height = context.fx(8 + 20 * math.sin(t * math.pi));
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: context.fx(2.5)),
                    width: context.fx(4),
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.AppBlue.withValues(alpha: 0.5 + 0.5 * math.sin(t * math.pi)),
                      borderRadius: BorderRadius.circular(context.fx(2)),
                    ),
                  );
                }),
              ),
            ),
          ),

          SizedBox(height: context.fx(16)),

          // "Listening..." or recognized text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.recognizedText.isEmpty ? 'Listening...' : widget.recognizedText,
              key: ValueKey(widget.recognizedText),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.ffs(16),
                fontWeight: FontWeight.w500,
                color: widget.recognizedText.isEmpty
                    ? Colors.grey.shade500
                    : const Color(0xFF111527),
              ),
            ),
          ),

          SizedBox(height: context.fx(8)),
          if (widget.recognizedText.isEmpty)
            Text(
              'Speak now',
              style: TextStyle(
                fontSize: context.ffs(12),
                color: Colors.grey.shade400,
              ),
            ),

        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final p = (progress + i * 0.33) % 1.0;
      final radius = 28 + (maxRadius - 28) * p;
      final opacity = (1.0 - p) * 0.25;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}
