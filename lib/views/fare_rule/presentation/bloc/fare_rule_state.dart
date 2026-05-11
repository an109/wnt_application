import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/fare_rule_entity.dart';

abstract class FareRuleState extends Equatable {
  const FareRuleState();

  @override
  List<Object?> get props => [];
}

class FareRuleInitial extends FareRuleState {}

class FareRuleLoading extends FareRuleState {}

class FareRuleLoaded extends FareRuleState {
  final FareRuleResponseEntity fareRuleResponse;

  const FareRuleLoaded({required this.fareRuleResponse});

  @override
  List<Object?> get props => [fareRuleResponse];
}

class FareRuleError extends FareRuleState {
  final String message;
  final DioException? error;

  const FareRuleError({required this.message, this.error});

  @override
  List<Object?> get props => [message, error];
}

class FareRuleCleared extends FareRuleState {}