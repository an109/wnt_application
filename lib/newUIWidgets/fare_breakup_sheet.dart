import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

/// One line-item in the fare breakup drawer: a bold `label`/`amount` row and,
/// optionally, a lighter `subLabel`/`subAmount` detail row beneath it
/// (e.g. "Adult(s) (1 X ₹ 4,892)" or a promo code). Set [isDiscount] to render
/// the whole group in green.
class FareBreakupLine {
  final String label;
  final String amount;
  final String? subLabel;
  final String? subAmount;
  final bool isDiscount;

  const FareBreakupLine({
    required this.label,
    required this.amount,
    this.subLabel,
    this.subAmount,
    this.isDiscount = false,
  });
}

/// Shared "Fare Breakup" bottom drawer — Wander Nova Figma "Fare flight"
/// (node 481:1556). Opened from the price + info-icon area of a bottom bar
/// (booking screen, add-ons screen, …). Presentational only: the caller
/// builds the [FareBreakupLine]s from its own already-computed, already
/// currency-converted figures, so this widget never touches pricing logic.
class FareBreakupSheet extends StatelessWidget {
  final String title;
  final List<FareBreakupLine> lines;
  final String totalLabel;
  final String totalAmount;

  const FareBreakupSheet({
    super.key,
    required this.lines,
    required this.totalAmount,
    this.title = 'Fare Breakup',
    this.totalLabel = 'Total Amount',
  });

  /// Shows the drawer as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required List<FareBreakupLine> lines,
    required String totalAmount,
    String title = 'Fare Breakup',
    String totalLabel = 'Total Amount',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FareBreakupSheet(
        lines: lines,
        totalAmount: totalAmount,
        title: title,
        totalLabel: totalLabel,
      ),
    );
  }

  static const _pri = AppColors.AppBlue; // #00A1E4
  static const _muted = AppColors.subhead; // #757575
  static const _title900 = Color(0xFF111527);
  static const _discount = Color(0xFF16A34A);
  static const _stroke = Color(0xFFE6E8EC);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- close, floating above the sheet ----
        Padding(
          padding: EdgeInsets.only(right: context.w(16), bottom: context.h(12)),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: context.w(32),
                height: context.w(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.close_rounded, size: context.w(18), color: _title900),
              ),
            ),
          ),
        ),
        // ---- sheet ----
        Flexible(
          child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(24))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    context.w(16), context.h(12), context.w(16), 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: context.w(44),
                        height: context.h(4),
                        decoration: BoxDecoration(
                          color: _stroke,
                          borderRadius: BorderRadius.circular(context.r(999)),
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(18)),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(18),
                        fontWeight: FontWeight.w700,
                        color: _title900,
                      ),
                    ),
                    SizedBox(height: context.h(22)),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      context.w(16), 0, context.w(16), context.h(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < lines.length; i++) ...[
                        if (i > 0) SizedBox(height: context.h(20)),
                        _lineGroup(context, lines[i]),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: _stroke),
              // ---- total, as a shadowed bottom bar ----
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        context.w(16), context.h(14), context.w(16), context.h(14)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            totalLabel,
                            style: TextStyle(
                              fontSize: context.fs(18),
                              fontWeight: FontWeight.w700,
                              color: _title900,
                            ),
                          ),
                        ),
                        SizedBox(width: context.w(12)),
                        Text(
                          totalAmount,
                          style: TextStyle(
                            fontSize: context.fs(24),
                            fontWeight: FontWeight.w800,
                            color: _pri,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }

  Widget _lineGroup(BuildContext context, FareBreakupLine line) {
    final mainColor = line.isDiscount ? _discount : _title900;
    final subColor = line.isDiscount ? _discount : _muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                line.label,
                style: TextStyle(
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w600,
                  color: mainColor,
                ),
              ),
            ),
            SizedBox(width: context.w(12)),
            Text(
              line.amount,
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w500,
                color: mainColor,
              ),
            ),
          ],
        ),
        if ((line.subLabel ?? '').trim().isNotEmpty) ...[
          SizedBox(height: context.h(6)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.subLabel!,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w400,
                    color: subColor,
                  ),
                ),
              ),
              if ((line.subAmount ?? '').trim().isNotEmpty) ...[
                SizedBox(width: context.w(12)),
                Text(
                  line.subAmount!,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w400,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
