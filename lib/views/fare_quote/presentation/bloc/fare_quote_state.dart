import 'package:equatable/equatable.dart';
import '../../domain/entities/fare_quote_entity.dart';

abstract class FareQuoteState extends Equatable {
  const FareQuoteState();

  @override
  List<Object?> get props => [];
}

class FareQuoteInitial extends FareQuoteState {}

class FareQuoteLoading extends FareQuoteState {}

class FareQuoteLoaded extends FareQuoteState {
  final FareQuoteEntity fareQuote;

  const FareQuoteLoaded(this.fareQuote);

  @override
  List<Object?> get props => [fareQuote];
}

class FareQuoteError extends FareQuoteState {
  final String message;

  const FareQuoteError(this.message);

  @override
  List<Object?> get props => [message];
}