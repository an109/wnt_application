import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/storage/shared_preference.dart';
import '../../injection_container.dart';
import 'geo_location_services.dart';

class ExchangeRateService {
  static const String _exchangeRateApiUrl = 'https://open.er-api.com/v6/latest/';

  /// Fetch latest exchange rates for base currency (usually USD)
  static Future<Map<String, double>?> fetchExchangeRates({String base = 'USD'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_exchangeRateApiUrl$base'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        final result = <String, double>{};
        for (final entry in rates.entries) {
          if (entry.value is num) {
            result[entry.key] = (entry.value as num).toDouble();
          }
        }

        // Cache the rates
        final prefs = sl<PreferencesManager>();
        await prefs.setString('exchange_rates_cache', jsonEncode(result));
        await prefs.setString('exchange_rates_updated', DateTime.now().toIso8601String());

        return result;
      }
    } catch (e) {
      print('⚠️ Failed to fetch exchange rates: $e');
    }

    // Return cached rates as fallback
    final prefs = sl<PreferencesManager>();
    return prefs.getCachedExchangeRates();
  }

  /// Get rates with cache (don't fetch too often)
  static Future<Map<String, double>?> getRatesWithCache({bool forceRefresh = false}) async {
    final prefs = sl<PreferencesManager>();

    if (!forceRefresh) {
      // Check if rates are fresh (less than 1 hour old)
      final lastUpdated = prefs.getString('exchange_rates_updated');
      if (lastUpdated != null) {
        final updatedTime = DateTime.parse(lastUpdated);
        if (DateTime.now().difference(updatedTime).inHours < 1) {
          return prefs.getCachedExchangeRates();
        }
      }
    }

    return await fetchExchangeRates();
  }

  /// Initialize user's preferred currency based on IP.
  ///
  /// Runs on every app launch, but only actually re-detects location when
  /// auto-detect is still on (first-ever launch, or the user hasn't manually
  /// picked a currency). This is what keeps the shown currency in sync when
  /// the device changes country — previously this bailed out permanently
  /// after the very first detection, so e.g. a phone first used in Dubai
  /// kept showing AED forever even after traveling to India. A user who has
  /// explicitly chosen a currency (auto-detect off) is left untouched.
  static Future<void> initializeUserCurrency() async {
    final prefs = sl<PreferencesManager>();

    final hasSavedPreference = prefs.getPreferredCurrency() != null;
    if (hasSavedPreference && !prefs.isCurrencyAutoDetect()) {
      // User manually chose a currency — don't override their choice.
      return;
    }

    // First launch, or auto-detect is still on: (re-)detect from IP.
    final geoInfo = await GeoLocationService.detectRegion();
    await prefs.savePreferredCurrency(geoInfo.currencyCode);
    await prefs.setCurrencyAutoDetect(true);
    print('💰 Preferred currency set to: ${geoInfo.currencyCode} based on IP');

    // Fetch exchange rates in background
    await getRatesWithCache(forceRefresh: true);
  }

  /// Force a fresh IP-based lookup and switch back to auto-detected currency.
  /// Used when the user explicitly picks "Auto (detect by location)" in settings.
  static Future<void> refreshCurrencyFromLocation() async {
    final prefs = sl<PreferencesManager>();
    final geoInfo = await GeoLocationService.detectRegion();
    await prefs.savePreferredCurrency(geoInfo.currencyCode);
    await prefs.setCurrencyAutoDetect(true);
    await getRatesWithCache(forceRefresh: true);
  }
}