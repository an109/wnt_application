import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKSeatLayout_entity.dart';

abstract class AkSeatLayoutState extends Equatable {
  const AkSeatLayoutState();

  @override
  List<Object?> get props => [];
}

class AkSeatLayoutInitial extends AkSeatLayoutState {
  const AkSeatLayoutInitial();
}

class AkSeatLayoutLoading extends AkSeatLayoutState {
  const AkSeatLayoutLoading();
}

class AkSeatLayoutLoaded extends AkSeatLayoutState {
  final AkSeatLayoutEntity data;

  const AkSeatLayoutLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkSeatLayoutFailed extends AkSeatLayoutState {
  final DioException error;

  const AkSeatLayoutFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
