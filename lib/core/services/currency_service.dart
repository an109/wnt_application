import 'package:dio/dio.dart';

/// Live currency conversion using exchangerate-api.com.
/// Rates are cached in-memory for 6 hours (same TTL as the backend).
class CurrencyService {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  static const String _apiKey = '5dff9de8575af8e0fcbeb0c5';
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6';
  static const Duration _cacheTtl = Duration(hours: 6);

  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
  final Map<String, _CachedRate> _cache = {};

  /// Returns the exchange rate from [from] to [to].
  /// Falls back to the last cached rate if the API call fails.
  Future<double> getRate(String from, String to) async {
    final fromU = from.trim().toUpperCase();
    final toU = to.trim().toUpperCase();

    if (fromU == toU) return 1.0;

    final key = '${fromU}_$toU';
    final cached = _cache[key];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.rate;
    }

    try {
      final response = await _dio.get('$_baseUrl/$_apiKey/pair/$fromU/$toU');
      if (response.data['result'] == 'success') {
        final rate = (response.data['conversion_rate'] as num).toDouble();
        _cache[key] = _CachedRate(rate, DateTime.now().add(_cacheTtl));
        return rate;
      }
    } catch (e) {
      // API failed — use stale cache if available
      if (cached != null) return cached.rate;
    }

    // Stale cache
    if (cached != null) return cached.rate;

    // Last resort: return 1.0 (no conversion, show original)
    return 1.0;
  }

  /// Converts [amount] from [fromCurrency] to INR.
  /// Returns the original amount unchanged if already INR.
  Future<double> toInr(double amount, String fromCurrency) async {
    if (fromCurrency.trim().toUpperCase() == 'INR') return amount;
    final rate = await getRate(fromCurrency, 'INR');
    return amount * rate;
  }

  /// Returns ₹ symbol for INR, otherwise the currency code.
  static String symbol(String currency) {
    switch (currency.trim().toUpperCase()) {
      case 'INR': return '₹';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'AED': return 'AED';
      default:    return currency.toUpperCase();
    }
  }
}

class _CachedRate {
  final double rate;
  final DateTime expiresAt;
  _CachedRate(this.rate, this.expiresAt);
}
