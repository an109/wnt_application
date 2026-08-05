import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKCreateItinerary_entity.dart';

abstract class AkCreateItineraryState extends Equatable {
  const AkCreateItineraryState();

  @override
  List<Object?> get props => [];
}

class AkCreateItineraryInitial extends AkCreateItineraryState {
  const AkCreateItineraryInitial();
}

class AkCreateItineraryLoading extends AkCreateItineraryState {
  const AkCreateItineraryLoading();
}

class AkCreateItineraryLoaded extends AkCreateItineraryState {
  final AkCreateItineraryEntity data;

  const AkCreateItineraryLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkCreateItineraryFailed extends AkCreateItineraryState {
  final DioException error;

  const AkCreateItineraryFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
