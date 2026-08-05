import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKStartPay_entity.dart';

abstract class AkStartPayState extends Equatable {
  const AkStartPayState();

  @override
  List<Object?> get props => [];
}

class AkStartPayInitial extends AkStartPayState {
  const AkStartPayInitial();
}

class AkStartPayLoading extends AkStartPayState {
  const AkStartPayLoading();
}

class AkStartPayLoaded extends AkStartPayState {
  final AkStartPayEntity data;

  const AkStartPayLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkStartPayFailed extends AkStartPayState {
  final DioException error;

  const AkStartPayFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
