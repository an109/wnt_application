import '../../domain/entities/visa_destination_entity.dart';

class VisaPopularDestinationModel extends VisaPopularDestinationEntity {
  const VisaPopularDestinationModel({
    required super.id,
    required super.reseller,
    required super.name,
    required super.region,
    required super.price,
    required super.priceCurrency,
    required super.processingTime,
    required super.imageUrl,
    required super.visaTypes,
    required super.requirementsItems,
    required super.priceIncludesItems,
    required super.showInPopular,
    required super.isActive,
    super.heroBannerImage,
    super.approvalRateText,
    super.requirementsHeading,
    super.faqs,
    super.requiredDocuments,
    super.appInsights,
  });

  factory VisaPopularDestinationModel.fromJson(Map<String, dynamic> json) {
    return VisaPopularDestinationModel(
      id: json['id'] ?? 0,
      reseller: json['reseller'] ?? 0,
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      price: json['price']?.toString() ?? '0',
      priceCurrency: json['price_currency'] ?? 'USD',
      processingTime: json['processing_time'] ?? '',
      imageUrl: json['image_url'] ?? json['img'] ?? '',
      visaTypes: (json['visa_types'] as List<dynamic>?)
          ?.map((item) => VisaTypeModel.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      requirementsItems: (json['requirements_items'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          [],
      priceIncludesItems: (json['price_includes_items'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          [],
      showInPopular: json['show_in_popular'] ?? false,
      isActive: json['is_active'] ?? false,
      heroBannerImage:
          json['hero_banner_image']?.toString() ??
          json['hero_banner_image_url']?.toString() ??
          '',
      approvalRateText: json['approval_rate_text']?.toString() ?? '',
      requirementsHeading: json['requirements_heading']?.toString() ?? '',
      faqs: (json['faqs'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((f) => {
                    'q': (f['q'] ?? f['question'] ?? '').toString(),
                    'a': (f['a'] ?? f['answer'] ?? '').toString(),
                  })
              .where((f) => f['q']!.isNotEmpty)
              .toList() ??
          [],
      // Admin stores either plain labels or {label, required}.
      requiredDocuments: (json['required_documents'] as List<dynamic>?)
              ?.map((d) => d is Map ? (d['label'] ?? '').toString() : d.toString())
              .where((d) => d.isNotEmpty)
              .toList() ??
          [],
      appInsights: json['app_insights'] is Map
          ? (json['app_insights'] as Map).cast<String, dynamic>()
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reseller': reseller,
      'name': name,
      'region': region,
      'price': price,
      'price_currency': priceCurrency,
      'processing_time': processingTime,
      'image_url': imageUrl,
      'visa_types': visaTypes.map((type) => (type as VisaTypeModel).toJson()).toList(),
      'requirements_items': requirementsItems,
      'price_includes_items': priceIncludesItems,
      'show_in_popular': showInPopular,
      'is_active': isActive,
    };
  }
}

class VisaTypeModel extends VisaTypeEntity {
  const VisaTypeModel({
    required super.stay,
    required super.entry,
    required super.title,
    required super.taxInr,
    required super.feesInr,
    required super.popular,
    required super.validity,
    required super.processing,
    required super.taxCurrency,
    required super.feesCurrency,
    super.category,
  });

  factory VisaTypeModel.fromJson(Map<String, dynamic> json) {
    return VisaTypeModel(
      stay: json['stay'] ?? '',
      entry: json['entry'] ?? '',
      title: json['title'] ?? '',
      taxInr: _parseNum(json['taxInr']).toInt(),
      feesInr: _parseNum(json['feesInr']),
      popular: json['popular'] ?? false,
      validity: json['validity'] ?? '',
      processing: json['processing'] ?? '',
      taxCurrency: json['tax_currency'] ?? 'INR',
      feesCurrency: json['fees_currency'] ?? 'USD',
      category: json['category']?.toString() ?? '',
    );
  }

  static num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      return double.tryParse(value) ?? int.tryParse(value) ?? 0;
    }
    return 0;
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
}