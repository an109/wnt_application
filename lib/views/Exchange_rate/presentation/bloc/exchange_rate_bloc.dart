import 'package:bloc/bloc.dart';
import '../../../../../core/error/data_state.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../data/repository/exchange_rate_repository_impl.dart';
import '../../domain/entity/exchange_rate_entity.dart';
import '../../domain/usecase/convert_currency_usecase.dart';
import '../../domain/usecase/get_exchange_rates_usecase.dart';
import 'exchange_rate_event.dart';
import 'exchange_rate_state.dart';

class ExchangeRateBloc extends Bloc<ExchangeRateEvent, ExchangeRateState> {
  final GetExchangeRatesUseCase getExchangeRatesUseCase;
  final ConvertCurrencyUseCase convertCurrencyUseCase;

  ExchangeRateBloc({
    required this.getExchangeRatesUseCase,
    required this.convertCurrencyUseCase,
  }) : super(ExchangeRateInitial()) {
    on<FetchExchangeRates>(_onFetchExchangeRates);
    on<ConvertCurrency>(_onConvertCurrency);
    on<ClearExchangeRateCache>(_onClearCache);
  }

  Future<void> _onFetchExchangeRates(
      FetchExchangeRates event,
      Emitter<ExchangeRateState> emit,
      ) async {
    emit(ExchangeRateLoading());

    final result = await getExchangeRatesUseCase(apiUrl: event.apiUrl);

    if (result is DataSuccess<ExchangeRateEntity>) {
      emit(ExchangeRateLoaded(result.data!));
    } else if (result is DataFailed<ExchangeRateEntity>) {
      final errorMessage = result.error?.message ?? 'Failed to fetch exchange rates';
      emit(ExchangeRateError(errorMessage));
    }
  }

  Future<void> _onConvertCurrency(
      ConvertCurrency event,
      Emitter<ExchangeRateState> emit,
      ) async {
    emit(ExchangeRateLoading());

    final result = await convertCurrencyUseCase(
      amount: event.amount,
      fromCurrency: event.fromCurrency,
      toCurrency: event.toCurrency,
    );

    if (result is DataSuccess<double>) {
      emit(ExchangeRateConversionComplete(
        convertedAmount: result.data!,
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
      ));
    } else if (result is DataFailed<double>) {
      final errorMessage = result.error?.message ?? 'Failed to convert currency';
      emit(ExchangeRateError(errorMessage));
    }
  }

  Future<void> _onClearCache(
      ClearExchangeRateCache event,
      Emitter<ExchangeRateState> emit,
      ) async {
    ExchangeRateRepositoryImpl.clearMemoryCache();

    final prefs = sl<PreferencesManager>();
    await prefs.remove('exchange_rates_cache');
    await prefs.remove('exchange_rates_cache_time');

    emit(ExchangeRateCacheCleared());
  }
}