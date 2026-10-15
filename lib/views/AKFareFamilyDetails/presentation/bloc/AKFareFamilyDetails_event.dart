import 'package:equatable/equatable.dart';
import '../../domain/entity/AKFareFamilyDetails_entity.dart';

abstract class AkFareFamilyDetailsEvent extends Equatable {
  const AkFareFamilyDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkFareFamilyDetailsEvent extends AkFareFamilyDetailsEvent {
  final AkFareFamilyDetailsRequestEntity request;

  const LoadAkFareFamilyDetailsEvent(this.request);

  @override
  List<Object?> get props => [request];
}
