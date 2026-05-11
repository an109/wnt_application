import 'package:equatable/equatable.dart';
import '../../domain/entities/ssr_entity.dart';

abstract class SsrState extends Equatable {
  const SsrState();

  @override
  List<Object> get props => [];
}

class SsrInitial extends SsrState {}

class SsrLoading extends SsrState {}

class SsrLoaded extends SsrState {
  final SsrEntity ssrData;

  const SsrLoaded(this.ssrData);

  @override
  List<Object> get props => [ssrData];
}

class SsrError extends SsrState {
  final String message;

  const SsrError(this.message);

  @override
  List<Object> get props => [message];
}