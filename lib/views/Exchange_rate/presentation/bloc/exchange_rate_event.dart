import 'package:equatable/equatable.dart';

abstract class ExchangeRateEvent extends Equatable {
  const ExchangeRateEvent();

  @override
  List<Object?> get props => [];
}

class FetchExchangeRates extends ExchangeRateEvent {
  final String? apiUrl;

  const FetchExchangeRates({this.apiUrl});

  @override
  List<Object?> get props => [apiUrl];
}

class ConvertCurrency extends ExchangeRateEvent {
  final double amount;
  final String fromCurrency;
  final String toCurrency;

  const ConvertCurrency({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [amount, fromCurrency, toCurrency];
}

class ClearExchangeRateCache extends ExchangeRateEvent {}