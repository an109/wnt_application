import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkSeatLayoutRequestEntity extends Equatable {
  // Pricing TUI (GetSPricer's returned TUI).
  final String tui;

  // Order IDs of every leg to fetch a seat map for — [1] for a plain
  // one-way, [1, 2] for round trip/multi-city. Without this the backend
  // defaults to just OrderID 1, so a round trip's return leg never gets a
  // seat map.
  final List<int> orderIds;

  const AkSeatLayoutRequestEntity({required this.tui, this.orderIds = const [1]});

  @override
  List<Object?> get props => [tui, orderIds];
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkSeatEntity extends Equatable {
  final String seatNumber;
  final int ssid;
  final double fare;
  final double tax;
  final bool selectable;
  final bool isEmergencyExit;
  final String seatTypeName;
  final String xValue;
  final String yValue;

  const AkSeatEntity({
    required this.seatNumber,
    required this.ssid,
    required this.fare,
    required this.tax,
    required this.selectable,
    required this.isEmergencyExit,
    required this.seatTypeName,
    required this.xValue,
    required this.yValue,
  });

  @override
  List<Object?> get props => [
        seatNumber,
        ssid,
        fare,
        tax,
        selectable,
        isEmergencyExit,
        seatTypeName,
        xValue,
        yValue,
      ];
}

class AkSeatLayoutSegmentEntity extends Equatable {
  final int fuid;
  final String flightNo;
  final List<AkSeatEntity> seats;

  const AkSeatLayoutSegmentEntity({
    required this.fuid,
    required this.flightNo,
    required this.seats,
  });

  @override
  List<Object?> get props => [fuid, flightNo, seats];
}

class AkSeatLayoutJourneyEntity extends Equatable {
  final List<AkSeatLayoutSegmentEntity> segments;

  const AkSeatLayoutJourneyEntity({required this.segments});

  @override
  List<Object?> get props => [segments];
}

class AkSeatLayoutTripEntity extends Equatable {
  final List<AkSeatLayoutJourneyEntity> journey;

  const AkSeatLayoutTripEntity({required this.journey});

  @override
  List<Object?> get props => [journey];
}

class AkSeatLayoutEntity extends Equatable {
  final bool success;
  // False when the airline simply doesn't sell seats — a normal answer, not
  // an error. Defaults to true when the API omits the key, so a
  // well-formed layout response with seats isn't misread as unsupported.
  final bool supported;
  final List<AkSeatLayoutTripEntity> trips;

  const AkSeatLayoutEntity({
    required this.success,
    required this.supported,
    required this.trips,
  });

  bool get hasSeats => trips.any(
        (t) => t.journey.any((j) => j.segments.any((s) => s.seats.isNotEmpty)),
      );

  @override
  List<Object?> get props => [success, supported, trips];
}
