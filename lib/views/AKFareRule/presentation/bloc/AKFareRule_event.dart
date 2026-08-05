import 'package:equatable/equatable.dart';
import '../../domain/entity/AKFareRule_entity.dart';

abstract class AkFareRuleEvent extends Equatable {
  const AkFareRuleEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkFareRuleEvent extends AkFareRuleEvent {
  final AkFareRuleRequestEntity request;

  const LoadAkFareRuleEvent(this.request);

  @override
  List<Object?> get props => [request];
}
