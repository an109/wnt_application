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

  const AkInsuranceContactInfoEntity({
    required this.number,
    required this.code,
    required this.emailAddress,
  });

  @override
  List<Object?> get props => [number, code, emailAddress];
}

class AkInsuranceAddressEntity extends Equatable {
  final String addressType;
  final String line1;
  final String pinCode;

  const AkInsuranceAddressEntity({
    this.addressType = 'PERMANENT',
    required this.line1,
    required this.pinCode,
  });

  @override
  List<Object?> get props => [addressType, line1, pinCode];
}

class AkInsuranceCustomerEntity extends Equatable {
  final String title;
  final String firstName;
  final String lastName;
  final String birthDate; // yyyy-MM-dd
  final AkInsuranceContactInfoEntity contactInfo;
  final List<AkInsuranceAddressEntity> addresses;

  const AkInsuranceCustomerEntity({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.contactInfo,
    required this.addresses,
  });

  @override
  List<Object?> get props => [title, firstName, lastName, birthDate, contactInfo, addresses];
}

class AkInsuranceBookingTravellerEntity extends Equatable {
  final int id;
  final String firstName;
  final String relationship;
  final bool isProposer;

  const AkInsuranceBookingTravellerEntity({
    required this.id,
    required this.firstName,
    required this.relationship,
    this.isProposer = false,
  });

  @override
  List<Object?> get props => [id, firstName, relationship, isProposer];
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

/// Step 6/7 — issues a real policy against WanderNova's Akbar/Benzy agent
/// balance. [paymentReference] should be the gateway transaction id (e.g. the
/// Razorpay payment id) the customer's charge was collected under, so the
/// provider call and the actual payment can be reconciled. [amount] must be
/// the plan's raw premium in its own (provider) currency — never a
/// display-converted figure.
class AkInsuranceStartPayRequestEntity extends Equatable {
  final String paymentReference;
  final String panNo;
  final List<String> countryCodes;
  final List<String> countryNames;
  final String startDate;
  final String endDate;
  final String policyType;
  final AkInsuranceCustomerEntity customer;
  final List<AkInsurancePlanBookingEntity> plans;
  final double amount;
  final bool onlinePayment;
  final bool depositPayment;
  final String channelId;
  final String tui;

  const AkInsuranceStartPayRequestEntity({
    required this.paymentReference,
    required this.panNo,
    required this.countryCodes,
    required this.countryNames,
    required this.startDate,
    required this.endDate,
    this.policyType = 'INDIVIDUAL',
    required this.customer,
    required this.plans,
    required this.amount,
    this.onlinePayment = false,
    this.depositPayment = true,
    this.channelId = 'b2bindia',
    required this.tui,
  });

  @override
  List<Object?> get props => [
        paymentReference,
        panNo,
        countryCodes,
        countryNames,
        startDate,
        endDate,
        policyType,
        customer,
        plans,
        amount,
        onlinePayment,
        depositPayment,
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
