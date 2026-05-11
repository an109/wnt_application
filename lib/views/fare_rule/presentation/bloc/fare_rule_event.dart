import 'package:equatable/equatable.dart';
import '../../domain/entities/fare_rule_entity.dart';

abstract class FareRuleEvent extends Equatable {
  const FareRuleEvent();

  @override
  List<Object?> get props => [];
}

class FetchFareRules extends FareRuleEvent {
  final FareRuleRequestEntity request;

  const FetchFareRules({required this.request});

  @override
  List<Object?> get props => [request];
}

class ClearFareRules extends FareRuleEvent {
  const ClearFareRules();
}