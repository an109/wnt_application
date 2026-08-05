import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKFlights_entity.dart';

abstract class AkflightsState extends Equatable {
  const AkflightsState();

  @override
  List<Object?> get props => [];
}

class AkflightsInitial extends AkflightsState {
  const AkflightsInitial();
}

class AkflightsLoading extends AkflightsState {
  const AkflightsLoading();
}

class AkflightsPolling extends AkflightsState {
  const AkflightsPolling();
}

class AkflightsSuccess extends AkflightsState {
  final AkflightsSearchEntity akflightsData;
  final bool isCompleted;

  const AkflightsSuccess({
    required this.akflightsData,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [akflightsData, isCompleted];
}

class AkflightsFailed extends AkflightsState {
  final DioException error;

  const AkflightsFailed({required this.error});

  @override
  List<Object?> get props => [error];
}