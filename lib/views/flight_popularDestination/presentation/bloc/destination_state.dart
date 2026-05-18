import 'package:equatable/equatable.dart';
import '../../domain/entities/Popular_destination_entity.dart';

abstract class PopularDestinationState extends Equatable {
  const PopularDestinationState();

  @override
  List<Object?> get props => [];
}

class PopularDestinationInitial extends PopularDestinationState {
  const PopularDestinationInitial();
}

class PopularDestinationLoading extends PopularDestinationState {
  const PopularDestinationLoading();
}

class PopularDestinationLoaded extends PopularDestinationState {
  final List<DestinationEntity> destinations;

  const PopularDestinationLoaded(this.destinations);

  @override
  List<Object?> get props => [destinations];
}

class PopularDestinationError extends PopularDestinationState {
  final String message;

  const PopularDestinationError(this.message);

  @override
  List<Object?> get props => [message];
}