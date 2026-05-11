import 'package:equatable/equatable.dart';

class BaggageOptionEntity extends Equatable {
  final String airlineCode;
  final String flightNumber;
  final int wayType;
  final String code;
  final int description;
  final int weight;
  final String currency;
  final double price;
  final String origin;
  final String destination;
  final bool isSelected;

  const BaggageOptionEntity({
    required this.airlineCode,
    required this.flightNumber,
    required this.wayType,
    required this.code,
    required this.description,
    required this.weight,
    required this.currency,
    required this.price,
    required this.origin,
    required this.destination,
    this.isSelected = false,
  });

  BaggageOptionEntity copyWith({bool? isSelected}) {
    return BaggageOptionEntity(
      airlineCode: airlineCode,
      flightNumber: flightNumber,
      wayType: wayType,
      code: code,
      description: description,
      weight: weight,
      currency: currency,
      price: price,
      origin: origin,
      destination: destination,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  String get displayTitle {
    if (code == 'NoBaggage') return 'No Checked Baggage';
    if (code.contains('EB')) return 'Extra Baggage';
    if (weight > 0) return '$weight kg Baggage';
    return 'Baggage Option';
  }

  String get displaySubtitle {
    if (code == 'NoBaggage') return 'Travel light with no checked baggage';
    if (code.contains('EB')) return 'Add extra baggage allowance';
    if (weight > 0) return 'Up to $weight kg included';
    return '';
  }

  String get displayPrice {
    if (price <= 0) return 'Free';
    return '$currency ${price.toStringAsFixed(2)}';
  }

  String get pricePerKg {
    if (price <= 0 || weight <= 0) return '';
    return '$currency ${(price / weight).toStringAsFixed(2)}/kg';
  }

  bool get isFree => price <= 0;
  bool get isNoBaggage => code == 'NoBaggage';

  @override
  List<Object?> get props => [
    airlineCode,
    flightNumber,
    wayType,
    code,
    description,
    weight,
    currency,
    price,
    origin,
    destination,
    isSelected,
  ];
}