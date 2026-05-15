import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/TResult_entity.dart';

abstract class TransportResultState extends Equatable {
  const TransportResultState();

  @override
  List<Object?> get props => [];
}

class TransportResultInitial extends TransportResultState {
  const TransportResultInitial();
}

class TransportResultLoading extends TransportResultState {
  const TransportResultLoading();
}

class TransportResultSuccess extends TransportResultState {
  final TransportResultEntity transportResult;

  const TransportResultSuccess(this.transportResult);

  @override
  List<Object?> get props => [transportResult];
}

class TransportResultFailure extends TransportResultState {
  final DataState<dynamic> error;

  const TransportResultFailure(this.error);

  @override
  List<Object?> get props => [error];
}