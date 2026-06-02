import 'dart:convert';
import 'package:http/http.dart' as http;


class GeoLocationService {
  static const String _ipApiUrl = 'https://ipapi.co/json/';
  static const String _ipInfoUrl = 'https://ipinfo.io/json';

  // Cache the detected country/currency
  static String? _cachedCountryCode;
  static String? _cachedCurrencyCode;

  /// Detect user's country and preferred currency from IP
  static Future<GeoInfo> detectRegion() async {
    try {
      // Try ipapi.co first (free, no key required)
      final response = await http.get(Uri.parse(_ipApiUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countryCode = data['country_code'] as String?;
        final currency = data['currency'] as String?;

        if (countryCode != null && currency != null) {
          _cachedCountryCode = countryCode;
          _cachedCurrencyCode = currency;
          return GeoInfo(countryCode: countryCode, currencyCode: currency);
        }
      }

      // Fallback to ipinfo.io
      final fallbackResponse = await http.get(Uri.parse(_ipInfoUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (fallbackResponse.statusCode == 200) {
        final data = jsonDecode(fallbackResponse.body);
        final countryCode = data['country'] as String?;
        // ipinfo.io doesn't give currency directly, map from country
        final currency = _getCurrencyForCountry(countryCode);

        if (countryCode != null && currency != null) {
          _cachedCountryCode = countryCode;
          _cachedCurrencyCode = currency;
          return GeoInfo(countryCode: countryCode, currencyCode: currency);
        }
      }
    } catch (e) {
      print('⚠️ IP detection failed: $e');
    }

    // Default to INR for India or USD as fallback
    return const GeoInfo(countryCode: 'IN', currencyCode: 'INR');
  }

  static String? _getCurrencyForCountry(String? countryCode) {
    const countryCurrency = {
      'IN': 'INR', 'US': 'USD', 'GB': 'GBP', 'EU': 'EUR',
      'AE': 'AED', 'CA': 'CAD', 'AU': 'AUD', 'SG': 'SGD',
      'JP': 'JPY', 'CN': 'CNY', 'DE': 'EUR', 'FR': 'EUR',
      'IT': 'EUR', 'ES': 'EUR', 'NL': 'EUR', 'BE': 'EUR',
    };
    return countryCurrency[countryCode] ?? 'USD';
  }

  /// Get cached or fetch fresh region info
  static Future<GeoInfo> getRegion() async {
    if (_cachedCountryCode != null && _cachedCurrencyCode != null) {
      return GeoInfo(
        countryCode: _cachedCountryCode!,
        currencyCode: _cachedCurrencyCode!,
      );
    }
    return await detectRegion();
  }
}

class GeoInfo {
  final String countryCode;
  final String currencyCode;

  const GeoInfo({required this.countryCode, required this.currencyCode});
}