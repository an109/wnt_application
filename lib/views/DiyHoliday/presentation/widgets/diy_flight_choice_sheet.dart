import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/diy_features.dart';
import '../../data/models/diy_models.dart';
import 'diy_common.dart';

/// "Please select an option" — the sheet a results card opens so the customer
/// chooses land-only or with-flight before the package is priced.
///
/// Both figures come off the same search row (`price_with_flight` /
/// `price_without_flight`), so opening this costs no extra request.
///
/// Returns true for with-flight, false for without, or null if dismissed.
Future<bool?> showDiyFlightChoiceSheet(
  BuildContext context, {
  required DiyPackageSummary package,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DiyFlightChoiceSheet(package: package),
  );
}

class _DiyFlightChoiceSheet extends StatelessWidget {
  final DiyPackageSummary package;

  const _DiyFlightChoiceSheet({required this.package});

  /// The party the price was quoted for — never divide by zero.
  int get _heads {
    final heads = package.adults + package.children;
    return heads > 0 ? heads : 1;
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(context.r(22));

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Close — floats outside the sheet, top-right, as in the design.
          Padding(
            padding: EdgeInsets.only(
              right: context.w(18),
              bottom: context.h(10),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: context.w(34),
                height: context.w(34),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: context.w(19),
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              context.w(20),
              context.h(10),
              context.w(20),
              context.h(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: context.w(48),
                    height: context.h(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DDE4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: context.h(18)),
                Text(
                  package.title,
                  style: TextStyle(
                    fontSize: context.fs(20),
                    fontWeight: FontWeight.w800,
                    color: DiyTokens.navy,
                  ),
                ),
                SizedBox(height: context.h(12)),
                Text(
                  'Please select an option',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: DiyTokens.subGrey,
                  ),
                ),
                SizedBox(height: context.h(16)),
                _option(
                  context,
                  withFlight: true,
                  label: 'With Flight',
                  total: package.priceWithFlight,
                ),
                SizedBox(height: context.h(12)),
                _option(
                  context,
                  withFlight: false,
                  label: 'Without Flight',
                  total: package.priceWithoutFlight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required bool withFlight,
    required String label,
    required double total,
  }) {
    final perPerson = total / _heads;

    return Material(
      color: const Color(0xFFFAFBFC),
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(14)),
        onTap: () => Navigator.of(context).pop(withFlight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Starting from - ${package.origin}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                    SizedBox(height: context.h(8)),
                    Row(
                      children: [
                        _planeIcon(context, withFlight: withFlight),
                        SizedBox(width: context.w(10)),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(17),
                              fontWeight: FontWeight.w800,
                              color: DiyTokens.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(10)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The design strikes through a "was" price. Nothing on the
                  // search row carries one, so it stays gated rather than
                  // showing a discount that does not exist.
                  if (DiyFeatures.partPayment &&
                      package.partPaymentAmount > total) ...[
                    Text(
                      diyMoney(
                        package.partPaymentAmount,
                        currency: package.currency,
                      ),
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        color: DiyTokens.navy,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    SizedBox(height: context.h(3)),
                  ],
                  Text.rich(
                    TextSpan(
                      text: diyMoney(perPerson, currency: package.currency),
                      style: TextStyle(
                        fontSize: context.fs(19),
                        fontWeight: FontWeight.w800,
                        color: DiyTokens.blue,
                      ),
                      children: [
                        TextSpan(
                          text: '/person',
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w500,
                            color: DiyTokens.subGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    'Total ${diyMoney(total, currency: package.currency)}',
                    style: TextStyle(
                      fontSize: context.fs(10.5),
                      color: DiyTokens.labelGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A plane, struck through with a red slash for the land-only option.
  Widget _planeIcon(BuildContext context, {required bool withFlight}) {
    final plane = Icon(
      Icons.flight_takeoff_rounded,
      size: context.w(22),
      color: DiyTokens.blue,
    );
    if (withFlight) return plane;

    return SizedBox(
      width: context.w(24),
      height: context.w(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          plane,
          Transform.rotate(
            angle: -0.7,
            child: Container(
              width: context.w(26),
              height: 1.6,
              color: const Color(0xFFE23744),
            ),
          ),
        ],
      ),
    );
  }
}
