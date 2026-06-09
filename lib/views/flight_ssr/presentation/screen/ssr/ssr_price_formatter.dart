import '../../../../../UI_helper/currency_converter.dart';
import '../../../../../core/utils/storage/shared_preference.dart';
import '../../../../../injection_container.dart' as di;

class SsrPriceFormatter {
  static String format(double amount, String currency) {
    if (amount <= 0) return 'Free';
    try {
      final targetCurrency =
          di.sl<PreferencesManager>().getPreferredCurrency() ?? 'INR';
      final sourceCurrency = currency.isEmpty ? 'INR' : currency;
      final converted =
          sourceCurrency.toUpperCase() == targetCurrency.toUpperCase()
          ? amount
          : CurrencyConverter.convert(
              amount: amount,
              fromCurrency: sourceCurrency,
              toCurrency: targetCurrency,
            );
      return CurrencyConverter.format(converted, targetCurrency);
    } catch (_) {
      return CurrencyConverter.format(amount, currency);
    }
  }

  static String unit(double amount, String currency, String suffix) {
    if (amount <= 0) return '';
    return '${format(amount, currency)}/$suffix';
  }

  static double convertAmount(double amount, String currency) {
    try {
      final targetCurrency =
          di.sl<PreferencesManager>().getPreferredCurrency() ?? 'INR';
      final sourceCurrency = currency.isEmpty ? 'INR' : currency;
      if (sourceCurrency.toUpperCase() == targetCurrency.toUpperCase()) {
        return amount;
      }
      return CurrencyConverter.convert(
        amount: amount,
        fromCurrency: sourceCurrency,
        toCurrency: targetCurrency,
      );
    } catch (_) {
      return amount;
    }
  }

  static String preferredCurrency([String fallback = 'INR']) {
    try {
      return di.sl<PreferencesManager>().getPreferredCurrency() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
