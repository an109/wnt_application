import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../data/model/trisha_models.dart';
import '../bloc/trisha_chat_state.dart';
import 'trisha_style.dart';

/// The initial chooser shown before any chat starts.
/// Offers: "Chat with Thrisha" (AI) and "Chat with an Expert".
/// If a previous expert chat is active, shows "Continue previous conversation".
class TrishaChooser extends StatelessWidget {
  final String name;
  final TrishaChooserAction? busyCard;
  final String? notice;
  final TrishaExpertChat? previousExpertChat;
  final VoidCallback onChatWithTisha;
  final VoidCallback onChatWithExpert;
  final VoidCallback onContinuePrevious;
  final VoidCallback onStartNew;

  const TrishaChooser({
    super.key,
    required this.name,
    this.busyCard,
    this.notice,
    this.previousExpertChat,
    required this.onChatWithTisha,
    required this.onChatWithExpert,
    required this.onContinuePrevious,
    required this.onStartNew,
  });

  bool get _hasPrevious => previousExpertChat?.active == true;
  bool get _anyBusy => busyCard != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.fx(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.fx(32)),
          // Greeting
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => TrishaStyle.welcomeGradient.createShader(r),
            child: Text(
              'Hi, ${name.toUpperCase()}',
              style: TrishaStyle.welcomeGreeting(context).copyWith(color: Colors.white),
            ),
          ),
          SizedBox(height: context.fx(8)),
          Text(
            'Let Thrisha help you plan flights, hotels, visas and holidays, or connect you with one of our travel experts.',
            style: TrishaStyle.body(context, 13, color: const Color(0xFF64748B)),
          ),
          SizedBox(height: context.fx(24)),

          // Recommended options header
          Row(
            children: [
              Container(
                width: context.fx(32),
                height: context.fx(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(context.fx(8)),
                ),
                child: Icon(Icons.auto_awesome, size: context.fx(16), color: TrishaStyle.brandBlue),
              ),
              SizedBox(width: context.fx(8)),
              Text(
                'Recommended options for you',
                style: TrishaStyle.body(context, 14, color: TrishaStyle.brandBlue, weight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: context.fx(16)),

          // Continue previous expert conversation
          if (_hasPrevious) ...[
            _ChooserCard(
              icon: Icons.headset_mic_rounded,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: TrishaStyle.brandBlue,
              title: 'Continue previous conversation',
              subtitle: 'Your chat with our expert is still open · ${previousExpertChat!.ticketNumber}',
              borderColor: TrishaStyle.brandBlue.withValues(alpha: 0.3),
              bgColor: const Color(0xFFF0F7FF),
              loading: busyCard == TrishaChooserAction.continuePrevious,
              disabled: _anyBusy && busyCard != TrishaChooserAction.continuePrevious,
              onTap: onContinuePrevious,
            ),
            SizedBox(height: context.fx(12)),
          ],

          // Chat with Tisha (or "Start a new chat" if previous exists)
          _ChooserCard(
            icon: Icons.chat_bubble_outline_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: TrishaStyle.brandBlue,
            title: _hasPrevious ? 'Start a new chat' : 'Chat with Thrisha',
            subtitle: _hasPrevious
                ? 'This will close your previous conversation'
                : 'Search flights and hotels, ask anything',
            loading: _hasPrevious
                ? busyCard == TrishaChooserAction.startNew
                : busyCard == TrishaChooserAction.tisha,
            disabled: _anyBusy &&
                (_hasPrevious
                    ? busyCard != TrishaChooserAction.startNew
                    : busyCard != TrishaChooserAction.tisha),
            onTap: _hasPrevious ? onStartNew : onChatWithTisha,
          ),
          SizedBox(height: context.fx(12)),

          // Chat with an Expert (hidden if previous is open)
          if (!_hasPrevious)
            _ChooserCard(
              icon: Icons.headset_mic_rounded,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: TrishaStyle.brandBlue,
              title: 'Chat with an Expert',
              subtitle: 'Get instant assistance from our travel team',
              loading: busyCard == TrishaChooserAction.expert,
              disabled: _anyBusy && busyCard != TrishaChooserAction.expert,
              onTap: onChatWithExpert,
            ),

          if (notice != null) ...[
            SizedBox(height: context.fx(16)),
            Center(
              child: Text(
                notice!,
                textAlign: TextAlign.center,
                style: TrishaStyle.body(context, 12, color: const Color(0xFFB45309)),
              ),
            ),
          ],

          const Spacer(),
        ],
      ),
    );
  }
}

class _ChooserCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? borderColor;
  final Color? bgColor;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const _ChooserCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.borderColor,
    this.bgColor,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return _ShimmerCard(context: context);

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: EdgeInsets.all(context.fx(14)),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            borderRadius: BorderRadius.circular(context.fx(16)),
            border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
            boxShadow: TrishaStyle.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: context.fx(44),
                height: context.fx(44),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: context.fx(22), color: iconColor),
              ),
              SizedBox(width: context.fx(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TrishaStyle.body(context, 14, color: TrishaStyle.brandBlue, weight: FontWeight.w600)),
                    SizedBox(height: context.fx(2)),
                    Text(subtitle, style: TrishaStyle.body(context, 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton that replaces a card while it's loading.
class _ShimmerCard extends StatelessWidget {
  final BuildContext context;
  const _ShimmerCard({required this.context});

  @override
  Widget build(BuildContext outerContext) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EDF4),
      highlightColor: const Color(0xFFF5F8FC),
      child: Container(
        padding: EdgeInsets.all(context.fx(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.fx(16)),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: context.fx(44),
              height: context.fx(44),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            SizedBox(width: context.fx(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.fx(140),
                    height: context.fx(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.fx(4))),
                  ),
                  SizedBox(height: context.fx(6)),
                  Container(
                    width: context.fx(200),
                    height: context.fx(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.fx(4))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
