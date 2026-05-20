import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/visaDestin_Entity.dart';

abstract class VisaDestinationState extends Equatable {
  const VisaDestinationState();

  @override
  List<Object?> get props => [];
}

class VisaDestinationInitial extends VisaDestinationState {}

class VisaDestinationLoading extends VisaDestinationState {}

class VisaDestinationLoaded extends VisaDestinationState {
  final List<VisaDestinationEntity> destinations;

  const VisaDestinationLoaded(this.destinations);

  @override
  List<Object?> get props => [destinations];
}

class VisaDestinationError extends VisaDestinationState {
  final String message;

  const VisaDestinationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Optional: If you want to use your DataState directly
class VisaDestinationDataState extends VisaDestinationState {
  final DataState<List<VisaDestinationEntity>> dataState;

  const VisaDestinationDataState(this.dataState);

  @override
  List<Object?> get props => [dataState];
}