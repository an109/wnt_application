import '../../domain/entity/AKInsurance_entity.dart';

// ---------------------------------------------------------------------------
// Shared parsing helpers
//
// The insurance responses are provider-shaped (Benzy), so key casing is not
// consistent across endpoints. Every getter below scans a list of candidate
// keys case-insensitively rather than hardcoding one spelling, which keeps the
// UI rendering real data instead of blanks when a field is spelled
// differently than expected.
// ---------------------------------------------------------------------------

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  final lower = {
    for (final e in json.entries) e.key.toLowerCase(): e.value,
  };
  for (final key in keys) {
    final v = lower[key.toLowerCase()];
    if (v != null) return v;
  }
  return null;
}

String _str(Map<String, dynamic> json, List<String> keys, {String fallback = ''}) {
  final v = _pick(json, keys);
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

double _num(Map<String, dynamic> json, List<String> keys) {
  final v = _pick(json, keys);
  if (v is num) return v.toDouble();
  if (v is String) {
    return double.tryParse(v.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
  }
  return 0;
}

bool _flag(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

List<String> _stringList(dynamic v) {
  if (v is List) {
    return v
        .map((e) => e is Map ? _str(e.cast<String, dynamic>(), ['name', 'title', 'text', 'label']) : e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }
  if (v is String && v.trim().isNotEmpty) return [v.trim()];
  return const [];
}

/// Turns a `{"FIELD NAME": 1, ...}` flag map (as ProviderChecklist returns)
/// into the names whose flag is truthy. Falls back to treating [v] as a
/// plain string list for providers that report it that way instead.
List<String> _flagMapKeys(dynamic v) {
  if (v is Map) {
    return v.entries
        .where((e) => _flag(e.value))
        .map((e) => e.key.toString())
        .toList();
  }
  return _stringList(v);
}

/// Finds the first list-of-objects under any of [keys], falling back to the
/// first list-of-objects anywhere in [json] when none of the expected keys are
/// present.
List<Map<String, dynamic>> _objectList(Map<String, dynamic> json, List<String> keys) {
  final direct = _pick(json, keys);
  if (direct is List) return direct.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

  for (final value in json.values) {
    if (value is List && value.isNotEmpty && value.first is Map) {
      return value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (value is Map<String, dynamic>) {
      final nested = _objectList(value, keys);
      if (nested.isNotEmpty) return nested;
    }
  }
  return const [];
}

// ---------------------------------------------------------------------------
// Request models
// ---------------------------------------------------------------------------

class AkInsuranceSignatureRequestModel extends AkInsuranceSignatureRequestEntity {
  const AkInsuranceSignatureRequestModel({required super.forceRefresh});

  factory AkInsuranceSignatureRequestModel.fromEntity(
    AkInsuranceSignatureRequestEntity entity,
  ) =>
      AkInsuranceSignatureRequestModel(forceRefresh: entity.forceRefresh);

  Map<String, dynamic> toJson() => {'force_refresh': forceRefresh};
}

class AkInsuranceProviderChecklistRequestModel
    extends AkInsuranceProviderChecklistRequestEntity {
  const AkInsuranceProviderChecklistRequestModel({required super.provider});

  factory AkInsuranceProviderChecklistRequestModel.fromEntity(
    AkInsuranceProviderChecklistRequestEntity entity,
  ) =>
      AkInsuranceProviderChecklistRequestModel(provider: entity.provider);

  Map<String, dynamic> toJson() => {'provider': provider};
}

class AkInsuranceTravellerModel extends AkInsuranceTravellerEntity {
  const AkInsuranceTravellerModel({
    required super.id,
    required super.birthdate,
    required super.relation,
  });

  factory AkInsuranceTravellerModel.fromEntity(AkInsuranceTravellerEntity entity) =>
      AkInsuranceTravellerModel(
        id: entity.id,
        birthdate: entity.birthdate,
        relation: entity.relation,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'birthdate': birthdate,
        'relation': relation,
      };
}

class AkInsuranceQuotesRequestModel extends AkInsuranceQuotesRequestEntity {
  const AkInsuranceQuotesRequestModel({
    required super.channelId,
    required super.policyType,
    required super.countryCodes,
    required super.countryNames,
    required super.startDate,
    required super.endDate,
    required super.tenureInMonths,
    required super.isPed,
    required super.travellers,
  });

  factory AkInsuranceQuotesRequestModel.fromEntity(
    AkInsuranceQuotesRequestEntity entity,
  ) =>
      AkInsuranceQuotesRequestModel(
        channelId: entity.channelId,
        policyType: entity.policyType,
        countryCodes: entity.countryCodes,
        countryNames: entity.countryNames,
        startDate: entity.startDate,
        endDate: entity.endDate,
        tenureInMonths: entity.tenureInMonths,
        isPed: entity.isPed,
        travellers: entity.travellers,
      );

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'policyType': policyType,
        'countryCodes': countryCodes,
        'CountryNames': countryNames,
        'startDate': startDate,
        'endDate': endDate,
        'tenureInMonths': tenureInMonths,
        'isPed': isPed,
        'travellers': travellers
            .map((t) => AkInsuranceTravellerModel.fromEntity(t).toJson())
            .toList(),
      };
}

class AkInsurancePlanDetailsRequestModel extends AkInsurancePlanDetailsRequestEntity {
  const AkInsurancePlanDetailsRequestModel({
    required super.planId,
    required super.countryNames,
    required super.channelId,
    required super.policyType,
    required super.startDate,
    required super.endDate,
    required super.isPed,
    required super.tenureInMonths,
    required super.travellers,
    required super.tui,
  });

  factory AkInsurancePlanDetailsRequestModel.fromEntity(
    AkInsurancePlanDetailsRequestEntity entity,
  ) =>
      AkInsurancePlanDetailsRequestModel(
        planId: entity.planId,
        countryNames: entity.countryNames,
        channelId: entity.channelId,
        policyType: entity.policyType,
        startDate: entity.startDate,
        endDate: entity.endDate,
        isPed: entity.isPed,
        tenureInMonths: entity.tenureInMonths,
        travellers: entity.travellers,
        tui: entity.tui,
      );

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'CountryNames': countryNames,
        'channelId': channelId,
        'policyType': policyType,
        'startDate': startDate,
        'endDate': endDate,
        'isPED': isPed,
        'tenureInMonths': tenureInMonths,
        'travellers': travellers
            .map((t) => AkInsuranceTravellerModel.fromEntity(t).toJson())
            .toList(),
        'tui': tui,
      };
}

// ---------------------------------------------------------------------------
// Response models
// ---------------------------------------------------------------------------

class AkInsuranceSignatureModel extends AkInsuranceSignatureEntity {
  const AkInsuranceSignatureModel({required super.success, required super.token});

  factory AkInsuranceSignatureModel.fromJson(Map<String, dynamic> json) {
    return AkInsuranceSignatureModel(
      success: _flag(_pick(json, ['success', 'Success', 'status'])),
      token: _str(json, ['token', 'Token', 'access_token', 'signature']),
    );
  }
}

class AkInsuranceProviderModel extends AkInsuranceProviderEntity {
  const AkInsuranceProviderModel({
    required super.code,
    required super.name,
    required super.insuranceTypes,
    required super.requiredFields,
  });

  factory AkInsuranceProviderModel.fromJson(Map<String, dynamic> json) {
    return AkInsuranceProviderModel(
      code: _str(json, ['code', 'Code', 'provider', 'providerCode', 'id']),
      name: _str(json, ['name', 'Name', 'providerName', 'displayName']),
      insuranceTypes: _stringList(
        _pick(json, ['insuranceTypes', 'InsuranceTypes', 'types', 'policyTypes']),
      ),
      requiredFields: _stringList(
        _pick(json, ['requiredFields', 'RequiredFields', 'checklist', 'fields']),
      ),
    );
  }
}

class AkInsuranceProviderChecklistModel extends AkInsuranceProviderChecklistEntity {
  const AkInsuranceProviderChecklistModel({
    required super.success,
    required super.providers,
    required super.policyTypes,
  });

  factory AkInsuranceProviderChecklistModel.fromJson(Map<String, dynamic> json) {
    final policyTypes = _stringList(
      _pick(json, ['policyTypes', 'PolicyTypes', 'insuranceTypes', 'insuranceType']),
    );
    final requiredFields = _flagMapKeys(
      _pick(json, ['providerCheckList', 'ProviderCheckList', 'checklist', 'requiredFields']),
    );

    // The real endpoint returns one flat `provider` list of code strings
    // (e.g. "BAJAJALLIANZ") plus a single shared `insuranceType` list and
    // `providerCheckList` flag map for the whole checklist — not one object
    // per provider. Only fall back to per-provider objects if a provider ever
    // ships that richer shape instead.
    final providerObjects = _objectList(json, ['providers', 'Providers', 'data', 'result']);
    final providers = providerObjects.isNotEmpty
        ? providerObjects.map(AkInsuranceProviderModel.fromJson).toList()
        : _stringList(_pick(json, ['provider', 'providers', 'Providers']))
            .map((code) => AkInsuranceProviderEntity(
                  code: code,
                  name: code,
                  insuranceTypes: policyTypes,
                  requiredFields: requiredFields,
                ))
            .toList();

    return AkInsuranceProviderChecklistModel(
      success: _flag(_pick(json, ['success', 'Success', 'status'])),
      providers: providers,
      policyTypes: policyTypes,
    );
  }
}

class AkInsurancePlanModel extends AkInsurancePlanEntity {
  const AkInsurancePlanModel({
    required super.planId,
    required super.planName,
    required super.provider,
    required super.premium,
    required super.sumInsured,
    required super.currency,
    required super.highlights,
    required super.raw,
  });

  factory AkInsurancePlanModel.fromJson(Map<String, dynamic> json) {
    return AkInsurancePlanModel(
      planId: _str(json, ['planId', 'PlanId', 'planID', 'id', 'planCode']),
      planName: _str(
        json,
        ['planName', 'PlanName', 'name', 'productName', 'title'],
        fallback: 'Travel Insurance',
      ),
      provider: _str(json, ['provider', 'Provider', 'insurer', 'companyName']),
      premium: _num(json, [
        'premium',
        'Premium',
        'totalPremium',
        'grossPremium',
        'amount',
        'netAmount',
        'price',
      ]),
      sumInsured: _num(json, [
        'sumInsured',
        'SumInsured',
        'coverAmount',
        'sumAssured',
        'coverage',
      ]),
      currency: _str(json, ['currency', 'Currency'], fallback: 'INR'),
      highlights: _stringList(
        _pick(json, ['highlights', 'Highlights', 'features', 'benefits', 'usp']),
      ),
      raw: json,
    );
  }
}

class AkInsuranceQuotesModel extends AkInsuranceQuotesEntity {
  const AkInsuranceQuotesModel({
    required super.success,
    required super.tui,
    required super.plans,
    required super.message,
  });

  factory AkInsuranceQuotesModel.fromJson(Map<String, dynamic> json) {
    final plans = _objectList(json, ['quotes', 'Quotes', 'plans', 'Plans', 'data', 'result'])
        .map(AkInsurancePlanModel.fromJson)
        // Rows with neither an id nor a premium are not purchasable — dropping
        // them keeps unusable cards out of the picker.
        .where((p) => p.planId.isNotEmpty || p.premium > 0)
        .toList();

    return AkInsuranceQuotesModel(
      success: _flag(_pick(json, ['success', 'Success', 'status'])) || plans.isNotEmpty,
      tui: _str(json, ['tui', 'TUI', 'Tui']),
      plans: plans,
      message: _str(json, ['message', 'Message', 'error', 'description']),
    );
  }

  /// Used when the provider answers with something that isn't a JSON object
  /// (e.g. a bare error string) — surfaced as "no plans" instead of a crash.
  factory AkInsuranceQuotesModel.empty(String message) => AkInsuranceQuotesModel(
        success: false,
        tui: '',
        plans: const [],
        message: message,
      );
}

class AkInsuranceBenefitModel extends AkInsuranceBenefitEntity {
  const AkInsuranceBenefitModel({required super.title, required super.value});

  factory AkInsuranceBenefitModel.fromJson(Map<String, dynamic> json) {
    return AkInsuranceBenefitModel(
      title: _str(json, ['title', 'Title', 'name', 'benefit', 'label', 'coverage']),
      value: _str(json, ['value', 'Value', 'amount', 'limit', 'cover', 'description']),
    );
  }
}

class AkInsurancePlanDetailsModel extends AkInsurancePlanDetailsEntity {
  const AkInsurancePlanDetailsModel({
    required super.success,
    required super.planId,
    required super.planName,
    required super.premium,
    required super.currency,
    required super.benefits,
    required super.deductibles,
    required super.healthQuestions,
    required super.termsAndConditions,
  });

  factory AkInsurancePlanDetailsModel.fromJson(Map<String, dynamic> json) {
    // The payload may wrap the plan under a `plan`/`data` key or be flat.
    final planJson = () {
      final nested = _pick(json, ['plan', 'Plan', 'planDetails', 'data', 'result']);
      return nested is Map ? nested.cast<String, dynamic>() : json;
    }();

    return AkInsurancePlanDetailsModel(
      success: _flag(_pick(json, ['success', 'Success', 'status'])),
      planId: _str(planJson, ['planId', 'PlanId', 'id', 'planCode']),
      planName: _str(
        planJson,
        ['planName', 'PlanName', 'name', 'productName', 'title'],
        fallback: 'Travel Insurance',
      ),
      premium: _num(planJson, ['premium', 'Premium', 'totalPremium', 'amount', 'price']),
      currency: _str(planJson, ['currency', 'Currency'], fallback: 'INR'),
      benefits: _objectList(planJson, ['benefits', 'Benefits', 'coverages', 'covers'])
          .map(AkInsuranceBenefitModel.fromJson)
          .where((b) => b.title.isNotEmpty)
          .toList(),
      deductibles: _objectList(planJson, ['deductibles', 'Deductibles', 'deductible'])
          .map(AkInsuranceBenefitModel.fromJson)
          .where((b) => b.title.isNotEmpty)
          .toList(),
      healthQuestions: _stringList(
        _pick(planJson, [
          'healthQuestions',
          'HealthQuestions',
          'pedQuestions',
          'questionnaire',
          'medicalQuestions',
        ]),
      ),
      termsAndConditions: _str(planJson, [
        'termsAndConditions',
        'TermsAndConditions',
        'terms',
        'tnc',
        'TnC',
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5/7 — ValidateKYC
// ---------------------------------------------------------------------------

class AkInsuranceKycRequestModel extends AkInsuranceKycRequestEntity {
  const AkInsuranceKycRequestModel({
    required super.pan,
    required super.aadhaar,
    required super.passport,
    required super.voterId,
    required super.drivingLicence,
    required super.ckyc,
    required super.name,
    required super.gender,
    required super.dob,
    required super.providerName,
    required super.proposalNo,
    required super.tui,
  });

  factory AkInsuranceKycRequestModel.fromEntity(AkInsuranceKycRequestEntity entity) =>
      AkInsuranceKycRequestModel(
        pan: entity.pan,
        aadhaar: entity.aadhaar,
        passport: entity.passport,
        voterId: entity.voterId,
        drivingLicence: entity.drivingLicence,
        ckyc: entity.ckyc,
        name: entity.name,
        gender: entity.gender,
        dob: entity.dob,
        providerName: entity.providerName,
        proposalNo: entity.proposalNo,
        tui: entity.tui,
      );

  Map<String, dynamic> toJson() => {
        'pan': pan,
        'aadhaar': aadhaar,
        'passport': passport,
        'voterid': voterId,
        'drivinglicence': drivingLicence,
        'ckyc': ckyc,
        'name': name,
        'gender': gender,
        'dob': dob,
        'ProviderName': providerName,
        'ProposalNo': proposalNo,
        'tui': tui,
      };
}

class AkInsuranceKycModel extends AkInsuranceKycEntity {
  const AkInsuranceKycModel({required super.success, required super.message});

  factory AkInsuranceKycModel.fromJson(Map<String, dynamic> json) {
    return AkInsuranceKycModel(
      success: _flag(_pick(json, ['success', 'Success', 'status', 'valid', 'isValid'])),
      message: _str(json, ['message', 'Message', 'error', 'description']),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 6/7 — StartPay
// ---------------------------------------------------------------------------

class AkInsuranceContactInfoModel extends AkInsuranceContactInfoEntity {
  const AkInsuranceContactInfoModel({
    required super.number,
    required super.code,
    required super.emailAddress,
  });

  factory AkInsuranceContactInfoModel.fromEntity(AkInsuranceContactInfoEntity entity) =>
      AkInsuranceContactInfoModel(
        number: entity.number,
        code: entity.code,
        emailAddress: entity.emailAddress,
      );

  Map<String, dynamic> toJson() => {
        'Number': number,
        'Code': code,
        'EmailAddress': emailAddress,
      };
}

class AkInsuranceAddressModel extends AkInsuranceAddressEntity {
  const AkInsuranceAddressModel({
    required super.addressType,
    required super.line1,
    required super.pinCode,
  });

  factory AkInsuranceAddressModel.fromEntity(AkInsuranceAddressEntity entity) =>
      AkInsuranceAddressModel(
        addressType: entity.addressType,
        line1: entity.line1,
        pinCode: entity.pinCode,
      );

  Map<String, dynamic> toJson() => {
        'AddressType': addressType,
        'Line1': line1,
        'PinCode': pinCode,
      };
}

class AkInsuranceCustomerModel extends AkInsuranceCustomerEntity {
  const AkInsuranceCustomerModel({
    required super.title,
    required super.firstName,
    required super.lastName,
    required super.birthDate,
    required super.contactInfo,
    required super.addresses,
  });

  factory AkInsuranceCustomerModel.fromEntity(AkInsuranceCustomerEntity entity) =>
      AkInsuranceCustomerModel(
        title: entity.title,
        firstName: entity.firstName,
        lastName: entity.lastName,
        birthDate: entity.birthDate,
        contactInfo: entity.contactInfo,
        addresses: entity.addresses,
      );

  Map<String, dynamic> toJson() => {
        'Title': title,
        'FirstName': firstName,
        'LastName': lastName,
        'BirthDate': birthDate,
        'ContactInfo': AkInsuranceContactInfoModel.fromEntity(contactInfo).toJson(),
        'Addresses': addresses.map((a) => AkInsuranceAddressModel.fromEntity(a).toJson()).toList(),
      };
}

class AkInsuranceBookingTravellerModel extends AkInsuranceBookingTravellerEntity {
  const AkInsuranceBookingTravellerModel({
    required super.id,
    required super.firstName,
    required super.relationship,
    required super.isProposer,
  });

  factory AkInsuranceBookingTravellerModel.fromEntity(AkInsuranceBookingTravellerEntity entity) =>
      AkInsuranceBookingTravellerModel(
        id: entity.id,
        firstName: entity.firstName,
        relationship: entity.relationship,
        isProposer: entity.isProposer,
      );

  Map<String, dynamic> toJson() => {
        'Id': id,
        'FirstName': firstName,
        'Relationship': relationship,
        'IsProposer': isProposer,
      };
}

class AkInsurancePlanBookingModel extends AkInsurancePlanBookingEntity {
  const AkInsurancePlanBookingModel({
    required super.id,
    required super.type,
    required super.travellers,
  });

  factory AkInsurancePlanBookingModel.fromEntity(AkInsurancePlanBookingEntity entity) =>
      AkInsurancePlanBookingModel(
        id: entity.id,
        type: entity.type,
        travellers: entity.travellers,
      );

  Map<String, dynamic> toJson() => {
        'Id': id,
        'Type': type,
        'Travellers': travellers
            .map((t) => AkInsuranceBookingTravellerModel.fromEntity(t).toJson())
            .toList(),
      };
}

class AkInsuranceStartPayRequestModel extends AkInsuranceStartPayRequestEntity {
  const AkInsuranceStartPayRequestModel({
    required super.paymentReference,
    required super.panNo,
    required super.countryCodes,
    required super.countryNames,
    required super.startDate,
    required super.endDate,
    required super.policyType,
    required super.customer,
    required super.plans,
    required super.amount,
    required super.onlinePayment,
    required super.depositPayment,
    required super.channelId,
    required super.tui,
  });

  factory AkInsuranceStartPayRequestModel.fromEntity(
    AkInsuranceStartPayRequestEntity entity,
  ) =>
      AkInsuranceStartPayRequestModel(
        paymentReference: entity.paymentReference,
        panNo: entity.panNo,
        countryCodes: entity.countryCodes,
        countryNames: entity.countryNames,
        startDate: entity.startDate,
        endDate: entity.endDate,
        policyType: entity.policyType,
        customer: entity.customer,
        plans: entity.plans,
        amount: entity.amount,
        onlinePayment: entity.onlinePayment,
        depositPayment: entity.depositPayment,
        channelId: entity.channelId,
        tui: entity.tui,
      );

  Map<String, dynamic> toJson() => {
        'payment_reference': paymentReference,
        'PanNo': panNo,
        'CountryCodes': countryCodes,
        'CountryNames': countryNames,
        'StartDate': startDate,
        'EndDate': endDate,
        'PolicyType': policyType,
        'Customer': AkInsuranceCustomerModel.fromEntity(customer).toJson(),
        'Plans': plans.map((p) => AkInsurancePlanBookingModel.fromEntity(p).toJson()).toList(),
        'Amount': amount,
        'OnlinePayment': onlinePayment,
        'DepositPayment': depositPayment,
        'ChannelId': channelId,
        'TUI': tui,
      };
}

class AkInsuranceStartPayModel extends AkInsuranceStartPayEntity {
  const AkInsuranceStartPayModel({
    required super.success,
    required super.transactionId,
    required super.message,
    required super.bookingInProgress,
  });

  factory AkInsuranceStartPayModel.fromJson(Map<String, dynamic> json) {
    final message = _str(json, ['message', 'Message', 'error', 'description']);
    return AkInsuranceStartPayModel(
      success: _flag(_pick(json, ['success', 'Success', 'status'])),
      transactionId: _str(json, ['TransactionID', 'transactionId', 'TransactionId', 'transaction_id']),
      message: message,
      // No documented "processing" shape upstream — treat a message that
      // explicitly says so as retryable rather than a hard failure, mirroring
      // flight/hotel StartPay's own retry-on-in-progress contract.
      bookingInProgress: message.toLowerCase().contains('progress') ||
          message.toLowerCase().contains('pending') ||
          _flag(_pick(json, ['inProgress', 'InProgress', 'processing'])),
    );
  }

  /// Used when the provider answers with something that isn't a JSON object.
  factory AkInsuranceStartPayModel.empty(String message) => AkInsuranceStartPayModel(
        success: false,
        transactionId: '',
        message: message,
        bookingInProgress: false,
      );
}

// ---------------------------------------------------------------------------
// Step 7/7 — GetItinerary
// ---------------------------------------------------------------------------

class AkInsuranceItineraryRequestModel extends AkInsuranceItineraryRequestEntity {
  const AkInsuranceItineraryRequestModel({
    required super.tui,
    required super.transactionId,
  });

  factory AkInsuranceItineraryRequestModel.fromEntity(
    AkInsuranceItineraryRequestEntity entity,
  ) =>
      AkInsuranceItineraryRequestModel(tui: entity.tui, transactionId: entity.transactionId);

  Map<String, dynamic> toJson() => {
        'TUI': tui,
        'TransactionID': transactionId,
      };
}

class AkInsuranceItineraryModel extends AkInsuranceItineraryEntity {
  const AkInsuranceItineraryModel({
    required super.success,
    required super.policyNumber,
    required super.status,
    required super.message,
  });

  factory AkInsuranceItineraryModel.fromJson(Map<String, dynamic> json) {
    return AkInsuranceItineraryModel(
      success: _flag(_pick(json, ['success', 'Success', 'status'])),
      policyNumber: _str(json, ['policyNumber', 'PolicyNumber', 'policyNo', 'PolicyNo', 'certificateNo']),
      status: _str(json, ['bookingStatus', 'BookingStatus', 'status', 'Status']),
      message: _str(json, ['message', 'Message', 'error', 'description']),
    );
  }
}
