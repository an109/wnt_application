import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

/// Shared look for the wallet checkout (MakeMyTrip-style accordion).
class CheckoutColors {
  static const primary = AppColors.AppBlue;
  static const ink = Color(0xFF0F172A);
  static const muted = AppColors.subhead;
  static const stroke = Color(0xFFE6E8EC);
  static const page = Color(0xFFF2F4F7);
  static const offer = Color(0xFF16A34A);
  static const error = Color(0xFFB42318);
  static const chip = Color(0xFFF1F5F9);
}

/// Formats "4111111111111111" as "4111 1111 1111 1111" while typing.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 19 ? digits.substring(0, 19) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(capped[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formats expiry as "MM/YY" while typing.
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = capped.length > 2
        ? '${capped.substring(0, 2)}/${capped.substring(2)}'
        : capped;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

enum CardNetwork { visa, mastercard, rupay, amex, diners, maestro, unknown }

extension CardNetworkX on CardNetwork {
  String get label => switch (this) {
    CardNetwork.visa => 'VISA',
    CardNetwork.mastercard => 'Mastercard',
    CardNetwork.rupay => 'RuPay',
    CardNetwork.amex => 'AMEX',
    CardNetwork.diners => 'Diners',
    CardNetwork.maestro => 'Maestro',
    CardNetwork.unknown => '',
  };

  int get cvvLength => this == CardNetwork.amex ? 4 : 3;
}

CardNetwork detectCardNetwork(String number) {
  final n = number.replaceAll(' ', '');
  if (n.isEmpty) return CardNetwork.unknown;
  if (RegExp(r'^4').hasMatch(n)) return CardNetwork.visa;
  if (RegExp(r'^3[47]').hasMatch(n)) return CardNetwork.amex;
  if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(n)) return CardNetwork.mastercard;
  if (RegExp(r'^(60|65|81|82|508|353|356)').hasMatch(n))
    return CardNetwork.rupay;
  if (RegExp(r'^3(0[0-5]|[68])').hasMatch(n)) return CardNetwork.diners;
  if (RegExp(r'^(50|5[6-9]|6)').hasMatch(n)) return CardNetwork.maestro;
  return CardNetwork.unknown;
}

/// Luhn check for card numbers.
bool isValidCardNumber(String number) {
  final n = number.replaceAll(' ', '');
  if (n.length < 12 || n.length > 19) return false;
  var sum = 0;
  var alt = false;
  for (var i = n.length - 1; i >= 0; i--) {
    var d = int.parse(n[i]);
    if (alt) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
    alt = !alt;
  }
  return sum % 10 == 0;
}

String formatInr(double v) {
  final whole = v.truncateToDouble() == v;
  final s = v.toStringAsFixed(whole ? 0 : 2);
  final parts = s.split('.');
  var intPart = parts[0];
  // Indian grouping: 12,34,567
  if (intPart.length > 3) {
    final last3 = intPart.substring(intPart.length - 3);
    var rest = intPart.substring(0, intPart.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    intPart = '${groups.join(',')},$last3';
  }
  return '₹$intPart${parts.length > 1 ? '.${parts[1]}' : ''}';
}

/// One expandable payment option. Only the body animates; the header row is
/// always visible, like MakeMyTrip / Cleartrip checkouts.
class CheckoutAccordion extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final bool expanded;
  final VoidCallback? onTap;
  final Widget? child;
  final String? badge;
  final bool enabled;

  const CheckoutAccordion({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.expanded,
    required this.onTap,
    this.child,
    this.badge,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: EdgeInsets.only(bottom: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(
          color: expanded
              ? CheckoutColors.primary.withValues(alpha: 0.5)
              : CheckoutColors.stroke,
          width: expanded ? 1.2 : 1,
        ),
        boxShadow: expanded
            ? [
                BoxShadow(
                  color: CheckoutColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(14),
                vertical: context.h(14),
              ),
              child: Row(
                children: [
                  Opacity(opacity: enabled ? 1 : 0.45, child: leading),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.fs(15),
                                  fontWeight: FontWeight.w700,
                                  color: enabled
                                      ? CheckoutColors.ink
                                      : CheckoutColors.muted,
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              SizedBox(width: context.w(6)),
                              Flexible(child: CheckoutBadge(badge!)),
                            ],
                          ],
                        ),
                        SizedBox(height: context.h(2)),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(12),
                            color: CheckoutColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: context.w(24),
                        color: CheckoutColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded && child != null
                ? Column(
                    children: [
                      const Divider(height: 1, color: CheckoutColors.stroke),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.w(14),
                          context.h(14),
                          context.w(14),
                          context.h(16),
                        ),
                        child: child,
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class CheckoutBadge extends StatelessWidget {
  final String text;
  final Color color;

  const CheckoutBadge(
    this.text, {
    super.key,
    this.color = CheckoutColors.offer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(6),
        vertical: context.h(2),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.r(4)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: context.fs(9),
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Square icon tile used as the accordion leading widget.
class CheckoutIcon extends StatelessWidget {
  final String asset;

  const CheckoutIcon(this.asset, {super.key});

  @override
  Widget build(BuildContext context) =>
      Image.asset(asset, width: context.w(34), height: context.w(34));
}

/// Network logo (bank / wallet from Razorpay's CDN) with an initials fallback.
class LogoAvatar extends StatelessWidget {
  final String? url;
  final String? asset;
  final String label;
  final double size;

  const LogoAvatar({
    super.key,
    this.url,
    this.asset,
    required this.label,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.w(size);
    final fallback = Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CheckoutColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        label.isEmpty ? '?' : label.trim()[0].toUpperCase(),
        style: TextStyle(
          fontSize: context.fs(size * 0.42),
          fontWeight: FontWeight.w800,
          color: CheckoutColors.primary,
        ),
      ),
    );
    Widget img;
    if (asset != null) {
      img = Image.asset(asset!, width: s, height: s, fit: BoxFit.contain);
    } else if (url != null) {
      img = Image.network(
        url!,
        width: s,
        height: s,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      img = fallback;
    }
    return SizedBox(width: s, height: s, child: img);
  }
}

String bankLogoUrl(String code) => 'https://cdn.razorpay.com/bank/$code.gif';
String walletLogoUrl(String code) =>
    'https://cdn.razorpay.com/wallet/$code.png';

class CheckoutPayButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const CheckoutPayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.h(48).clamp(44.0, 56.0),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CheckoutColors.primary,
          disabledBackgroundColor: CheckoutColors.primary.withValues(
            alpha: 0.35,
          ),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(10)),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}

InputDecoration checkoutInput(
  BuildContext context,
  String label, {
  String? hint,
  Widget? suffix,
  Widget? prefixIcon,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(context.r(10)),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    suffixIcon: suffix,
    prefixIcon: prefixIcon,
    counterText: '',
    contentPadding: EdgeInsets.symmetric(
      horizontal: context.w(14),
      vertical: context.h(14),
    ),
    labelStyle: TextStyle(
      fontSize: context.fs(13),
      color: CheckoutColors.muted,
    ),
    hintStyle: TextStyle(
      fontSize: context.fs(13),
      color: CheckoutColors.muted.withValues(alpha: 0.6),
    ),
    border: border(CheckoutColors.stroke),
    enabledBorder: border(CheckoutColors.stroke),
    focusedBorder: border(CheckoutColors.primary, 1.4),
    errorBorder: border(CheckoutColors.error),
    focusedErrorBorder: border(CheckoutColors.error, 1.4),
  );
}

class InlineNote extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const InlineNote(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.color = CheckoutColors.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: context.w(14), color: color),
        SizedBox(width: context.w(6)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: context.fs(11.5),
              color: color,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Segmented filter tabs (e.g. UPI Apps | UPI ID | Scan QR).
class CheckoutTabs extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  const CheckoutTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(3)),
      decoration: BoxDecoration(
        color: CheckoutColors.chip,
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(vertical: context.h(9)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(context.r(8)),
                    boxShadow: i == index
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: context.fs(12.5),
                        fontWeight: i == index
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: i == index
                            ? CheckoutColors.primary
                            : CheckoutColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
