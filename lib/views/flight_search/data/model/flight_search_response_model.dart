import 'flight_model.dart';

class FlightSearchResponseModel {
  final List<FlightModel> flights;
  final String? traceId;
  final String? origin;
  final String? destination;

  const FlightSearchResponseModel({
    required this.flights,
    this.traceId,
    this.origin,
    this.destination,
  });

  factory FlightSearchResponseModel.fromJson(Map<String, dynamic> json) {
    final response = json['Response'] as Map<String, dynamic>;
    final results = response['Results'] as List<dynamic>? ?? [];

    List<FlightModel> flights = [];

    for (var result in results) {
      if (result is List && result.isNotEmpty) {
        for (var flightData in result) {
          if (flightData is Map<String, dynamic>) {
            flights.add(FlightModel.fromJson(flightData));
          }
        }
      }
    }

    return FlightSearchResponseModel(
      flights: flights,
      traceId: response['TraceId'] as String?,
      origin: response['Origin'] as String?,
      destination: response['Destination'] as String?,
    );
  }
}