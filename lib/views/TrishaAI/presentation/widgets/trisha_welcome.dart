import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import 'trisha_style.dart';

/// "AI 1 / AI 2" frames: greeting, the orb and three starter cards.
class TrishaWelcome extends StatelessWidget {
  final String name;
  final ValueChanged<String> onSuggestion;

  /// Shown above the cards when the chat couldn't be opened.
  final Widget? notice;

  const TrishaWelcome({super.key, required this.name, required this.onSuggestion, this.notice});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.fx(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.fx(24)),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [TrishaStyle.brandBlue, TrishaStyle.brandBlueLight],
            ).createShader(r),
            child: Text(
              'Hi, ${name.toUpperCase()}',
              style: TrishaStyle.display(context, 26).copyWith(color: Colors.white),
            ),
          ),
          SizedBox(height: context.fx(4)),
          SizedBox(
            width: context.fx(279),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'I’m Thrisha', style: TextStyle(color: TrishaStyle.accent)),
                  const TextSpan(text: ' - your personal travel assistant. Let’s plan your next trip together.'),
                ],
              ),
              style: TrishaStyle.body(context, 12, height: 1.5).copyWith(letterSpacing: 0.3),
            ),
          ),
          // Figma: orb centred ~170 px below the greeting, cards ~130 px above
          // the input; flex keeps those proportions on shorter screens.
          Expanded(flex: 3, child: Center(child: TrishaOrb(size: context.fx(144), glow: true))),
          if (notice != null) notice!,
          Row(
            children: [
              _StarterCard(
                asset: TrishaStyle.cardFlightAsset,
                fallback: Icons.flight_takeoff_rounded,
                label: 'Search for your next holiday destination',
                onTap: () => onSuggestion('Book a flight'),
              ),
              SizedBox(width: context.fx(16)),
              _StarterCard(
                asset: TrishaStyle.cardStayAsset,
                fallback: Icons.hotel_rounded,
                label: 'Find a stay that matches your vibe',
                onTap: () => onSuggestion('Find hotels'),
              ),
              SizedBox(width: context.fx(16)),
              _StarterCard(
                asset: TrishaStyle.cardHolidayAsset,
                fallback: Icons.map_rounded,
                label: 'Discover your next holiday destination',
                onTap: () => onSuggestion('Plan a holiday package'),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  final String asset;
  final IconData fallback;
  final String label;
  final VoidCallback onTap;

  const _StarterCard({required this.asset, required this.fallback, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: context.fx(88),
          padding: EdgeInsets.fromLTRB(context.fx(9.5), context.fx(12), context.fx(9.5), 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.fx(8)),
            boxShadow: TrishaStyle.softShadow,
          ),
          child: Column(
            children: [
              TrishaAssetImage(asset: asset, size: context.fx(32), fallback: fallback),
              SizedBox(height: context.fx(4)),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TrishaStyle.body(context, 10, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
