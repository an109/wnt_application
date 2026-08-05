import 'package:equatable/equatable.dart';
import '../../domain/entity/AKSmartPricer_entity.dart';

abstract class AkSmartPricerEvent extends Equatable {
  const AkSmartPricerEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkSmartPricerEvent extends AkSmartPricerEvent {
  final AkSmartPricerRequestEntity request;

  const LoadAkSmartPricerEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class ResetAkSmartPricerEvent extends AkSmartPricerEvent {
  const ResetAkSmartPricerEvent();
}
