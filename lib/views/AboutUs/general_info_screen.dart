import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../Dashboard/profile/widgets/account_kit.dart';
import 'AboutUs.dart';
import 'legal_document_screen.dart';

/// Figma "General Information": drawer → About WanderNova, Terms & Services,
/// Privacy Policy.
class GeneralInfoScreen extends StatelessWidget {
  const GeneralInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void push(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(8), context.fx(16), 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AccountTopBar(title: 'General Information'),
              SizedBox(height: context.fx(16)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.fx(12), vertical: context.fx(4)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.fx(16)),
                  border: Border.all(color: kAccountLine),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.info_rounded,
                      title: Text.rich(
                        const TextSpan(
                          text: 'About ',
                          children: [
                            TextSpan(text: 'Wander', style: TextStyle(color: AppColors.AppBlue)),
                            TextSpan(text: 'Nova', style: TextStyle(color: kAccountOrange)),
                          ],
                        ),
                        style: _rowStyle(context),
                      ),
                      onTap: () => push(const AboutUsScreen()),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0F1F4)),
                    _InfoRow(
                      icon: FontAwesomeIcons.fileCircleExclamation.data,
                      iconSize: 15,
                      title: Text('Terms & Services', style: _rowStyle(context)),
                      onTap: () => push(const LegalDocumentScreen.terms()),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0F1F4)),
                    _InfoRow(
                      icon: Icons.verified_user_rounded,
                      title: Text('Privacy Policy', style: _rowStyle(context)),
                      onTap: () => push(const LegalDocumentScreen.privacy()),
                    ),
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

TextStyle _rowStyle(BuildContext context) =>
    TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w500, color: kAccountInk);

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Widget title;
  final VoidCallback onTap;

  const _InfoRow({required this.icon, required this.title, required this.onTap, this.iconSize = 18});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.fx(16)),
        child: Row(
          children: [
            SizedBox(
              width: context.fx(20),
              child: Icon(icon, size: context.fx(iconSize), color: const Color(0xFF6B6B6B)),
            ),
            SizedBox(width: context.fx(12)),
            Expanded(child: title),
            Icon(Icons.chevron_right_rounded, size: context.fx(22), color: AppColors.AppBlue),
          ],
        ),
      ),
    );
  }
}
