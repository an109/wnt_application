import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

/// Flag + currency symbol chip from the Figma top bars (home, flight…).
///
/// Static display of the saved preferred currency — not a picker. Rebuilds
/// on `CurrencyConverter.currencyListenable` so the flag and symbol follow
/// whatever the user picks in the drawer's currency setting.
class CurrencyChip extends StatelessWidget {
  const CurrencyChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: CurrencyConverter.currencyListenable,
      builder: (context, currency, _) {
        final symbol = CurrencyConverter.getSymbol(currency);
        final flag = CurrencyConverter.getFlag(currency);

        return Container(
          height: context.fx(36),
          padding: EdgeInsets.symmetric(horizontal: context.fx(6)),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5),
            borderRadius: BorderRadius.circular(context.fx(6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: TextStyle(fontSize: context.ffs(14))),
              SizedBox(width: context.fx(4)),
              Text(
                symbol,
                style: TextStyle(
                  color: AppColors.AppBlue,
                  fontSize: context.ffs(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: context.fx(2)),
              RotatedBox(
                quarterTurns: 1,
                child: SvgPicture.asset(
                  'assets/home/chevron_down.svg',
                  width: context.fx(6),
                  height: context.fx(10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
