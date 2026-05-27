import '../../../../../core/error/data_state.dart';
import '../entity/exchange_rate_entity.dart';
import '../repository/exchange_rate_repository.dart';

class GetExchangeRatesUseCase {
  final ExchangeRateRepository repository;

  GetExchangeRatesUseCase(this.repository);

  Future<DataState<ExchangeRateEntity>> call({String? apiUrl}) {
    return repository.getExchangeRates(apiUrl: apiUrl);
  }
}