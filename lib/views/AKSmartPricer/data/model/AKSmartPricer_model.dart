import '../../domain/entity/AKSmartPricer_entity.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkSmartPricerTripRequestModel extends AkSmartPricerTripRequestEntity {
  const AkSmartPricerTripRequestModel({
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

class AkSmartPricerRequestModel extends AkSmartPricerRequestEntity {
  const AkSmartPricerRequestModel({
    required super.searchTui,
    required super.tripType,
    required super.trips,
    super.preview,
  });

  factory AkSmartPricerRequestModel.fromEntity(AkSmartPricerRequestEntity entity) {
    return AkSmartPricerRequestModel(
      searchTui: entity.searchTui,
      tripType: entity.tripType,
      trips: entity.trips
          .map((t) => AkSmartPricerTripRequestModel(
                index: t.index,
                amount: t.amount,
                orderId: t.orderId,
              ))
          .toList(),
      preview: entity.preview,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'search_tui': searchTui,
      'trip_type': tripType,
      'trips': trips
          .map((t) => (t as AkSmartPricerTripRequestModel).toJson())
          .toList(),
      'preview': preview,
    };
  }
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkSmartPricerFlightModel extends AkSmartPricerFlightEntity {
  const AkSmartPricerFlightModel({
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

  factory AkSmartPricerFlightModel.fromJson(Map<String, dynamic> json) {
    return AkSmartPricerFlightModel(
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

class AkSmartPricerFareModel extends AkSmartPricerFareEntity {
  const AkSmartPricerFareModel({
    required super.grossFare,
    required super.netFare,
    required super.totalBaseFare,
    required super.totalTax,
    required super.totalServiceTax,
    required super.totalTransactionFee,
    required super.totalCommission,
  });

  factory AkSmartPricerFareModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return AkSmartPricerFareModel(
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

class AkSmartPricerSegmentModel extends AkSmartPricerSegmentEntity {
  const AkSmartPricerSegmentModel({
    required super.flight,
    required super.fare,
  });

  factory AkSmartPricerSegmentModel.fromJson(Map<String, dynamic> json) {
    return AkSmartPricerSegmentModel(
      flight: AkSmartPricerFlightModel.fromJson(
          json['Flight'] as Map<String, dynamic>? ?? {}),
      fare: AkSmartPricerFareModel.fromJson(
          json['Fares'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class AkSmartPricerJourneyModel extends AkSmartPricerJourneyEntity {
  const AkSmartPricerJourneyModel({
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

  factory AkSmartPricerJourneyModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final segmentsList = json['Segments'] as List? ?? [];
    return AkSmartPricerJourneyModel(
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
          .map((s) => AkSmartPricerSegmentModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AkSmartPricerTripModel extends AkSmartPricerTripEntity {
  const AkSmartPricerTripModel({required super.journey});

  factory AkSmartPricerTripModel.fromJson(Map<String, dynamic> json) {
    final journeyList = json['Journey'] as List? ?? [];
    return AkSmartPricerTripModel(
      journey: journeyList
          .map((j) => AkSmartPricerJourneyModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AkSmartPricerBaggageModel extends AkSmartPricerBaggageEntity {
  const AkSmartPricerBaggageModel({
    required super.checkin,
    required super.cabin,
  });

  factory AkSmartPricerBaggageModel.fromJson(Map<String, dynamic> json) {
    return AkSmartPricerBaggageModel(
      checkin: json['checkin']?.toString() ?? '',
      cabin: json['cabin']?.toString() ?? '',
    );
  }
}

class AkSmartPricerModel extends AkSmartPricerEntity {
  const AkSmartPricerModel({
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
    required super.includedBaggage,
    required super.trips,
  });

  factory AkSmartPricerModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final tripsList = json['Trips'] as List? ?? [];

    final baggageJson = json['included_baggage'] as Map<String, dynamic>? ?? {};
    final includedBaggage = <String, Map<String, AkSmartPricerBaggageEntity>>{};
    baggageJson.forEach((fuid, byPtc) {
      if (byPtc is! Map<String, dynamic>) return;
      final ptcMap = <String, AkSmartPricerBaggageEntity>{};
      byPtc.forEach((ptc, baggageEntry) {
        if (baggageEntry is Map<String, dynamic>) {
          ptcMap[ptc] = AkSmartPricerBaggageModel.fromJson(baggageEntry);
        }
      });
      includedBaggage[fuid] = ptcMap;
    });

    final returnDateRaw = json['ReturnDate']?.toString();

    return AkSmartPricerModel(
      success: json['success'] ?? false,
      sessionId: json['session_id']?.toString() ?? '',
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
      includedBaggage: includedBaggage,
      trips: tripsList
          .map((t) => AkSmartPricerTripModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
