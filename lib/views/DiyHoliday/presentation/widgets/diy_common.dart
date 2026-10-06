import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/resources/app_colours.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

/// Tokens shared by every DIY Holiday screen so the flow stays visually
/// consistent with the flight SearchCard it was modelled on.
class DiyTokens {
  const DiyTokens._();

  static const Color labelGrey = Color(0xFF9AA3B2);
  static const Color subGrey = Color(0xFF7A8494);
  static const Color pageBg = Color(0xFFF8F9FA);
  static const Color line = Color(0xFFECEEF4);
  static const Color blue = AppColors.AppBlue;
  static const Color orange = Color(0xFFFF6B00);
  static const Color navy = AppColors.navy;
}

// ------------------------------------------------------------- formatting

final NumberFormat _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String diyMoney(num value, {String currency = 'INR'}) {
  if (currency == 'INR') return _inr.format(value);
  return '$currency ${value.toStringAsFixed(0)}';
}

/// Signed money, for the "+₹1,640 / -₹924" deltas on flight and hotel cards.
String diyDelta(num value, {String currency = 'INR'}) {
  if (value == 0) return 'Same price';
  final sign = value > 0 ? '+' : '-';
  return '$sign${diyMoney(value.abs(), currency: currency)}';
}

String diyDuration(int minutes) {
  if (minutes <= 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Parses the API's naive ISO timestamps ("2026-12-10T05:45:00").
DateTime? diyParseDate(String value) =>
    value.isEmpty ? null : DateTime.tryParse(value);

String diyTime(String isoValue) {
  final d = diyParseDate(isoValue);
  return d == null ? '--:--' : DateFormat('HH:mm').format(d);
}

String diyDayDate(String isoValue) {
  final d = diyParseDate(isoValue);
  return d == null ? '' : DateFormat('dd MMM').format(d);
}

String diyFullDate(DateTime d) => DateFormat('dd MMM, yy').format(d);

String diyWeekday(DateTime d) => DateFormat('EEEE').format(d);

// ---------------------------------------------------------------- widgets

/// Network image with the rounded placeholder used across the flow.
class DiyImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  const DiyImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: const Color(0xFFE9EDF3),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: DiyTokens.labelGrey,
        size: context.w(20),
      ),
    );

    final image = url.isEmpty
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => placeholder,
          );

    if (radius == null) return image;
    return ClipRRect(borderRadius: radius!, child: image);
  }
}

/// White rounded card used for every field/list tile in the flow.
class DiyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const DiyCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.r(14)),
        child: Container(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: context.w(14),
                vertical: context.h(12),
              ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: borderColor ?? DiyTokens.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: context.w(12),
                offset: Offset(0, context.h(3)),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The full-width orange CTA at the bottom of the detail/enquiry screens.
class DiyPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  const DiyPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.h(48),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: DiyTokens.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE3E6EC),
          disabledForegroundColor: DiyTokens.labelGrey,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(10)),
          ),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox(
                width: context.w(20),
                height: context.w(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (icon != null) ...[
                    SizedBox(width: context.w(8)),
                    Icon(icon, size: context.w(18)),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Centred spinner + caption, used for the calls the API warns are slow:
/// the with-flight price (~7s) and the first hotel search for a stop (~19s).
class DiyLoading extends StatelessWidget {
  final String message;
  final String? hint;

  const DiyLoading({super.key, required this.message, this.hint});

  @override
  Widget build(BuildContext context) {
    return AppLoadingView(message: message, hint: hint);
  }
}

/// Error panel with a Retry button, shared by every loader in the flow.
class DiyErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const DiyErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: context.w(40),
              color: Colors.red.shade300,
            ),
            SizedBox(height: context.h(12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(13),
                color: DiyTokens.subGrey,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: context.h(16)),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DiyTokens.blue,
                  side: const BorderSide(color: DiyTokens.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(8)),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Plain white app bar with a back arrow — the header in every Figma frame
/// after the hero (Select Date, Filters, Upload Image, …).
PreferredSizeWidget diyAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  Widget? leading,
  bool closeIcon = false,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0.5,
    leading:
        leading ??
        IconButton(
          icon: Icon(
            closeIcon ? Icons.close : Icons.arrow_back,
            color: DiyTokens.navy,
            size: context.w(22),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
    titleSpacing: 0,
    title: Text(
      title,
      style: TextStyle(
        fontSize: context.fs(20),
        fontWeight: FontWeight.w700,
        color: DiyTokens.navy,
      ),
    ),
    actions: actions,
  );
}

void diySnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : DiyTokens.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
