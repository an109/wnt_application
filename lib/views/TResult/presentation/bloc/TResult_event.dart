import 'package:equatable/equatable.dart';

abstract class TransportResultEvent extends Equatable {
  const TransportResultEvent();

  @override
  List<Object?> get props => [];
}

class GetTransportResultEvent extends TransportResultEvent {
  final String searchId;
  final String resultId;

  const GetTransportResultEvent({
    required this.searchId,
    required this.resultId,
  });

  @override
  List<Object?> get props => [searchId, resultId];

  @override
  String toString() =>
      'GetTransportResultEvent(searchId: $searchId, resultId: $resultId)';
}