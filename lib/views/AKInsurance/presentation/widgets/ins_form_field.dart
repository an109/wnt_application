import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../tokens/ins_tokens.dart';

/// The outlined field used across the review screen, with its label notched
/// into the top border and a red asterisk when required — Figma
/// `insurance Individual review`.
class InsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final TextInputType keyboardType;
  final int maxLength;
  final List<TextInputFormatter> formatters;
  final Widget? prefix;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const InsField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLength = 0,
    this.formatters = const [],
    this.prefix,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: [
        if (maxLength > 0) LengthLimitingTextInputFormatter(maxLength),
        ...formatters,
      ],
      onChanged: onChanged,
      style: TextStyle(fontSize: context.fs(15), color: InsTokens.navy),
      decoration: InputDecoration(
        label: _Label(label: label, required: required),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle:
            TextStyle(fontSize: context.fs(15), color: InsTokens.labelGrey),
        prefixIcon: prefix,
        prefixIconConstraints: BoxConstraints(minWidth: context.w(40)),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(16),
        ),
        border: _border(context, InsTokens.line),
        enabledBorder: _border(context, InsTokens.line),
        focusedBorder: _border(context, InsTokens.blue),
        disabledBorder: _border(context, InsTokens.line),
      ),
    );
  }

  OutlineInputBorder _border(BuildContext context, Color colour) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.r(10)),
      borderSide: BorderSide(color: colour),
    );
  }
}

/// Dropdown styled to match [InsField].
class InsDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool required;
  final Widget? prefix;

  const InsDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.required = false,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        label: _Label(label: label, required: required),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: prefix,
        prefixIconConstraints: BoxConstraints(minWidth: context.w(40)),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(14),
        ),
        border: _border(context, InsTokens.line),
        enabledBorder: _border(context, InsTokens.line),
        focusedBorder: _border(context, InsTokens.blue),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : null,
          isExpanded: true,
          isDense: true,
          hint: Text(
            'Select',
            style:
                TextStyle(fontSize: context.fs(15), color: InsTokens.labelGrey),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: context.w(22), color: InsTokens.blue),
          style: TextStyle(fontSize: context.fs(15), color: InsTokens.navy),
          items: [
            for (final o in options)
              DropdownMenuItem(
                value: o,
                child: Text(o, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  OutlineInputBorder _border(BuildContext context, Color colour) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.r(10)),
      borderSide: BorderSide(color: colour),
    );
  }
}

/// Read-only field that opens a picker — used for dates of birth.
class InsPickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final bool required;
  final VoidCallback onTap;
  final IconData icon;

  const InsPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint = 'Select',
    this.required = false,
    this.icon = Icons.calendar_month_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: InputDecorator(
        decoration: InputDecoration(
          label: _Label(label: label, required: required),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(16),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(10)),
            borderSide: const BorderSide(color: InsTokens.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.r(10)),
            borderSide: const BorderSide(color: InsTokens.line),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: context.fs(15),
                  color: value == null ? InsTokens.labelGrey : InsTokens.navy,
                ),
              ),
            ),
            Icon(icon, size: context.w(19), color: InsTokens.subGrey),
          ],
        ),
      ),
    );
  }
}

/// `LABEL*` with the asterisk in red, as every required field shows it.
class _Label extends StatelessWidget {
  final String label;
  final bool required;

  const _Label({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(
          fontSize: context.fs(11),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: InsTokens.subGrey,
        ),
        children: [
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Color(0xFFE4572E)),
            ),
        ],
      ),
    );
  }
}

/// A titled white card with a coloured leading icon — "Proposer Details",
/// "Travellers", "Nominee Details".
class InsSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColour;
  final Widget? trailing;
  final List<Widget> children;

  const InsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColour,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.h(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: InsTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(14),
              context.w(14),
              context.h(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: context.w(22), color: iconColour),
                SizedBox(width: context.w(9)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.w600,
                      color: InsTokens.navy,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: InsTokens.line),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(18),
              context.w(14),
              context.h(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
