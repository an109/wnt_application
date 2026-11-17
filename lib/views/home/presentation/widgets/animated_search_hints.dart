import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedSearchHints extends StatefulWidget {
  final List<String> hints;
  final TextStyle? style;
  final Duration interval;
  final Duration animationDuration;

  const AnimatedSearchHints({
    super.key,
    required this.hints,
    this.style,
    this.interval = const Duration(milliseconds: 3000),
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedSearchHints> createState() => _AnimatedSearchHintsState();
}

class _AnimatedSearchHintsState extends State<AnimatedSearchHints>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideOut;
  late Animation<double> _slideIn;
  late Animation<double> _fadeOut;
  late Animation<double> _fadeIn;

  int _currentIndex = 0;
  int _nextIndex = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _slideOut = Tween<double>(begin: 0, end: -1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeIn)),
    );
    _slideIn = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1, curve: Curves.easeOut)),
    );
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1)),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = _nextIndex;
          _nextIndex = (_nextIndex + 1) % widget.hints.length;
        });
        _controller.reset();
      }
    });

    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        TextStyle(color: const Color(0xFF757575), fontSize: 14, fontWeight: FontWeight.w500);

    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final showCurrent = _controller.value <= 0.5;
          final text = showCurrent
              ? widget.hints[_currentIndex]
              : widget.hints[_nextIndex];
          final slide = showCurrent ? _slideOut.value : _slideIn.value;
          final fade = showCurrent ? _fadeOut.value : _fadeIn.value;

          return FractionalTranslation(
            translation: Offset(0, slide),
            child: Opacity(
              opacity: fade,
              child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          );
        },
      ),
    );
  }
}
