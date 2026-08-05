
import '../../domain/entity/AKFlights_entity.dart';

class AkflightsModel extends AkflightsEntity {
  const AkflightsModel({
    required super.index,
    required super.netFare,
    required super.provider,
    required super.marketingAirlineCode,
    required super.flightNo,
    required super.departureTime,
    required super.arrivalTime,
    required super.stops,
    required super.refundable,
    required super.origin,
    required super.destination,
    required super.originName,
    required super.destinationName,
    required super.airlineName,
    required super.duration,
    required super.cabin,
  });

  factory AkflightsModel.fromJson(Map<String, dynamic> json) {
    return AkflightsModel(
      index: json['Index']?.toString() ?? '',
      netFare: (json['NetFare'] ?? 0).toDouble(),
      provider: json['Provider']?.toString() ?? '',
      marketingAirlineCode: json['MAC']?.toString() ?? '',
      flightNo: json['FlightNo']?.toString() ?? '',
      departureTime: json['DepartureTime']?.toString() ?? '',
      arrivalTime: json['ArrivalTime']?.toString() ?? '',
      stops: json['Stops'] ?? 0,
      refundable: json['Refundable']?.toString() ?? '',
      origin: json['From']?.toString() ?? '',
      destination: json['To']?.toString() ?? '',
      originName: json['FromName']?.toString() ?? '',
      destinationName: json['ToName']?.toString() ?? '',
      airlineName: json['AirlineName']?.toString() ?? '',
      duration: json['Duration']?.toString() ?? '',
      cabin: json['Cabin']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Index': index,
      'NetFare': netFare,
      'Provider': provider,
      'MAC': marketingAirlineCode,
      'FlightNo': flightNo,
      'DepartureTime': departureTime,
      'ArrivalTime': arrivalTime,
      'Stops': stops,
      'Refundable': refundable,
      'From': origin,
      'To': destination,
      'FromName': originName,
      'ToName': destinationName,
      'AirlineName': airlineName,
      'Duration': duration,
      'Cabin': cabin,
    };
  }
}

class TripModel extends TripEntity {
  const TripModel({required super.journey});

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final journeyList = json['Journey'] as List? ?? [];
    final journey = journeyList
        .map((f) => AkflightsModel.fromJson(f as Map<String, dynamic>))
        .toList();
    return TripModel(journey: journey);
  }

  Map<String, dynamic> toJson() {
    return {
      'Journey': journey.map((f) => (f as AkflightsModel).toJson()).toList(),
    };
  }
}

class AkflightsSearchModel extends AkflightsSearchEntity {
  const AkflightsSearchModel({
    required super.success,
    required super.completed,
    required super.trips,
  });

  factory AkflightsSearchModel.fromJson(Map<String, dynamic> json) {
    final tripsList = json['Trips'] as List? ?? [];
    final trips = tripsList
        .map((trip) => TripModel.fromJson(trip))
        .toList();

    return AkflightsSearchModel(
      success: json['success'] ?? false,
      completed: json['Completed'] ?? false,
      trips: trips,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'Completed': completed,
      'Trips': trips.map((t) => (t as TripModel).toJson()).toList(),
    };
  }
}
