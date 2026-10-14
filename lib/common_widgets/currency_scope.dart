import 'package:flutter/widgets.dart';

import '../UI_helper/currency_converter.dart';

/// Sits above every screen (see `main.dart`). When the user picks another
/// currency or fresh exchange rates arrive, every widget below is rebuilt in
/// place (state is kept), so prices formatted in any `build` method —
/// through [CurrencyContext] or [CurrencyConverter] — update at once.
class CurrencyScope extends StatefulWidget {
  final Widget child;
  const CurrencyScope({super.key, required this.child});

  @override
  State<CurrencyScope> createState() => _CurrencyScopeState();
}

class _CurrencyScopeState extends State<CurrencyScope> {
  @override
  void initState() {
    super.initState();
    CurrencyConverter.changes.addListener(_rebuildAll);
  }

  @override
  void dispose() {
    CurrencyConverter.changes.removeListener(_rebuildAll);
    super.dispose();
  }

  void _rebuildAll() {
    if (!mounted) return;
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

extension CurrencyContext on BuildContext {
  /// [amount] (in [from], INR by default) shown in the selected currency,
  /// e.g. `₹4,820`, `$58`. Falls back to [from] when no rate is available.
  String money(num amount, {String from = 'INR'}) {
    return CurrencyConverter.display(amount.toDouble(), fromCurrency: from);
  }

  /// Like [money] for a value that may be text such as `'8,222'`;
  /// unparseable values are returned as they are.
  String moneyOf(Object? value, {String from = 'INR'}) {
    final n = value is num ? value : num.tryParse('$value'.replaceAll(RegExp(r'[^0-9.\-]'), ''));
    return n == null ? '$value' : money(n, from: from);
  }

  /// [amount] converted to the selected currency, as a number.
  double convertMoney(num amount, {String from = 'INR'}) {
    final to = CurrencyConverter.getPreferredCurrency();
    if (!CurrencyConverter.canConvert(from, to)) return amount.toDouble();
    return CurrencyConverter.convert(amount: amount.toDouble(), fromCurrency: from, toCurrency: to);
  }

  /// "≈ $58" next to a rupee amount that is charged in INR; empty when the
  /// user's currency is INR (or no rate is cached).
  String moneyHint(num inrAmount) {
    final to = CurrencyConverter.getPreferredCurrency();
    if (to == 'INR' || !CurrencyConverter.canConvert('INR', to)) return '';
    return '≈ ${CurrencyConverter.display(inrAmount.toDouble())}';
  }

  /// Symbol of the selected currency, e.g. `₹`, `$`.
  String get currencySymbol {
    return CurrencyConverter.getSymbol(CurrencyConverter.getPreferredCurrency()).trim();
  }
}
