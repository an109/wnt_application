import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import 'trisha_style.dart';

/// "Ask me anything…" bar. Shows the mic while empty (AI 1) and the orange
/// send button once the user types (AI 2).
class TrishaInputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;
  final VoidCallback onMic;

  const TrishaInputBar({super.key, required this.enabled, required this.onSend, required this.onMic});

  @override
  State<TrishaInputBar> createState() => _TrishaInputBarState();
}

class _TrishaInputBarState extends State<TrishaInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

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
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return; // a reply is on its way; keep the draft
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Soft orange / blue glow rising behind the bar ("Group 41").
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
            context.fx(14) + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(context.fx(24))),
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
                    hintText: 'Ask me anything...',
                    hintStyle: TrishaStyle.body(context, 12, color: TrishaStyle.hint),
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(width: context.fx(8)),
              GestureDetector(
                onTap: _hasText ? _send : widget.onMic,
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
