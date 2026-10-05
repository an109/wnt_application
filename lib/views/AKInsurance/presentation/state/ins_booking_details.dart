import 'package:flutter/foundation.dart';

import '../../domain/entity/AKInsurance_entity.dart';

/// Who is buying the policy — the "Proposer Details" card on the review
/// screen. Becomes StartPay's `Customer` block.
@immutable
class InsProposer {
  final String mobile;
  final String dialCode;
  final String email;
  final String addressLine1;
  final String addressLine2;
  final String nationality;
  final String state;
  final String district;
  final String city;
  final String pincode;

  /// Both optional on the form and on StartPay.
  final String gstNumber;
  final String panNumber;

  const InsProposer({
    this.mobile = '',
    this.dialCode = '+91',
    this.email = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.nationality = 'India',
    this.state = '',
    this.district = '',
    this.city = '',
    this.pincode = '',
    this.gstNumber = '',
    this.panNumber = '',
  });

  /// StartPay wants the bare number; the dial code travels separately.
  String get contactNumber => mobile.trim();

  String get contactCode => dialCode.replaceAll('+', '').trim();
}

/// One insured person — the "Travellers" card.
@immutable
class InsBookingTraveller {
  final String title; // Mr / Ms / Mrs
  final String firstName;
  final String lastName;
  final DateTime? dob;
  final String gender; // Male / Female
  final String passport;
  final String relationship;
  final String nationality;

  /// STUDENT policies only — the provider's own extra block.
  final String university;
  final String sponsor;
  final String guardian;

  const InsBookingTraveller({
    this.title = 'Mr',
    this.firstName = '',
    this.lastName = '',
    this.dob,
    this.gender = 'Male',
    this.passport = '',
    this.relationship = 'SELF',
    this.nationality = 'India',
    this.university = '',
    this.sponsor = '',
    this.guardian = '',
  });

  InsBookingTraveller copyWith({
    String? title,
    String? firstName,
    String? lastName,
    DateTime? dob,
    String? gender,
    String? passport,
    String? relationship,
    String? nationality,
    String? university,
    String? sponsor,
    String? guardian,
  }) {
    return InsBookingTraveller(
      title: title ?? this.title,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      passport: passport ?? this.passport,
      relationship: relationship ?? this.relationship,
      nationality: nationality ?? this.nationality,
      university: university ?? this.university,
      sponsor: sponsor ?? this.sponsor,
      guardian: guardian ?? this.guardian,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  /// StartPay's gender flag.
  String get genderCode => gender.toLowerCase().startsWith('f') ? 'F' : 'M';

  bool get isComplete =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      dob != null;
}

/// The "Nominee Details" card. Benzy rejects the whole booking unless
/// [relation] is one of its seven accepted words, so the form offers exactly
/// those.
@immutable
class InsNominee {
  final String firstName;
  final String lastName;
  final String relation;

  const InsNominee({
    this.firstName = '',
    this.lastName = '',
    this.relation = 'Spouse',
  });

  /// The only values the provider accepts — anything else makes it answer
  /// HTTP 200 with `Status: "Failure"` and no policy.
  static const relations = [
    'Spouse',
    'Son',
    'Daughter',
    'Father',
    'Mother',
    'Brother',
    'Sister',
  ];

  InsNominee copyWith({
    String? firstName,
    String? lastName,
    String? relation,
  }) {
    return InsNominee(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      relation: relation ?? this.relation,
    );
  }

  bool get isComplete =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;
}

/// The closed value sets the provider's schema accepts. These are contract
/// enumerations, not content: sending anything outside them makes Benzy
/// reject the booking, so they are fixed here rather than fetched.
class InsOptions {
  const InsOptions._();

  static const titles = ['Mr', 'Mrs', 'Ms'];
  static const genders = ['Male', 'Female'];
  static const travellerRelations = [
    'Self',
    'Spouse',
    'Son',
    'Daughter',
    'Father',
    'Mother',
    'Other',
  ];

  /// Indian states, for the proposer's address. The provider's address block
  /// takes a free-text state name, and this is the list the previous booking
  /// form offered.
  static const states = [
    'Andhra Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];
}

/// The traveller's answers to the PED questionnaire PlanDetails returned.
///
/// Carries [questions] alongside the answers so the booking request can be
/// built from the provider's own question list — the app no longer invents a
/// single hardcoded "no pre-existing disease" row, which declared every
/// traveller healthy whether they were or not.
@immutable
class InsHealthDeclaration {
  /// The questionnaire this declaration answers, straight from PlanDetails.
  final List<AkInsurancePedQuestionEntity> questions;

  /// The gate answer. Null until the traveller has actually answered — the
  /// review form will not submit while it is.
  final bool? hasPed;

  /// Question codes of the tick-box conditions ticked under the gate.
  final Set<String> conditions;

  /// Free-text answers, keyed by question code, for the rows the provider
  /// marks as `TextBox` rather than `CheckBox`.
  final Map<String, String> textAnswers;

  final String description;
  final String sufferingSince;

  const InsHealthDeclaration({
    this.questions = const [],
    this.hasPed,
    this.conditions = const {},
    this.textAnswers = const {},
    this.description = '',
    this.sufferingSince = '',
  });

  InsHealthDeclaration copyWith({
    List<AkInsurancePedQuestionEntity>? questions,
    bool? hasPed,
    Set<String>? conditions,
    Map<String, String>? textAnswers,
    String? description,
    String? sufferingSince,
  }) {
    return InsHealthDeclaration(
      questions: questions ?? this.questions,
      hasPed: hasPed ?? this.hasPed,
      conditions: conditions ?? this.conditions,
      textAnswers: textAnswers ?? this.textAnswers,
      description: description ?? this.description,
      sufferingSince: sufferingSince ?? this.sufferingSince,
    );
  }

  AkInsurancePedQuestionEntity? get gate {
    for (final q in questions) {
      if (q.isGate) return q;
    }
    return null;
  }

  /// Rows that only apply once the gate is answered yes.
  List<AkInsurancePedQuestionEntity> get gatedQuestions =>
      [for (final q in questions) if (q.isUnderGate) q];

  /// Rows the provider asks of everyone, gate or no gate.
  List<AkInsurancePedQuestionEntity> get independentQuestions =>
      [for (final q in questions) if (!q.isGate && !q.isUnderGate) q];

  /// Nothing to ask when the plan returned no questionnaire.
  bool get isEmpty => questions.isEmpty;

  String _text(String code) => (textAnswers[code] ?? '').trim();

  /// The one reason this declaration is not ready, or null.
  String? get validationError {
    if (isEmpty) return null;
    if (hasPed == null) return 'Answer the health declaration';
    if (hasPed == true &&
        conditions.isEmpty &&
        gatedQuestions.where((q) => !q.isCheckbox).every(
              (q) => _text(q.questionCode).isEmpty,
            )) {
      return 'Tell us which pre-existing condition applies';
    }
    return null;
  }

  /// The rows StartPay's `QuestionsAnswers` takes: every question the plan
  /// asked, answered as the traveller actually answered it.
  List<AkInsuranceQuestionAnswerEntity> toQuestionAnswers() {
    if (isEmpty) return const [AkInsuranceQuestionAnswerEntity.defaultPed];

    final declared = hasPed == true;
    return [
      for (final q in questions)
        AkInsuranceQuestionAnswerEntity(
          question: AkInsuranceQuestionEntity(
            title: q.title,
            questionCode: q.questionCode,
          ),
          answer: AkInsuranceAnswerEntity(
            // A tick box answers yes/no; a text box answers yes when the
            // traveller wrote something, and carries what they wrote. A row
            // under an unanswered gate is a plain no.
            yesNo: q.isGate
                ? declared
                : q.isCheckbox
                    ? (declared && conditions.contains(q.questionCode))
                    : _text(q.questionCode).isNotEmpty,
            description: q.isGate ? description : _text(q.questionCode),
          ),
          // The provider repeats the declaration on the gate row, which is
          // where its own example carries the disease list.
          preExisting: q.isGate ? declared : false,
          preExistingDisease:
              q.isGate && declared ? conditions.toList() : const [],
          preExistingDesc: q.isGate ? description : '',
          sufferingSince: q.isGate ? sufferingSince : '',
        ),
    ];
  }
}

/// Everything the review screen collects, handed to the payment screen in
/// one object instead of eight positional arguments.
@immutable
class InsBookingDetails {
  final InsProposer proposer;
  final List<InsBookingTraveller> travellers;
  final InsNominee nominee;
  final InsHealthDeclaration health;

  const InsBookingDetails({
    required this.proposer,
    required this.travellers,
    required this.nominee,
    this.health = const InsHealthDeclaration(),
  });

  InsBookingTraveller get lead => travellers.first;
}
