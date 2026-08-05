import 'package:equatable/equatable.dart';

class AkSelectedSeatItemEntity extends Equatable {
  final int ssid;
  final int fuid;
  final int paxId;
  final double fare;
  final double tax;

  const AkSelectedSeatItemEntity({
    required this.ssid,
    required this.fuid,
    required this.paxId,
    required this.fare,
    required this.tax,
  });

  @override
  List<Object?> get props => [ssid, fuid, paxId, fare, tax];
}

class AkSelectSeatsRequestEntity extends Equatable {
  final String sessionId;
  final List<AkSelectedSeatItemEntity> selectedSeats;

  const AkSelectSeatsRequestEntity({
    required this.sessionId,
    required this.selectedSeats,
  });

  @override
  List<Object?> get props => [sessionId, selectedSeats];
}

class AkSelectSeatsEntity extends Equatable {
  final bool success;

  const AkSelectSeatsEntity({required this.success});

  @override
  List<Object?> get props => [success];
}
