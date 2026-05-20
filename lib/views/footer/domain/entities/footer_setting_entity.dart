import 'package:equatable/equatable.dart';

class FooterSettingsEntity extends Equatable {
  final bool success;
  final SettingsEntity settings;

  const FooterSettingsEntity({
    required this.success,
    required this.settings,
  });

  @override
  List<Object?> get props => [success, settings];
}

class SettingsEntity extends Equatable {
  final int id;
  final int reseller;
  final String phoneNumber1;
  final String phoneNumber2;
  final String emailAddress;
  final String officeAddress;
  final bool showVisa;
  final bool showMastercard;
  final bool showAmex;
  final bool showRupay;
  final String facebookUrl;
  final String instagramUrl;
  final String twitterUrl;
  final String? tiktokUrl;
  final String linkedinUrl;
  final String youtubeUrl;
  final String copyrightText;
  final String footerBannerImage;
  final String footerBannerUrl;
  final bool showFooterBanner;
  final String created;
  final String updated;

  const SettingsEntity({
    required this.id,
    required this.reseller,
    required this.phoneNumber1,
    required this.phoneNumber2,
    required this.emailAddress,
    required this.officeAddress,
    required this.showVisa,
    required this.showMastercard,
    required this.showAmex,
    required this.showRupay,
    required this.facebookUrl,
    required this.instagramUrl,
    required this.twitterUrl,
    this.tiktokUrl,
    required this.linkedinUrl,
    required this.youtubeUrl,
    required this.copyrightText,
    required this.footerBannerImage,
    required this.footerBannerUrl,
    required this.showFooterBanner,
    required this.created,
    required this.updated,
  });

  @override
  List<Object?> get props => [
    id, reseller, phoneNumber1, phoneNumber2, emailAddress, officeAddress,
    showVisa, showMastercard, showAmex, showRupay, facebookUrl, instagramUrl,
    twitterUrl, tiktokUrl, linkedinUrl, youtubeUrl, copyrightText,
    footerBannerImage, footerBannerUrl, showFooterBanner, created, updated,
  ];
}