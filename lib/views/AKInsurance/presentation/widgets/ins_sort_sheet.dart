import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../state/ins_plan_filter.dart';
import '../tokens/ins_tokens.dart';
import 'ins_common.dart';

/// "Sort by" bottom sheet — Figma `Insurance sort`, with its dismiss
/// cross floating on the barrier above the sheet's top-right corner.
///
/// Deliberately a short list of the three orderings a traveller actually
/// asks for; the filter screen carries the same choices plus the supplier
/// and coverage groups.
class InsSortSheet extends StatefulWidget {
  final InsSortBy selected;

  const InsSortSheet({super.key, required this.selected});

  static Future<InsSortBy?> show(
    BuildContext context, {
    required InsSortBy selected,
  }) {
    return showModalBottomSheet<InsSortBy>(
      context: context,
      isScrollControlled: true,
      // Transparent so the × can float on the barrier above the sheet; the
      // sheet draws its own white card and rounded top corners.
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => InsSortSheet(selected: selected),
    );
  }

  @override
  State<InsSortSheet> createState() => _InsSortSheetState();
}

class _InsSortSheetState extends State<InsSortSheet> {
  late InsSortBy _value = widget.selected;

  static const _options = [
    InsSortBy.premiumLowToHigh,
    InsSortBy.premiumHighToLow,
    InsSortBy.coverageHighToLow,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The cross sits on the barrier just above the sheet's top-right
        // corner, rather than inside the sheet.
        Padding(
          padding: EdgeInsets.only(
            right: context.w(16),
            bottom: context.h(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_closeButton(context)],
          ),
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(context.r(20))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const InsSheetHandle(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(18),
                    context.h(16),
                    context.w(18),
                    context.h(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sort by',
                        style: TextStyle(
                          fontSize: context.fs(14),
                          color: InsTokens.subGrey,
                        ),
                      ),
                      SizedBox(height: context.h(12)),
                      for (final o in _options) _row(context, o),
                      SizedBox(height: context.h(14)),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: context.h(50),
                              child: OutlinedButton(
                                onPressed: () => setState(
                                    () => _value = InsSortBy.popularity),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: InsTokens.line),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(context.r(12)),
                                  ),
                                ),
                                child: Text(
                                  'RESET',
                                  style: TextStyle(
                                    fontSize: context.fs(14.5),
                                    fontWeight: FontWeight.w600,
                                    color: InsTokens.subGrey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: context.w(14)),
                          Expanded(
                            child: InsPrimaryButton(
                              label: 'DONE',
                              onPressed: () =>
                                  Navigator.of(context).pop(_value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The dismiss cross that sits outside the sheet, top right.
  Widget _closeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(34),
        height: context.w(34),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded,
            size: context.w(20), color: InsTokens.navy),
      ),
    );
  }

  Widget _row(BuildContext context, InsSortBy option) {
    return GestureDetector(
      onTap: () => setState(() => _value = option),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(15)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: context.fs(16),
                  color: InsTokens.navy,
                ),
              ),
            ),
            InsRadio(
              selected: _value == option,
              onTap: () => setState(() => _value = option),
            ),
          ],
        ),
      ),
    );
  }
}
