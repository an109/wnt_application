import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../domain/entity/benefit_entity.dart';

/// The "apply your benefit credit" row on a payment screen.
///
/// Shows how much of the booking the traveller's benefit balance can cover,
/// lets them dial it down, and says plainly what is left to pay by card/UPI.
///
/// Two things this deliberately does NOT do:
///   * decide the cap — [quote.maxRedeemable] comes from the server, which
///     has already applied the booking %, the margin guard and the flat
///     ceiling. Recomputing any of that here would let a stale app version
///     hand out more than the booking earned.
///   * hide the reason — when the cap bites (a zero-margin fare, say) the
///     traveller is told why, instead of silently seeing a smaller number
///     than their balance suggests.
class BenefitApplyCard extends StatelessWidget {
  const BenefitApplyCard({
    super.key,
    required this.quote,
    required this.appliedAmount,
    required this.onChanged,
    required this.money,
    this.enabled = true,
    this.locked = false,
  });

  /// The server's answer for this booking.
  final BenefitQuote quote;

  /// How much the traveller has chosen to apply, in INR.
  final double appliedAmount;

  final ValueChanged<double> onChanged;

  /// Formats an INR amount for display — passed in so this card follows
  /// whatever currency the payment screen is already showing.
  final String Function(double) money;

  final bool enabled;

  /// True once the credit is held and the gateway is open: the amount is
  /// fixed for the rest of the attempt, so the controls go read-only rather
  /// than letting the traveller change a number the server has reserved.
  final bool locked;

  bool get _isOn => appliedAmount > 0;

  @override
  Widget build(BuildContext context) {
    if (!quote.success) return const SizedBox.shrink();

    // Nothing to offer: say so once, quietly, instead of an empty control.
    if (quote.maxRedeemable <= 0) {
      if (quote.availableBalance <= 0) return const SizedBox.shrink();
      return _shell(
        context,
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: context.w(16), color: AppColors.authInk.withValues(alpha: 0.5)),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Text(
                quote.reason.isNotEmpty
                    ? quote.reason
                    : 'Benefits cannot be applied to this booking',
                style: TextStyle(
                  fontSize: context.fs(11.5),
                  color: AppColors.authInk.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _shell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.w(6)),
                decoration: BoxDecoration(
                  color: AppColors.OrangeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.w(8)),
                ),
                child: Icon(Icons.redeem_rounded,
                    size: context.w(16), color: AppColors.OrangeColor),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use your benefit credit',
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.authInk,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      '${money(quote.availableBalance)} available · '
                      'up to ${money(quote.maxRedeemable)} on this booking',
                      style: TextStyle(
                        fontSize: context.fs(10.5),
                        color: AppColors.authInk.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isOn,
                activeTrackColor: AppColors.OrangeColor,
                onChanged: (!enabled || locked)
                    ? null
                    : (on) => onChanged(on ? quote.maxRedeemable : 0),
              ),
            ],
          ),

          if (_isOn) ...[
            SizedBox(height: context.h(6)),

            // Only worth a slider when there is a range to choose from.
            if (quote.maxRedeemable > 1 && !locked)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: context.h(3),
                  activeTrackColor: AppColors.OrangeColor,
                  inactiveTrackColor:
                      AppColors.OrangeColor.withValues(alpha: 0.18),
                  thumbColor: AppColors.OrangeColor,
                  overlayShape:
                      RoundSliderOverlayShape(overlayRadius: context.w(14)),
                ),
                child: Slider(
                  value: appliedAmount.clamp(0, quote.maxRedeemable),
                  min: 0,
                  max: quote.maxRedeemable,
                  onChanged: enabled
                      ? (v) => onChanged(double.parse(v.toStringAsFixed(2)))
                      : null,
                ),
              ),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(8),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FBF4),
                borderRadius: BorderRadius.circular(context.w(10)),
                border: Border.all(color: const Color(0xFFBBF0CC)),
              ),
              child: Column(
                children: [
                  _line(
                    context,
                    'Benefit applied',
                    '− ${money(appliedAmount)}',
                    valueColour: const Color(0xFF16A34A),
                  ),
                  SizedBox(height: context.h(5)),
                  _line(
                    context,
                    'Left to pay',
                    money(
                      (quote.bookingAmount - appliedAmount)
                          .clamp(0, double.infinity),
                    ),
                    bold: true,
                  ),
                ],
              ),
            ),

            if (quote.reason.isNotEmpty) ...[
              SizedBox(height: context.h(6)),
              Text(
                quote.reason,
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: AppColors.authInk.withValues(alpha: 0.55),
                ),
              ),
            ],

            if (locked) ...[
              SizedBox(height: context.h(6)),
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: context.w(12),
                      color: AppColors.authInk.withValues(alpha: 0.45)),
                  SizedBox(width: context.w(5)),
                  Expanded(
                    child: Text(
                      'Reserved for this payment',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: AppColors.authInk.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _shell(BuildContext context, {required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.h(8)),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.w(12)),
        border: Border.all(color: const Color(0xFFEDEDF0)),
      ),
      child: child,
    );
  }

  Widget _line(BuildContext context, String label, String value,
      {Color? valueColour, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.fs(11.5),
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.authInk,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.fs(bold ? 13 : 11.5),
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColour ?? AppColors.authInk,
          ),
        ),
      ],
    );
  }
}
