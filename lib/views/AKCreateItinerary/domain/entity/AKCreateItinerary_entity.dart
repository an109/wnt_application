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

  // Passport / travel-document block. GetTravelCheckList decides per fare
  // which of these the airline insists on (1 = mandatory); on an
  // international fare CreateItinerary is rejected outright without them.
  // Empty is the normal case on domestic fares, where the checklist asks for
  // none of them, so each is optional here and omitted from the payload when
  // blank rather than sent as "".
  final String passportNo;
  final String nationality;
  final String visaType;

  /// Passport date of expiry (PDOE), ISO yyyy-MM-dd.
  final String pdoe;

  /// Passport date of issue (PDOI), ISO yyyy-MM-dd.
  final String pdoi;

  /// Place of issue (PLI).
  final String pli;

  final String panNo;

  const AkTravellerRequestEntity({
    required this.title,
    required this.fName,
    required this.lName,
    required this.gender,
    required this.ptc,
    required this.dob,
    required this.email,
    required this.pMobileNo,
    this.passportNo = '',
    this.nationality = '',
    this.visaType = '',
    this.pdoe = '',
    this.pdoi = '',
    this.pli = '',
    this.panNo = '',
  });

  @override
  List<Object?> get props => [
    title, fName, lName, gender, ptc, dob, email, pMobileNo,
    passportNo, nationality, visaType, pdoe, pdoi, pli, panNo,
  ];
}

class AkCreateItineraryRequestEntity extends Equatable {
  final String sessionId;
  final AkContactInfoRequestEntity contactInfo;
  final List<AkTravellerRequestEntity> travellers;

  // DM chaining fields. SequenceID starts at 1 for the first leg and
  // increments for each subsequent leg. RefTransactionID holds the
  // TransactionID returned by the previous leg's CreateItinerary call
  // (absent for the first leg).
  final int? sequenceId;
  final String? refTransactionId;

  const AkCreateItineraryRequestEntity({
    required this.sessionId,
    required this.contactInfo,
    required this.travellers,
    this.sequenceId,
    this.refTransactionId,
  });

  @override
  List<Object?> get props => [sessionId, contactInfo, travellers, sequenceId, refTransactionId];
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkCreateItineraryEntity extends Equatable {
  final bool success;
  final String transactionId;
  /// B2B/agent net fare (what Akbar charges us). Used only for internal
  /// accounting — do NOT charge the customer this amount.
  final double netAmount;
  final double airlineNetFare;
  final double ssrAmount;
  /// Retail/published fare (what the customer pays). Falls back to [netAmount]
  /// when Akbar doesn't return GrossAmount (older routes).
  final double grossAmount;
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
    double? grossAmount,
    required this.itineraryChanged,
  }) : grossAmount = grossAmount ?? netAmount;

  @override
  List<Object?> get props => [
    success, transactionId, netAmount, grossAmount, airlineNetFare, ssrAmount, itineraryChanged,
  ];
}
