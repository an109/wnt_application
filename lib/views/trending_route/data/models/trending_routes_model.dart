import '../../domain/entities/trending_routes_entity.dart';

class TrendingRouteModel extends TrendingRouteEntity {
  const TrendingRouteModel({
    required String to,
    required String date,
    required String from,
    required num price,
    required String toCode,
    required String currency,
    required String fromCode,
    required String imageUrl,
  }) : super(
    to: to,
    date: date,
    from: from,
    price: price,
    toCode: toCode,
    currency: currency,
    fromCode: fromCode,
    imageUrl: imageUrl,
  );

  factory TrendingRouteModel.fromJson(Map<String, dynamic> json) {
    return TrendingRouteModel(
      to: json['to'] ?? '',
      date: json['date'] ?? '',
      from: json['from'] ?? '',
      price: json['price'] ?? 0,
      toCode: json['to_code'] ?? '',
      currency: json['currency'] ?? '',
      fromCode: json['from_code'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'to': to,
      'date': date,
      'from': from,
      'price': price,
      'to_code': toCode,
      'currency': currency,
      'from_code': fromCode,
      'image_url': imageUrl,
    };
  }
}