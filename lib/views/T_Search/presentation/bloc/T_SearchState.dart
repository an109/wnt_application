import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/T_SearchEntity.dart';

abstract class TransportSearchState extends Equatable {
  const TransportSearchState();

  @override
  List<Object?> get props => [];
}

class TransportSearchInitial extends TransportSearchState {
  const TransportSearchInitial();
}

class TransportSearchLoading extends TransportSearchState {
  const TransportSearchLoading();
}

class TransportSearchSuccess extends TransportSearchState {
  final TransportSearchEntity transportSearch; // Changed from TransportSearchModel

  const TransportSearchSuccess(this.transportSearch);

  @override
  List<Object?> get props => [transportSearch];
}

class TransportSearchFailed extends TransportSearchState {
  final DataState<dynamic> dataState;

  const TransportSearchFailed(this.dataState);

  @override
  List<Object?> get props => [dataState];
}