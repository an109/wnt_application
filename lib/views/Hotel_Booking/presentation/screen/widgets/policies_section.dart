import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../domain/entities/hotel_booking_entity.dart';

class PoliciesSection extends StatefulWidget {
  final List<CancelPolicyEntity> cancelPolicies;
  final List<String> rateConditions;

  const PoliciesSection({
    super.key,
    required this.cancelPolicies,
    required this.rateConditions,
  });

  @override
  State<PoliciesSection> createState() => _PoliciesSectionState();
}

class _PoliciesSectionState extends State<PoliciesSection> {
  bool _isExpanded = false;
  static const int _previewItemCount = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.h(10),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.cancelPolicies.isNotEmpty) ...[
              _buildCancellationPolicies(context),
              SizedBox(height: context.h(16)),
            ],
            if (widget.rateConditions.isNotEmpty) ...[
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
            fontSize: context.fs(18),
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: context.h(12)),
        ...widget.cancelPolicies.map((policy) => Container(
          padding: EdgeInsets.all(context.w(12)),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(context.r(8)),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'From ${policy.fromDate} — ${policy.chargeType}',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Text(
                'Charge: ${policy.cancellationCharge}',
                style: TextStyle(
                  fontSize: context.fs(13),
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

    for (var condition in widget.rateConditions) {
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

    // Collect all condition widgets
    final List<Widget> conditionWidgets = [];

    if (checkInTimes.isNotEmpty) {
      conditionWidgets.add(_buildSectionTitle(context, 'Check-in Time'));
      conditionWidgets.addAll(checkInTimes.map((time) => _buildConditionItem(context, time)));
      conditionWidgets.add(SizedBox(height: context.h(12)));
    }

    if (checkOutTimes.isNotEmpty) {
      conditionWidgets.add(_buildSectionTitle(context, 'Check-out Time'));
      conditionWidgets.addAll(checkOutTimes.map((time) => _buildConditionItem(context, time)));
      conditionWidgets.add(SizedBox(height: context.h(12)));
    }

    if (instructions.isNotEmpty) {
      conditionWidgets.add(_buildSectionTitle(context, 'Check-in Instructions'));
      conditionWidgets.addAll(instructions.map((instruction) => _buildHtmlContent(context, instruction)));
      conditionWidgets.add(SizedBox(height: context.h(12)));
    }

    if (specialInstructions.isNotEmpty) {
      conditionWidgets.add(_buildSectionTitle(context, 'Special Instructions'));
      conditionWidgets.addAll(specialInstructions.map((instruction) => _buildHtmlContent(context, instruction)));
      conditionWidgets.add(SizedBox(height: context.h(12)));
    }

    if (mandatoryFees.isNotEmpty) {
      conditionWidgets.add(_buildSectionTitle(context, 'Mandatory Fees'));
      conditionWidgets.addAll(mandatoryFees.map((fee) => _buildHtmlContent(context, fee)));
      conditionWidgets.add(SizedBox(height: context.h(12)));
    }

    if (optionalFees.isNotEmpty) {
      conditionWidgets.add(_buildSectionTitle(context, 'Optional Fees'));
      conditionWidgets.addAll(optionalFees.map((fee) => _buildHtmlContent(context, fee)));
      conditionWidgets.add(SizedBox(height: context.h(12)));
    }

    if (cardsAccepted.isNotEmpty) {
      conditionWidgets.add(_buildSectionTitle(context, 'Cards Accepted'));
      conditionWidgets.addAll(cardsAccepted.map((card) => _buildConditionItem(context, card)));
      conditionWidgets.add(SizedBox(height: context.h(12)));
    }

    if (otherConditions.isNotEmpty) {
      conditionWidgets.add(_buildSectionTitle(context, 'Additional Information'));
      conditionWidgets.addAll(otherConditions.map((condition) => _buildHtmlContent(context, condition)));
    }

    // Get visible items based on expanded state
    final visibleWidgets = _isExpanded
        ? conditionWidgets
        : conditionWidgets.take(_previewItemCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RATE CONDITIONS',
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: context.h(12)),
        ...visibleWidgets,

        // Add Read More / Read Less button if there are more items
        if (conditionWidgets.length > _previewItemCount) ...[
          SizedBox(height: context.h(12)),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isExpanded ? 'Read Less' : 'Read More',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(width: context.w(8)),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: context.w(20),
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
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
      padding: EdgeInsets.only(bottom: context.h(8), top: context.h(8)),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.fs(14),
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildConditionItem(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(13),
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
        padding: EdgeInsets.only(bottom: context.h(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.h(4), left: context.w(8)),
              child: Text(
                item.trim(),
                style: TextStyle(
                  fontSize: context.fs(13),
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