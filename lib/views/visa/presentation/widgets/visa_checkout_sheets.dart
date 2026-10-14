import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import 'visa_calendar.dart';

/// Travel cover offered as a checkout add-on (Figma "Insurance Cover…").
class VisaInsurancePlan {
  VisaInsurancePlan._();

  static const title = '\$50,000 Travel Coverage';
  static const provider = 'Care Health Insurance';
  static const perDayInr = 72.0;
  static const minDays = 1;
  static const maxDays = 180;
  static const benefits = [
    ('Sum Insured', '\$50,000'),
    ('Repatriation of Mortal Remains', '\$7,000'),
    ('Medical Evacuation', '\$50,000'),
    ('Baggage Loss & Delay', '\$1,000'),
    ('Trip Cancellation / Interruption', '\$3,000'),
  ];
}

final _cardDate = DateFormat('dd MMM, yyyy');

/// Insurance details sheet; pops the chosen number of days.
class VisaInsuranceSheet extends StatefulWidget {
  final DateTime from;
  final int initialDays;
  const VisaInsuranceSheet({super.key, required this.from, required this.initialDays});

  @override
  State<VisaInsuranceSheet> createState() => _VisaInsuranceSheetState();
}

class _VisaInsuranceSheetState extends State<VisaInsuranceSheet> {
  late int _days = widget.initialDays.clamp(VisaInsurancePlan.minDays, VisaInsurancePlan.maxDays);

  @override
  Widget build(BuildContext context) {
    final till = widget.from.add(Duration(days: _days - 1));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: VisaColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.flight, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              Text(VisaInsurancePlan.title,
                  textAlign: TextAlign.center, style: visaText(16, weight: FontWeight.w600, color: VisaColors.title)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(colors: [Color(0xFFE6F6FD), Color(0xFFBFE6F8)]),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.health_and_safety, size: 16, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Text('Provided by ${VisaInsurancePlan.provider}', style: visaText(10, color: VisaColors.title)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _date('VALID FROM', widget.from, CrossAxisAlignment.start),
                        const Expanded(child: _PlaneLine()),
                        _date('VALID TILL', till, CrossAxisAlignment.end),
                      ],
                    ),
                    const Divider(height: 20, color: VisaColors.divider),
                    Row(
                      children: [
                        Text('Trip Duration', style: visaText(10, color: VisaColors.text)),
                        const Spacer(),
                        _Stepper(
                          label: '$_days Day${_days == 1 ? '' : 's'}',
                          onMinus: _days > VisaInsurancePlan.minDays ? () => setState(() => _days--) : null,
                          onPlus: _days < VisaInsurancePlan.maxDays ? () => setState(() => _days++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < VisaInsurancePlan.benefits.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: i.isEven ? VisaColors.greenSoft : VisaColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 13, color: VisaColors.text),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(VisaInsurancePlan.benefits[i].$1,
                              style: visaText(9.5, color: VisaColors.title))),
                      Text(VisaInsurancePlan.benefits[i].$2,
                          style: visaText(10, weight: FontWeight.w700, color: VisaColors.green)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: VisaPrimaryButton(
            label: 'Add insurance for $_days day${_days == 1 ? '' : 's'}',
            onPressed: () => Navigator.pop(context, _days),
          ),
        ),
      ],
    );
  }

  Widget _date(String label, DateTime d, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: visaText(8, weight: FontWeight.w500, color: VisaColors.text)),
        const SizedBox(height: 2),
        Text(_cardDate.format(d), style: visaText(13, weight: FontWeight.w700, color: VisaColors.title)),
      ],
    );
  }
}

/// Visa validity sheet (Figma "Visa Validity"); pops the chosen start date.
class VisaValiditySheet extends StatefulWidget {
  final DateTime start;
  final int days;
  const VisaValiditySheet({super.key, required this.start, required this.days});

  @override
  State<VisaValiditySheet> createState() => _VisaValiditySheetState();
}

class _VisaValiditySheetState extends State<VisaValiditySheet> {
  late DateTime _start = widget.start;
  late DateTime _month = DateTime(widget.start.year, widget.start.month);

  @override
  Widget build(BuildContext context) {
    final end = _start.add(Duration(days: widget.days - 1));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                Text('Visa Validity', style: visaText(16, weight: FontWeight.w600, color: VisaColors.title)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      _date('VALID FROM', _start, CrossAxisAlignment.start),
                      Expanded(child: _PlaneLine(label: '${widget.days} Days')),
                      _date('VALID TILL', end, CrossAxisAlignment.end),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                VisaMonthSwitcher(
                  month: _month,
                  centered: false,
                  firstMonth: DateTime.now(),
                  onChanged: (m) => setState(() => _month = m),
                ),
                VisaMonthGrid(
                  month: _month,
                  start: _start,
                  end: end,
                  firstDate: DateTime.now(),
                  onTap: (d) => setState(() => _start = d),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: VisaPrimaryButton(label: 'Confirm', onPressed: () => Navigator.pop(context, _start)),
        ),
      ],
    );
  }

  Widget _date(String label, DateTime d, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: visaText(8, weight: FontWeight.w500, color: VisaColors.text)),
        const SizedBox(height: 2),
        Text(visaDateFormat.format(d), style: visaText(13, weight: FontWeight.w700, color: VisaColors.title)),
      ],
    );
  }
}

class _PlaneLine extends StatelessWidget {
  final String? label;
  const _PlaneLine({this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: VisaColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(label!, style: visaText(7, weight: FontWeight.w600, color: VisaColors.text)),
            ),
          Row(
            children: [
              const Expanded(child: _Dashes()),
              Transform.rotate(angle: 1.5708, child: const Icon(Icons.flight, size: 14, color: VisaColors.primary)),
              const Expanded(child: _Dashes()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dashes extends StatelessWidget {
  const _Dashes();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          (c.maxWidth / 5).floor().clamp(0, 200),
          (_) => Container(width: 2, height: 1, color: VisaColors.stroke),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  const _Stepper({required this.label, this.onMinus, this.onPlus});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback? onTap, Color bg) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: onTap == null ? VisaColors.surface : bg, shape: BoxShape.circle),
            child: Icon(icon, size: 12, color: onTap == null ? VisaColors.stroke : Colors.white),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, onMinus, VisaColors.text),
          SizedBox(
            width: 56,
            child: Text(label,
                textAlign: TextAlign.center, style: visaText(10, weight: FontWeight.w700, color: VisaColors.title)),
          ),
          btn(Icons.add, onPlus, VisaColors.primary),
        ],
      ),
    );
  }
}

/// Days a visa stays valid, from text such as "60 days", "1 Year",
/// "Upto 10 Years" or "3 months- 1 year" (smallest figure wins).
int visaValidityDays(String validity, {int fallback = 30}) {
  final m = RegExp(r'(\d+)\s*(day|week|month|year)', caseSensitive: false).firstMatch(validity);
  if (m == null) return fallback;
  final n = int.parse(m.group(1)!);
  return switch (m.group(2)!.toLowerCase()) {
    'week' => n * 7,
    'month' => n * 30,
    'year' => n * 365,
    _ => n,
  };
}
