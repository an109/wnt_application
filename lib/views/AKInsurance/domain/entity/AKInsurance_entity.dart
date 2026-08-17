import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Requests
// ---------------------------------------------------------------------------

/// Step 1/7 — mints the Bearer token every other insurance call authenticates
/// with. Credentials live server-side, so this only carries the refresh flag.
class AkInsuranceSignatureRequestEntity extends Equatable {
  final bool forceRefresh;

  const AkInsuranceSignatureRequestEntity({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Step 2/7 — page-load data for the search form. An empty [provider] asks for
/// every enabled provider.
class AkInsuranceProviderChecklistRequestEntity extends Equatable {
  final String provider;

  const AkInsuranceProviderChecklistRequestEntity({this.provider = ''});

  @override
  List<Object?> get props => [provider];
}

/// One traveller on the quote/plan-details request. [id] is the zero-based
/// index and [relation] describes the traveller's link to the lead pax.
class AkInsuranceTravellerEntity extends Equatable {
  final int id;
  final String birthdate; // yyyy-MM-dd
  final String relation; // SELF for the lead pax

  const AkInsuranceTravellerEntity({
    required this.id,
    required this.birthdate,
    required this.relation,
  });

  @override
  List<Object?> get props => [id, birthdate, relation];
}

/// Step 3/7 — searches the rate sheet for the given policy type, destination,
/// trip dates and traveller list.
class AkInsuranceQuotesRequestEntity extends Equatable {
  final String channelId;
  final String policyType;
  final List<String> countryCodes;
  final List<String> countryNames;
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd
  final int tenureInMonths;
  final bool isPed;
  final List<AkInsuranceTravellerEntity> travellers;

  const AkInsuranceQuotesRequestEntity({
    this.channelId = 'b2bindia',
    this.policyType = 'INDIVIDUAL',
    required this.countryCodes,
    required this.countryNames,
    required this.startDate,
    required this.endDate,
    this.tenureInMonths = 3,
    this.isPed = false,
    required this.travellers,
  });

  @override
  List<Object?> get props => [
        channelId,
        policyType,
        countryCodes,
        countryNames,
        startDate,
        endDate,
        tenureInMonths,
        isPed,
        travellers,
      ];
}

/// Step 4/7 — full detail for one plan picked out of a quotes listing. The
/// trip parameters must match the listing call that produced [planId], and
/// [tui] is the listing response's tui.
class AkInsurancePlanDetailsRequestEntity extends Equatable {
  final String planId;
  final List<String> countryNames;
  final String channelId;
  final String policyType;
  final String startDate;
  final String endDate;
  final bool isPed;
  final int tenureInMonths;
  final List<AkInsuranceTravellerEntity> travellers;
  final String tui;

  const AkInsurancePlanDetailsRequestEntity({
    required this.planId,
    required this.countryNames,
    this.channelId = 'b2bindia',
    this.policyType = 'INDIVIDUAL',
    required this.startDate,
    required this.endDate,
    this.isPed = false,
    this.tenureInMonths = 3,
    required this.travellers,
    required this.tui,
  });

  @override
  List<Object?> get props => [
        planId,
        countryNames,
        channelId,
        policyType,
        startDate,
        endDate,
        isPed,
        tenureInMonths,
        travellers,
        tui,
      ];
}

// ---------------------------------------------------------------------------
// Responses
// ---------------------------------------------------------------------------

class AkInsuranceSignatureEntity extends Equatable {
  final bool success;
  final String token;

  const AkInsuranceSignatureEntity({
    required this.success,
    required this.token,
  });

  @override
  List<Object?> get props => [success, token];
}

/// A provider the checklist reports as enabled, plus the insurance types it
/// offers and the traveller fields it requires.
class AkInsuranceProviderEntity extends Equatable {
  final String code;
  final String name;
  final List<String> insuranceTypes;
  final List<String> requiredFields;

  const AkInsuranceProviderEntity({
    required this.code,
    required this.name,
    required this.insuranceTypes,
    required this.requiredFields,
  });

  @override
  List<Object?> get props => [code, name, insuranceTypes, requiredFields];
}

class AkInsuranceProviderChecklistEntity extends Equatable {
  final bool success;
  final List<AkInsuranceProviderEntity> providers;
  final List<String> policyTypes;

  const AkInsuranceProviderChecklistEntity({
    required this.success,
    required this.providers,
    required this.policyTypes,
  });

  @override
  List<Object?> get props => [success, providers, policyTypes];
}

/// One purchasable plan out of the quotes listing.
class AkInsurancePlanEntity extends Equatable {
  final String planId;
  final String planName;
  final String provider;

  /// Premium for the whole traveller list, in [currency].
  final double premium;

  /// Cover amount, when the rate sheet exposes one. 0 when unknown.
  final double sumInsured;
  final String currency;

  /// Short marketing bullets, when present on the listing row.
  final List<String> highlights;

  /// The row exactly as the provider returned it — kept so [planId] can be
  /// echoed back on PlanDetails without lossy re-mapping.
  final Map<String, dynamic> raw;

  const AkInsurancePlanEntity({
    required this.planId,
    required this.planName,
    required this.provider,
    required this.premium,
    required this.sumInsured,
    required this.currency,
    required this.highlights,
    required this.raw,
  });

  @override
  List<Object?> get props => [
        planId,
        planName,
        provider,
        premium,
        sumInsured,
        currency,
        highlights,
      ];
}

class AkInsuranceQuotesEntity extends Equatable {
  final bool success;

  /// Echoed back on the PlanDetails call for the plan the user picks.
  final String tui;
  final List<AkInsurancePlanEntity> plans;

  /// Provider-supplied message when the listing came back empty (no cover for
  /// this destination/date range, rate sheet missing, …).
  final String message;

  const AkInsuranceQuotesEntity({
    required this.success,
    required this.tui,
    required this.plans,
    required this.message,
  });

  @override
  List<Object?> get props => [success, tui, plans, message];
}

/// A single benefit line on the plan-details response.
class AkInsuranceBenefitEntity extends Equatable {
  final String title;
  final String value;

  const AkInsuranceBenefitEntity({required this.title, required this.value});

  @override
  List<Object?> get props => [title, value];
}

class AkInsurancePlanDetailsEntity extends Equatable {
  final bool success;
  final String planId;
  final String planName;
  final double premium;
  final String currency;
  final List<AkInsuranceBenefitEntity> benefits;
  final List<AkInsuranceBenefitEntity> deductibles;

  /// PED health questionnaire — only relevant when the user declares a
  /// pre-existing disease.
  final List<String> healthQuestions;
  final String termsAndConditions;

  const AkInsurancePlanDetailsEntity({
    required this.success,
    required this.planId,
    required this.planName,
    required this.premium,
    required this.currency,
    required this.benefits,
    required this.deductibles,
    required this.healthQuestions,
    required this.termsAndConditions,
  });

  @override
  List<Object?> get props => [
        success,
        planId,
        planName,
        premium,
        currency,
        benefits,
        deductibles,
        healthQuestions,
        termsAndConditions,
      ];
}

// ---------------------------------------------------------------------------
// Step 5/7 — ValidateKYC
// ---------------------------------------------------------------------------

/// Step 5/7 — validates exactly one ID document before a plan can be paid
/// for. Pass one of [pan]/[aadhaar]/[passport]/[voterId]/[drivingLicence]/
/// [ckyc] and leave the rest empty, per the provider's contract.
class AkInsuranceKycRequestEntity extends Equatable {
  final String pan;
  final String aadhaar;
  final String passport;
  final String voterId;
  final String drivingLicence;
  final String ckyc;
  final String name;
  final String gender; // 'M' | 'F'
  final String dob; // yyyy-MM-dd
  final String providerName;
  final String proposalNo;
  final String tui;

  const AkInsuranceKycRequestEntity({
    this.pan = '',
    this.aadhaar = '',
    this.passport = '',
    this.voterId = '',
    this.drivingLicence = '',
    this.ckyc = '',
    required this.name,
    required this.gender,
    required this.dob,
    required this.providerName,
    this.proposalNo = '',
    required this.tui,
  });

  @override
  List<Object?> get props => [
        pan,
        aadhaar,
        passport,
        voterId,
        drivingLicence,
        ckyc,
        name,
        gender,
        dob,
        providerName,
        proposalNo,
        tui,
      ];
}

class AkInsuranceKycEntity extends Equatable {
  final bool success;
  final String message;

  const AkInsuranceKycEntity({required this.success, required this.message});

  @override
  List<Object?> get props => [success, message];
}

// ---------------------------------------------------------------------------
// Step 6/7 — StartPay
// ---------------------------------------------------------------------------

class AkInsuranceContactInfoEntity extends Equatable {
  final String number;
  final String code;
  final String emailAddress;
  final String contactType;
  final String emailAddressType;
  final String? fax;

  const AkInsuranceContactInfoEntity({
    required this.number,
    required this.code,
    required this.emailAddress,
    this.contactType = 'MOBILE',
    this.emailAddressType = 'PERSONAL',
    this.fax,
  });

  @override
  List<Object?> get props =>
      [number, code, emailAddress, contactType, emailAddressType, fax];
}

/// The full schema nests City/State/Country as their own {Code, Name}
/// objects under Address (not flat strings), plus Line2/AreaCode — all
/// defaulted so existing callers don't need to change.
class AkInsuranceAddressEntity extends Equatable {
  final String addressType;
  final String line1;
  final String line2;
  final String pinCode;
  final String areaCode;
  final String? cityCode;
  final String cityName;
  final String? stateCode;
  final String stateName;
  final String countryCode;
  final String countryName;

  const AkInsuranceAddressEntity({
    this.addressType = 'PERMANENT',
    required this.line1,
    this.line2 = '',
    required this.pinCode,
    this.areaCode = '0',
    this.cityCode,
    this.cityName = '',
    this.stateCode,
    this.stateName = '',
    this.countryCode = 'IN',
    this.countryName = 'INDIA',
  });

  @override
  List<Object?> get props => [
        addressType,
        line1,
        line2,
        pinCode,
        areaCode,
        cityCode,
        cityName,
        stateCode,
        stateName,
        countryCode,
        countryName,
      ];
}

class AkInsuranceCustomerEntity extends Equatable {
  final String nationality;
  final String title;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String birthDate;
  final AkInsuranceContactInfoEntity contactInfo;
  final List<AkInsuranceAddressEntity> addresses;
  final String gstin;
  final String? passportNumber;
  final String? gender;
  final String? employeId;
  final String? gstMobile;
  final String? gstEmail;
  final String? gstHolderName;

  const AkInsuranceCustomerEntity({
    this.nationality = 'indian',
    required this.title,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.birthDate,
    required this.contactInfo,
    required this.addresses,
    this.gstin = '',
    this.passportNumber,
    this.gender,
    this.employeId,
    this.gstMobile,
    this.gstEmail,
    this.gstHolderName,
  });

  @override
  List<Object?> get props => [
        nationality,
        title,
        firstName,
        middleName,
        lastName,
        birthDate,
        contactInfo,
        addresses,
        gstin,
        passportNumber,
        gender,
        employeId,
        gstMobile,
        gstEmail,
        gstHolderName,
      ];
}

/// [relation] must be exactly one of Spouse, Son, Daughter, Father, Mother,
/// Brother, Sister — any other value makes Benzy silently drop the whole
/// booking (HTTP 200 back, but `Status: "Failure"`).
class AkInsuranceNomineeEntity extends Equatable {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String relation;
  final String? birthDate;

  const AkInsuranceNomineeEntity({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.relation,
    this.birthDate,
  });

  @override
  List<Object?> get props => [firstName, middleName, lastName, relation, birthDate];
}

class AkInsuranceStudentDetailsEntity extends Equatable {
  final String? universityDetails;
  final String? sponsor;
  final String? guardian;

  const AkInsuranceStudentDetailsEntity({
    this.universityDetails,
    this.sponsor,
    this.guardian,
  });

  @override
  List<Object?> get props => [universityDetails, sponsor, guardian];
}

class AkInsuranceQuestionEntity extends Equatable {
  final String title;
  final String questionCode;

  const AkInsuranceQuestionEntity({
    required this.title,
    required this.questionCode,
  });

  @override
  List<Object?> get props => [title, questionCode];
}

class AkInsuranceAnswerEntity extends Equatable {
  final bool yesNo;
  final String description;

  const AkInsuranceAnswerEntity({
    this.yesNo = false,
    this.description = '',
  });

  @override
  List<Object?> get props => [yesNo, description];
}

/// One health question + answer on a StartPay traveller. Benzy's schema
/// requires this list to be non-null on every traveller — [defaultPed] is
/// the PED (pre-existing disease) question the API doc shows, answered "No"
/// since this app doesn't collect real health answers.
class AkInsuranceQuestionAnswerEntity extends Equatable {
  final AkInsuranceQuestionEntity question;
  final AkInsuranceAnswerEntity answer;
  final bool preExisting;
  final List<String> preExistingDisease;
  final String preExistingDesc;
  final String sufferingSince;

  const AkInsuranceQuestionAnswerEntity({
    required this.question,
    required this.answer,
    this.preExisting = false,
    this.preExistingDisease = const [],
    this.preExistingDesc = '',
    this.sufferingSince = '',
  });

  static const defaultPed = AkInsuranceQuestionAnswerEntity(
    question: AkInsuranceQuestionEntity(
      title: 'Do you have any Pre-existing diseases?',
      questionCode: 'ISPED',
    ),
    answer: AkInsuranceAnswerEntity(yesNo: false, description: ''),
  );

  @override
  List<Object?> get props =>
      [question, answer, preExisting, preExistingDisease, preExistingDesc, sufferingSince];
}

class AkInsuranceBookingTravellerEntity extends Equatable {
  final int id;
  final String title;
  final String firstName;
  // Optional — the flight Trip Secure flow only has a single combined
  // display name per co-traveller, so this stays blank there. The doc's
  // example Traveller object has FirstName/LastName as separate keys.
  final String lastName;
  final String birthDate;
  final String? passportNumber;
  final String visaType;
  final String? pnrNumber;
  final bool maritalStatus;
  final String? gender;
  final String relationship;
  final bool isProposer;
  final AkInsuranceNomineeEntity nominee;
  final List<AkInsuranceQuestionAnswerEntity> questionsAnswers;
  final List<AkInsuranceAddressEntity> addresses;
  final AkInsuranceContactInfoEntity? contactInfo;
  final AkInsuranceStudentDetailsEntity studentDetails;
  final String? employeId;

  const AkInsuranceBookingTravellerEntity({
    required this.id,
    this.title = '',
    required this.firstName,
    this.lastName = '',
    this.birthDate = '',
    this.passportNumber,
    this.visaType = 'TOURIST',
    this.pnrNumber,
    this.maritalStatus = false,
    this.gender,
    required this.relationship,
    this.isProposer = false,
    // Defaulted (not required) so the flight Trip Secure flow — which
    // doesn't collect a nominee — keeps compiling unchanged. A blank name
    // with a valid enum relation is the closest placeholder to the API
    // doc's "null/""/0 where you have no real data" guidance.
    this.nominee = const AkInsuranceNomineeEntity(firstName: '', lastName: '', relation: 'Spouse'),
    this.questionsAnswers = const [AkInsuranceQuestionAnswerEntity.defaultPed],
    this.addresses = const [],
    this.contactInfo,
    this.studentDetails = const AkInsuranceStudentDetailsEntity(),
    this.employeId,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        firstName,
        lastName,
        birthDate,
        passportNumber,
        visaType,
        pnrNumber,
        maritalStatus,
        gender,
        relationship,
        isProposer,
        nominee,
        questionsAnswers,
        addresses,
        contactInfo,
        studentDetails,
        employeId,
      ];
}

class AkInsurancePlanBookingEntity extends Equatable {
  final String id;
  final String type;
  final List<AkInsuranceBookingTravellerEntity> travellers;

  const AkInsurancePlanBookingEntity({
    required this.id,
    required this.type,
    required this.travellers,
  });

  @override
  List<Object?> get props => [id, type, travellers];
}

/// Card payment details — StartPay's schema always expects this object even
/// when the charge went through Razorpay/wallet (i.e. not a direct card),
/// so every field defaults to the doc's own null/""/0/false placeholders.
class AkInsuranceCardEntity extends Equatable {
  final String number;
  final String expiry;
  final String cvv;
  final String chName;
  final String? fName;
  final String? lName;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pin;
  final bool international;
  final bool saveCard;
  final String emiMonths;
  final String token;
  final String numberAlias;
  final String? issuer;

  const AkInsuranceCardEntity({
    this.number = '',
    this.expiry = '',
    this.cvv = '',
    this.chName = '',
    this.fName,
    this.lName,
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.pin = '',
    this.international = false,
    this.saveCard = false,
    this.emiMonths = '0',
    this.token = '',
    this.numberAlias = '',
    this.issuer,
  });

  @override
  List<Object?> get props => [
        number,
        expiry,
        cvv,
        chName,
        fName,
        lName,
        address,
        city,
        state,
        country,
        pin,
        international,
        saveCard,
        emiMonths,
        token,
        numberAlias,
        issuer,
      ];
}

class AkInsuranceThirdPartyInfoEntity extends Equatable {
  final String? code;
  final String? campaign;
  final String? provider;
  final String? medium;
  final String? url;
  final String? utmId;

  const AkInsuranceThirdPartyInfoEntity({
    this.code,
    this.campaign,
    this.provider,
    this.medium,
    this.url,
    this.utmId,
  });

  @override
  List<Object?> get props => [code, campaign, provider, medium, url, utmId];
}

/// Step 6/7 — issues a real policy against WanderNova's Akbar/Benzy agent
/// balance. [paymentReference] should be the gateway transaction id (e.g. the
/// Razorpay payment id) the customer's charge was collected under, so the
/// provider call and the actual payment can be reconciled. [amount] must be
/// the plan's raw premium in its own (provider) currency — never a
/// display-converted figure.
///
/// Benzy's real schema has ~50 fields — most carry no meaningful data from
/// this app and are defaulted to the doc's own null/""/0/false placeholders
/// so every field required to avoid a schema-validation crash is still
/// present in the JSON body.
class AkInsuranceStartPayRequestEntity extends Equatable {
  final String paymentReference;

  /// Which of WanderNova's own gateways collected [paymentReference] —
  /// 'razorpay' or 'wallet'. Lets the backend's payment guard look up the
  /// charge under the right ledger before it will issue a policy.
  final String gateway;
  final String ckyc;
  final String panNo;
  final bool isDocumentUpload;
  final bool isForm60;
  final String passportFileNo;
  final List<String> countryCodes;
  final List<String> countryNames;
  final String? originAirport;
  final String? destinationAirport;
  final bool isTravelingFromIndia;
  final int? tenureInMonths;
  final String startDate;
  final String endDate;
  final String policyType;
  final AkInsuranceCustomerEntity customer;
  final List<AkInsurancePlanBookingEntity> plans;
  final String tripType;
  final String returnArrivalDate;
  final String returnDepartureDate;
  final int amount;
  final String? paymentId;
  final int billingCompanyId;
  final String? costCenter;
  final String? project;
  final String? hrmsTourRequestNumber;
  final String? billingType;
  final String? bookingTimeRemarks;
  final String? tripPurposeDescription;
  final String ibossDetailsForCorporate;
  final int userCompanyId;
  final String? tripId;
  final String? tripName;
  final int addonBenefit;
  final bool onlinePayment;
  final String paymentType;
  final String bankCode;
  final String gateWayCode;
  final String merchantId;
  final double paymentAmount;
  final double paymentCharge;
  final String vpa;
  final String cardAlias;
  final String rmsSignature;
  final String? serviceType;
  final String targetCurrency;
  final double targetAmount;
  final bool hold;
  final bool depositPayment;
  final String releaseDate;
  final String? browserKey;
  final double netAmount;
  final String? promo;
  final AkInsuranceCardEntity card;
  final String? quickPay;
  final String? recharge;
  final AkInsuranceThirdPartyInfoEntity thirdPartyInfo;
  final String? dRefNo;
  final String? agentAti;
  final String channelId;
  final String tui;

  const AkInsuranceStartPayRequestEntity({
    required this.paymentReference,
    this.gateway = 'razorpay',
    this.ckyc = '',
    required this.panNo,
    this.isDocumentUpload = false,
    this.isForm60 = false,
    this.passportFileNo = '',
    required this.countryCodes,
    required this.countryNames,
    this.originAirport,
    this.destinationAirport,
    this.isTravelingFromIndia = true,
    this.tenureInMonths,
    required this.startDate,
    required this.endDate,
    this.policyType = 'INDIVIDUAL',
    required this.customer,
    required this.plans,
    this.tripType = 'Single',
    this.returnArrivalDate = '0001-01-01T00:00:00',
    this.returnDepartureDate = '0001-01-01T00:00:00',
    required this.amount,
    this.paymentId,
    this.billingCompanyId = 0,
    this.costCenter,
    this.project,
    this.hrmsTourRequestNumber,
    this.billingType,
    this.bookingTimeRemarks,
    this.tripPurposeDescription,
    this.ibossDetailsForCorporate = '',
    this.userCompanyId = 0,
    this.tripId,
    this.tripName,
    this.addonBenefit = 0,
    this.onlinePayment = false,
    this.paymentType = '',
    this.bankCode = '',
    this.gateWayCode = '',
    this.merchantId = '',
    this.paymentAmount = 0.0,
    this.paymentCharge = 0.0,
    this.vpa = '',
    this.cardAlias = '',
    this.rmsSignature = '',
    this.serviceType,
    this.targetCurrency = '',
    this.targetAmount = 0.0,
    this.hold = false,
    this.depositPayment = true,
    this.releaseDate = '',
    this.browserKey,
    this.netAmount = 0.0,
    this.promo,
    this.card = const AkInsuranceCardEntity(),
    this.quickPay,
    this.recharge,
    this.thirdPartyInfo = const AkInsuranceThirdPartyInfoEntity(),
    this.dRefNo,
    this.agentAti,
    this.channelId = 'b2bindia',
    required this.tui,
  });

  @override
  List<Object?> get props => [
        paymentReference,
        gateway,
        ckyc,
        panNo,
        isDocumentUpload,
        isForm60,
        passportFileNo,
        countryCodes,
        countryNames,
        originAirport,
        destinationAirport,
        isTravelingFromIndia,
        tenureInMonths,
        startDate,
        endDate,
        policyType,
        customer,
        plans,
        tripType,
        returnArrivalDate,
        returnDepartureDate,
        amount,
        paymentId,
        billingCompanyId,
        costCenter,
        project,
        hrmsTourRequestNumber,
        billingType,
        bookingTimeRemarks,
        tripPurposeDescription,
        ibossDetailsForCorporate,
        userCompanyId,
        tripId,
        tripName,
        addonBenefit,
        onlinePayment,
        paymentType,
        bankCode,
        gateWayCode,
        merchantId,
        paymentAmount,
        paymentCharge,
        vpa,
        cardAlias,
        rmsSignature,
        serviceType,
        targetCurrency,
        targetAmount,
        hold,
        depositPayment,
        releaseDate,
        browserKey,
        netAmount,
        promo,
        card,
        quickPay,
        recharge,
        thirdPartyInfo,
        dRefNo,
        agentAti,
        channelId,
        tui,
      ];
}

/// Response is provider-shaped like the rest of this module — only
/// [success] and [transactionId] are load-bearing (GetItinerary needs the
/// latter); everything else is best-effort.
class AkInsuranceStartPayEntity extends Equatable {
  final bool success;
  final String transactionId;
  final String message;

  /// True when the provider is still processing and the caller should retry
  /// after a short delay, mirroring the flight/hotel StartPay retry contract.
  final bool bookingInProgress;

  const AkInsuranceStartPayEntity({
    required this.success,
    required this.transactionId,
    required this.message,
    required this.bookingInProgress,
  });

  bool get isBooked => success && transactionId.isNotEmpty;

  @override
  List<Object?> get props => [success, transactionId, message, bookingInProgress];
}

// ---------------------------------------------------------------------------
// Step 7/7 — GetItinerary
// ---------------------------------------------------------------------------

class AkInsuranceItineraryRequestEntity extends Equatable {
  final String tui;
  final String transactionId;

  const AkInsuranceItineraryRequestEntity({
    required this.tui,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [tui, transactionId];
}

class AkInsuranceItineraryEntity extends Equatable {
  final bool success;
  final String policyNumber;
  final String status;
  final String message;

  const AkInsuranceItineraryEntity({
    required this.success,
    required this.policyNumber,
    required this.status,
    required this.message,
  });

  @override
  List<Object?> get props => [success, policyNumber, status, message];
}

// ---------------------------------------------------------------------------
// Cross-screen handoff
// ---------------------------------------------------------------------------

/// Bundles everything the payment screen needs to actually pay for and issue
/// the Trip Secure plan the traveller picked on the booking screen: the
/// quoted plan itself, the KYC the traveller already passed, and the trip
/// parameters (dates/destination/travellers) the original quote was priced
/// against — StartPay must be called with matching parameters or the
/// provider rejects it.
class TripSecureBookingContext extends Equatable {
  final AkInsurancePlanEntity plan;
  final AkInsuranceKycRequestEntity kyc;
  final AkInsuranceQuotesRequestEntity quotesRequest;
  final String tui;

  const TripSecureBookingContext({
    required this.plan,
    required this.kyc,
    required this.quotesRequest,
    required this.tui,
  });

  @override
  List<Object?> get props => [plan, kyc, quotesRequest, tui];
}
