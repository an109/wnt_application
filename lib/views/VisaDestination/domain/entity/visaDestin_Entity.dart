import 'package:equatable/equatable.dart';

class VisaDestinationEntity extends Equatable {
  final int id;
  final String name;
  final String region;
  final String price;
  final String priceCurrency;
  final String processingTime;
  final String? heroBannerImageUrl;
  final String? heroBannerImage;
  final String? imageUrl;
  final String? VisaIntroParagraph;
  final List<VisaTypeEntity> visaTypes;
  final String priceIncludesHeading;
  final List<String> priceIncludesItems;
  final List<String> requirementsItems;

  const VisaDestinationEntity({
    required this.id,
    required this.name,
    required this.region,
    required this.price,
    required this.priceCurrency,
    required this.processingTime,
    this.heroBannerImageUrl,
    this.heroBannerImage,
    this.imageUrl,
    this.VisaIntroParagraph,
    required this.visaTypes,
    required this.priceIncludesHeading,
    required this.priceIncludesItems,
    required this.requirementsItems,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    region,
    price,
    priceCurrency,
    processingTime,
    heroBannerImageUrl,
    visaTypes,
    priceIncludesHeading,
    priceIncludesItems,
    requirementsItems,
    heroBannerImage,
    imageUrl,
    VisaIntroParagraph,
  ];
}

class VisaTypeEntity extends Equatable {
  final String stay;
  final String entry;
  final String title;
  final num feesInr;
  final bool popular;
  final String validity;
  final String processing;

  const VisaTypeEntity({
    required this.stay,
    required this.entry,
    required this.title,
    required this.feesInr,
    required this.popular,
    required this.validity,
    required this.processing,
  });

  @override
  List<Object?> get props => [
    stay,
    entry,
    title,
    feesInr,
    popular,
    validity,
    processing,
  ];
}