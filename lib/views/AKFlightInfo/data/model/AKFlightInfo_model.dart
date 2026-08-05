import '../../domain/entity/AKFlightInfo_entity.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkFlightInfoTripRequestModel extends AkFlightInfoTripRequestEntity {
  const AkFlightInfoTripRequestModel({
    required super.index,
    required super.amount,
    required super.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'amount': amount,
      'order_id': orderId,
    };
  }
}

class AkFlightInfoRequestModel extends AkFlightInfoRequestEntity {
  const AkFlightInfoRequestModel({
    required super.tui,
    required super.tripType,
    required super.trips,
  });

  factory AkFlightInfoRequestModel.fromEntity(AkFlightInfoRequestEntity entity) {
    return AkFlightInfoRequestModel(
      tui: entity.tui,
      tripType: entity.tripType,
      trips: entity.trips
          .map((t) => AkFlightInfoTripRequestModel(
                index: t.index,
                amount: t.amount,
                orderId: t.orderId,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tui': tui,
      'trip_type': tripType,
      'trips': trips
          .map((t) => (t as AkFlightInfoTripRequestModel).toJson())
          .toList(),
    };
  }
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkFlightInfoFlightModel extends AkFlightInfoFlightEntity {
  const AkFlightInfoFlightModel({
    required super.vac,
    required super.fuid,
    required super.mac,
    required super.oac,
    required super.fbc,
    required super.airline,
    required super.flightNo,
    required super.departureTime,
    required super.arrivalTime,
    required super.fareClass,
    required super.departureCode,
    required super.arrivalCode,
    required super.departureTerminal,
    required super.arrivalTerminal,
    required super.depAirportName,
    required super.arrAirportName,
    required super.equipmentType,
    required super.aircraft,
    required super.rbd,
    required super.cabin,
    required super.refundable,
    required super.seats,
    required super.duration,
  });

  factory AkFlightInfoFlightModel.fromJson(Map<String, dynamic> json) {
    return AkFlightInfoFlightModel(
      fuid: json['FUID'] is int
          ? json['FUID']
          : int.tryParse(json['FUID']?.toString() ?? '') ?? 0,
      vac: json['VAC']?.toString() ?? '',
      mac: json['MAC']?.toString() ?? '',
      oac: json['OAC']?.toString() ?? '',
      fbc: json['FBC']?.toString() ?? '',
      airline: json['Airline']?.toString() ?? '',
      flightNo: json['FlightNo']?.toString() ?? '',
      departureTime: json['DepartureTime']?.toString() ?? '',
      arrivalTime: json['ArrivalTime']?.toString() ?? '',
      fareClass: json['FareClass']?.toString() ?? '',
      departureCode: json['DepartureCode']?.toString() ?? '',
      arrivalCode: json['ArrivalCode']?.toString() ?? '',
      departureTerminal: json['DepartureTerminal']?.toString() ?? '',
      arrivalTerminal: json['ArrivalTerminal']?.toString() ?? '',
      depAirportName: json['DepAirportName']?.toString() ?? '',
      arrAirportName: json['ArrAirportName']?.toString() ?? '',
      equipmentType: json['EquipmentType']?.toString() ?? '',
      aircraft: json['AirCraft']?.toString() ?? '',
      rbd: json['RBD']?.toString() ?? '',
      cabin: json['Cabin']?.toString() ?? '',
      refundable: json['Refundable']?.toString() ?? '',
      seats: (json['Seats'] ?? 0) is int
          ? json['Seats'] ?? 0
          : int.tryParse(json['Seats'].toString()) ?? 0,
      duration: json['Duration']?.toString() ?? '',
    );
  }
}

class AkFlightInfoFareModel extends AkFlightInfoFareEntity {
  const AkFlightInfoFareModel({
    required super.grossFare,
    required super.netFare,
    required super.totalBaseFare,
    required super.totalTax,
    required super.totalServiceTax,
    required super.totalTransactionFee,
    required super.totalCommission,
  });

  factory AkFlightInfoFareModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return AkFlightInfoFareModel(
      grossFare: toD(json['GrossFare']),
      netFare: toD(json['NetFare']),
      totalBaseFare: toD(json['TotalBaseFare']),
      totalTax: toD(json['TotalTax']),
      totalServiceTax: toD(json['TotalServiceTax']),
      totalTransactionFee: toD(json['TotalTransactionFee']),
      totalCommission: toD(json['TotalCommission']),
    );
  }
}

class AkFlightInfoSegmentModel extends AkFlightInfoSegmentEntity {
  const AkFlightInfoSegmentModel({
    required super.flight,
    required super.fare,
  });

  factory AkFlightInfoSegmentModel.fromJson(Map<String, dynamic> json) {
    return AkFlightInfoSegmentModel(
      flight: AkFlightInfoFlightModel.fromJson(
          json['Flight'] as Map<String, dynamic>? ?? {}),
      fare: AkFlightInfoFareModel.fromJson(
          json['Fares'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class AkFlightInfoJourneyModel extends AkFlightInfoJourneyEntity {
  const AkFlightInfoJourneyModel({
    required super.provider,
    required super.stops,
    required super.orderId,
    required super.grossFare,
    required super.netFare,
    required super.duration,
    required super.promo,
    required super.fareType,
    required super.segments,
  });

  factory AkFlightInfoJourneyModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final segmentsList = json['Segments'] as List? ?? [];
    return AkFlightInfoJourneyModel(
      provider: json['Provider']?.toString() ?? '',
      stops: int.tryParse(json['Stops']?.toString() ?? '') ?? 0,
      orderId: json['OrderID'] is int
          ? json['OrderID']
          : int.tryParse(json['OrderID']?.toString() ?? '') ?? 0,
      grossFare: toD(json['GrossFare']),
      netFare: toD(json['NetFare']),
      duration: json['Duration']?.toString() ?? '',
      promo: json['Promo']?.toString() ?? '',
      fareType: json['FCType']?.toString() ?? '',
      segments: segmentsList
          .map((s) => AkFlightInfoSegmentModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AkFlightInfoTripModel extends AkFlightInfoTripEntity {
  const AkFlightInfoTripModel({required super.journey});

  factory AkFlightInfoTripModel.fromJson(Map<String, dynamic> json) {
    final journeyList = json['Journey'] as List? ?? [];
    return AkFlightInfoTripModel(
      journey: journeyList
          .map((j) => AkFlightInfoJourneyModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AkFlightInfoModel extends AkFlightInfoEntity {
  const AkFlightInfoModel({
    required super.success,
    required super.sessionId,
    required super.tui,
    required super.from,
    required super.to,
    required super.fromName,
    required super.toName,
    required super.onwardDate,
    super.returnDate,
    required super.adultCount,
    required super.childCount,
    required super.infantCount,
    required super.netAmount,
    required super.grossAmount,
    required super.fareType,
    required super.hold,
    required super.trips,
  });

  factory AkFlightInfoModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final tripsList = json['Trips'] as List? ?? [];
    return AkFlightInfoModel(
      success: json['success'] ?? false,
      sessionId: json['session_id']?.toString() ?? '',
      tui: json['TUI']?.toString() ?? '',
      from: json['From']?.toString() ?? '',
      to: json['To']?.toString() ?? '',
      fromName: json['FromName']?.toString() ?? '',
      toName: json['ToName']?.toString() ?? '',
      onwardDate: json['OnwardDate']?.toString() ?? '',
      returnDate: json['ReturnDate']?.toString(),
      adultCount: json['ADT'] ?? 0,
      childCount: json['CHD'] ?? 0,
      infantCount: json['INF'] ?? 0,
      netAmount: toD(json['NetAmount']),
      grossAmount: toD(json['GrossAmount']),
      fareType: json['FareType']?.toString() ?? '',
      hold: json['Hold'] ?? false,
      trips: tripsList
          .map((t) => AkFlightInfoTripModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
