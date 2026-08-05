import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKFlightInfo_entity.dart';

abstract class AkFlightInfoState extends Equatable {
  const AkFlightInfoState();

  @override
  List<Object?> get props => [];
}

class AkFlightInfoInitial extends AkFlightInfoState {
  const AkFlightInfoInitial();
}

class AkFlightInfoLoading extends AkFlightInfoState {
  const AkFlightInfoLoading();
}

class AkFlightInfoLoaded extends AkFlightInfoState {
  final AkFlightInfoEntity data;

  const AkFlightInfoLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkFlightInfoFailed extends AkFlightInfoState {
  final DioException error;

  const AkFlightInfoFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
