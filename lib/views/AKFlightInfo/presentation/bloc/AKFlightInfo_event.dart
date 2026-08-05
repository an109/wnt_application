import 'package:equatable/equatable.dart';
import '../../domain/entity/AKFlightInfo_entity.dart';

abstract class AkFlightInfoEvent extends Equatable {
  const AkFlightInfoEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkFlightInfoEvent extends AkFlightInfoEvent {
  final AkFlightInfoRequestEntity request;

  const LoadAkFlightInfoEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class ResetAkFlightInfoEvent extends AkFlightInfoEvent {
  const ResetAkFlightInfoEvent();
}
