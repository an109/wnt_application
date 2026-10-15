import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKFareFamilyDetails_entity.dart';

abstract class AkFareFamilyDetailsState extends Equatable {
  const AkFareFamilyDetailsState();

  @override
  List<Object?> get props => [];
}

class AkFareFamilyDetailsInitial extends AkFareFamilyDetailsState {
  const AkFareFamilyDetailsInitial();
}

class AkFareFamilyDetailsLoading extends AkFareFamilyDetailsState {
  const AkFareFamilyDetailsLoading();
}

class AkFareFamilyDetailsLoaded extends AkFareFamilyDetailsState {
  final AkFareFamilyDetailsEntity data;

  const AkFareFamilyDetailsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkFareFamilyDetailsFailed extends AkFareFamilyDetailsState {
  final DioException error;

  const AkFareFamilyDetailsFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
