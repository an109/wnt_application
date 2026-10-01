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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(20))),
      ),
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
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              const InsSheetHandle(),
              Positioned(
                right: context.w(8),
                top: context.h(2),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.all(context.w(8)),
                    child: Icon(Icons.close_rounded,
                        size: context.w(22), color: InsTokens.navy),
                  ),
                ),
              ),
            ],
          ),
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
                    fontSize: context.fs(24),
                    fontWeight: FontWeight.w700,
                    color: InsTokens.navy,
                  ),
                ),
                SizedBox(height: context.h(6)),
                Text(
                  '$planName · $travellers Traveller'
                  '${travellers == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: InsTokens.subGrey,
                  ),
                ),
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
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: InsTokens.line)),
            ),
            padding: EdgeInsets.fromLTRB(
              context.w(18),
              context.h(18),
              context.w(18),
              context.h(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: context.fs(22),
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
        ],
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
                    fontSize: context.fs(19),
                    color: InsTokens.navy,
                  ),
                ),
                if (note != null) ...[
                  SizedBox(height: context.h(3)),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: InsTokens.subGrey,
                    ),
                  ),
                ],
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
