import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKTravelCheckList_entity.dart';

abstract class AkTravelCheckListState extends Equatable {
  const AkTravelCheckListState();

  @override
  List<Object?> get props => [];
}

class AkTravelCheckListInitial extends AkTravelCheckListState {
  const AkTravelCheckListInitial();
}

class AkTravelCheckListLoading extends AkTravelCheckListState {
  const AkTravelCheckListLoading();
}

class AkTravelCheckListLoaded extends AkTravelCheckListState {
  final AkTravelCheckListEntity data;

  const AkTravelCheckListLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkTravelCheckListFailed extends AkTravelCheckListState {
  final DioException error;

  const AkTravelCheckListFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
