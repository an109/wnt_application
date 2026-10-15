
import '../../domain/entity/akflight_search_entity.dart';

class AkFlightSearchModel extends AkFlightSearchEntity {
  const AkFlightSearchModel({
    required super.success,
    required super.tui,
    required super.sessionId,
    super.tuis,
  });

  factory AkFlightSearchModel.fromJson(Map<String, dynamic> json) {
    final rawTuis = json['tuis'];
    final List<String> tuiList = rawTuis is List
        ? rawTuis.map((e) => e.toString()).toList()
        : const [];
    return AkFlightSearchModel(
      success: json['success'] ?? false,
      tui: json['tui'] ?? '',
      sessionId: json['session_id'] ?? '',
      tuis: tuiList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'tui': tui,
      'session_id': sessionId,
      if (tuis.isNotEmpty) 'tuis': tuis,
    };
  }
}

class TripModel extends TripEntity {
  const TripModel({
    required super.from,
    required super.to,
    required super.onwardDate,
    super.returnDate,
    super.fromCity,
    super.toCity,
    super.fromArptName,
    super.toArptName,
    super.orderId,
    super.onwardCabin,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      onwardDate: json['onward_date'] ?? '',
      returnDate: json['return_date'],
      fromCity: json['from_city'],
      toCity: json['to_city'],
      fromArptName: json['from_arpt_name'],
      toArptName: json['to_arpt_name'],
      orderId: json['order_id'],
      onwardCabin: json['onward_cabin'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'from': from,
      'to': to,
      'onward_date': onwardDate,
    };
    if (returnDate != null) data['return_date'] = returnDate;
    if (fromCity != null) data['from_city'] = fromCity;
    if (toCity != null) data['to_city'] = toCity;
    if (fromArptName != null) data['from_arpt_name'] = fromArptName;
    if (toArptName != null) data['to_arpt_name'] = toArptName;
    if (orderId != null) data['order_id'] = orderId;
    if (onwardCabin != null) data['onward_cabin'] = onwardCabin;
    return data;
  }
}

class FlightSearchRequestModel extends FlightSearchRequestEntity {
  const FlightSearchRequestModel({
    required super.adults,
    required super.children,
    required super.infants,
    required super.cabin,
    required super.fareType,
    required super.trips,
  });

  factory FlightSearchRequestModel.fromEntity(FlightSearchRequestEntity entity) {
    return FlightSearchRequestModel(
      adults: entity.adults,
      children: entity.children,
      infants: entity.infants,
      cabin: entity.cabin,
      fareType: entity.fareType,
      trips: entity.trips.map((trip) => TripModel(
        from: trip.from,
        to: trip.to,
        onwardDate: trip.onwardDate,
        returnDate: trip.returnDate,
      )).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adults': adults,
      'children': children,
      'infants': infants,
      'cabin': cabin,
      'fare_type': fareType,
      'trips': trips.map((trip) => (trip as TripModel).toJson()).toList(),
    };
  }
}