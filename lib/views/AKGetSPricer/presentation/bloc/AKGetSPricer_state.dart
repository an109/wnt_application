import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKGetSPricer_entity.dart';

abstract class AkGetSPricerState extends Equatable {
  const AkGetSPricerState();

  @override
  List<Object?> get props => [];
}

class AkGetSPricerInitial extends AkGetSPricerState {
  const AkGetSPricerInitial();
}

class AkGetSPricerLoading extends AkGetSPricerState {
  const AkGetSPricerLoading();
}

class AkGetSPricerLoaded extends AkGetSPricerState {
  final AkGetSPricerEntity data;

  const AkGetSPricerLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkGetSPricerFailed extends AkGetSPricerState {
  final DioException error;

  const AkGetSPricerFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
