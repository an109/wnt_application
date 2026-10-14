import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/utils/storage/shared_preference.dart';
import '../core/services/exchange_rate_service.dart';
import '../injection_container.dart';

class CurrencyConverter {
  /// Currencies selectable from the app's currency setting.
  static const Map<String, String> supportedCurrencies = {
    'USD': 'US Dollar',
    'INR': 'Indian Rupee',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'AED': 'UAE Dirham',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'SGD': 'Singapore Dollar',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
  };

  /// Broadcasts the current preferred currency. Screens that show a price
  /// should wrap that part of their UI in a `ValueListenableBuilder` on this
  /// so they update the moment the user changes currency, instead of only
  /// picking it up on their next full rebuild (e.g. a fresh navigation).
  static final ValueNotifier<String> currencyListenable =
      ValueNotifier<String>(getPreferredCurrency());

  /// Bumped whenever fresh exchange rates are cached, so converted prices
  /// redraw even when the selected currency itself didn't change.
  static final ValueNotifier<int> ratesVersion = ValueNotifier<int>(0);

  /// Fires on a currency switch or a rate refresh — listen to this around
  /// any converted price.
  static final Listenable changes = Listenable.merge([currencyListenable, ratesVersion]);

  /// Whether [from] → [to] can be converted with the cached rates.
  static bool canConvert(String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return true;
    final rates = sl<PreferencesManager>().getCachedExchangeRates();
    return rates != null && rates[from.toUpperCase()] != null && rates[to.toUpperCase()] != null;
  }

  static bool isAutoDetectEnabled() {
    final prefs = sl<PreferencesManager>();
    return prefs.isCurrencyAutoDetect();
  }

  /// User explicitly picked a currency from settings — stop following IP location.
  static Future<void> setManualCurrency(String currency) async {
    final prefs = sl<PreferencesManager>();
    await prefs.savePreferredCurrency(currency);
    await prefs.setCurrencyAutoDetect(false);
    currencyListenable.value = currency;
    // Make sure rates for the new currency are on hand.
    ExchangeRateService.getRatesWithCache();
  }

  /// User picked "Auto" from settings — re-detect from IP and follow it again.
  static Future<String> enableAutoDetect() async {
    await ExchangeRateService.refreshCurrencyFromLocation();
    final currency = getPreferredCurrency();
    currencyListenable.value = currency;
    return currency;
  }
  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) return amount;

    final prefs = sl<PreferencesManager>();
    final rates = prefs.getCachedExchangeRates();

    // print('💱 DEBUG: from=$fromCurrency, to=$toCurrency, rates?=${rates != null}');
    if (rates != null) {
      // print('💱 DEBUG: AED=${rates['AED']}, INR=${rates['INR']}');
    }

    if (rates == null) return amount;
    final fromRate = rates[fromCurrency.toUpperCase()];
    final toRate = rates[toCurrency.toUpperCase()];
    if (fromRate == null || toRate == null) return amount;

    final result = (amount / fromRate) * toRate;
    // print('💱 CONVERTED: $amount $fromCurrency → $result $toCurrency');
    return result;
  }

  /// `₹12,34,567` (Indian grouping) or `$1,234`; cents only below 100.
  static String format(double amount, String currency) {
    final code = currency.toUpperCase();
    final f = NumberFormat.decimalPattern(code == 'INR' ? 'en_IN' : 'en_US')
      ..maximumFractionDigits = amount.abs() < 100 && code != 'INR' && code != 'JPY' ? 2 : 0
      ..minimumFractionDigits = 0;
    return '${getSymbol(code)}${f.format(amount)}';
  }

  // Add to your existing CurrencyConverter class
  static String getPreferredCurrency() {
    final prefs = sl<PreferencesManager>();
    return prefs.getPreferredCurrency() ?? 'INR';
  }

  static Future<void> setPreferredCurrency(String currency) async {
    final prefs = sl<PreferencesManager>();
    await prefs.savePreferredCurrency(currency);
    currencyListenable.value = currency;
  }

  static Future<double> convertAmountWithPreferredCurrency(double amountInUSD) async {
    final prefs = sl<PreferencesManager>();
    final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';

    if (targetCurrency == 'USD') return amountInUSD;

    final rates = prefs.getCachedExchangeRates();
    if (rates == null) return amountInUSD;

    final targetRate = rates[targetCurrency];
    if (targetRate == null) return amountInUSD;

    // Convert USD to target currency
    return amountInUSD * targetRate;
  }

  /// Flag emoji for the country/region that issues [currency]. Used by the
  /// chips that show the active currency so the flag tracks whatever the
  /// user picked in the drawer's currency picker instead of being hardcoded.
  /// Unknown codes fall back to a neutral white flag rather than throwing.
  static const Map<String, String> _currencyFlags = {
    'USD': '\u{1F1FA}\u{1F1F8}',
    'INR': '\u{1F1EE}\u{1F1F3}',
    'EUR': '\u{1F1EA}\u{1F1FA}',
    'GBP': '\u{1F1EC}\u{1F1E7}',
    'AED': '\u{1F1E6}\u{1F1EA}',
    'AUD': '\u{1F1E6}\u{1F1FA}',
    'CAD': '\u{1F1E8}\u{1F1E6}',
    'SGD': '\u{1F1F8}\u{1F1EC}',
    'JPY': '\u{1F1EF}\u{1F1F5}',
    'CNY': '\u{1F1E8}\u{1F1F3}',
  };

  static String getFlag(String currency) =>
      _currencyFlags[currency.toUpperCase()] ?? '\u{1F3F3}\u{FE0F}';

  static const Map<String, String> _symbols = {
    'INR': '₹',
    'USD': '\$',
    'AED': 'د.إ ',
    'EUR': '€',
    'GBP': '£',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'SGD': 'S\$',
    'JPY': '¥',
    'CNY': 'CN¥',
  };

  static String getSymbol(String currency) => _symbols[currency.toUpperCase()] ?? '${currency.toUpperCase()} ';

  /// [amount] in [fromCurrency] shown in the user's currency, e.g. "$120".
  /// Without a usable rate it stays in [fromCurrency] rather than showing a
  /// wrong number with the wrong symbol.
  static String display(double amount, {String fromCurrency = 'INR', String? toCurrency}) {
    final to = toCurrency ?? getPreferredCurrency();
    if (!canConvert(fromCurrency, to)) return format(amount, fromCurrency);
    return format(convert(amount: amount, fromCurrency: fromCurrency, toCurrency: to), to);
  }
}