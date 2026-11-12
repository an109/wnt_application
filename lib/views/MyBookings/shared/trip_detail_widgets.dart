import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../core/resources/app_colours.dart';
import '../../../core/services/pdf_generator.dart';

const Color kInk = Color(0xFF111527);
const Color kMuted = Color(0xFF6B7280);
const Color kLine = Color(0xFFE5E7EB);
const Color kOrange = Color(0xFFEE7330);
const Color kRed = Color(0xFFE53935);
const Color kGreen = Color(0xFF34A853);

const Map<String, String> kCurrencySymbols = {
  'INR': '₹',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'AED': 'AED ',
};

String formatMoney(num amount, String currency) {
  final symbol =
      kCurrencySymbols[currency.toUpperCase()] ?? '${currency.toUpperCase()} ';
  final whole = amount.round().abs().toString();
  String grouped;
  if (whole.length <= 3) {
    grouped = whole;
  } else {
    final last3 = whole.substring(whole.length - 3);
    var rest = whole.substring(0, whole.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${amount < 0 ? '- ' : ''}$symbol$grouped';
}

Future<void> saveAndOfferPdf(
  BuildContext context, {
  required Future<pw.Document> Function(pw.ImageProvider? logo) build,
  required String filename,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(
        content: Text('Preparing PDF…'),
        behavior: SnackBarBehavior.floating));
  try {
    pw.ImageProvider? logo;
    try {
      final data = await rootBundle.load('assets/images/wander_logo.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}
    final file = await PDFService.savePDF(await build(logo), filename);
    messenger.hideCurrentSnackBar();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              sheet.fx(20), sheet.fx(16), sheet.fx(20), sheet.fx(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: kGreen),
                  SizedBox(width: sheet.fx(8)),
                  Expanded(
                    child: Text(
                      'PDF ready',
                      style: TextStyle(
                          fontSize: sheet.ffs(16),
                          fontWeight: FontWeight.w600,
                          color: kInk),
                    ),
                  ),
                ],
              ),
              SizedBox(height: sheet.fx(4)),
              Text(filename,
                  style: TextStyle(fontSize: sheet.ffs(12), color: kMuted)),
              SizedBox(height: sheet.fx(12)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.share_rounded, color: AppColors.AppBlue),
                title: const Text('Share / Save to Files'),
                onTap: () {
                  Navigator.pop(sheet);
                  Share.shareXFiles([XFile(file.path)]);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.print_rounded, color: AppColors.AppBlue),
                title: const Text('Open / Print'),
                onTap: () {
                  Navigator.pop(sheet);
                  PDFService.printPDF(file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
            content: Text("Couldn't create the PDF: $e"),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating),
      );
  }
}

class TripSection extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets? padding;
  final (String, Color)? cornerTag;
  final bool compact;

  const TripSection({
    super.key,
    this.title,
    this.icon,
    this.iconColor,
    this.trailing,
    required this.child,
    this.padding,
    this.cornerTag,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(context.fx(compact ? 12 : 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(14)),
        border: Border.all(color: kLine),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(icon, size: context.fx(compact ? 16 : 18), color: iconColor),
                SizedBox(width: context.fx(8)),
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: context.ffs(compact ? 13 : 14.5),
                      fontWeight: FontWeight.w600,
                      color: kInk,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: context.fx(trailing != null ? 4 : 12)),
          ],
          child,
        ],
      ),
    );
    if (cornerTag == null) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -1,
          right: context.fx(10),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.fx(10), vertical: context.fx(3)),
            decoration: BoxDecoration(
              color: cornerTag!.$2,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(context.fx(8))),
            ),
            child: Text(
              cornerTag!.$1,
              style: TextStyle(
                  fontSize: context.ffs(10.5),
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class TripInset extends StatelessWidget {
  final Widget child;
  final bool tinted;
  final String? title;
  final IconData? titleIcon;

  const TripInset(
      {super.key,
      required this.child,
      this.tinted = false,
      this.title,
      this.titleIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: BoxDecoration(
        color: tinted ? const Color(0xFFF3FAFE) : Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border:
            Border.all(color: tinted ? const Color(0xFFD6ECF8) : kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(titleIcon, size: context.fx(16), color: kGreen),
                SizedBox(width: context.fx(8)),
                Text(title!,
                    style: TextStyle(
                        fontSize: context.ffs(12.5),
                        fontWeight: FontWeight.w600,
                        color: kInk)),
              ],
            ),
            SizedBox(height: context.fx(6)),
          ],
          child,
        ],
      ),
    );
  }
}

class TripActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  const TripActionButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed,
      this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: context.fx(18)),
        SizedBox(width: context.fx(8)),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: context.ffs(13.5),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2),
          ),
        ),
      ],
    );
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.fx(10)));
    final size = Size.fromHeight(context.fx(50));
    return outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: kOrange,
              side: const BorderSide(color: kOrange),
              shape: shape,
              minimumSize: size,
              padding: EdgeInsets.symmetric(horizontal: context.fx(8)),
            ),
            child: content,
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: kOrange,
              disabledBackgroundColor: const Color(0xFFF5C3A6),
              disabledForegroundColor: Colors.white,
              shape: shape,
              minimumSize: size,
              padding: EdgeInsets.symmetric(horizontal: context.fx(8)),
            ),
            child: content,
          );
  }
}

class TripStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const TripStat(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: context.fx(30),
          height: context.fx(30),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(context.fx(6)),
          ),
          child: Icon(icon, size: context.fx(17), color: const Color(0xFF3B9BE0)),
        ),
        SizedBox(width: context.fx(6)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.ffs(10.5), color: kMuted)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: context.ffs(13),
                    fontWeight: FontWeight.w600,
                    color: kInk),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget tripKv(BuildContext context, String label, String value,
    {bool muted = false, (String, Color)? chip}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: context.fx(5)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
                fontSize: context.ffs(12.5),
                color: muted ? kMuted : const Color(0xFF4B5563)),
          ),
        ),
        SizedBox(width: context.fx(8)),
        Flexible(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: chip != null
                ? Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.fx(10), vertical: context.fx(3)),
                    decoration: BoxDecoration(
                      color: chip.$2.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(context.fx(20)),
                    ),
                    child: Text(chip.$1,
                        style: TextStyle(
                            fontSize: context.ffs(11.5), color: chip.$2)),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: context.ffs(12.5),
                        fontWeight: FontWeight.w500,
                        color: kInk),
                  ),
          ),
        ),
      ],
    ),
  );
}

Widget tripTopBar(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String statusLabel,
  required Color statusColor,
  VoidCallback? onShare,
}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(
        context.fx(8), context.fx(6), context.fx(4), context.fx(10)),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, size: context.fx(24), color: kInk),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: context.ffs(18),
                        fontWeight: FontWeight.w600,
                        color: kInk),
                  ),
                  SizedBox(width: context.fx(8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.fx(8), vertical: context.fx(2)),
                    decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius:
                            BorderRadius.circular(context.fx(20))),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                          fontSize: context.ffs(10.5),
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.ffs(11), color: kMuted),
              ),
            ],
          ),
        ),
        if (onShare != null)
          IconButton(
            tooltip: 'Share',
            onPressed: onShare,
            icon:
                Icon(Icons.share_rounded, size: context.fx(20), color: kInk),
          ),
      ],
    ),
  );
}

Widget tripBottomBar(BuildContext context, List<Widget> buttons) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
            color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            context.fx(16), context.fx(12), context.fx(16), context.fx(12)),
        child: Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) SizedBox(width: context.fx(12)),
              Expanded(child: buttons[i]),
            ],
          ],
        ),
      ),
    ),
  );
}

(String, Color) statusInfo(String status) {
  final s = status.toLowerCase();
  if (s.contains('cancelled') || s.contains('cancel')) {
    return ('Cancelled', const Color(0xFFEF4444));
  }
  if (s.contains('pending')) return ('Pending', const Color(0xFFFF9800));
  if (s.contains('confirmed') || s.contains('completed') || s.contains('approved')) {
    return ('Confirmed', AppColors.AppBlue);
  }
  return (status.isEmpty ? 'Pending' : status, const Color(0xFFFF9800));
}

String formatTripDate(String dateString) {
  if (dateString.isEmpty) return 'N/A';
  try {
    final dt = DateTime.parse(dateString);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return dateString;
  }
}
