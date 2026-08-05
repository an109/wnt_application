import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKFareRule_entity.dart';

abstract class AkFareRuleState extends Equatable {
  const AkFareRuleState();

  @override
  List<Object?> get props => [];
}

class AkFareRuleInitial extends AkFareRuleState {
  const AkFareRuleInitial();
}

class AkFareRuleLoading extends AkFareRuleState {
  const AkFareRuleLoading();
}

class AkFareRuleLoaded extends AkFareRuleState {
  final AkFareRuleEntity data;

  const AkFareRuleLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkFareRuleFailed extends AkFareRuleState {
  final DioException error;

  const AkFareRuleFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
