import 'package:equatable/equatable.dart';

class FareEntity extends Equatable {
  final double baseFare;
  final double tax;
  final double totalFare;
  final String currency;

  const FareEntity({
    required this.baseFare,
    required this.tax,
    required this.totalFare,
    required this.currency,
  });

  @override
  List<Object?> get props => [baseFare, tax, totalFare, currency];
}