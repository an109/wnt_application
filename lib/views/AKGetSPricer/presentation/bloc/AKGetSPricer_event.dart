import 'package:equatable/equatable.dart';
import '../../domain/entity/AKGetSPricer_entity.dart';

abstract class AkGetSPricerEvent extends Equatable {
  const AkGetSPricerEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkGetSPricerEvent extends AkGetSPricerEvent {
  final AkGetSPricerRequestEntity request;

  const LoadAkGetSPricerEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class ResetAkGetSPricerEvent extends AkGetSPricerEvent {
  const ResetAkGetSPricerEvent();
}
