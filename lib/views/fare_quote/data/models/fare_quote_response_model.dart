class FareQuoteResponseModel {
  final ResponseData? response;

  FareQuoteResponseModel({this.response});

  factory FareQuoteResponseModel.fromJson(Map<String, dynamic> json) {
    return FareQuoteResponseModel(
      response: json['Response'] != null
          ? ResponseData.fromJson(json['Response'])
          : null,
    );
  }
}

class ResponseData {
  final ErrorData? error;
  final bool? isPriceChanged;
  final int? responseStatus;
  final ResultsData? results;
  final String? traceId;

  ResponseData({
    this.error,
    this.isPriceChanged,
    this.responseStatus,
    this.results,
    this.traceId,
  });

  factory ResponseData.fromJson(Map<String, dynamic> json) {
    return ResponseData(
      error: json['Error'] != null ? ErrorData.fromJson(json['Error']) : null,
      isPriceChanged: json['IsPriceChanged'],
      responseStatus: json['ResponseStatus'],
      results: json['Results'] != null ? ResultsData.fromJson(json['Results']) : null,
      traceId: json['TraceId'],
    );
  }
}

class ErrorData {
  final int? errorCode;
  final String? errorMessage;

  ErrorData({this.errorCode, this.errorMessage});

  factory ErrorData.fromJson(Map<String, dynamic> json) {
    return ErrorData(
      errorCode: json['ErrorCode'],
      errorMessage: json['ErrorMessage'],
    );
  }
}

class ResultsData {
  final String? resultIndex;
  final bool? isRefundable;
  final bool? isHoldAllowed;
  final String? airlineCode;
  final String? resultFareType;
  final FareData? fare;
  final List<List<SegmentData>>? segments;

  ResultsData({
    this.resultIndex,
    this.isRefundable,
    this.isHoldAllowed,
    this.airlineCode,
    this.resultFareType,
    this.fare,
    this.segments,
  });

  factory ResultsData.fromJson(Map<String, dynamic> json) {
    return ResultsData(
      resultIndex: json['ResultIndex'],
      isRefundable: json['IsRefundable'],
      isHoldAllowed: json['IsHoldAllowed'],
      airlineCode: json['AirlineCode'],
      resultFareType: json['ResultFareType'],
      fare: json['Fare'] != null ? FareData.fromJson(json['Fare']) : null,
      segments: json['Segments'] != null
          ? (json['Segments'] as List).map((segmentList) =>
          (segmentList as List).map((item) => SegmentData.fromJson(item)).toList()).toList()
          : null,
    );
  }
}

class FareData {
  final String? currency;
  final double? baseFare;
  final double? tax;
  final double? offeredFare;
  final double? publishedFare;
  final double? serviceFee;

  FareData({
    this.currency,
    this.baseFare,
    this.tax,
    this.offeredFare,
    this.publishedFare,
    this.serviceFee,
  });

  factory FareData.fromJson(Map<String, dynamic> json) {
    return FareData(
      currency: json['Currency'],
      baseFare: (json['BaseFare'] as num?)?.toDouble(),
      tax: (json['Tax'] as num?)?.toDouble(),
      offeredFare: (json['OfferedFare'] as num?)?.toDouble(),
      publishedFare: (json['PublishedFare'] as num?)?.toDouble(),
      serviceFee: (json['ServiceFee'] as num?)?.toDouble(),
    );
  }
}

class SegmentData {
  final String? baggage;
  final AirlineData? airline;
  final OriginData? origin;
  final DestinationData? destination;
  final int? duration;

  SegmentData({
    this.baggage,
    this.airline,
    this.origin,
    this.destination,
    this.duration,
  });

  factory SegmentData.fromJson(Map<String, dynamic> json) {
    return SegmentData(
      baggage: json['Baggage'],
      airline: json['Airline'] != null ? AirlineData.fromJson(json['Airline']) : null,
      origin: json['Origin'] != null ? OriginData.fromJson(json['Origin']) : null,
      destination: json['Destination'] != null ? DestinationData.fromJson(json['Destination']) : null,
      duration: json['Duration'],
    );
  }
}

class AirlineData {
  final String? airlineCode;
  final String? airlineName;
  final String? flightNumber;

  AirlineData({
    this.airlineCode,
    this.airlineName,
    this.flightNumber,
  });

  factory AirlineData.fromJson(Map<String, dynamic> json) {
    return AirlineData(
      airlineCode: json['AirlineCode'],
      airlineName: json['AirlineName'],
      flightNumber: json['FlightNumber'],
    );
  }
}

class OriginData {
  final AirportData? airport;
  final String? depTime;

  OriginData({this.airport, this.depTime});

  factory OriginData.fromJson(Map<String, dynamic> json) {
    return OriginData(
      airport: json['Airport'] != null ? AirportData.fromJson(json['Airport']) : null,
      depTime: json['DepTime'],
    );
  }
}

class DestinationData {
  final AirportData? airport;
  final String? arrTime;

  DestinationData({this.airport, this.arrTime});

  factory DestinationData.fromJson(Map<String, dynamic> json) {
    return DestinationData(
      airport: json['Airport'] != null ? AirportData.fromJson(json['Airport']) : null,
      arrTime: json['ArrTime'],
    );
  }
}

class AirportData {
  final String? airportCode;
  final String? airportName;
  final String? cityName;
  final String? terminal;

  AirportData({
    this.airportCode,
    this.airportName,
    this.cityName,
    this.terminal,
  });

  factory AirportData.fromJson(Map<String, dynamic> json) {
    return AirportData(
      airportCode: json['AirportCode'],
      airportName: json['AirportName'],
      cityName: json['CityName'],
      terminal: json['Terminal'],
    );
  }
}