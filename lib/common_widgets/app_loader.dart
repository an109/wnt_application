import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

// ===========================================================================
// WanderNova loader — the "wave in a circle" from the Figma loading frames
// (nodes 2760:12264 / 12272 / 12280). Use these everywhere a screen or a
// section is waiting on data; keep small inline spinners only inside
// buttons and image placeholders.
//
//   AppLoadingView(message: 'Searching flights…')        // in a body/section
//   AppLoadingScreen(message: 'Loading your booking…')   // as a whole page
//   AppLoadingOverlay.show(context, message: 'Processing payment…')
// ===========================================================================

const Color _circleBg = Color(0xFFF2F2F2);
const Color _waveTop = Color(0xFF4FB6F8);
const Color _waveBottom = Color(0xFFC8EBFD);
const Color _waveAccent = Color(0xFFF37A2F);
const Color _messageColor = Color(0xFF757575);

/// The animated wave circle on its own, without any text.
class WaveLoader extends StatefulWidget {
  /// Diameter in logical pixels. Defaults to 100 (the Figma size on a
  /// 412-wide frame, scaled to the screen).
  final double? size;

  const WaveLoader({super.key, this.size});

  @override
  State<WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<WaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the OS "reduce motion" setting: show a still frame instead.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.25;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? context.fx(100);
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _WavePainter(_controller.value),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  /// Animation progress, 0 → 1 per wave cycle.
  final double t;

  _WavePainter(this.t);

  Path _wave(Size size, double phase, double level, double amplitude) {
    final w = size.width;
    final h = size.height;
    final k = 2 * math.pi / w; // one full wave across the circle
    final path = Path()..moveTo(0, h);
    for (double x = 0; x <= w; x += 1) {
      path.lineTo(x, h * level + h * amplitude * math.cos(k * x + phase));
    }
    return path
      ..lineTo(w, h)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(rect, Paint()..color = _circleBg);

    final phase = -t * 2 * math.pi;
    // Orange wave sits just behind the blue one, slightly ahead in phase,
    // so it peeks out on the rising side of the trough.
    canvas.drawPath(
      _wave(size, phase - 0.75, 0.53, 0.11),
      Paint()..color = _waveAccent,
    );
    canvas.drawPath(
      _wave(size, phase, 0.55, 0.11),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_waveTop, _waveBottom],
          stops: [0.4, 1.0],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

/// Wave loader with a line underneath telling the user *what* is loading.
///
/// Pass [messages] to rotate through several steps (e.g. for long
/// searches); otherwise [message] is shown as-is.
class AppLoadingView extends StatefulWidget {
  final String? message;
  final List<String>? messages;

  /// Optional smaller second line, e.g. "Please do not close the app".
  final String? hint;
  final double? size;

  /// Space to reserve vertically when used inside a list or a section, so
  /// the layout doesn't jump when the content arrives.
  final double? height;

  const AppLoadingView({
    super.key,
    this.message,
    this.messages,
    this.hint,
    this.size,
    this.height,
  });

  /// Smaller variant for dropdowns, sheets and in-page sections.
  const AppLoadingView.compact({
    super.key,
    this.message,
    this.messages,
    this.hint,
    this.height,
  }) : size = 56;

  @override
  State<AppLoadingView> createState() => _AppLoadingViewState();
}

class _AppLoadingViewState extends State<AppLoadingView> {
  int _index = 0;
  Timer? _timer;

  List<String> get _lines => widget.messages ?? const [];

  @override
  void initState() {
    super.initState();
    if (_lines.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
        if (mounted) setState(() => _index = (_index + 1) % _lines.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _lines.isNotEmpty ? _lines[_index] : widget.message;
    final compact = widget.size != null && widget.size! < 80;

    final content = Semantics(
      liveRegion: true,
      label: text ?? 'Loading',
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.fx(24),
          vertical: context.fx(compact ? 12 : 24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WaveLoader(size: widget.size),
            if (text != null && text.isNotEmpty) ...[
              SizedBox(height: context.fx(compact ? 10 : 16)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  text,
                  key: ValueKey(text),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.ffs(compact ? 12 : 14),
                    fontWeight: FontWeight.w500,
                    color: _messageColor,
                  ),
                ),
              ),
            ],
            if (widget.hint != null && widget.hint!.isNotEmpty) ...[
              SizedBox(height: context.fx(6)),
              Text(
                widget.hint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.ffs(compact ? 10 : 12),
                  color: _messageColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final centered = Center(child: content);
    return widget.height == null
        ? centered
        : SizedBox(height: widget.height, child: centered);
  }
}

/// A whole white page showing the loader — for routes pushed while data
/// loads.
class AppLoadingScreen extends StatelessWidget {
  final String? message;
  final List<String>? messages;

  const AppLoadingScreen({super.key, this.message, this.messages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AppLoadingView(message: message, messages: messages),
      ),
    );
  }
}

/// Blocking overlay for actions the user must wait on (payments,
/// confirmations). Back is disabled while it's showing.
class AppLoadingOverlay {
  const AppLoadingOverlay._();

  /// Shows the overlay. Close it with [hide] (or `Navigator.pop` on the
  /// root navigator).
  static Future<void> show(
    BuildContext context, {
    String? message,
    String? hint,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => PopScope(
        canPop: false,
        child: Center(child: AppLoadingCard(message: message, hint: hint)),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// White rounded card holding the loader — what [AppLoadingOverlay] shows,
/// and usable directly inside an existing dialog.
class AppLoadingCard extends StatelessWidget {
  final String? message;
  final String? hint;

  const AppLoadingCard({super.key, this.message, this.hint});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.fx(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.fx(260)),
        child: AppLoadingView(
          message: message,
          hint: hint,
          size: context.fx(80),
        ),
      ),
    );
  }
}
