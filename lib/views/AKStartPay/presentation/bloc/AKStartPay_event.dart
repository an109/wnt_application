import 'package:equatable/equatable.dart';
import '../../domain/entity/AKStartPay_entity.dart';

abstract class AkStartPayEvent extends Equatable {
  const AkStartPayEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkStartPayEvent extends AkStartPayEvent {
  final AkStartPayRequestEntity request;

  const LoadAkStartPayEvent(this.request);

  @override
  List<Object?> get props => [request];
}
