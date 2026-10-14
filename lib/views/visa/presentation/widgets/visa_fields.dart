import 'package:flutter/material.dart';

import '../utils/visa_theme.dart';

/// Outlined form field with the small upper-case label of the visa designs.
/// [locked] fields were read from the passport and cannot be edited.
class VisaFieldBox extends StatelessWidget {
  final String label;
  final bool required;
  final bool error;
  final bool locked;
  final Widget child;

  const VisaFieldBox({
    super.key,
    required this.label,
    required this.child,
    this.required = true,
    this.error = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFF7FBFD) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: error ? Colors.red : const Color(0xFFD1D5DB), width: error ? 1 : 0.7),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: label.toUpperCase(), style: visaText(6.5, weight: FontWeight.w500, color: VisaColors.text)),
                  if (required) TextSpan(text: '*', style: visaText(7, weight: FontWeight.w600, color: Colors.red)),
                ])),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
          if (locked) const Icon(Icons.verified, size: 14, color: VisaColors.green),
        ],
      ),
    );
  }
}

class VisaTextInput extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool required;
  final bool error;
  final bool locked;
  final TextCapitalization capitalization;
  final TextInputType keyboard;

  const VisaTextInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = true,
    this.error = false,
    this.locked = false,
    this.capitalization = TextCapitalization.words,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return VisaFieldBox(
      label: label,
      required: required,
      error: error,
      locked: locked,
      child: TextFormField(
        initialValue: value,
        readOnly: locked,
        textCapitalization: capitalization,
        keyboardType: keyboard,
        onChanged: onChanged,
        style: visaText(10.5, weight: FontWeight.w500, color: VisaColors.title),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }
}

class VisaTapInput extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool error;
  final bool locked;

  const VisaTapInput({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.error = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: locked
          ? null
          : () {
              FocusScope.of(context).unfocus();
              onTap();
            },
      child: VisaFieldBox(
        label: label,
        error: error,
        locked: locked,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value.isEmpty ? 'Select' : value,
            style: visaText(10.5,
                weight: FontWeight.w500, color: value.isEmpty ? const Color(0xFFBDBDBD) : VisaColors.title),
          ),
        ),
      ),
    );
  }
}

/// Card with the light-blue title band of the "Detail" design.
class VisaDetailCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onEdit;
  final Widget child;

  const VisaDetailCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor = VisaColors.primary,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFCDEBF8), Color(0xFFEFF8FD)]),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: visaText(12, weight: FontWeight.w600, color: VisaColors.title))),
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(Icons.edit, size: 16, color: VisaColors.primary),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}
