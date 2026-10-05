import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../tokens/ins_tokens.dart';
import 'ins_common.dart';

/// "Fare Breakup" — Figma `Fare insurance`.
///
/// Opened from the (i) beside the total on the review and payment screens.
/// The provider quotes a single GST-inclusive premium, so the base line is
/// the premium for the party and the surcharge line is whatever the quote
/// carries on top of it — zero for every plan in this account, which the
/// sheet states rather than inventing a split.
class InsFareSheet extends StatelessWidget {
  final double baseFare;
  final double taxes;
  final int travellers;
  final String planName;

  const InsFareSheet({
    super.key,
    required this.baseFare,
    required this.taxes,
    required this.travellers,
    required this.planName,
  });

  static Future<void> show(
    BuildContext context, {
    required double baseFare,
    required double taxes,
    required int travellers,
    required String planName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // Transparent so the × can float on the barrier above the sheet; the
      // sheet draws its own white card and rounded top corners.
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => InsFareSheet(
        baseFare: baseFare,
        taxes: taxes,
        travellers: travellers,
        planName: planName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The cross sits on the barrier just above the sheet's top-left
        // corner, rather than inside the sheet.
        Padding(
          padding: EdgeInsets.only(
            right: context.w(16),
            bottom: context.h(10),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_closeButton(context)]),
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(context.r(20))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const InsSheetHandle(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(18),
                  context.h(18),
                  context.w(18),
                  context.h(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare Breakup',
                      style: TextStyle(
                        fontSize: context.fs(20),
                        fontWeight: FontWeight.w800,
                        color: InsTokens.navy,
                      ),
                    ),
                    // SizedBox(height: context.h(6)),
                    // Text(
                    //   '$planName · $travellers Traveller'
                    //   '${travellers == 1 ? '' : 's'}',
                    //   style: TextStyle(
                    //     fontSize: context.fs(13),
                    //     color: InsTokens.subGrey,
                    //   ),
                    // ),
                    SizedBox(height: context.h(24)),
                    _row(context, 'Base Fare', baseFare),
                    const Divider(height: 1, color: InsTokens.line),
                    _row(
                      context,
                      'Taxes & Surcharges',
                      taxes,
                      note: taxes == 0 ? 'Included in the premium' : null,
                    ),
                  ],
                ),
              ),
              _footer(context),
            ],
          ),
        ),
      ],
    );
  }

  /// The dismiss cross that sits outside the sheet, top left.
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

  /// The total band. Last in the Column, so it paints over the rows above
  /// and its upward shadow lands on them instead of a hairline rule.
  Widget _footer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: context.r(10),
            offset: Offset(0, -context.h(4)), // negative = cast upward
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(18),
        context.w(18),
        context.h(0),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w700,
                  color: InsTokens.navy,
                ),
              ),
            ),
            Text(
              InsTokens.rupees(baseFare + taxes),
              style: TextStyle(
                fontSize: context.fs(24),
                fontWeight: FontWeight.w700,
                color: InsTokens.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double value, {
    String? note,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w400,
                    color: InsTokens.navy,
                  ),
                ),
                // if (note != null) ...[
                //   // SizedBox(height: context.h(1)),
                //   Text(
                //     note,
                //     style: TextStyle(
                //       fontSize: context.fs(15),
                //       fontWeight: FontWeight.w500,
                //       color: InsTokens.subGrey,
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
          Text(
            InsTokens.rupees(value),
            style: TextStyle(
              fontSize: context.fs(19),
              color: InsTokens.navy,
            ),
          ),
        ],
      ),
    );
  }
}
