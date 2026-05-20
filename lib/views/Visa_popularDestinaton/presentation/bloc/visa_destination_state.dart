import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/visa_destination_entity.dart';

abstract class VisaPopularDestinationState extends Equatable {
  const VisaPopularDestinationState();

  @override
  List<Object?> get props => [];
}

class VisaDestinationInitial extends VisaPopularDestinationState {}

class VisaDestinationLoading extends VisaPopularDestinationState {}

class VisaDestinationLoaded extends VisaPopularDestinationState {
  final List<VisaPopularDestinationEntity> destinations;

  const VisaDestinationLoaded(this.destinations);

  @override
  List<Object?> get props => [destinations];
}

class VisaDestinationError extends VisaPopularDestinationState {
  final String message;

  const VisaDestinationError(this.message);

  @override
  List<Object?> get props => [message];
}

class VisaDestinationDataState extends VisaPopularDestinationState {
  final DataState<List<VisaPopularDestinationEntity>> dataState;

  const VisaDestinationDataState(this.dataState);

  @override
  List<Object?> get props => [dataState];
}