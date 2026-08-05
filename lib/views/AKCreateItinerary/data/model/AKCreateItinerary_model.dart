import '../../domain/entity/AKCreateItinerary_entity.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkContactInfoRequestModel extends AkContactInfoRequestEntity {
  const AkContactInfoRequestModel({
    required super.title,
    required super.fName,
    required super.lName,
    required super.mobile,
    required super.destMob,
    required super.phone,
    required super.email,
    required super.address,
    required super.countryCode,
    required super.mobileCountryCode,
    required super.destMobCountryCode,
    required super.state,
    required super.city,
    required super.pin,
    required super.gstCompanyName,
    required super.gstTIN,
    required super.gstMobile,
    required super.gstEmail,
    required super.updateProfile,
    required super.isGuest,
    required super.saveGST,
  });

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'FName': fName,
      'LName': lName,
      'Mobile': mobile,
      'DestMob': destMob,
      'Phone': phone,
      'Email': email,
      'Address': address,
      'CountryCode': countryCode,
      'MobileCountryCode': mobileCountryCode,
      'DestMobCountryCode': destMobCountryCode,
      'State': state,
      'City': city,
      'PIN': pin,
      'GSTCompanyName': gstCompanyName,
      'GSTTIN': gstTIN,
      'GstMobile': gstMobile,
      'GSTEmail': gstEmail,
      'UpdateProfile': updateProfile,
      'IsGuest': isGuest,
      'SaveGST': saveGST,
    };
  }
}

class AkTravellerRequestModel extends AkTravellerRequestEntity {
  const AkTravellerRequestModel({
    required super.title,
    required super.fName,
    required super.lName,
    required super.gender,
    required super.ptc,
    required super.dob,
    required super.email,
    required super.pMobileNo,
  });

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'FName': fName,
      'LName': lName,
      'Gender': gender,
      'PTC': ptc,
      'DOB': dob,
      'Email': email,
      'PMobileNo': pMobileNo,
    };
  }
}

class AkCreateItineraryRequestModel extends AkCreateItineraryRequestEntity {
  const AkCreateItineraryRequestModel({
    required super.sessionId,
    required super.contactInfo,
    required super.travellers,
  });

  factory AkCreateItineraryRequestModel.fromEntity(AkCreateItineraryRequestEntity entity) {
    final contact = entity.contactInfo;
    return AkCreateItineraryRequestModel(
      sessionId: entity.sessionId,
      contactInfo: AkContactInfoRequestModel(
        title: contact.title,
        fName: contact.fName,
        lName: contact.lName,
        mobile: contact.mobile,
        destMob: contact.destMob,
        phone: contact.phone,
        email: contact.email,
        address: contact.address,
        countryCode: contact.countryCode,
        mobileCountryCode: contact.mobileCountryCode,
        destMobCountryCode: contact.destMobCountryCode,
        state: contact.state,
        city: contact.city,
        pin: contact.pin,
        gstCompanyName: contact.gstCompanyName,
        gstTIN: contact.gstTIN,
        gstMobile: contact.gstMobile,
        gstEmail: contact.gstEmail,
        updateProfile: contact.updateProfile,
        isGuest: contact.isGuest,
        saveGST: contact.saveGST,
      ),
      travellers: entity.travellers
          .map((t) => AkTravellerRequestModel(
                title: t.title,
                fName: t.fName,
                lName: t.lName,
                gender: t.gender,
                ptc: t.ptc,
                dob: t.dob,
                email: t.email,
                pMobileNo: t.pMobileNo,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'contact_info': (contactInfo as AkContactInfoRequestModel).toJson(),
      'travellers': travellers.map((t) => (t as AkTravellerRequestModel).toJson()).toList(),
    };
  }
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkCreateItineraryModel extends AkCreateItineraryEntity {
  const AkCreateItineraryModel({
    required super.success,
    required super.transactionId,
    required super.netAmount,
    required super.airlineNetFare,
    required super.ssrAmount,
    required super.itineraryChanged,
  });

  factory AkCreateItineraryModel.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return AkCreateItineraryModel(
      success: json['success'] ?? false,
      transactionId: json['TransactionID']?.toString() ?? '',
      netAmount: toD(json['NetAmount']),
      airlineNetFare: toD(json['AirlineNetFare']),
      ssrAmount: toD(json['SSRAmount']),
      itineraryChanged: json['itinerary_changed'] ?? false,
    );
  }
}
