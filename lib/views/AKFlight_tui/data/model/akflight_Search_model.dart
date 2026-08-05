
import '../../domain/entity/akflight_search_entity.dart';

class AkFlightSearchModel extends AkFlightSearchEntity {
  const AkFlightSearchModel({
    required super.success,
    required super.tui,
    required super.sessionId,
  });

  factory AkFlightSearchModel.fromJson(Map<String, dynamic> json) {
    return AkFlightSearchModel(
      success: json['success'] ?? false,
      tui: json['tui'] ?? '',
      sessionId: json['session_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'tui': tui,
      'session_id': sessionId,
    };
  }
}

class TripModel extends TripEntity {
  const TripModel({
    required super.from,
    required super.to,
    required super.onwardDate,
    super.returnDate,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      onwardDate: json['onward_date'] ?? '',
      returnDate: json['return_date'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'from': from,
      'to': to,
      'onward_date': onwardDate,
    };
    if (returnDate != null) {
      data['return_date'] = returnDate;
    }
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