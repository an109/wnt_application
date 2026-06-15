import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/loyality_entity.dart';

abstract class LoyaltyState extends Equatable {
  const LoyaltyState();

  @override
  List<Object?> get props => [];
}

class LoyaltyInitial extends LoyaltyState {}

class LoyaltyLoading extends LoyaltyState {}

// We wrap DataState inside LoyaltyLoaded to handle both Success and Failed states cleanly
class LoyaltyLoaded extends LoyaltyState {
  final DataState<LoyaltyEntity> dataState;

  const LoyaltyLoaded(this.dataState);

  @override
  List<Object?> get props => [dataState];
}