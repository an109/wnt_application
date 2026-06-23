import '../../domain/entities/flight_entity.dart';

class FlightModel extends FlightEntity {
  const FlightModel({
    String? resultIndex, String? airlineCode, String? airlineName, String? flightNumber,
    String? origin, String? originName, String? destination, String? destinationName,
    String? departureTime, String? arrivalTime, String? duration, String? cabinClass,
    double? baseFare, double? tax, double? totalFare, String? currency, int? seatsAvailable,
    String? traceId, int? stops, bool isRoundTrip = false, String? returnDepartureTime,
    String? returnArrivalTime, String? returnDuration, String? returnOrigin,
    String? returnOriginName, String? returnDestination, String? returnDestinationName,
    int? returnStops,
  }) : super(
    resultIndex: resultIndex, airlineCode: airlineCode, airlineName: airlineName,
    flightNumber: flightNumber, origin: origin, originName: originName,
    destination: destination, destinationName: destinationName,
    departureTime: departureTime, arrivalTime: arrivalTime, duration: duration,
    cabinClass: cabinClass, baseFare: baseFare, tax: tax, totalFare: totalFare,
    currency: currency, seatsAvailable: seatsAvailable, traceId: traceId,
    stops: stops, isRoundTrip: isRoundTrip, returnDepartureTime: returnDepartureTime,
    returnArrivalTime: returnArrivalTime, returnDuration: returnDuration,
    returnOrigin: returnOrigin, returnOriginName: returnOriginName,
    returnDestination: returnDestination, returnDestinationName: returnDestinationName,
    returnStops: returnStops,
  );

  factory FlightModel.fromJson(Map<String, dynamic> json, {String? responseTraceId}) {
    final fare = json['Fare'] as Map<String, dynamic>?;
    final segments = json['Segments'] as List<dynamic>?;

    Map<String, dynamic>? firstSegment;
    Map<String, dynamic>? returnSegment;
    int? stops;
    int? returnStops;

    // Check if it's a round trip (Segments array has more than 1 element)
    final isRoundTrip = segments != null && segments.length > 1;

    if (segments != null && segments.isNotEmpty && segments[0] is List && (segments[0] as List).isNotEmpty) {
      final outboundLegs = segments[0] as List;
      firstSegment = outboundLegs.first as Map<String, dynamic>;
      // Stops = number of connecting legs (non-stop when there is a single leg).
      stops = outboundLegs.length - 1;
    }

    if (isRoundTrip && segments[1] is List && (segments[1] as List).isNotEmpty) {
      final returnLegs = segments[1] as List;
      returnSegment = returnLegs.first as Map<String, dynamic>;
      returnStops = returnLegs.length - 1;
    }

    final origin = firstSegment?['Origin'] as Map<String, dynamic>?;
    final destination = firstSegment?['Destination'] as Map<String, dynamic>?;
    final originAirport = origin?['Airport'] as Map<String, dynamic>?;
    final destinationAirport = destination?['Airport'] as Map<String, dynamic>?;

    final returnOrigin = returnSegment?['Origin'] as Map<String, dynamic>?;
    final returnDestination = returnSegment?['Destination'] as Map<String, dynamic>?;
    final returnOriginAirport = returnOrigin?['Airport'] as Map<String, dynamic>?;
    final returnDestinationAirport = returnDestination?['Airport'] as Map<String, dynamic>?;

    return FlightModel(
      resultIndex: json['ResultIndex'] as String?,
      traceId: responseTraceId,
      airlineCode: firstSegment?['Airline']?['AirlineCode'] as String?,
      airlineName: firstSegment?['Airline']?['AirlineName'] as String?,
      flightNumber: firstSegment?['Airline']?['FlightNumber'] as String?,
      origin: originAirport?['AirportCode'] as String?,
      originName: originAirport?['AirportName'] as String?,
      destination: destinationAirport?['AirportCode'] as String?,
      destinationName: destinationAirport?['AirportName'] as String?,
      departureTime: origin?['DepTime'] as String?,
      arrivalTime: destination?['ArrTime'] as String?,
      duration: firstSegment?['Duration']?.toString(),
      cabinClass: firstSegment?['CabinClass']?.toString(),
      baseFare: (fare?['BaseFare'] as num?)?.toDouble(),
      tax: (fare?['Tax'] as num?)?.toDouble(),
      totalFare: (fare?['OfferedFare'] as num?)?.toDouble(),
      currency: fare?['Currency'] as String?,
      seatsAvailable: firstSegment?['NoOfSeatAvailable'] as int?,
      stops: stops,
      returnStops: returnStops,
      isRoundTrip: isRoundTrip,
      returnDepartureTime: returnOrigin?['DepTime'] as String?,
      returnArrivalTime: returnDestination?['ArrTime'] as String?,
      returnDuration: returnSegment?['Duration']?.toString(),
      returnOrigin: returnOriginAirport?['AirportCode'] as String?,
      returnOriginName: returnOriginAirport?['AirportName'] as String?,
      returnDestination: returnDestinationAirport?['AirportCode'] as String?,
      returnDestinationName: returnDestinationAirport?['AirportName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {}; // Keep your existing toJson implementation if needed
  }
}