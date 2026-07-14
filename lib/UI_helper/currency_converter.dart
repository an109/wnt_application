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

  static bool isAutoDetectEnabled() {
    final prefs = sl<PreferencesManager>();
    return prefs.isCurrencyAutoDetect();
  }

  /// User explicitly picked a currency from settings — stop following IP location.
  static Future<void> setManualCurrency(String currency) async {
    final prefs = sl<PreferencesManager>();
    await prefs.savePreferredCurrency(currency);
    await prefs.setCurrencyAutoDetect(false);
  }

  /// User picked "Auto" from settings — re-detect from IP and follow it again.
  static Future<String> enableAutoDetect() async {
    await ExchangeRateService.refreshCurrencyFromLocation();
    return getPreferredCurrency();
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

  static String format(double amount, String currency) {
    final symbols = {
      'INR': '₹',
      'USD': '\$',
      'AED': 'د.إ',
      'EUR': '€',
      'GBP': '£',
    };
    final symbol = symbols[currency.toUpperCase()] ?? '$currency ';
    final priceStr = amount.toStringAsFixed(0);

    final buffer = StringBuffer();
    final len = priceStr.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0 && len > 3) {
        buffer.write(',');
      }
      buffer.write(priceStr[i]);
    }
    return '$symbol$buffer';
  }

  // Add to your existing CurrencyConverter class
  static String getPreferredCurrency() {
    final prefs = sl<PreferencesManager>();
    return prefs.getPreferredCurrency() ?? 'USD';
  }

  static Future<void> setPreferredCurrency(String currency) async {
    final prefs = sl<PreferencesManager>();
    await prefs.savePreferredCurrency(currency);
  }

  static Future<double> convertAmountWithPreferredCurrency(double amountInUSD) async {
    final prefs = sl<PreferencesManager>();
    final targetCurrency = prefs.getPreferredCurrency() ?? 'USD';

    if (targetCurrency == 'USD') return amountInUSD;

    final rates = prefs.getCachedExchangeRates();
    if (rates == null) return amountInUSD;

    final targetRate = rates[targetCurrency];
    if (targetRate == null) return amountInUSD;

    // Convert USD to target currency
    return amountInUSD * targetRate;
  }

  static String getSymbol(String currency) {
    final symbols = {
      'INR': '₹',
      'USD': '\$',
      'AED': 'د.إ',
      'EUR': '€',
      'GBP': '£',
    };
    return symbols[currency.toUpperCase()] ?? '$currency ';
  }
}