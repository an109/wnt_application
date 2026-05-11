class SpecialServiceModel {
  final List<SegmentSpecialService>? segmentSpecialService;

  SpecialServiceModel({this.segmentSpecialService});

  factory SpecialServiceModel.fromJson(Map<String, dynamic> json) {
    return SpecialServiceModel(
      segmentSpecialService: (json['SegmentSpecialService'] as List?)?.map((item) =>
          SegmentSpecialService.fromJson(item)
      ).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SegmentSpecialService': segmentSpecialService?.map((item) => item.toJson()).toList(),
    };
  }
}

class SegmentSpecialService {
  final List<SsrService>? ssrService;

  SegmentSpecialService({this.ssrService});

  factory SegmentSpecialService.fromJson(Map<String, dynamic> json) {
    return SegmentSpecialService(
      ssrService: (json['SSRService'] as List?)?.map((item) =>
          SsrService.fromJson(item)
      ).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SSRService': ssrService?.map((item) => item.toJson()).toList(),
    };
  }
}

class SsrService {
  final String? origin;
  final String? destination;
  final String? departureTime;
  final String? airlineCode;
  final String? flightNumber;
  final String? code;
  final int? serviceType;
  final String? text;
  final int? wayType;
  final String? currency;
  final double? price;

  SsrService({
    this.origin,
    this.destination,
    this.departureTime,
    this.airlineCode,
    this.flightNumber,
    this.code,
    this.serviceType,
    this.text,
    this.wayType,
    this.currency,
    this.price,
  });

  factory SsrService.fromJson(Map<String, dynamic> json) {
    return SsrService(
      origin: json['Origin'] as String?,
      destination: json['Destination'] as String?,
      departureTime: json['DepartureTime'] as String?,
      airlineCode: json['AirlineCode'] as String?,
      flightNumber: json['FlightNumber'] as String?,
      code: json['Code'] as String?,
      serviceType: json['ServiceType'] as int?,
      text: json['Text'] as String?,
      wayType: json['WayType'] as int?,
      currency: json['Currency'] as String?,
      price: (json['Price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Origin': origin,
      'Destination': destination,
      'DepartureTime': departureTime,
      'AirlineCode': airlineCode,
      'FlightNumber': flightNumber,
      'Code': code,
      'ServiceType': serviceType,
      'Text': text,
      'WayType': wayType,
      'Currency': currency,
      'Price': price,
    };
  }
}