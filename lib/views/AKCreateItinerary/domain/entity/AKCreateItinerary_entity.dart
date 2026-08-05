import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkContactInfoRequestEntity extends Equatable {
  final String title;
  final String fName;
  final String lName;
  final String mobile;
  final String destMob;
  final String phone;
  final String email;
  final String address;
  final String countryCode;
  final String mobileCountryCode;
  final String destMobCountryCode;
  final String state;
  final String city;
  final String pin;
  final String gstCompanyName;
  final String gstTIN;
  final String gstMobile;
  final String gstEmail;
  final bool updateProfile;
  final bool isGuest;
  final bool saveGST;

  const AkContactInfoRequestEntity({
    required this.title,
    required this.fName,
    required this.lName,
    required this.mobile,
    required this.destMob,
    required this.phone,
    required this.email,
    required this.address,
    required this.countryCode,
    required this.mobileCountryCode,
    required this.destMobCountryCode,
    required this.state,
    required this.city,
    required this.pin,
    required this.gstCompanyName,
    required this.gstTIN,
    required this.gstMobile,
    required this.gstEmail,
    required this.updateProfile,
    required this.isGuest,
    required this.saveGST,
  });

  @override
  List<Object?> get props => [
    title, fName, lName, mobile, destMob, phone, email, address, countryCode,
    mobileCountryCode, destMobCountryCode, state, city, pin, gstCompanyName,
    gstTIN, gstMobile, gstEmail, updateProfile, isGuest, saveGST,
  ];
}

class AkTravellerRequestEntity extends Equatable {
  final String title;
  final String fName;
  final String lName;
  final String gender;
  // "ADT" | "CHD" | "INF"
  final String ptc;
  final String dob;
  final String email;
  final String pMobileNo;

  const AkTravellerRequestEntity({
    required this.title,
    required this.fName,
    required this.lName,
    required this.gender,
    required this.ptc,
    required this.dob,
    required this.email,
    required this.pMobileNo,
  });

  @override
  List<Object?> get props => [title, fName, lName, gender, ptc, dob, email, pMobileNo];
}

class AkCreateItineraryRequestEntity extends Equatable {
  final String sessionId;
  final AkContactInfoRequestEntity contactInfo;
  final List<AkTravellerRequestEntity> travellers;

  const AkCreateItineraryRequestEntity({
    required this.sessionId,
    required this.contactInfo,
    required this.travellers,
  });

  @override
  List<Object?> get props => [sessionId, contactInfo, travellers];
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkCreateItineraryEntity extends Equatable {
  final bool success;
  final String transactionId;
  final double netAmount;
  final double airlineNetFare;
  final double ssrAmount;
  // True when the fare or flight time moved since GetSPricer — the doc
  // says to show the change, get consent, and call CreateItinerary again;
  // no TransactionID is issued until it settles false.
  final bool itineraryChanged;

  const AkCreateItineraryEntity({
    required this.success,
    required this.transactionId,
    required this.netAmount,
    required this.airlineNetFare,
    required this.ssrAmount,
    required this.itineraryChanged,
  });

  @override
  List<Object?> get props => [
    success, transactionId, netAmount, airlineNetFare, ssrAmount, itineraryChanged,
  ];
}
