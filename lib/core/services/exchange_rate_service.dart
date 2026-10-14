import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/storage/shared_preference.dart';
import '../../injection_container.dart';
import 'geo_location_services.dart';
import '../constants/urls.dart';
import '../../UI_helper/currency_converter.dart';

class ExchangeRateService {
  static const _updatedKey = 'exchange_rates_updated';
  static const _freshFor = Duration(hours: 1);

  static Future<Map<String, double>?>? _inFlight;

  /// Fetches USD-based rates from our backend (falling back to the public
  /// feed), caches them for [CurrencyConverter] and tells listening screens.
  /// Concurrent callers share one request.
  static Future<Map<String, double>?> fetchExchangeRates() {
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  static Future<Map<String, double>?> _fetch() async {
    for (final url in [Urls.exchangeRatePrimary, Urls.exchangeRateFallback, Urls.exchangeRateLastResort]) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) continue;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = (data['rates'] ?? data['conversion_rates']) as Map<String, dynamic>?;
        if (rates == null || rates.isEmpty) continue;
        final result = <String, double>{
          for (final e in rates.entries)
            if (e.value is num) e.key.toUpperCase(): (e.value as num).toDouble(),
        };
        final prefs = sl<PreferencesManager>();
        await prefs.setString('exchange_rates_cache', jsonEncode(result));
        await prefs.setString(_updatedKey, DateTime.now().toIso8601String());
        // Keep the ExchangeRate bloc's freshness stamp in step.
        await prefs.setInt('exchange_rates_cache_time', DateTime.now().millisecondsSinceEpoch);
        CurrencyConverter.ratesVersion.value++;
        return result;
      } catch (e) {
        print('⚠️ Exchange rates from $url failed: $e');
      }
    }
    return sl<PreferencesManager>().getCachedExchangeRates();
  }

  /// Cached rates when fresh, otherwise a new fetch.
  static Future<Map<String, double>?> getRatesWithCache({bool forceRefresh = false}) async {
    final prefs = sl<PreferencesManager>();
    final cached = prefs.getCachedExchangeRates();
    if (!forceRefresh && cached != null) {
      final updated = DateTime.tryParse(prefs.getString(_updatedKey) ?? '');
      if (updated != null && DateTime.now().difference(updated) < _freshFor) return cached;
    }
    return fetchExchangeRates();
  }

  /// Initialize user's preferred currency.
  ///
  /// First-ever launch now defaults to INR instead of IP-geolocation — no
  /// silent network lookup before the user has chosen anything. IP-based
  /// detection only runs on later launches if the user has explicitly turned
  /// on "Auto (detect by location)" from the currency picker; a user who
  /// manually picked a currency (auto-detect off) is left untouched.
  static Future<void> initializeUserCurrency() async {
    final prefs = sl<PreferencesManager>();

    final hasSavedPreference = prefs.getPreferredCurrency() != null;
    if (!hasSavedPreference) {
      // First launch: default to INR, no geolocation lookup.
      await prefs.savePreferredCurrency('INR');
      await prefs.setCurrencyAutoDetect(false);
      unawaited(getRatesWithCache(forceRefresh: true));
      return;
    }

    if (!prefs.isCurrencyAutoDetect()) {
      // User manually chose a currency — don't override their choice, but
      // keep the rates current (in the background; start-up never waits).
      unawaited(getRatesWithCache());
      return;
    }

    // User previously enabled auto-detect: re-detect from IP.
    final geoInfo = await GeoLocationService.detectRegion();
    await prefs.savePreferredCurrency(geoInfo.currencyCode);
    await prefs.setCurrencyAutoDetect(true);
    print('💰 Preferred currency set to: ${geoInfo.currencyCode} based on IP');

    // Fetch exchange rates in background
    unawaited(getRatesWithCache(forceRefresh: true));
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