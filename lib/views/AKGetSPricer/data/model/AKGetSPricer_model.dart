import '../../domain/entity/AKGetSPricer_entity.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkGetSPricerRequestModel extends AkGetSPricerRequestEntity {
  const AkGetSPricerRequestModel({
    required super.tui,
    super.preview,
  });

  factory AkGetSPricerRequestModel.fromEntity(AkGetSPricerRequestEntity entity) {
    return AkGetSPricerRequestModel(tui: entity.tui, preview: entity.preview);
  }

  Map<String, dynamic> toJson() {
    return {
      'tui': tui,
      'preview': preview,
    };
  }
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkGetSPricerFlightModel extends AkGetSPricerFlightEntity {
  const AkGetSPricerFlightModel({
    required super.fuid,
    required super.vac,
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

  factory AkGetSPricerFlightModel.fromJson(Map<String, dynamic> json) {
    return AkGetSPricerFlightModel(
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

class AkGetSPricerFareModel extends AkGetSPricerFareEntity {
  const AkGetSPricerFareModel({
    required super.grossFare,
    required super.netFare,
    required super.totalBaseFare,
    required super.totalTax,
    required super.totalServiceTax,
    required super.totalTransactionFee,
    required super.totalCommission,
  });

  factory AkGetSPricerFareModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return AkGetSPricerFareModel(
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

class AkGetSPricerSegmentModel extends AkGetSPricerSegmentEntity {
  const AkGetSPricerSegmentModel({
    required super.flight,
    required super.fare,
  });

  factory AkGetSPricerSegmentModel.fromJson(Map<String, dynamic> json) {
    return AkGetSPricerSegmentModel(
      flight: AkGetSPricerFlightModel.fromJson(
          json['Flight'] as Map<String, dynamic>? ?? {}),
      fare: AkGetSPricerFareModel.fromJson(
          json['Fares'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class AkGetSPricerJourneyModel extends AkGetSPricerJourneyEntity {
  const AkGetSPricerJourneyModel({
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

  factory AkGetSPricerJourneyModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final segmentsList = json['Segments'] as List? ?? [];
    return AkGetSPricerJourneyModel(
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
          .map((s) => AkGetSPricerSegmentModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AkGetSPricerTripModel extends AkGetSPricerTripEntity {
  const AkGetSPricerTripModel({required super.journey});

  factory AkGetSPricerTripModel.fromJson(Map<String, dynamic> json) {
    final journeyList = json['Journey'] as List? ?? [];
    return AkGetSPricerTripModel(
      journey: journeyList
          .map((j) => AkGetSPricerJourneyModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AkGetSPricerBaggageModel extends AkGetSPricerBaggageEntity {
  const AkGetSPricerBaggageModel({
    required super.checkin,
    required super.cabin,
  });

  factory AkGetSPricerBaggageModel.fromJson(Map<String, dynamic> json) {
    return AkGetSPricerBaggageModel(
      checkin: json['checkin']?.toString() ?? '',
      cabin: json['cabin']?.toString() ?? '',
    );
  }
}

class AkGetSPricerModel extends AkGetSPricerEntity {
  const AkGetSPricerModel({
    required super.success,
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
    required super.fareChanged,
    required super.includedBaggage,
    required super.trips,
  });

  factory AkGetSPricerModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final tripsList = json['Trips'] as List? ?? [];

    final baggageJson = json['included_baggage'] as Map<String, dynamic>? ?? {};
    final includedBaggage = <String, Map<String, AkGetSPricerBaggageEntity>>{};
    baggageJson.forEach((fuid, byPtc) {
      if (byPtc is! Map<String, dynamic>) return;
      final ptcMap = <String, AkGetSPricerBaggageEntity>{};
      byPtc.forEach((ptc, baggageEntry) {
        if (baggageEntry is Map<String, dynamic>) {
          ptcMap[ptc] = AkGetSPricerBaggageModel.fromJson(baggageEntry);
        }
      });
      includedBaggage[fuid] = ptcMap;
    });

    final returnDateRaw = json['ReturnDate']?.toString();

    return AkGetSPricerModel(
      success: json['success'] ?? false,
      tui: json['TUI']?.toString() ?? '',
      from: json['From']?.toString() ?? '',
      to: json['To']?.toString() ?? '',
      fromName: json['FromName']?.toString() ?? '',
      toName: json['ToName']?.toString() ?? '',
      onwardDate: json['OnwardDate']?.toString() ?? '',
      returnDate: (returnDateRaw == null || returnDateRaw.isEmpty) ? null : returnDateRaw,
      adultCount: json['ADT'] ?? 0,
      childCount: json['CHD'] ?? 0,
      infantCount: json['INF'] ?? 0,
      netAmount: toD(json['NetAmount']),
      grossAmount: toD(json['GrossAmount']),
      fareType: json['FareType']?.toString() ?? '',
      fareChanged: json['fare_changed'] ?? false,
      includedBaggage: includedBaggage,
      trips: tripsList
          .map((t) => AkGetSPricerTripModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
