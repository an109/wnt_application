import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import 'trisha_style.dart';

/// Banner shown at the top of expert chat mode, with the ticket reference.
class TrishaExpertBanner extends StatelessWidget {
  final String ticketNumber;

  const TrishaExpertBanner({super.key, required this.ticketNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.fx(16), vertical: context.fx(4)),
      padding: EdgeInsets.symmetric(horizontal: context.fx(12), vertical: context.fx(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(context.fx(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.headset_mic_rounded, size: context.fx(16), color: TrishaStyle.brandBlue),
          SizedBox(width: context.fx(8)),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'A travel expert is joining — your reference is '),
                  TextSpan(
                    text: ticketNumber,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: '. Everything you told Thrisha is already with them.'),
                ],
              ),
              style: TrishaStyle.body(context, 12, color: const Color(0xFF1E3A5F)),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Talk to a travel expert instead" link shown at the bottom of AI chat.
class TrishaExpertLink extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const TrishaExpertLink({super.key, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.fx(8)),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset_mic_rounded, size: context.fx(14), color: const Color(0xFF64748B)),
            SizedBox(width: context.fx(6)),
            Text(
              'Talk to a travel expert instead',
              style: TrishaStyle.body(context, 12, color: const Color(0xFF64748B), weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
