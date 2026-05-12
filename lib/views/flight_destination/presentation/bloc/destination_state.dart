import 'package:equatable/equatable.dart';
import '../../data/models/destination_model.dart';

abstract class DestinationState extends Equatable {
  const DestinationState();

  @override
  List<Object?> get props => [];
}

class DestinationInitial extends DestinationState {
  const DestinationInitial();
}

class DestinationLoading extends DestinationState {
  const DestinationLoading();
}

class DestinationLoaded extends DestinationState {
  final DestinationSearchModel destinationData;

  const DestinationLoaded(this.destinationData);

  @override
  List<Object?> get props => [destinationData];
}

class DestinationError extends DestinationState {
  final String message;

  const DestinationError(this.message);

  @override
  List<Object?> get props => [message];
}