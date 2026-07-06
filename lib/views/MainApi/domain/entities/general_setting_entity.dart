import 'package:equatable/equatable.dart';

class GeneralSettingsEntity extends Equatable {
  final String companyName;
  final String tagline;
  final String companyLogo;
  final String appBannerImage;
  final String dashboardImage;
  final List<AboutTabEntity> aboutTabsContent;
  final List<MoreLinkEntity> moreLinksContent;
  final String flightsBanner1;
  final DealEntity? flightsBanner1Deal;
  final List<TrendingRouteEntity> trendingRoutes;
  final List<FaqEntity> faqList;
  final String hotelBanner1;
  final DealEntity? hotelBanner1Deal;
  final String holidaysBanner1;

  const GeneralSettingsEntity({
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

class PromoCodeEntity extends Equatable {
  final String code;
  final String category;
  final String discountType;
  final String discountValue;
  final String description;

  const PromoCodeEntity({
    required this.code,
    required this.category,
    required this.discountType,
    required this.discountValue,
    required this.description,
  });

  @override
  List<Object?> get props => [code, category, discountType, discountValue, description];
}

class AboutTabEntity extends Equatable {
  final String content;
  final String heading;

  const AboutTabEntity({required this.content, required this.heading});

  @override
  List<Object?> get props => [content, heading];
}

class MoreLinkEntity extends Equatable {
  final String text;
  final String title;

  const MoreLinkEntity({required this.text, required this.title});

  @override
  List<Object?> get props => [text, title];
}

class DealEntity extends Equatable {
  final String brand;
  final String title;
  final String validUpto;
  final String couponCode;
  final String description;
  final String sectorType;
  final String discountText;

  const DealEntity({
    required this.brand,
    required this.title,
    required this.validUpto,
    required this.couponCode,
    required this.description,
    required this.sectorType,
    required this.discountText,
  });

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

class TrendingRouteEntity extends Equatable {
  final String to;
  final String date;
  final String from;
  final num price;
  final String toCode;
  final String currency;
  final String fromCode;
  final String imageUrl;

  const TrendingRouteEntity({
    required this.to,
    required this.date,
    required this.from,
    required this.price,
    required this.toCode,
    required this.currency,
    required this.fromCode,
    required this.imageUrl,
  });

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

class FaqEntity extends Equatable {
  final String answer;
  final String question;

  const FaqEntity({required this.answer, required this.question});

  @override
  List<Object?> get props => [answer, question];
}