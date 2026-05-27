import '../../../../../core/error/data_state.dart';
import '../repository/exchange_rate_repository.dart';

class ConvertCurrencyUseCase {
  final ExchangeRateRepository repository;

  ConvertCurrencyUseCase(this.repository);

  Future<DataState<double>> call({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    return repository.convertCurrency(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
  }
}