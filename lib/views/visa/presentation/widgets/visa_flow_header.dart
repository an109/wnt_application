import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/visa_theme.dart';

/// Steps of the cost-visa application (Figma "Start now …").
enum VisaFlowStep { dates, photo, passport, detail, checkout }

/// Back arrow, "Visa on …" pill and the five-step progress bar.
class VisaFlowHeader extends StatelessWidget {
  final DateTime visaOn;
  final VisaFlowStep step;
  final VoidCallback onBack;
  /// "Traveller 2 of 3" when several travellers apply together.
  final String? subtitle;

  const VisaFlowHeader({
    super.key,
    required this.visaOn,
    required this.step,
    required this.onBack,
    this.subtitle,
  });

  static const _labels = ['Dates', 'Photo', 'Passport', 'Detail', 'Checkout'];
  static const _icons = [
    Icons.calendar_month,
    Icons.center_focus_strong_outlined,
    Icons.document_scanner_outlined,
    Icons.person_add_alt_1_outlined,
    Icons.verified_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: VisaColors.title), onPressed: onBack),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFCDEBF8), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 12, color: VisaColors.primary),
                    const SizedBox(width: 4),
                    Text('Visa on ${DateFormat('d MMM, hh:mm a').format(visaOn)}',
                        style: visaText(9, weight: FontWeight.w500, color: VisaColors.primary)),
                  ],
                ),
              ),
              const Spacer(),
              if (subtitle != null)
                Text(subtitle!, style: visaText(9, weight: FontWeight.w600, color: VisaColors.text)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 5; i++) ...[
                  _node(i),
                  if (i < 4)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.only(top: 13),
                        color: i < step.index ? VisaColors.primary : const Color(0xFFBFE6F8),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _node(int i) {
    final done = i < step.index;
    final current = i == step.index;
    final filled = done || current;
    return SizedBox(
      width: 46,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? VisaColors.primary : Colors.white,
                  border: Border.all(color: filled ? VisaColors.primary : const Color(0xFFBFE6F8), width: 1.5),
                ),
                child: Icon(_icons[i], size: 15, color: filled ? Colors.white : const Color(0xFF9BD8F3)),
              ),
              if (done)
                Positioned(
                  right: -2,
                  top: -3,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 8, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_labels[i],
              style: visaText(8.5,
                  weight: current ? FontWeight.w600 : FontWeight.w500,
                  color: filled ? VisaColors.primary : const Color(0xFF7CC6EA))),
        ],
      ),
    );
  }
}
