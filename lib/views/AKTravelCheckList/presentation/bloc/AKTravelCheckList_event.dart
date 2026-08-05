import 'package:equatable/equatable.dart';
import '../../domain/entity/AKTravelCheckList_entity.dart';

abstract class AkTravelCheckListEvent extends Equatable {
  const AkTravelCheckListEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkTravelCheckListEvent extends AkTravelCheckListEvent {
  final AkTravelCheckListRequestEntity request;

  const LoadAkTravelCheckListEvent(this.request);

  @override
  List<Object?> get props => [request];
}
