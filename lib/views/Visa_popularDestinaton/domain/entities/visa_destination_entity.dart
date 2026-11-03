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
  final String heroBannerImage;
  final String approvalRateText;
  final String requirementsHeading;
  /// `{q, a}` pairs from the destination's FAQ list.
  final List<Map<String, String>> faqs;
  /// Documents the applicant must provide, as configured per destination in
  /// the reseller dashboard. Each one may be tied to a single occupation.
  final List<VisaRequiredDocument> requiredDocuments;
  /// Admin-entered stats for the app visa page (forecast, portal uptime …);
  /// empty when not filled in.
  final Map<String, dynamic> appInsights;

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
    this.heroBannerImage = '',
    this.approvalRateText = '',
    this.requirementsHeading = '',
    this.faqs = const [],
    this.requiredDocuments = const [],
    this.appInsights = const {},
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
    heroBannerImage,
    approvalRateText,
    requirementsHeading,
    faqs,
    requiredDocuments,
    appInsights,
  ];

  /// Plain labels, for the places that only list the documents as text.
  List<String> get requiredDocumentLabels =>
      [for (final d in requiredDocuments) d.label];

  /// The documents an applicant with [occupation] has to provide. Documents
  /// left on "All" apply to everyone; when the occupation is unknown only
  /// those are asked for, rather than every occupation's documents at once.
  List<VisaRequiredDocument> documentsFor(String occupation) {
    if (occupation.trim().isEmpty) {
      return [for (final d in requiredDocuments) if (d.forEveryone) d];
    }
    return [for (final d in requiredDocuments) if (d.appliesTo(occupation)) d];
  }
}

/// One configured document: `{label, description, required, occupation}` as
/// stored in `VisaPopularDestination.required_documents`.
class VisaRequiredDocument extends Equatable {
  final String label;
  final String description;
  final bool required;

  /// `All` (everyone) or one of Employee | Self-Employed | Student | Homemaker.
  final String occupation;

  const VisaRequiredDocument({
    required this.label,
    this.description = '',
    this.required = true,
    this.occupation = 'All',
  });

  /// Stable key for holding the picked file against this document.
  String get key => '$occupation|$label';

  bool get forEveryone {
    final o = occupation.trim().toLowerCase();
    return o.isEmpty || o == 'all';
  }

  bool appliesTo(String other) =>
      forEveryone || occupation.trim().toLowerCase() == other.trim().toLowerCase();

  @override
  List<Object?> get props => [label, description, required, occupation];
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
  /// Optional admin override: visa_free | on_arrival | e_visa | sticker.
  final String category;

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
    this.category = '',
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
    category,
  ];
}