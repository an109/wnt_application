import 'package:equatable/equatable.dart';

import '../../domain/entities/general_setting_entity.dart';

class GeneralSettingsModel extends Equatable {
  final String companyName;
  final String tagline;
  final String companyLogo;
  final String appBannerImage;
  final String dashboardImage;
  final List<AboutTabModel> aboutTabsContent;
  final List<MoreLinkModel> moreLinksContent;
  final String flightsBanner1;
  final DealModel? flightsBanner1Deal;
  final List<TrendingRouteModel> trendingRoutes;
  final List<FaqModel> faqList;
  final String hotelBanner1;
  final DealModel? hotelBanner1Deal;
  final String holidaysBanner1;

  const GeneralSettingsModel({
    required this.companyName,
    required this.tagline,
    required this.companyLogo,
    required this.appBannerImage,
    required this.dashboardImage,
    required this.aboutTabsContent,
    required this.moreLinksContent,
    required this.flightsBanner1,
    this.flightsBanner1Deal,
    required this.trendingRoutes,
    required this.faqList,
    required this.hotelBanner1,
    this.hotelBanner1Deal,
    required this.holidaysBanner1,
  });

  factory GeneralSettingsModel.fromJson(Map<String, dynamic> json) {
    final settings = json['general_settings'] as Map<String, dynamic>? ?? {};
    return GeneralSettingsModel(
      companyName: settings['company_name'] ?? 'WANDER NOVA',
      tagline: settings['tagline'] ?? '',
      companyLogo: settings['company_logo'] ?? '',
      appBannerImage: settings['app_banner_image'] ?? '',
      dashboardImage: settings['dashboard_image'] ?? '',
      aboutTabsContent: (settings['about_tabs_content'] as List<dynamic>?)
          ?.map((e) => AboutTabModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      moreLinksContent: (settings['more_links_content'] as List<dynamic>?)
          ?.map((e) => MoreLinkModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      flightsBanner1: settings['flights_banner_1'] ?? '',
      flightsBanner1Deal: settings['flights_banner_1_deal'] != null
          ? DealModel.fromJson(settings['flights_banner_1_deal'])
          : null,
      trendingRoutes: (settings['trending_routes'] as List<dynamic>?)
          ?.map((e) => TrendingRouteModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      faqList: (settings['faq_list'] as List<dynamic>?)
          ?.map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      hotelBanner1: settings['hotel_banner_1'] ?? '',
      hotelBanner1Deal: settings['hotel_banner_1_deal'] != null
          ? DealModel.fromJson(settings['hotel_banner_1_deal'])
          : null,
      holidaysBanner1: settings['holidays_banner_1'] ?? '',
    );
  }

  GeneralSettingsEntity toEntity() {
    return GeneralSettingsEntity(
      companyName: companyName,
      tagline: tagline,
      companyLogo: companyLogo,
      appBannerImage: appBannerImage,
      dashboardImage: dashboardImage,
      aboutTabsContent: aboutTabsContent.map((e) => e.toEntity()).toList(),
      moreLinksContent: moreLinksContent.map((e) => e.toEntity()).toList(),
      flightsBanner1: flightsBanner1,
      flightsBanner1Deal: flightsBanner1Deal?.toEntity(),
      trendingRoutes: trendingRoutes.map((e) => e.toEntity()).toList(),
      faqList: faqList.map((e) => e.toEntity()).toList(),
      hotelBanner1: hotelBanner1,
      hotelBanner1Deal: hotelBanner1Deal?.toEntity(),
      holidaysBanner1: holidaysBanner1,
    );
  }

  @override
  List<Object?> get props => [
    companyName,
    tagline,
    companyLogo,
    appBannerImage,
    dashboardImage,
    aboutTabsContent,
    moreLinksContent,
    flightsBanner1,
    flightsBanner1Deal,
    trendingRoutes,
    faqList,
    hotelBanner1,
    hotelBanner1Deal,
    holidaysBanner1,
  ];

}

class PromoCodeModel extends Equatable {
  final String code;
  final String category;
  final String discountType; // percent or fixed
  final String discountValue;
  final String description;

  const PromoCodeModel({
    required this.code,
    required this.category,
    required this.discountType,
    required this.discountValue,
    required this.description,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeModel(
      code: json['code'] ?? '',
      category: json['category'] ?? '',
      discountType: json['discount_type'] ?? '',
      discountValue: json['discount_value']?.toString() ?? '0',
      description: json['description'] ?? '',
    );
  }

  PromoCodeEntity toEntity() {
    return PromoCodeEntity(
      code: code,
      category: category,
      discountType: discountType,
      discountValue: discountValue,
      description: description,
    );
  }

  @override
  List<Object?> get props => [code, category, discountType, discountValue, description];
}

class AboutTabModel extends Equatable {
  final String content;
  final String heading;

  const AboutTabModel({required this.content, required this.heading});

  factory AboutTabModel.fromJson(Map<String, dynamic> json) {
    return AboutTabModel(
      content: json['content'] ?? '',
      heading: json['heading'] ?? '',
    );
  }

  AboutTabEntity toEntity() {
    return AboutTabEntity(
      content: content,
      heading: heading,
    );
  }

  @override
  List<Object?> get props => [content, heading];
}

class MoreLinkModel extends Equatable {
  final String text;
  final String title;

  const MoreLinkModel({required this.text, required this.title});

  factory MoreLinkModel.fromJson(Map<String, dynamic> json) {
    return MoreLinkModel(
      text: json['text'] ?? '',
      title: json['title'] ?? '',
    );
  }

  MoreLinkEntity toEntity() {
    return MoreLinkEntity(
      text: text,
      title: title,
    );
  }

  @override
  List<Object?> get props => [text, title];
}

class DealModel extends Equatable {
  final String brand;
  final String title;
  final String validUpto;
  final String couponCode;
  final String description;
  final String sectorType;
  final String discountText;

  const DealModel({
    required this.brand,
    required this.title,
    required this.validUpto,
    required this.couponCode,
    required this.description,
    required this.sectorType,
    required this.discountText,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      brand: json['brand'] ?? '',
      title: json['title'] ?? '',
      validUpto: json['valid_upto'] ?? '',
      couponCode: json['coupon_code'] ?? '',
      description: json['description'] ?? '',
      sectorType: json['sector_type'] ?? '',
      discountText: json['discount_text'] ?? '',
    );
  }

  DealEntity toEntity() {
    return DealEntity(
      brand: brand,
      title: title,
      validUpto: validUpto,
      couponCode: couponCode,
      description: description,
      sectorType: sectorType,
      discountText: discountText,
    );
  }

  @override
  List<Object?> get props => [
    brand,
    title,
    validUpto,
    couponCode,
    description,
    sectorType,
    discountText,
  ];
}

class TrendingRouteModel extends Equatable {
  final String to;
  final String date;
  final String from;
  final num price;
  final String toCode;
  final String currency;
  final String fromCode;
  final String imageUrl;

  const TrendingRouteModel({
    required this.to,
    required this.date,
    required this.from,
    required this.price,
    required this.toCode,
    required this.currency,
    required this.fromCode,
    required this.imageUrl,
  });

  factory TrendingRouteModel.fromJson(Map<String, dynamic> json) {
    return TrendingRouteModel(
      to: json['to'] ?? '',
      date: json['date'] ?? '',
      from: json['from'] ?? '',
      price: json['price'] ?? 0,
      toCode: json['to_code'] ?? '',
      currency: json['currency'] ?? 'INR',
      fromCode: json['from_code'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  TrendingRouteEntity toEntity() {
    return TrendingRouteEntity(
      to: to,
      date: date,
      from: from,
      price: price,
      toCode: toCode,
      currency: currency,
      fromCode: fromCode,
      imageUrl: imageUrl,
    );
  }

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

class FaqModel extends Equatable {
  final String answer;
  final String question;

  const FaqModel({required this.answer, required this.question});

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      answer: json['a'] ?? '',
      question: json['q'] ?? '',
    );
  }

  FaqEntity toEntity() {
    return FaqEntity(
      answer: answer,
      question: question,
    );
  }

  @override
  List<Object?> get props => [answer, question];
}