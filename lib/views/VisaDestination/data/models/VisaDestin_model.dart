import 'package:equatable/equatable.dart';

class VisaDestinationModel extends Equatable {
  final int id;
  final String name;
  final String region;
  final String price;
  final String priceCurrency;
  final String originalPriceCurrency;
  final String processingTime;
  final String? approvalRateText;
  final String? heroBannerImageUrl;
  final String? heroBannerImage;
  final String? imageUrl;
  final String? VisaIntroParagraph;
  final String? authorisedBadge;
  final List<VisaTypeModel> visaTypes;
  final String priceIncludesHeading;
  final List<String> priceIncludesItems;
  final List<String> requirementsItems;

  const VisaDestinationModel({
    required this.id,
    required this.name,
    required this.region,
    required this.price,
    required this.priceCurrency,
    required this.originalPriceCurrency,
    required this.processingTime,
    this.approvalRateText,
    this.heroBannerImageUrl,
    this.heroBannerImage,
    this.VisaIntroParagraph,
    this.imageUrl,
    this.authorisedBadge,
    required this.visaTypes,
    required this.priceIncludesHeading,
    required this.priceIncludesItems,
    required this.requirementsItems,
  });

  factory VisaDestinationModel.fromJson(Map<String, dynamic> json) {
    print(" Building Model from JSON for: ${json['name']}");
    print("   hero_banner_image from JSON: ${json['hero_banner_image']}");
    print("   image_url from JSON: ${json['image_url']}");
    return VisaDestinationModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      price: json['price'] ?? '0',
      priceCurrency: json['price_currency'] ?? 'USD',
      originalPriceCurrency: json['original_price_currency'] ?? 'INR',
      processingTime: json['processing_time'] ?? '',
      approvalRateText: json['approval_rate_text'],
      heroBannerImageUrl: json['hero_banner_image_url'],
      heroBannerImage: json['hero_banner_image'] ?? json['hero_banner_image_url'],
      imageUrl: json['image_url'] ?? json['img'],
      VisaIntroParagraph: json['visa_intro_paragraph'],
      authorisedBadge: json['authorised_badge'],
      visaTypes: json['visa_types'] != null
          ? List<VisaTypeModel>.from(
        json['visa_types'].map((x) => VisaTypeModel.fromJson(x)),
      )
          : [],
      priceIncludesHeading: json['price_includes_heading'] ?? '',
      priceIncludesItems: json['price_includes_items'] != null
          ? List<String>.from(json['price_includes_items'])
          : [],
      requirementsItems: json['requirements_items'] != null
          ? List<String>.from(json['requirements_items'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'price': price,
      'price_currency': priceCurrency,
      'original_price_currency': originalPriceCurrency,
      'processing_time': processingTime,
      'approval_rate_text': approvalRateText,
      'hero_banner_image_url': heroBannerImageUrl,
      'hero_banner_image': heroBannerImage,
      'image_url': imageUrl,
      'authorised_badge': authorisedBadge,
      'visa_types': visaTypes.map((x) => x.toJson()).toList(),
      'price_includes_heading': priceIncludesHeading,
      'price_includes_items': priceIncludesItems,
      'requirements_items': requirementsItems,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    region,
    price,
    priceCurrency,
    originalPriceCurrency,
    processingTime,
    approvalRateText,
    heroBannerImageUrl,
    heroBannerImage,
    imageUrl,
    authorisedBadge,
    visaTypes,
    priceIncludesHeading,
    priceIncludesItems,
    requirementsItems,
  ];
}

class VisaTypeModel extends Equatable {
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

  const VisaTypeModel({
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

  factory VisaTypeModel.fromJson(Map<String, dynamic> json) {
    return VisaTypeModel(
      stay: json['stay'] ?? '',
      entry: json['entry'] ?? '',
      title: json['title'] ?? '',
      taxInr: json['taxInr'] ?? 0,
      feesInr: json['feesInr'] ?? 0,
      popular: json['popular'] ?? false,
      validity: json['validity'] ?? '',
      processing: json['processing'] ?? '',
      taxCurrency: json['tax_currency'] ?? 'INR',
      feesCurrency: json['fees_currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stay': stay,
      'entry': entry,
      'title': title,
      'taxInr': taxInr,
      'feesInr': feesInr,
      'popular': popular,
      'validity': validity,
      'processing': processing,
      'tax_currency': taxCurrency,
      'fees_currency': feesCurrency,
    };
  }

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

class VisaDestinationResponseModel extends Equatable {
  final bool success;
  final List<VisaDestinationModel> destinations;

  const VisaDestinationResponseModel({
    required this.success,
    required this.destinations,
  });

  factory VisaDestinationResponseModel.fromJson(Map<String, dynamic> json) {
    return VisaDestinationResponseModel(
      success: json['success'] ?? false,
      destinations: json['destinations'] != null
          ? List<VisaDestinationModel>.from(
        json['destinations'].map((x) => VisaDestinationModel.fromJson(x)),
      )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'destinations': destinations.map((x) => x.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [success, destinations];
}