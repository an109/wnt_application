import '../../UI_helper/currency_converter.dart';
import 'exchange_rate_service.dart';

/// Pair rates for screens that need one number (e.g. visa fees to INR).
/// Uses the app-wide rates from our backend (see [ExchangeRateService]); the
/// app no longer holds an exchange-rate API key.
class CurrencyService {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  /// Rate from [from] to [to]. Returns 1.0 when no rate is available, so
  /// callers that charge money must treat 1.0 for different currencies as
  /// "unknown" (the visa checkout does).
  Future<double> getRate(String from, String to) async {
    final fromU = from.trim().toUpperCase();
    final toU = to.trim().toUpperCase();
    if (fromU == toU) return 1.0;
    if (!CurrencyConverter.canConvert(fromU, toU)) {
      await ExchangeRateService.getRatesWithCache(forceRefresh: true);
    }
    if (!CurrencyConverter.canConvert(fromU, toU)) return 1.0;
    return CurrencyConverter.convert(amount: 1, fromCurrency: fromU, toCurrency: toU);
  }

  /// Converts [amount] from [fromCurrency] to INR.
  Future<double> toInr(double amount, String fromCurrency) async {
    if (fromCurrency.trim().toUpperCase() == 'INR') return amount;
    return amount * await getRate(fromCurrency, 'INR');
  }

  static String symbol(String currency) => CurrencyConverter.getSymbol(currency).trim();
}
