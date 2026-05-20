import 'package:equatable/equatable.dart';

class VisaPopularDestinationEntity extends Equatable {
  final int id;
  final int reseller;
  final String name;
  final String region;
  final String price;
  final String priceCurrency;
  final String processingTime;
  final String imageUrl;
  final List<VisaTypeEntity> visaTypes;
  final List<String> requirementsItems;
  final List<String> priceIncludesItems;
  final bool showInPopular;
  final bool isActive;

  const VisaPopularDestinationEntity({
    required this.id,
    required this.reseller,
    required this.name,
    required this.region,
    required this.price,
    required this.priceCurrency,
    required this.processingTime,
    required this.imageUrl,
    required this.visaTypes,
    required this.requirementsItems,
    required this.priceIncludesItems,
    required this.showInPopular,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    reseller,
    name,
    region,
    price,
    priceCurrency,
    processingTime,
    imageUrl,
    visaTypes,
    requirementsItems,
    priceIncludesItems,
    showInPopular,
    isActive,
  ];
}

class VisaTypeEntity extends Equatable {
  final String stay;
  final String entry;
  final String title;
  final int taxInr;
  final num feesInr;
  final bool popular;
  final String validity;
  final String processing;
  final String taxCurrency;
  final String feesCurrency;

  const VisaTypeEntity({
    required this.stay,
    required this.entry,
    required this.title,
    required this.taxInr,
    required this.feesInr,
    required this.popular,
    required this.validity,
    required this.processing,
    required this.taxCurrency,
    required this.feesCurrency,
  });

  @override
  List<Object?> get props => [
    stay,
    entry,
    title,
    taxInr,
    feesInr,
    popular,
    validity,
    processing,
    taxCurrency,
    feesCurrency,
  ];
}