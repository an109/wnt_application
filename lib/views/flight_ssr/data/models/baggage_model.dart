class BaggageModel {
  final String? airlineCode;
  final String? flightNumber;
  final int? wayType;
  final String? code;
  final int? description;
  final int? weight;
  final String? currency;
  final double? price;
  final String? origin;
  final String? destination;

  BaggageModel({
    this.airlineCode,
    this.flightNumber,
    this.wayType,
    this.code,
    this.description,
    this.weight,
    this.currency,
    this.price,
    this.origin,
    this.destination,
  });

  factory BaggageModel.fromJson(Map<String, dynamic> json) {
    return BaggageModel(
      airlineCode: json['AirlineCode'] as String?,
      flightNumber: json['FlightNumber'] as String?,
      wayType: json['WayType'] as int?,
      code: json['Code'] as String?,
      description: json['Description'] as int?,
      weight: json['Weight'] as int?,
      currency: json['Currency'] as String?,
      price: (json['Price'] as num?)?.toDouble(),
      origin: json['Origin'] as String?,
      destination: json['Destination'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AirlineCode': airlineCode,
      'FlightNumber': flightNumber,
      'WayType': wayType,
      'Code': code,
      'Description': description,
      'Weight': weight,
      'Currency': currency,
      'Price': price,
      'Origin': origin,
      'Destination': destination,
    };
  }
}