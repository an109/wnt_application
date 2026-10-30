import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../UI_helper/responsive_layout.dart';
import 'trisha_style.dart';

/// "Ask me anything…" bar with voice typing support.
class TrishaInputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;
  final String? hintText;

  const TrishaInputBar({super.key, required this.enabled, required this.onSend, this.hintText});

  @override
  State<TrishaInputBar> createState() => _TrishaInputBarState();
}

class _TrishaInputBarState extends State<TrishaInputBar> {
  final _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _hasText = false;
  bool _isListening = false;
  bool _speechReady = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    bool available = _speechReady;
    if (!available) {
      try {
        available = await _speech.initialize(
          onStatus: (status) {
            if ((status == 'done' || status == 'notListening') && mounted) {
              setState(() => _isListening = false);
            }
          },
          onError: (_) {
            if (mounted) setState(() => _isListening = false);
          },
        );
      } catch (_) {
        available = false;
      }
    }
    _speechReady = available;

    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input is unavailable. Please allow microphone access.'),
        ),
      );
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(partialResults: true),
      onResult: (result) {
        if (!mounted) return;
        _controller.value = TextEditingValue(
          text: result.recognizedWords,
          selection: TextSelection.collapsed(offset: result.recognizedWords.length),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: -context.fx(40),
          height: context.fx(110),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Row(
              children: [
                Expanded(flex: 3, child: _blob(const Color(0x40F97316))),
                Expanded(flex: 2, child: _blob(const Color(0x404A9FE8))),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            context.fx(16),
            context.fx(14),
            context.fx(16),
            context.fx(45) + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: TrishaStyle.body(context, 13),
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening…' : (widget.hintText ?? 'Ask me anything...'),
                    hintStyle: TrishaStyle.body(context, 12, color: _isListening ? TrishaStyle.accent : TrishaStyle.hint),
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(width: context.fx(8)),
              GestureDetector(
                onTap: _hasText ? _send : _toggleListening,
                child: _hasText
                    ? Container(
                        width: context.fx(24),
                        height: context.fx(24),
                        decoration: BoxDecoration(
                          color: widget.enabled ? TrishaStyle.accent : TrishaStyle.hint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_upward_rounded, size: context.fx(16), color: Colors.white),
                      )
                    : _isListening
                        ? _ListeningMic(size: context.fx(24))
                        : TrishaMicIcon(size: context.fx(24)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _blob(Color color) => DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(200)),
      );
}

class _ListeningMic extends StatefulWidget {
  final double size;
  const _ListeningMic({required this.size});

  @override
  State<_ListeningMic> createState() => _ListeningMicState();
}

class _ListeningMicState extends State<_ListeningMic> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: TrishaStyle.accent.withOpacity(0.15 + _anim.value * 0.2),
        ),
        child: child,
      ),
      child: Icon(Icons.mic, size: widget.size * 0.65, color: TrishaStyle.accent),
    );
  }
}
