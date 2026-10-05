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
  final FocusNode? focusNode;

  /// `false` when the field is the second half of a pair and the label
  /// is notched into the first half instead — the mobile number next to
  /// its country code.
  final bool showLabel;

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
    this.showLabel = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      // A no-op at the field's natural height; it keeps the text centred
      // when the field is stretched to a taller sibling's height.
      textAlignVertical: TextAlignVertical.center,
      keyboardType: keyboardType,
      inputFormatters: [
        if (maxLength > 0) LengthLimitingTextInputFormatter(maxLength),
        ...formatters,
      ],
      onChanged: onChanged,
      style: TextStyle(fontSize: context.fs(12), color: InsTokens.navy),
      decoration: InputDecoration(
        label: showLabel
            ? InsFieldLabel(label: label, required: required)
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle:
            TextStyle(fontSize: context.fs(13), color: InsTokens.labelGrey),
        prefixIcon: prefix,
        prefixIconConstraints: BoxConstraints(minWidth: context.w(40)),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(12.5),
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
      borderRadius: BorderRadius.circular(context.r(8)),
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
        label: InsFieldLabel(label: label, required: required),
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
          label: InsFieldLabel(label: label, required: required),
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
///
/// Public so a field built by hand out of an [InputDecorator] — the
/// review screen's country-code card — notches the same label into its
/// border as [InsField] does.
class InsFieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const InsFieldLabel({
    super.key,
    required this.label,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(
          fontSize: context.fs(8),
          fontWeight: FontWeight.w600,
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

  /// Drawn when no [iconAsset] is given, or when the asset fails to
  /// load, so a missing file degrades to a glyph rather than a gap.
  final IconData icon;

  /// An artwork icon from `assets/NewIcons`, used as-is: these are drawn
  /// in their own colours, so [iconColour] does not tint them.
  final String? iconAsset;

  final Color iconColour;
  final Widget? trailing;
  final List<Widget> children;

  const InsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColour,
    required this.children,
    this.iconAsset,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.h(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: InsTokens.line, width: 0.8),
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
                _icon(context),
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

  Widget _icon(BuildContext context) {
    final asset = iconAsset;
    if (asset == null) {
      return Icon(icon, size: context.w(22), color: iconColour);
    }
    return Image.asset(
      asset,
      width: context.w(22),
      height: context.w(22),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(icon, size: context.w(22), color: iconColour),
    );
  }
}
