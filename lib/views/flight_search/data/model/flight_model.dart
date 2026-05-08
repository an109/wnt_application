import '../../domain/entities/flight_entity.dart';

class FlightModel extends FlightEntity {
  const FlightModel({
    String? resultIndex,
    String? airlineCode,
    String? airlineName,
    String? flightNumber,
    String? origin,
    String? destination,
    String? departureTime,
    String? arrivalTime,
    String? duration,
    String? cabinClass,
    double? baseFare,
    double? tax,
    double? totalFare,
    String? currency,
    int? seatsAvailable,
  }) : super(
    resultIndex: resultIndex,
    airlineCode: airlineCode,
    airlineName: airlineName,
    flightNumber: flightNumber,
    origin: origin,
    destination: destination,
    departureTime: departureTime,
    arrivalTime: arrivalTime,
    duration: duration,
    cabinClass: cabinClass,
    baseFare: baseFare,
    tax: tax,
    totalFare: totalFare,
    currency: currency,
    seatsAvailable: seatsAvailable,
  );

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    final fare = json['Fare'] as Map<String, dynamic>?;

    final segments = json['Segments'] as List<dynamic>?;

    Map<String, dynamic>? firstSegment;

    if (segments != null &&
        segments.isNotEmpty &&
        segments[0] is List &&
        (segments[0] as List).isNotEmpty) {
      firstSegment =
      (segments[0] as List).first as Map<String, dynamic>;
    }

    final origin = firstSegment?['Origin'] as Map<String, dynamic>?;
    final destination =
    firstSegment?['Destination'] as Map<String, dynamic>?;

    return FlightModel(
      resultIndex: json['ResultIndex'] as String?,
      airlineCode:
      firstSegment?['Airline']?['AirlineCode'] as String?,
      airlineName:
      firstSegment?['Airline']?['AirlineName'] as String?,
      flightNumber:
      firstSegment?['Airline']?['FlightNumber'] as String?,
      origin: origin?['Airport']?['AirportCode'] as String?,
      destination:
      destination?['Airport']?['AirportCode'] as String?,
      departureTime: origin?['DepTime'] as String?,
      arrivalTime: destination?['ArrTime'] as String?,
      duration: firstSegment?['Duration']?.toString(),
      cabinClass: firstSegment?['CabinClass']?.toString(),
      baseFare: (fare?['BaseFare'] as num?)?.toDouble(),
      tax: (fare?['Tax'] as num?)?.toDouble(),
      totalFare: (fare?['OfferedFare'] as num?)?.toDouble(),
      currency: fare?['Currency'] as String?,
      seatsAvailable:
      firstSegment?['NoOfSeatAvailable'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ResultIndex': resultIndex,
      'Fare': {
        'BaseFare': baseFare,
        'Tax': tax,
        'OfferedFare': totalFare,
        'Currency': currency,
      },
      'Segments': [
        {
          'Airline': {
            'AirlineCode': airlineCode,
            'AirlineName': airlineName,
            'FlightNumber': flightNumber,
          },
          'Origin': {
            'Airport': {
              'AirportCode': origin,
            },
            'DepTime': departureTime,
          },
          'Destination': {
            'Airport': {
              'AirportCode': destination,
            },
            'ArrTime': arrivalTime,
          },
          'Duration': duration,
          'CabinClass': cabinClass,
          'NoOfSeatAvailable': seatsAvailable,
        }
      ],
    };
  }
}