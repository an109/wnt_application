import '../../domain/entities/holiday_destination_entity.dart';

class HolidayDestinationModel extends HolidayDestinationEntity {
  const HolidayDestinationModel({
    required super.id,
    required super.reseller,
    required super.name,
    required super.price,
    required super.priceCurrency,
    required super.imageUrl,
    required super.country,
    required super.state,
    required super.city,
    required super.type,
    required super.isFeatured,
    required super.showInHolidaysTrending,
    required super.domesticRegion,
    required super.originalPrice,
    required super.originalPriceCurrency,
    required super.whereToGoMonths,
    required super.tagline,
    required super.description,
    required super.longDescription,
    required super.packages,
    required super.order,
    required super.isActive,
    required super.created,
    required super.updated,
    required super.img,
  });

  factory HolidayDestinationModel.fromJson(Map<String, dynamic> json) {
    return HolidayDestinationModel(
      id: json['id'] ?? 0,
      reseller: json['reseller'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      priceCurrency: json['price_currency'] ?? '',
      imageUrl: json['image_url'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      type: json['type'] ?? '',
      isFeatured: json['is_featured'] ?? false,
      showInHolidaysTrending: json['show_in_holidays_trending'] ?? false,
      domesticRegion: json['domestic_region'] ?? '',
      originalPrice: json['original_price'] ?? '',
      originalPriceCurrency: json['original_price_currency'] ?? '',
      whereToGoMonths: json['where_to_go_months'] != null
          ? List<String>.from(json['where_to_go_months'])
          : [],
      tagline: json['tagline'] ?? '',
      description: json['description'] ?? '',
      longDescription: json['long_description'] ?? '',
      packages: json['packages'] != null
          ? List<Map<String, dynamic>>.from(json['packages'])
          : [],
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? false,
      created: json['created'] ?? '',
      updated: json['updated'] ?? '',
      img: json['img'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reseller': reseller,
      'name': name,
      'price': price,
      'price_currency': priceCurrency,
      'image_url': imageUrl,
      'country': country,
      'state': state,
      'city': city,
      'type': type,
      'is_featured': isFeatured,
      'show_in_holidays_trending': showInHolidaysTrending,
      'domestic_region': domesticRegion,
      'original_price': originalPrice,
      'original_price_currency': originalPriceCurrency,
      'where_to_go_months': whereToGoMonths,
      'tagline': tagline,
      'description': description,
      'long_description': longDescription,
      'packages': packages,
      'order': order,
      'is_active': isActive,
      'created': created,
      'updated': updated,
      'img': img,
    };
  }
}