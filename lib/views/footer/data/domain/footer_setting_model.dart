class FooterSettingsModel {
  final bool success;
  final SettingsData settings;

  FooterSettingsModel({
    required this.success,
    required this.settings,
  });

  factory FooterSettingsModel.fromJson(Map<String, dynamic> json) {
    return FooterSettingsModel(
      success: json['success'] ?? false,
      settings: SettingsData.fromJson(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'settings': settings.toJson(),
    };
  }

  @override
  String toString() {
    return 'FooterSettingsModel(success: $success, settings: $settings)';
  }
}

class SettingsData {
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

  SettingsData({
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

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      id: json['id'] ?? 0,
      reseller: json['reseller'] ?? 0,
      phoneNumber1: json['phone_number_1'] ?? '',
      phoneNumber2: json['phone_number_2'] ?? '',
      emailAddress: json['email_address'] ?? '',
      officeAddress: json['office_address'] ?? '',
      showVisa: json['show_visa'] ?? false,
      showMastercard: json['show_mastercard'] ?? false,
      showAmex: json['show_amex'] ?? false,
      showRupay: json['show_rupay'] ?? false,
      facebookUrl: json['facebook_url'] ?? '',
      instagramUrl: json['instagram_url'] ?? '',
      twitterUrl: json['twitter_url'] ?? '',
      tiktokUrl: json['tiktok_url'],
      linkedinUrl: json['linkedin_url'] ?? '',
      youtubeUrl: json['youtube_url'] ?? '',
      copyrightText: json['copyright_text'] ?? '',
      footerBannerImage: json['footer_banner_image'] ?? '',
      footerBannerUrl: json['footer_banner_url'] ?? '',
      showFooterBanner: json['show_footer_banner'] ?? false,
      created: json['created'] ?? '',
      updated: json['updated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reseller': reseller,
      'phone_number_1': phoneNumber1,
      'phone_number_2': phoneNumber2,
      'email_address': emailAddress,
      'office_address': officeAddress,
      'show_visa': showVisa,
      'show_mastercard': showMastercard,
      'show_amex': showAmex,
      'show_rupay': showRupay,
      'facebook_url': facebookUrl,
      'instagram_url': instagramUrl,
      'twitter_url': twitterUrl,
      'tiktok_url': tiktokUrl,
      'linkedin_url': linkedinUrl,
      'youtube_url': youtubeUrl,
      'copyright_text': copyrightText,
      'footer_banner_image': footerBannerImage,
      'footer_banner_url': footerBannerUrl,
      'show_footer_banner': showFooterBanner,
      'created': created,
      'updated': updated,
    };
  }

  @override
  String toString() {
    return 'SettingsData(id: $id, copyrightText: $copyrightText)';
  }
}