import 'package:equatable/equatable.dart';

abstract class FareQuoteEvent extends Equatable {
  const FareQuoteEvent();

  @override
  List<Object?> get props => [];
}

class FetchFareQuote extends FareQuoteEvent {
  final String endUserIp;
  final String traceId;
  final String tokenId;
  final String resultIndex;

  const FetchFareQuote({
    required this.endUserIp,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
  });

  @override
  List<Object?> get props => [endUserIp, traceId, tokenId, resultIndex];
}