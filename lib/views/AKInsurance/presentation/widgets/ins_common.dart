import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../tokens/ins_tokens.dart';

/// The plain back-arrow + title bar every inner insurance screen uses
/// ("Individual", "Review", "Payment", "Filters").
PreferredSizeWidget insAppBar(
  BuildContext context, {
  required String title,
  List<Widget> actions = const [],
  bool closeIcon = false,
  VoidCallback? onBack,
  String? subtitle,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0.5,
    centerTitle: false,
    titleSpacing: 0,
    leading: IconButton(
      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      icon: Icon(
        closeIcon ? Icons.close_rounded : Icons.arrow_back_rounded,
        size: context.w(18),
        color: InsTokens.navy,
      ),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.fs(18),
            fontWeight: FontWeight.w600,
            color: InsTokens.navy,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: context.fs(11.5),
              color: InsTokens.subGrey,
            ),
          ),
      ],
    ),
    actions: actions,
  );
}

/// Full-screen spinner with a line of copy — used while quotes, plan
/// details, KYC and StartPay are in flight.
class InsLoading extends StatelessWidget {
  final String message;

  const InsLoading({super.key, this.message = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: context.w(30),
            height: context.w(30),
            child: const CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(InsTokens.blue),
            ),
          ),
          SizedBox(height: context.h(14)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.fs(12.5),
              color: InsTokens.subGrey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty / error state with an optional retry.
class InsEmpty extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const InsEmpty({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.search_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.w(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.w(46), color: InsTokens.labelGrey),
            SizedBox(height: context.h(14)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w700,
                color: InsTokens.navy,
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              SizedBox(height: context.h(6)),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.fs(12),
                  height: 1.45,
                  color: InsTokens.subGrey,
                ),
              ),
            ],
            if (onAction != null) ...[
              SizedBox(height: context.h(18)),
              SizedBox(
                height: context.h(42),
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InsTokens.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        EdgeInsets.symmetric(horizontal: context.w(26)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                  ),
                  child: Text(
                    actionLabel ?? 'Try again',
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Red inline error strip, shown above a CTA rather than as a snackbar when
/// the message needs to stay on screen (payment failures, KYC rejections).
class InsErrorCard extends StatelessWidget {
  final String message;

  const InsErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: InsTokens.errorBg,
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              size: context.w(17), color: InsTokens.errorIcon),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: context.fs(11.5),
                height: 1.4,
                color: InsTokens.errorFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The full-width orange CTA at the bottom of most screens
/// (EXPLORE PLANS, ADD DESTINATION, DONE, APPLY FILTER, PAY NOW).
class InsPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Widget? leading;
  final Widget? trailing;
  final double height;

  const InsPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.leading,
    this.trailing,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.h(height),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.OrangeColor,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: InsTokens.orange.withOpacity(0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
        ),
        child: busy
            ? SizedBox(
                width: context.w(20),
                height: context.w(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: context.w(8)),
                  ],
                  // Flexible + ellipsis: a long label next to a leading icon
                  // and a trailing arrow can exceed a narrow button (the
                  // half-width CTAs on the sort sheet are only ~130px), and
                  // an unbounded Text overflows rather than shrinking.
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: context.w(10)),
                    trailing!,
                  ],
                ],
              ),
      ),
    );
  }
}

/// Square blue tick used by the destination picker and the filter sheet.
class InsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const InsCheckbox({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(22),
        height: context.w(22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value ? InsTokens.blue : Colors.white,
          borderRadius: BorderRadius.circular(context.r(5)),
          border: Border.all(
            color: value ? InsTokens.blue : const Color(0xFFCBD2DD),
            width: 1.4,
          ),
        ),
        child: value
            ? Icon(Icons.check_rounded,
                size: context.w(15), color: Colors.white)
            : null,
      ),
    );
  }
}

/// Blue radio dot used by the sort sheet.
class InsRadio extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const InsRadio({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(22),
        height: context.w(22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? InsTokens.blue : const Color(0xFFCBD2DD),
            width: selected ? 5.5 : 1.4,
          ),
        ),
      ),
    );
  }
}

/// The `−  1  +` stepper on the search card and the traveller sheet.
class InsStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const InsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 9,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(3)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F9),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(context, Icons.remove_rounded, value > min,
              () => onChanged(value - 1)),
          SizedBox(
            width: context.w(28),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w700,
                color: InsTokens.navy,
              ),
            ),
          ),
          _btn(context, Icons.add_rounded, value < max,
              () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _btn(
    BuildContext context,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(30),
        height: context.w(30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        child: Icon(
          icon,
          size: context.w(17),
          color: enabled ? InsTokens.blue : const Color(0xFFCBD2DD),
        ),
      ),
    );
  }
}

/// The grab handle at the top of every bottom sheet in the flow.
class InsSheetHandle extends StatelessWidget {
  const InsSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: context.w(103),
        height: context.h(8),
        margin: EdgeInsets.only(top: context.h(12), bottom: context.h(6)),
        decoration: BoxDecoration(
          color: const Color(0xFFD1D1D6),
          borderRadius: BorderRadius.circular(context.r(24)),
        ),
      ),
    );
  }
}

/// One-line floating snackbar, matching the rest of the app.
void insSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? InsTokens.errorFg : InsTokens.navy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(10)),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: context.fs(12.5)),
        ),
      ),
    );
}

/// The provider's own logo when the quote row carries one, falling back to
/// the provider's initials on a tinted tile — plan artwork is supplied per
/// provider, so there is no bundled asset to use instead.
class InsProviderLogo extends StatelessWidget {
  final String? logoUrl;
  final String provider;
  final double width;
  final double height;

  const InsProviderLogo({
    super.key,
    required this.provider,
    this.logoUrl,
    this.width = 50,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final w = context.w(width);
    final h = context.h(height);
    final url = logoUrl;

    if (url == null || url.isEmpty) return _initials(context, w, h);

    // The insurer artwork is a JPEG drawn on white, so it is laid on a white
    // tile and contained rather than cropped — stretching a logo is worse
    // than showing it small.
    return Container(
      width: w,
      height: h,
      padding: EdgeInsets.all(context.w(2)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        // A blank box while the logo downloads, not the initials — flashing
        // a fallback and then replacing it reads as a glitch.
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const SizedBox.shrink(),
        errorBuilder: (_, __, ___) => _initials(context, w, h),
      ),
    );
  }

  Widget _initials(BuildContext context, double w, double h) {
    final letters = provider
        .split(RegExp(r'[\s\-_]+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: InsTokens.blue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(context.r(6)),
      ),
      child: Text(
        letters.isEmpty ? '—' : letters,
        style: TextStyle(
          fontSize: context.fs(14),
          fontWeight: FontWeight.w800,
          color: InsTokens.blue,
        ),
      ),
    );
  }
}
