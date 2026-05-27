import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../../core/error/data_state.dart';
import '../../domain/entity/exchange_rate_entity.dart';
import '../../domain/repository/exchange_rate_repository.dart';
import '../data_source/exchange_rate_api_service.dart';
import '../models/exchange_rate_model.dart';
import '../../../../../core/utils/storage/shared_preference.dart';
import '../../../../../injection_container.dart' as injection;

class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  final ExchangeRateApiService apiService;
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _cacheTimeKey = 'exchange_rates_cache_time';
  static const int _cacheDurationHours = 24;

  ExchangeRateRepositoryImpl(this.apiService);

  @override
  Future<DataState<ExchangeRateEntity>> getExchangeRates({String? apiUrl}) async {
    try {
      // Check memory cache first (static)
      if (_memoryCache != null) {
        return DataSuccess(ExchangeRateModel(
          result: 'success',
          documentation: '',
          termsOfUse: '',
          timeLastUpdateUnix: '',
          timeLastUpdateUtc: '',
          timeNextUpdateUnix: '',
          timeNextUpdateUtc: '',
          baseCode: 'USD',
          conversionRates: _memoryCache!,
        ));
      }

      // Check persistent cache
      final prefs = injection.sl<PreferencesManager>();
      final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - cacheTime < _cacheDurationHours * 3600 * 1000) {
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          final decoded = _parseRates(cached);
          _memoryCache = decoded;
          return DataSuccess(ExchangeRateModel(
            result: 'success',
            documentation: '',
            termsOfUse: '',
            timeLastUpdateUnix: '',
            timeLastUpdateUtc: '',
            timeNextUpdateUnix: '',
            timeNextUpdateUtc: '',
            baseCode: 'USD',
            conversionRates: decoded,
          ));
        }
      }

      // Fetch from primary API
      final response = await apiService.fetchExchangeRates(apiUrl: apiUrl);

      if (response.data['result'] == 'success') {
        final rates = _extractRates(response.data);
        await _saveCache(prefs, rates);
        _memoryCache = rates;

        final model = ExchangeRateModel.fromJson(response.data);
        return DataSuccess(model);
      } else {
        // Try fallback API
        final fallbackResponse = await apiService.fetchExchangeRates(
          apiUrl: 'https://open.er-api.com/v6/latest/USD',
        );

        if (fallbackResponse.data['result'] == 'success') {
          final rates = _extractRates(fallbackResponse.data, key: 'rates');
          await _saveCache(prefs, rates);
          _memoryCache = rates;

          return DataSuccess(ExchangeRateModel(
            result: 'success',
            documentation: '',
            termsOfUse: '',
            timeLastUpdateUnix: '',
            timeLastUpdateUtc: '',
            timeNextUpdateUnix: '',
            timeNextUpdateUtc: '',
            baseCode: 'USD',
            conversionRates: rates,
          ));
        }
        throw DioException(
          requestOptions: RequestOptions(path: apiUrl ?? ''),
          error: 'Failed to fetch exchange rates from both APIs',
          type: DioExceptionType.badResponse,
          response: fallbackResponse,
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: apiUrl ?? ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<double>> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return DataSuccess(amount);
    }

    final ratesResult = await getExchangeRates();

    if (ratesResult is DataFailed) {
      return DataFailed(ratesResult.error!);
    }

    final rates = (ratesResult as DataSuccess).data!.conversionRates;
    final fromRate = rates[fromCurrency.toUpperCase()];
    final toRate = rates[toCurrency.toUpperCase()];

    if (fromRate == null || toRate == null) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Currency code not found: ${fromRate == null ? fromCurrency : toCurrency}',
          type: DioExceptionType.badResponse,
        ),
      );
    }

    // Formula: (amount / fromRate) * toRate
    final converted = (amount / fromRate) * toRate;
    return DataSuccess(converted);
  }

  Map<String, double> _extractRates(Map<String, dynamic> data, {String key = 'conversion_rates'}) {
    // Try 'conversion_rates' first (exchangerate-api.com format)
    var rates = data[key] as Map<String, dynamic>?;

    // Fallback to 'rates' (open.er-api.com format)
    if (rates == null || rates.isEmpty) {
      rates = data['rates'] as Map<String, dynamic>?;
    }

    if (rates == null) return {};

    return rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Map<String, double> _parseRates(String cached) {

    final decoded = jsonDecode(cached) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> _saveCache(PreferencesManager prefs, Map<String, double> rates) async {

    await prefs.setString(_cacheKey, jsonEncode(rates));
    await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Static memory cache
  static Map<String, double>? _memoryCache;

  static void clearMemoryCache() {
    _memoryCache = null;
  }
}