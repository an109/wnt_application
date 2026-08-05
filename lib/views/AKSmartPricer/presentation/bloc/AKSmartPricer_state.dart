import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKSmartPricer_entity.dart';

abstract class AkSmartPricerState extends Equatable {
  const AkSmartPricerState();

  @override
  List<Object?> get props => [];
}

class AkSmartPricerInitial extends AkSmartPricerState {
  const AkSmartPricerInitial();
}

class AkSmartPricerLoading extends AkSmartPricerState {
  const AkSmartPricerLoading();
}

class AkSmartPricerLoaded extends AkSmartPricerState {
  final AkSmartPricerEntity data;

  const AkSmartPricerLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkSmartPricerFailed extends AkSmartPricerState {
  final DioException error;

  const AkSmartPricerFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
