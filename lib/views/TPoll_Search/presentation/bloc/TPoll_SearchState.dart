import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/TPollSearchEntity.dart';

abstract class TpollSearchState extends Equatable {
  const TpollSearchState();

  @override
  List<Object?> get props => [];
}

class TpollSearchInitial extends TpollSearchState {
  const TpollSearchInitial();
}

class TpollSearchLoading extends TpollSearchState {
  const TpollSearchLoading();
}

class TpollSearchSuccess extends TpollSearchState {
  final TpollSearchEntity tpollSearchEntity;

  const TpollSearchSuccess({required this.tpollSearchEntity});

  @override
  List<Object?> get props => [tpollSearchEntity];
}

class TpollSearchFailure extends TpollSearchState {
  final DioException error;

  const TpollSearchFailure({required this.error});

  @override
  List<Object?> get props => [error];
}