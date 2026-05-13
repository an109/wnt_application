import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../domain/entities/hotel_booking_entity.dart';

class PoliciesSection extends StatelessWidget {
  final List<CancelPolicyEntity> cancelPolicies;
  final List<String> rateConditions;

  const PoliciesSection({
    super.key,
    required this.cancelPolicies,
    required this.rateConditions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cancelPolicies.isNotEmpty) ...[
              _buildCancellationPolicies(context),
              const SizedBox(height: 16),
            ],
            if (rateConditions.isNotEmpty) ...[
              _buildRateConditions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationPolicies(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CANCELLATION POLICIES',
          style: TextStyle(
            fontSize: context.titleSmall,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...cancelPolicies.map((policy) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'From ${policy.fromDate} — ${policy.chargeType}',
                  style: TextStyle(
                    fontSize: context.sp(13),
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Text(
                'Charge: ${policy.cancellationCharge}',
                style: TextStyle(
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRateConditions(BuildContext context) {
    // Parse and categorize rate conditions
    final checkInTimes = <String>[];
    final checkOutTimes = <String>[];
    final instructions = <String>[];
    final specialInstructions = <String>[];
    final mandatoryFees = <String>[];
    final optionalFees = <String>[];
    final cardsAccepted = <String>[];
    final otherConditions = <String>[];

    for (var condition in rateConditions) {
      final lowerCondition = condition.toLowerCase();

      if (lowerCondition.contains('check-in time') || lowerCondition.contains('checkin time')) {
        checkInTimes.add(_cleanHtml(condition));
      } else if (lowerCondition.contains('check-out time') || lowerCondition.contains('checkout time')) {
        checkOutTimes.add(_cleanHtml(condition));
      } else if (lowerCondition.contains('check-in instructions') || lowerCondition.contains('checkin instructions')) {
        instructions.add(_cleanHtml(condition));
      } else if (lowerCondition.contains('special instructions')) {
        specialInstructions.add(_cleanHtml(condition));
      } else if (lowerCondition.contains('mandatory fees')) {
        mandatoryFees.add(_cleanHtml(condition));
      } else if (lowerCondition.contains('optional fees')) {
        optionalFees.add(_cleanHtml(condition));
      } else if (lowerCondition.contains('cards accepted')) {
        cardsAccepted.add(_cleanHtml(condition));
      } else if (!lowerCondition.contains('early check out')) {
        otherConditions.add(_cleanHtml(condition));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RATE CONDITIONS',
          style: TextStyle(
            fontSize: context.titleSmall,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        if (checkInTimes.isNotEmpty) ...[
          _buildSectionTitle(context, 'Check-in Time'),
          ...checkInTimes.map((time) => _buildConditionItem(context, time)),
          const SizedBox(height: 12),
        ],

        if (checkOutTimes.isNotEmpty) ...[
          _buildSectionTitle(context, 'Check-out Time'),
          ...checkOutTimes.map((time) => _buildConditionItem(context, time)),
          const SizedBox(height: 12),
        ],

        if (instructions.isNotEmpty) ...[
          _buildSectionTitle(context, 'Check-in Instructions'),
          ...instructions.map((instruction) => _buildHtmlContent(context, instruction)),
          const SizedBox(height: 12),
        ],

        if (specialInstructions.isNotEmpty) ...[
          _buildSectionTitle(context, 'Special Instructions'),
          ...specialInstructions.map((instruction) => _buildHtmlContent(context, instruction)),
          const SizedBox(height: 12),
        ],

        if (mandatoryFees.isNotEmpty) ...[
          _buildSectionTitle(context, 'Mandatory Fees'),
          ...mandatoryFees.map((fee) => _buildHtmlContent(context, fee)),
          const SizedBox(height: 12),
        ],

        if (optionalFees.isNotEmpty) ...[
          _buildSectionTitle(context, 'Optional Fees'),
          ...optionalFees.map((fee) => _buildHtmlContent(context, fee)),
          const SizedBox(height: 12),
        ],

        if (cardsAccepted.isNotEmpty) ...[
          _buildSectionTitle(context, 'Cards Accepted'),
          ...cardsAccepted.map((card) => _buildConditionItem(context, card)),
          const SizedBox(height: 12),
        ],

        if (otherConditions.isNotEmpty) ...[
          _buildSectionTitle(context, 'Additional Information'),
          ...otherConditions.map((condition) => _buildHtmlContent(context, condition)),
        ],
      ],
    );
  }

  String _cleanHtml(String text) {
    // Remove HTML tags
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.sp(14),
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildConditionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.sp(13),
          color: Colors.grey[600],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildHtmlContent(BuildContext context, String htmlContent) {
    final cleanedText = _cleanHtml(htmlContent);

    // Check if content contains list items
    if (cleanedText.contains('<li>') || cleanedText.contains('</li>')) {
      // Split by list items
      final items = cleanedText
          .replaceAll(RegExp(r'<li>'), '\n• ')
          .replaceAll(RegExp(r'</li>'), '')
          .split('\n')
          .where((item) => item.trim().isNotEmpty)
          .toList();

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8),
              child: Text(
                item.trim(),
                style: TextStyle(
                  fontSize: context.sp(13),
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return _buildConditionItem(context, cleanedText);
  }
}