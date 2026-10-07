import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../Dashboard/profile/widgets/account_kit.dart';
import 'legal_content.dart';

// Figma "term of Services" / "Privacy Policy" frames (412px wide): summary
// card on top, then one numbered card per section.

const Color _kCardLine = Color(0xFFE5E7EB);
const Color _kBody = Color(0xFF4B5563);

/// Number-badge accents, cycled per section (blue, amber, indigo, green,
/// orange, purple, red, cyan — in Figma order).
const List<Color> _kAccents = [
  Color(0xFF3B82F6),
  Color(0xFFD97706),
  Color(0xFF6366F1),
  Color(0xFF10B981),
  Color(0xFFF97316),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFF06B6D4),
];

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalDocumentScreen({super.key, required this.document});

  const LegalDocumentScreen.terms({super.key}) : document = kTermsOfService;

  const LegalDocumentScreen.privacy({super.key}) : document = kPrivacyPolicy;

  void _open(BuildContext context, LegalLink link) {
    final target = link == LegalLink.terms ? kTermsOfService : kPrivacyPolicy;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LegalDocumentScreen(document: target)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = document.sections;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(8), context.fx(16), 0),
              child: AccountTopBar(title: document.title),
            ),
            Expanded(
              child: ListView.separated(
                physics: context.scrollPhysics,
                padding: EdgeInsets.fromLTRB(
                  context.fx(16),
                  context.fx(12),
                  context.fx(16),
                  context.fx(24) + MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: sections.length + 1,
                separatorBuilder: (_, __) => SizedBox(height: context.fx(12)),
                itemBuilder: (context, i) {
                  if (i == 0) return _SummaryCard(document: document);
                  return _SectionCard(
                    number: i,
                    section: sections[i - 1],
                    accent: _kAccents[(i - 1) % _kAccents.length],
                    onLink: (link) => _open(context, link),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(context.fx(12)),
  border: Border.all(color: _kCardLine),
  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
);

class _SummaryCard extends StatelessWidget {
  final LegalDocument document;

  const _SummaryCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(14)),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.fx(8),
            runSpacing: context.fx(6),
            children: [
              _Chip(
                color: const Color(0xFF16A34A),
                background: const Color(0xFFF0FDF4),
                leading: Container(
                  width: context.fx(6),
                  height: context.fx(6),
                  decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                ),
                label: 'Active Version',
              ),
              _Chip(
                color: const Color(0xFFEA580C),
                background: const Color(0xFFFFF7ED),
                leading: Icon(Icons.schedule_rounded, size: context.fx(12), color: const Color(0xFFEA580C)),
                label: '${document.readMinutes} min read',
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.fx(12)),
            child: const Divider(height: 1, color: _kCardLine),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.fx(12)),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F0FD),
              borderRadius: BorderRadius.circular(context.fx(10)),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_rounded, size: context.fx(18), color: const Color(0xFF2563EB)),
                SizedBox(width: context.fx(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUICK SUMMARY',
                        style: TextStyle(
                          fontSize: context.ffs(12),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(height: context.fx(4)),
                      Text(
                        document.summary,
                        style: TextStyle(
                          fontSize: context.ffs(12.5),
                          height: 1.45,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color color;
  final Color background;
  final Widget leading;
  final String label;

  const _Chip({required this.color, required this.background, required this.leading, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.fx(8), vertical: context.fx(3)),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.fx(20)),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          SizedBox(width: context.fx(5)),
          Text(
            label,
            style: TextStyle(fontSize: context.ffs(11), fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final int number;
  final LegalSection section;
  final Color accent;
  final ValueChanged<LegalLink> onLink;

  const _SectionCard({
    required this.number,
    required this.section,
    required this.accent,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(fontSize: context.ffs(13), height: 1.5, color: _kBody);
    final gap = SizedBox(height: context.fx(10));
    return Container(
      padding: EdgeInsets.all(context.fx(14)),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.fx(24),
                height: context.fx(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(context.fx(6)),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(fontSize: context.ffs(12), fontWeight: FontWeight.w700, color: accent),
                ),
              ),
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: context.fx(2)),
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: context.ffs(15),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: kAccountInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
          for (final p in section.paragraphs) ...[gap, Text(p, style: body)],
          if (section.quote != null) ...[
            gap,
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(left: context.fx(12)),
              padding: EdgeInsets.all(context.fx(10)),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(context.fx(8)),
                border: Border.all(color: _kCardLine),
              ),
              child: Text(
                '"${section.quote}"',
                style: body.copyWith(fontStyle: FontStyle.italic, color: const Color(0xFF374151)),
              ),
            ),
          ],
          if (section.itemsHeading != null) ...[
            gap,
            Text(
              section.itemsHeading!,
              style: TextStyle(fontSize: context.ffs(12.5), fontWeight: FontWeight.w600, color: kAccountInk),
            ),
          ],
          if (section.items.isNotEmpty) ...[
            SizedBox(height: context.fx(8)),
            for (final item in section.items)
              Padding(
                padding: EdgeInsets.only(bottom: context.fx(8)),
                child: _ItemTile(item: item, accent: accent),
              ),
          ],
          if (section.note != null) ...[
            gap,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: context.fx(1)),
                  child: Icon(Icons.info_outline_rounded, size: context.fx(14), color: const Color(0xFF4F46E5)),
                ),
                SizedBox(width: context.fx(6)),
                Expanded(
                  child: Text(
                    section.note!,
                    style: TextStyle(fontSize: context.ffs(12), height: 1.45, color: const Color(0xFF4338CA)),
                  ),
                ),
              ],
            ),
          ],
          if (section.link != null) ...[
            gap,
            Semantics(
              button: true,
              child: InkWell(
                onTap: () => onLink(section.link!),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.fx(4)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        section.link == LegalLink.terms ? 'View Terms & Services' : 'View Privacy Policy',
                        style: TextStyle(
                          fontSize: context.ffs(13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.AppBlue,
                        ),
                      ),
                      SizedBox(width: context.fx(4)),
                      Icon(Icons.arrow_forward_rounded, size: context.fx(14), color: AppColors.AppBlue),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final LegalItem item;
  final Color accent;

  const _ItemTile({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final text = TextStyle(fontSize: context.ffs(12.5), height: 1.45, color: _kBody);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(left: context.fx(12)),
      padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(9)),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.fx(8)),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.fx(1)),
            child: Icon(item.icon, size: context.fx(15), color: accent),
          ),
          SizedBox(width: context.fx(8)),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (item.label != null)
                    TextSpan(
                      text: '${item.label}: ',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: kAccountInk),
                    ),
                  TextSpan(text: item.text),
                ],
              ),
              style: text,
            ),
          ),
        ],
      ),
    );
  }
}
