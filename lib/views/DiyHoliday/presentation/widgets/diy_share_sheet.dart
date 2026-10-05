import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import 'diy_common.dart';
import 'diy_trip_day_card.dart';

/// "Share Results" — Figma `share flight`: the message straight into
/// WhatsApp, X or Telegram, and the phone's own share sheet for apps that
/// take no text by link (Facebook, Instagram) or anything else.
///
/// The design's "Recent people" row needs contacts the app does not keep,
/// so it is left out rather than filled with invented names.
Future<void> showDiyShareSheet(BuildContext context, {required String text}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20))),
    ),
    builder: (_) => _ShareSheet(text: text),
  );
}

class _ShareSheet extends StatelessWidget {
  final String text;

  const _ShareSheet({required this.text});

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) await Share.share(text);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _system(BuildContext context) async {
    await Share.share(text);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final encoded = Uri.encodeComponent(text);
    final iconSize = context.w(20);
    final targets = <(String, Widget, Color, VoidCallback)>[
      (
        'WhatsApp',
        FaIcon(FontAwesomeIcons.whatsapp, size: iconSize, color: Colors.white),
        const Color(0xFF25D366),
        () => _open(context, Uri.parse('https://wa.me/?text=$encoded')),
      ),
      (
        'Facebook',
        FaIcon(FontAwesomeIcons.facebookF, size: iconSize, color: Colors.white),
        const Color(0xFF1877F2),
        () => _system(context),
      ),
      (
        'X',
        FaIcon(FontAwesomeIcons.xTwitter, size: iconSize, color: Colors.white),
        Colors.black,
        () => _open(
          context,
          Uri.parse('https://twitter.com/intent/tweet?text=$encoded'),
        ),
      ),
      (
        'Instagram',
        FaIcon(FontAwesomeIcons.instagram, size: iconSize, color: Colors.white),
        const Color(0xFFE1306C),
        () => _system(context),
      ),
      (
        'Telegram',
        FaIcon(FontAwesomeIcons.telegram, size: iconSize, color: Colors.white),
        const Color(0xFF229ED9),
        () => _open(context, Uri.parse('https://t.me/share/url?text=$encoded')),
      ),
      (
        'More',
        Icon(Icons.more_horiz_rounded, size: iconSize, color: Colors.white),
        DiyTripStyle.grey,
        () => _system(context),
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.w(20),
          context.h(12),
          context.w(20),
          context.h(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: context.w(48),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DDE4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: context.h(18)),
            Text(
              'Share Results',
              style: TextStyle(
                fontSize: context.fs(17),
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: context.h(18)),
            Text(
              'SOCIAL MEDIA',
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w600,
                color: DiyTripStyle.grey,
              ),
            ),
            SizedBox(height: context.h(12)),
            Wrap(
              spacing: context.w(18),
              runSpacing: context.h(14),
              children: [
                for (final (label, icon, color, onTap) in targets)
                  GestureDetector(
                    onTap: onTap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: context.w(44),
                          height: context.w(44),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: icon,
                        ),
                        SizedBox(height: context.h(6)),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: context.fs(10),
                            color: DiyTokens.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
