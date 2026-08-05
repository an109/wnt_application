import 'package:equatable/equatable.dart';

class AkAcceptFareChangeRequestEntity extends Equatable {
  final String sessionId;

  const AkAcceptFareChangeRequestEntity({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class AkAcceptFareChangeEntity extends Equatable {
  final bool success;

  const AkAcceptFareChangeEntity({required this.success});

  @override
  List<Object?> get props => [success];
}
