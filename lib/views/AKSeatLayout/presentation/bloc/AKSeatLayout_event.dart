import 'package:equatable/equatable.dart';
import '../../domain/entity/AKSeatLayout_entity.dart';

abstract class AkSeatLayoutEvent extends Equatable {
  const AkSeatLayoutEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkSeatLayoutEvent extends AkSeatLayoutEvent {
  final AkSeatLayoutRequestEntity request;

  const LoadAkSeatLayoutEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class ResetAkSeatLayoutEvent extends AkSeatLayoutEvent {
  const ResetAkSeatLayoutEvent();
}
