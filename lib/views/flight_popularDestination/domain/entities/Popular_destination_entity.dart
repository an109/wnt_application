import 'package:equatable/equatable.dart';

class DestinationEntity extends Equatable {
  final int id;
  final int reseller;
  final String name;
  final String price;
  final String priceCurrency;
  final String imageUrl;
  final String country;
  final String state;
  final String city;
  final String type;
  final bool isFeatured;
  final bool showInHolidaysTrending;
  final String domesticRegion;
  final String originalPrice;
  final String originalPriceCurrency;
  final List<String> whereToGoMonths;
  final String tagline;
  final String description;
  final String longDescription;
  final List<PackageEntity>? packages;
  final int order;
  final bool isActive;
  final DateTime created;
  final DateTime updated;
  final String img;

  const DestinationEntity({
    required this.id,
    required this.reseller,
    required this.name,
    required this.price,
    required this.priceCurrency,
    required this.imageUrl,
    required this.country,
    required this.state,
    required this.city,
    required this.type,
    required this.isFeatured,
    required this.showInHolidaysTrending,
    required this.domesticRegion,
    required this.originalPrice,
    required this.originalPriceCurrency,
    required this.whereToGoMonths,
    required this.tagline,
    required this.description,
    required this.longDescription,
    this.packages,
    required this.order,
    required this.isActive,
    required this.created,
    required this.updated,
    required this.img,
  });

  @override
  List<Object?> get props => [
    id,
    reseller,
    name,
    price,
    priceCurrency,
    imageUrl,
    country,
    state,
    city,
    type,
    isFeatured,
    showInHolidaysTrending,
    domesticRegion,
    originalPrice,
    originalPriceCurrency,
    whereToGoMonths,
    tagline,
    description,
    longDescription,
    packages,
    order,
    isActive,
    created,
    updated,
    img,
  ];
}

class PackageEntity extends Equatable {
  final int id;
  final String title;
  final String imageUrl;
  final String slug;
  final int nights;
  final int days;
  final String packagePrice;
  final String? originalPrice;
  final List<AccommodationTierEntity> accommodationTiers;

  const PackageEntity({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.slug,
    required this.nights,
    required this.days,
    required this.packagePrice,
    this.originalPrice,
    required this.accommodationTiers,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    imageUrl,
    slug,
    nights,
    days,
    packagePrice,
    originalPrice,
    accommodationTiers,
  ];
}

class AccommodationTierEntity extends Equatable {
  final String name;
  final String tier;
  final int stars;

  const AccommodationTierEntity({
    required this.name,
    required this.tier,
    required this.stars,
  });

  @override
  List<Object?> get props => [name, tier, stars];
}