import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/akflight_search_entity.dart';

abstract class AkFlightSearchState extends Equatable {
  const AkFlightSearchState();

  @override
  List<Object?> get props => [];
}

class AkFlightSearchInitial extends AkFlightSearchState {
  const AkFlightSearchInitial();
}

class AkFlightSearchLoading extends AkFlightSearchState {
  const AkFlightSearchLoading();
}

class AkFlightSearchSuccess extends AkFlightSearchState {
  final AkFlightSearchEntity result;

  const AkFlightSearchSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class AkFlightSearchFailed extends AkFlightSearchState {
  final String errorMessage;

  const AkFlightSearchFailed(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class AkFlightSearchDataState extends AkFlightSearchState {
  final DataState<AkFlightSearchEntity> dataState;

  const AkFlightSearchDataState(this.dataState);

  @override
  List<Object?> get props => [dataState];
}