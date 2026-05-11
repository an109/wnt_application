import 'package:equatable/equatable.dart';

abstract class SsrEvent extends Equatable {
  const SsrEvent();

  @override
  List<Object> get props => [];
}

class LoadSsrData extends SsrEvent {
  final String endUserIp;
  final String traceId;
  final String tokenId;
  final String resultIndex;

  const LoadSsrData({
    required this.endUserIp,
    required this.traceId,
    required this.tokenId,
    required this.resultIndex,
  });

  @override
  List<Object> get props => [endUserIp, traceId, tokenId, resultIndex];
}