import 'package:equatable/equatable.dart';
import '../../domain/entity/AKSsr_entity.dart';

abstract class AkSsrEvent extends Equatable {
  const AkSsrEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkSsrEvent extends AkSsrEvent {
  final AkSsrRequestEntity request;

  const LoadAkSsrEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class ResetAkSsrEvent extends AkSsrEvent {
  const ResetAkSsrEvent();
}
