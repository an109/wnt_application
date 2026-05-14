import 'package:equatable/equatable.dart';

class ExclusiveDealEntity extends Equatable {
  final int id;
  final int reseller;
  final String ownerTab;
  final String category;
  final String brand;
  final String title;
  final String imageUrl;
  final String description;
  final String shortDescription;
  final String discountText;
  final String couponCode;
  final String validUpto;
  final String sectorType;
  final dynamic linkUrl;
  final bool isHotDeal;
  final String country;
  final bool isFixedDeparture;
  final bool isCoachTour;
  final int order;
  final bool isActive;
  final DateTime created;
  final DateTime updated;

  const ExclusiveDealEntity({
    required this.id,
    required this.reseller,
    required this.ownerTab,
    required this.category,
    required this.brand,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.shortDescription,
    required this.discountText,
    required this.couponCode,
    required this.validUpto,
    required this.sectorType,
    required this.linkUrl,
    required this.isHotDeal,
    required this.country,
    required this.isFixedDeparture,
    required this.isCoachTour,
    required this.order,
    required this.isActive,
    required this.created,
    required this.updated,
  });

  @override
  List<Object?> get props => [
    id,
    reseller,
    ownerTab,
    category,
    brand,
    title,
    imageUrl,
    description,
    shortDescription,
    discountText,
    couponCode,
    validUpto,
    sectorType,
    linkUrl,
    isHotDeal,
    country,
    isFixedDeparture,
    isCoachTour,
    order,
    isActive,
    created,
    updated,
  ];
}