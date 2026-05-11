class MealDynamicModel {
  final String? airlineCode;
  final String? flightNumber;
  final int? wayType;
  final String? code;
  final int? description;
  final String? airlineDescription;
  final int? quantity;
  final String? currency;
  final double? price;
  final String? origin;
  final String? destination;

  MealDynamicModel({
    this.airlineCode,
    this.flightNumber,
    this.wayType,
    this.code,
    this.description,
    this.airlineDescription,
    this.quantity,
    this.currency,
    this.price,
    this.origin,
    this.destination,
  });

  factory MealDynamicModel.fromJson(Map<String, dynamic> json) {
    return MealDynamicModel(
      airlineCode: json['AirlineCode'] as String?,
      flightNumber: json['FlightNumber'] as String?,
      wayType: json['WayType'] as int?,
      code: json['Code'] as String?,
      description: json['Description'] as int?,
      airlineDescription: json['AirlineDescription'] as String?,
      quantity: json['Quantity'] as int?,
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
      'AirlineDescription': airlineDescription,
      'Quantity': quantity,
      'Currency': currency,
      'Price': price,
      'Origin': origin,
      'Destination': destination,
    };
  }
}