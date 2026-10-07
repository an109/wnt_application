import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../data/model/trisha_models.dart';
import 'trisha_cards.dart';
import 'trisha_style.dart';

class TrishaUserBubble extends StatelessWidget {
  final String text;

  const TrishaUserBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(context.fx(12));
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: context.fx(280)),
        margin: EdgeInsets.only(left: context.fx(48), bottom: context.fx(24)),
        padding: EdgeInsets.symmetric(horizontal: context.fx(16), vertical: context.fx(10)),
        decoration: BoxDecoration(
          color: TrishaStyle.userBubble,
          borderRadius: BorderRadius.only(topLeft: r, bottomLeft: r, bottomRight: r, topRight: Radius.circular(context.fx(2))),
        ),
        child: Text(
          text,
          style: TrishaStyle.body(context, 13, color: Colors.white).copyWith(letterSpacing: 0.5),
        ),
      ),
    );
  }
}

/// A Thrisha reply: "Thrisha ✦" label, text, feedback row, cards, quick replies.
class TrishaReplyView extends StatelessWidget {
  final TrishaMessage message;
  final bool isLatest;
  final bool busy;
  final TrishaCardHandler handler;
  final ValueChanged<String> onQuickReply;
  final ValueChanged<bool> onFeedback;
  final VoidCallback onSave;

  const TrishaReplyView({
    super.key,
    required this.message,
    required this.isLatest,
    required this.busy,
    required this.handler,
    required this.onQuickReply,
    required this.onFeedback,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = context.fx(18);
    return Padding(
      padding: EdgeInsets.only(bottom: context.fx(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TrishaLabel(),
          SizedBox(height: context.fx(8)),
          Text(message.text, style: TrishaStyle.body(context, 13)),
          SizedBox(height: context.fx(10)),
          Row(
            children: [
              _FeedbackIcon(
                icon: message.liked == true ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                size: iconSize,
                onTap: () => onFeedback(true),
              ),
              _FeedbackIcon(
                icon: message.liked == false ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
                size: iconSize,
                onTap: () => onFeedback(false),
              ),
              _FeedbackIcon(
                icon: message.saved ? Icons.bookmark : Icons.bookmark_border,
                size: iconSize,
                onTap: onSave,
              ),
              _FeedbackIcon(
                icon: Icons.copy_rounded,
                size: iconSize,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)));
                },
              ),
            ],
          ),
          for (final card in message.cards) ...[
            SizedBox(height: context.fx(12)),
            TrishaCardView(card: card, active: isLatest && !busy, handler: handler),
          ],
          if (isLatest && !busy && message.quickReplies.isNotEmpty) ...[
            SizedBox(height: context.fx(16)),
            TrishaQuickReplies(options: message.quickReplies, onTap: onQuickReply),
          ],
        ],
      ),
    );
  }
}

class TrishaLabel extends StatelessWidget {
  const TrishaLabel({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thrisha', style: TrishaStyle.display(context, 15, weight: FontWeight.w500).copyWith(letterSpacing: 1)),
          Icon(Icons.auto_awesome, size: context.fx(12), color: TrishaStyle.brandBlue),
        ],
      );
}

class _FeedbackIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _FeedbackIcon({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        radius: size,
        child: Padding(
          padding: EdgeInsets.only(right: context.fx(14)),
          child: Icon(icon, size: size, color: TrishaStyle.text),
        ),
      );
}

/// Quick replies as a tappable list (rows with an arrow).
class TrishaQuickReplies extends StatelessWidget {
  final List<String> options;
  final ValueChanged<String> onTap;

  const TrishaQuickReplies({super.key, required this.options, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.fx(8), vertical: context.fx(4)),
      decoration: BoxDecoration(
        color: TrishaStyle.quickReplyBg,
        borderRadius: BorderRadius.circular(context.fx(12)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: TrishaStyle.quickReplyDivider),
            InkWell(
              onTap: () => onTap(options[i]),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.fx(12), vertical: context.fx(12)),
                child: Row(
                  children: [
                    Expanded(child: Text(options[i], style: TrishaStyle.body(context, 13, height: 1.2))),
                    Icon(Icons.subdirectory_arrow_right_rounded, size: context.fx(18), color: TrishaStyle.userBubble),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Thrisha is thinking…" while a reply is on its way. After a few seconds it
/// explains the wait, since flight searches can take up to a minute.
class TrishaTyping extends StatefulWidget {
  const TrishaTyping({super.key});

  @override
  State<TrishaTyping> createState() => _TrishaTypingState();
}

class _TrishaTypingState extends State<TrishaTyping> with SingleTickerProviderStateMixin {
  late final AnimationController _dots =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  final _started = DateTime.now();

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.fx(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TrishaLabel(),
          SizedBox(height: context.fx(8)),
          AnimatedBuilder(
            animation: _dots,
            builder: (context, _) {
              final count = 1 + (_dots.value * 3).floor();
              final slow = DateTime.now().difference(_started).inSeconds >= 6;
              return Text(
                '${slow ? 'Checking live prices, this can take up to a minute' : 'Thinking'}${'.' * count}',
                style: TrishaStyle.body(context, 13, color: TrishaStyle.hint),
              );
            },
          ),
        ],
      ),
    );
  }
}


/// Inline error with a Retry button (e.g. the server can't be reached).
class TrishaErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TrishaErrorRow({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: context.fx(16)),
        padding: EdgeInsets.fromLTRB(context.fx(12), context.fx(8), context.fx(4), context.fx(8)),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4ED),
          borderRadius: BorderRadius.circular(context.fx(12)),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: context.fx(18), color: TrishaStyle.accent),
            SizedBox(width: context.fx(8)),
            Expanded(child: Text(message, style: TrishaStyle.body(context, 12, height: 1.35))),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: TrishaStyle.body(context, 13, color: TrishaStyle.accent, weight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
