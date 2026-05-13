import 'package:equatable/equatable.dart';
import '../../domain/entities/exclusive_deal_entity.dart';

abstract class ExclusiveDealsState extends Equatable {
  const ExclusiveDealsState();

  @override
  List<Object?> get props => [];
}

class ExclusiveDealsInitial extends ExclusiveDealsState {
  const ExclusiveDealsInitial();
}

class ExclusiveDealsLoading extends ExclusiveDealsState {
  const ExclusiveDealsLoading();
}

class ExclusiveDealsLoaded extends ExclusiveDealsState {
  final List<ExclusiveDealEntity> deals;

  const ExclusiveDealsLoaded(this.deals);

  @override
  List<Object?> get props => [deals];
}

class ExclusiveDealsError extends ExclusiveDealsState {
  final String message;

  const ExclusiveDealsError(this.message);

  @override
  List<Object?> get props => [message];
}