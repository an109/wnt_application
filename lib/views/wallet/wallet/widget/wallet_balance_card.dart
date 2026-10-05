import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

/// The card at the top of the wallet — Figma `Wallet 1`.
///
/// Drawn as a payment card: `assets/NewIcons/walletBack.png` fills it, the
/// chip and contactless marks sit top-left, the scheme marks top-right, and a
/// dashed rule separates the balance from the holder's name and **Top Up**.
///
/// The scheme marks are decoration, not a claim about a real card — the
/// wallet is an account balance, so they are drawn, never read from data.
class WalletBalanceCard extends StatelessWidget {
  final double balance;
  final String currencySymbol;
  final String holderName;

  /// The movement pill beside `TOTAL BALANCE`, e.g. `+2.4%`. Hidden when
  /// null, so a wallet with nothing to compare against shows no pill rather
  /// than a made-up zero.
  final String? changeLabel;

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onTopUp;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    required this.holderName,
    this.currencySymbol = '₹',
    this.changeLabel,
    this.isLoading = false,
    this.errorMessage,
    this.onTopUp,
  });

  /// `22,883.09` — grouped in thousands with the paise kept, as the design
  /// prints it.
  String get _formatted {
    final parts = balance.abs().toStringAsFixed(2).split('.');
    final whole = parts.first;
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return '$buf.${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      // The artwork is 1639x919; holding its ratio keeps the card from
      // stretching on short or very tall screens.
      aspectRatio: 1639 / 919,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(18)),
          // A flat fill under the artwork, so a slow or missing image still
          // leaves white text on blue rather than white on white.
          // color: const Color(0xFF4FC3F0),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: context.w(15),
              offset: Offset(0, context.h(4)),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1.15,
              child: Image.asset(
                'assets/NewIcons/walletBack.png',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(18),
                context.h(16),
                context.w(18),
                context.h(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topRow(context),
                  const Spacer(),
                  _balanceBlock(context),
                  SizedBox(height: context.h(12)),
                  _DashedRule(color: Colors.white.withOpacity(0.55)),
                  SizedBox(height: context.h(10)),
                  _holderRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- rows

  Widget _topRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ChipMark(size: context.w(26)),
        SizedBox(width: context.w(8)),
        Icon(
          Icons.contactless,
          size: context.w(16),
          color: Colors.white.withOpacity(0.9),
        ),
        const Spacer(),
        _MastercardMark(height: context.w(18)),
        SizedBox(width: context.w(8)),
        Text(
          'VISA',
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _balanceBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'TOTAL BALANCE',
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: AppColors.white,
              ),
            ),
            if (changeLabel != null) ...[
              SizedBox(width: context.w(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Text(
                  changeLabel!,
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: context.h(4)),
        if (isLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(6)),
            child: SizedBox(
              width: context.w(22),
              height: context.w(22),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$currencySymbol$_formatted',
              style: TextStyle(
                fontSize: context.fs(24),
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                // height: 1.1,
              ),
            ),
          ),
        if (errorMessage != null) ...[
          SizedBox(height: context.h(2)),
          Text(
            errorMessage!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(10),
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ],
    );
  }

  Widget _holderRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CARD HOLDER',
                style: TextStyle(
                  fontSize: context.fs(9),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                  color: AppColors.subhead,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                holderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.fs(15),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(10)),
        _TopUpButton(onTap: onTopUp),
      ],
    );
  }
}

class _TopUpButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _TopUpButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: context.w(16),
                color: AppColors.AppBlue,
              ),
              SizedBox(width: context.w(5)),
              Text(
                'Top Up',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.AppBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The gold contact plate on a payment card.
class _ChipMark extends StatelessWidget {
  final double size;

  const _ChipMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7D98B), Color(0xFFE2B457)],
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.52,
          height: size * 0.40,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x558A6520)),
            borderRadius: BorderRadius.circular(size * 0.06),
          ),
        ),
      ),
    );
  }
}

/// The two interlocking circles, drawn rather than shipped as an asset.
class _MastercardMark extends StatelessWidget {
  final double height;

  const _MastercardMark({required this.height});

  @override
  Widget build(BuildContext context) {
    final d = height;
    return SizedBox(
      width: d * 1.62,
      height: d,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: _dot(d, const Color(0xFFEB001B)),
          ),
          Positioned(
            right: 0,
            child: _dot(d, const Color(0xFFF79E1B)),
          ),
        ],
      ),
    );
  }

  Widget _dot(double d, Color color) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
      );
}

/// The dashed rule across the card.
class _DashedRule extends StatelessWidget {
  final Color color;

  const _DashedRule({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 4.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count < 0 ? 0 : count,
            (_) => SizedBox(
              width: dash,
              height: 1,
              child: ColoredBox(color: color),
            ),
          ),
        );
      },
    );
  }
}
