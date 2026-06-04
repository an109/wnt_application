// import '../../domain/entities/flight_entity.dart';
//
// class FlightModel extends FlightEntity {
//   const FlightModel({
//     String? resultIndex,
//     String? airlineCode,
//     String? airlineName,
//     String? flightNumber,
//     String? origin,
//     String? destination,
//     String? departureTime,
//     String? arrivalTime,
//     String? duration,
//     String? cabinClass,
//     double? baseFare,
//     double? tax,
//     double? totalFare,
//     String? currency,
//     int? seatsAvailable,
//     String? traceId,
//   }) : super(
//     resultIndex: resultIndex,
//     airlineCode: airlineCode,
//     airlineName: airlineName,
//     flightNumber: flightNumber,
//     origin: origin,
//     destination: destination,
//     departureTime: departureTime,
//     arrivalTime: arrivalTime,
//     duration: duration,
//     cabinClass: cabinClass,
//     baseFare: baseFare,
//     tax: tax,
//     totalFare: totalFare,
//     currency: currency,
//     seatsAvailable: seatsAvailable,
//     traceId: traceId,
//   );
//
//   factory FlightModel.fromJson(Map<String, dynamic> json, {String? responseTraceId}) {
//     final fare = json['Fare'] as Map<String, dynamic>?;
//
//     final segments = json['Segments'] as List<dynamic>?;
//
//     Map<String, dynamic>? firstSegment;
//
//     if (segments != null &&
//         segments.isNotEmpty &&
//         segments[0] is List &&
//         (segments[0] as List).isNotEmpty) {
//       firstSegment =
//       (segments[0] as List).first as Map<String, dynamic>;
//     }
//
//     final origin = firstSegment?['Origin'] as Map<String, dynamic>?;
//     final destination =
//     firstSegment?['Destination'] as Map<String, dynamic>?;
//
//     return FlightModel(
//       resultIndex: json['ResultIndex'] as String?,
//       traceId: responseTraceId,
//       airlineCode:
//       firstSegment?['Airline']?['AirlineCode'] as String?,
//       airlineName:
//       firstSegment?['Airline']?['AirlineName'] as String?,
//       flightNumber:
//       firstSegment?['Airline']?['FlightNumber'] as String?,
//       origin: origin?['Airport']?['AirportCode'] as String?,
//       destination:
//       destination?['Airport']?['AirportCode'] as String?,
//       departureTime: origin?['DepTime'] as String?,
//       arrivalTime: destination?['ArrTime'] as String?,
//       duration: firstSegment?['Duration']?.toString(),
//       cabinClass: firstSegment?['CabinClass']?.toString(),
//       baseFare: (fare?['BaseFare'] as num?)?.toDouble(),
//       tax: (fare?['Tax'] as num?)?.toDouble(),
//       totalFare: (fare?['OfferedFare'] as num?)?.toDouble(),
//       currency: fare?['Currency'] as String?,
//       seatsAvailable:
//       firstSegment?['NoOfSeatAvailable'] as int?,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     print('========== FLIGHT DATA ==========');
//     print('TraceId: $traceId');
//     print('ResultIndex: $resultIndex');
//     print('==================================');
//     return {
//       'ResultIndex': resultIndex,
//       'Fare': {
//         'BaseFare': baseFare,
//         'Tax': tax,
//         'OfferedFare': totalFare,
//         'Currency': currency,
//       },
//       'Segments': [
//         {
//           'Airline': {
//             'AirlineCode': airlineCode,
//             'AirlineName': airlineName,
//             'FlightNumber': flightNumber,
//           },
//           'Origin': {
//             'Airport': {
//               'AirportCode': origin,
//             },
//             'DepTime': departureTime,
//           },
//           'Destination': {
//             'Airport': {
//               'AirportCode': destination,
//             },
//             'ArrTime': arrivalTime,
//           },
//           'Duration': duration,
//           'CabinClass': cabinClass,
//           'NoOfSeatAvailable': seatsAvailable,
//         }
//       ],
//     };
//   }
// }

import '../../domain/entities/flight_entity.dart';

class FlightModel extends FlightEntity {
  const FlightModel({
    String? resultIndex, String? airlineCode, String? airlineName, String? flightNumber,
    String? origin, String? originName, String? destination, String? destinationName,
    String? departureTime, String? arrivalTime, String? duration, String? cabinClass,
    double? baseFare, double? tax, double? totalFare, String? currency, int? seatsAvailable,
    String? traceId, bool isRoundTrip = false, String? returnDepartureTime,
    String? returnArrivalTime, String? returnDuration, String? returnOrigin,
    String? returnOriginName, String? returnDestination, String? returnDestinationName,
  }) : super(
    resultIndex: resultIndex, airlineCode: airlineCode, airlineName: airlineName,
    flightNumber: flightNumber, origin: origin, originName: originName,
    destination: destination, destinationName: destinationName,
    departureTime: departureTime, arrivalTime: arrivalTime, duration: duration,
    cabinClass: cabinClass, baseFare: baseFare, tax: tax, totalFare: totalFare,
    currency: currency, seatsAvailable: seatsAvailable, traceId: traceId,
    isRoundTrip: isRoundTrip, returnDepartureTime: returnDepartureTime,
    returnArrivalTime: returnArrivalTime, returnDuration: returnDuration,
    returnOrigin: returnOrigin, returnOriginName: returnOriginName,
    returnDestination: returnDestination, returnDestinationName: returnDestinationName,
  );

  factory FlightModel.fromJson(Map<String, dynamic> json, {String? responseTraceId}) {
    final fare = json['Fare'] as Map<String, dynamic>?;
    final segments = json['Segments'] as List<dynamic>?;

    Map<String, dynamic>? firstSegment;
    Map<String, dynamic>? returnSegment;

    // Check if it's a round trip (Segments array has more than 1 element)
    final isRoundTrip = segments != null && segments.length > 1;

    if (segments != null && segments.isNotEmpty && segments[0] is List && (segments[0] as List).isNotEmpty) {
      firstSegment = (segments[0] as List).first as Map<String, dynamic>;
    }

    if (isRoundTrip && segments![1] is List && (segments[1] as List).isNotEmpty) {
      returnSegment = (segments[1] as List).first as Map<String, dynamic>;
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