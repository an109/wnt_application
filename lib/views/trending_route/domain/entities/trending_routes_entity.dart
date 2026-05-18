import 'package:equatable/equatable.dart';

class TrendingRouteEntity extends Equatable {
  final String to;
  final String date;
  final String from;
  final num price;
  final String toCode;
  final String currency;
  final String fromCode;
  final String imageUrl;

  const TrendingRouteEntity({
    required this.to,
    required this.date,
    required this.from,
    required this.price,
    required this.toCode,
    required this.currency,
    required this.fromCode,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [
    to,
    date,
    from,
    price,
    toCode,
    currency,
    fromCode,
    imageUrl,
  ];
}