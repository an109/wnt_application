import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKSsr_entity.dart';

abstract class AkSsrState extends Equatable {
  const AkSsrState();

  @override
  List<Object?> get props => [];
}

class AkSsrInitial extends AkSsrState {
  const AkSsrInitial();
}

class AkSsrLoading extends AkSsrState {
  const AkSsrLoading();
}

class AkSsrLoaded extends AkSsrState {
  final AkSsrEntity data;

  const AkSsrLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkSsrFailed extends AkSsrState {
  final DioException error;

  const AkSsrFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
