import 'package:flutter/material.dart';
import '../../../../../UI_helper/responsive_layout.dart';

class TermsAndConditionsSection extends StatelessWidget {
  final String termsText;

  const TermsAndConditionsSection({
    super.key,
    required this.termsText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: context.gapLarge),
      padding: EdgeInsets.all(context.isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & Conditions:',
            style: TextStyle(
              fontSize: context.responsiveFontSize(18, 16, 15),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
          ),
          SizedBox(height: context.gapMedium),
          _buildTermsContent(context),
        ],
      ),
    );
  }

  Widget _buildTermsContent(BuildContext context) {
    // Parse the terms text and display it
    final lines = termsText.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value.trim();

        if (line.isEmpty) {
          return SizedBox(height: context.gapSmall);
        }

        // Check if it's a bullet point
        if (line.startsWith('•') || line.startsWith('-')) {
          return _buildBulletPoint(context, line.substring(1).trim());
        }

        // Regular text
        return Padding(
          padding: EdgeInsets.only(bottom: context.gapSmall),
          child: Text(
            line,
            style: TextStyle(
              fontSize: context.responsiveFontSize(14, 13, 12),
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.gapSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16, 14, 13),
              color: const Color(0xff005B7F),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: context.gapSmall),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.responsiveFontSize(14, 13, 12),
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}