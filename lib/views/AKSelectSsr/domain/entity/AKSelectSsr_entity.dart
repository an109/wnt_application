import 'package:equatable/equatable.dart';

class AkSelectedSsrItemEntity extends Equatable {
  final int id;
  final int fuid;
  final int paxId;
  final double charge;
  final double vat;

  const AkSelectedSsrItemEntity({
    required this.id,
    required this.fuid,
    required this.paxId,
    required this.charge,
    this.vat = 0,
  });

  @override
  List<Object?> get props => [id, fuid, paxId, charge, vat];
}

class AkSelectSsrRequestEntity extends Equatable {
  final String sessionId;
  final List<AkSelectedSsrItemEntity> selectedSsr;

  const AkSelectSsrRequestEntity({
    required this.sessionId,
    required this.selectedSsr,
  });

  @override
  List<Object?> get props => [sessionId, selectedSsr];
}

class AkSelectSsrEntity extends Equatable {
  final bool success;

  const AkSelectSsrEntity({required this.success});

  @override
  List<Object?> get props => [success];
}
