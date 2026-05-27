import 'package:equatable/equatable.dart';
import '../../domain/entity/exchange_rate_entity.dart';

abstract class ExchangeRateState extends Equatable {
  const ExchangeRateState();

  @override
  List<Object?> get props => [];
}

class ExchangeRateInitial extends ExchangeRateState {}

class ExchangeRateLoading extends ExchangeRateState {}

class ExchangeRateLoaded extends ExchangeRateState {
  final ExchangeRateEntity exchangeRates;

  const ExchangeRateLoaded(this.exchangeRates);

  @override
  List<Object?> get props => [exchangeRates];
}

class ExchangeRateConversionComplete extends ExchangeRateState {
  final double convertedAmount;
  final String fromCurrency;
  final String toCurrency;

  const ExchangeRateConversionComplete({
    required this.convertedAmount,
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [convertedAmount, fromCurrency, toCurrency];
}

class ExchangeRateError extends ExchangeRateState {
  final String message;

  const ExchangeRateError(this.message);

  @override
  List<Object?> get props => [message];
}

class ExchangeRateCacheCleared extends ExchangeRateState {}