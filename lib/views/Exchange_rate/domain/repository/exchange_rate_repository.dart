import '../../../../../core/error/data_state.dart';
import '../entity/exchange_rate_entity.dart';

abstract class ExchangeRateRepository {
  Future<DataState<ExchangeRateEntity>> getExchangeRates({String? apiUrl});
  Future<DataState<double>> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  });
}