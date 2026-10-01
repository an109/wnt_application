import 'package:flutter/foundation.dart';

import '../../../countries/domain/entities/country_entity.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../tokens/ins_tokens.dart';

/// One policy type as the search screen's tab row shows it.
///
/// [code] is what the provider expects on QuotesListing/StartPay
/// (`INDIVIDUAL`, `ANNUALMULTITRIP`, …) and always comes from the live
/// ProviderChecklist response — never from a list in this file. [label] is
/// only how that code is spelled for the tab.
@immutable
class InsPolicyType {
  final String code;
  final String label;

  /// The Figma puts a "New" flag on Annual Multi-Trip.
  final bool isNew;

  const InsPolicyType({
    required this.code,
    required this.label,
    this.isNew = false,
  });

  /// Turns a provider code into the tab label the design shows. Anything the
  /// checklist returns that isn't spelled out here still gets a readable
  /// label (`SENIORCITIZEN` → `Senior Citizen`) rather than being dropped —
  /// the tab row must show exactly what the account has enabled.
  factory InsPolicyType.fromCode(String raw) {
    final code = raw.trim().toUpperCase();
    // The checklist spells the same type differently across providers
    // ("ANNUAL MULTITRIP", "AnnualMultiTrip", "ANNUAL_MULTI_TRIP"), so the
    // match is made on the letters alone while [code] keeps the provider's
    // own spelling — that is what QuotesListing and StartPay are sent.
    switch (code.replaceAll(RegExp(r'[\s_\-]'), '')) {
      case 'INDIVIDUAL':
        return const InsPolicyType(code: 'INDIVIDUAL', label: 'Individual');
      case 'ANNUALMULTITRIP':
      case 'ANNUALMULTI':
        return InsPolicyType(
          code: code,
          label: 'Annual Multi - Trip',
          isNew: true,
        );
      case 'FAMILY':
        return const InsPolicyType(code: 'FAMILY', label: 'Family');
      case 'FRIENDS':
        return const InsPolicyType(code: 'FRIENDS', label: 'Friends');
      case 'STUDENT':
        return const InsPolicyType(code: 'STUDENT', label: 'Student');
      case 'CORPORATE':
        return const InsPolicyType(code: 'CORPORATE', label: 'Corporate');
      default:
        return InsPolicyType(code: code, label: _titleCase(code));
    }
  }

  static String _titleCase(String code) {
    final spaced = code
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ');
    return spaced
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// [code] with spacing and punctuation removed, for comparisons that must
  /// hold whichever way the provider spelled the type.
  String get _key => code.toUpperCase().replaceAll(RegExp(r'[\s_\-]'), '');

  bool get isStudent => _key == 'STUDENT';

  /// Benzy's support team: on a FRIENDS policy every non-lead traveller's
  /// relation must go out as MEMBER, not the general
  /// SPOUSE/CHILD/PARENT/SIBLING/FRIEND enum.
  bool get isFriends => _key == 'FRIENDS';

  /// How many people this policy type can cover.
  ///
  /// A product rule, not API data: ProviderChecklist reports which types and
  /// fields a provider has enabled but carries no per-type party size, so
  /// the limits the Figma shows ("Only 1 Traveller" on Individual and
  /// Student, "Traveller (Max.6)" on Family/Friends) live here. Anything the
  /// checklist returns that isn't one of those falls back to the provider's
  /// own ceiling of 9 rather than being capped at 1.
  int get maxTravellers {
    switch (_key) {
      case 'INDIVIDUAL':
      case 'STUDENT':
        return 1;
      case 'FAMILY':
      case 'FRIENDS':
        return 6;
      default:
        return 9;
    }
  }

  /// The blue pill beside "Add Traveller with Date of Birth".
  String get travellerLimitLabel => maxTravellers == 1
      ? 'Only 1 Traveller'
      : 'Traveller (Max.$maxTravellers)';

  @override
  bool operator ==(Object other) =>
      other is InsPolicyType && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// A traveller row on the search form: a date of birth plus how that person
/// relates to the lead traveller.
@immutable
class InsTraveller {
  final DateTime? dob;
  final String relation;

  const InsTraveller({this.dob, this.relation = 'SELF'});

  InsTraveller copyWith({DateTime? dob, String? relation, bool clearDob = false}) =>
      InsTraveller(
        dob: clearDob ? null : (dob ?? this.dob),
        relation: relation ?? this.relation,
      );
}

/// Everything the search form collects, as one immutable value.
///
/// Replaces the loose `_insuranceType` / `_travelCountries` / `_startDate`
/// fields the old search card kept in its State: screens now pass this
/// object forward instead of re-deriving the trip from widget parameters,
/// and [toQuotesRequest] is the single place the provider request is built.
@immutable
class InsSearchQuery {
  final InsPolicyType policyType;

  /// Where the traveller is flying from. Carried into StartPay's address
  /// block; the quote itself is priced off the destinations.
  final CountryEntity fromCountry;

  /// One or more destinations, as chosen in the "Select destination" screen.
  final List<CountryEntity> destinations;

  final DateTime startDate;

  /// Null until picked. For a STUDENT policy this is derived from
  /// [tenureMonths] instead of being pickable — see [resolvedEndDate].
  final DateTime? endDate;

  /// STUDENT only. Benzy prices a student policy off start date + tenure,
  /// so the end date is computed rather than picked.
  final int? tenureMonths;

  final List<InsTraveller> travellers;

  const InsSearchQuery({
    required this.policyType,
    required this.fromCountry,
    required this.destinations,
    required this.startDate,
    this.endDate,
    this.tenureMonths,
    required this.travellers,
  });

  /// A blank form: today, one traveller, nothing chosen yet.
  factory InsSearchQuery.initial({
    required InsPolicyType policyType,
    required CountryEntity fromCountry,
  }) {
    return InsSearchQuery(
      policyType: policyType,
      fromCountry: fromCountry,
      destinations: const [],
      startDate: DateUtilsX.today(),
      travellers: const [InsTraveller(relation: 'SELF')],
    );
  }

  InsSearchQuery copyWith({
    InsPolicyType? policyType,
    CountryEntity? fromCountry,
    List<CountryEntity>? destinations,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    int? tenureMonths,
    bool clearTenure = false,
    List<InsTraveller>? travellers,
  }) {
    return InsSearchQuery(
      policyType: policyType ?? this.policyType,
      fromCountry: fromCountry ?? this.fromCountry,
      destinations: destinations ?? this.destinations,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      tenureMonths: clearTenure ? null : (tenureMonths ?? this.tenureMonths),
      travellers: travellers ?? this.travellers,
    );
  }

  // ------------------------------------------------------------- derived

  bool get isStudent => policyType.isStudent;

  /// A student policy's end date is start + tenure; every other type uses
  /// the picked [endDate]. Null when the form isn't complete yet.
  DateTime? get resolvedEndDate {
    if (!isStudent) return endDate;
    final months = tenureMonths;
    if (months == null) return null;
    // DateTime rolls month 13 into next January on its own.
    return DateTime(startDate.year, startDate.month + months, startDate.day);
  }

  /// Inclusive trip length, as the "5 Day" pill shows it.
  int? get days {
    final end = resolvedEndDate;
    if (end == null) return null;
    final n = end.difference(startDate).inDays + 1;
    return n > 0 ? n : null;
  }

  int get travellerCount => travellers.length;

  /// `Thailand, UAE, USA` — the destination summary on the quotes header.
  String get destinationLabel =>
      destinations.isEmpty ? '' : destinations.map((c) => c.name).join(', ');

  /// `Thailand, UAE +2` — the compact form the search card shows.
  String get destinationShort {
    if (destinations.isEmpty) return 'Select';
    if (destinations.length <= 2) {
      return destinations.map((c) => c.name).join(', ');
    }
    return '${destinations.take(2).map((c) => c.name).join(', ')} '
        '+${destinations.length - 2}';
  }

  /// `20 Sep' 26 - 25 Sep' 26 (5 days),  • 1 Traveller`
  String get tripSummary {
    final end = resolvedEndDate;
    final range = end == null
        ? InsTokens.shortDate(startDate)
        : '${InsTokens.shortDate(startDate)} - ${InsTokens.shortDate(end)}';
    final d = days;
    final dayPart = d == null ? '' : ' ($d day${d == 1 ? '' : 's'})';
    final t = travellerCount;
    return '$range$dayPart,  • $t Traveller${t == 1 ? '' : 's'}';
  }

  /// The one reason the form can't be submitted yet, or null when it can.
  /// Order matches the order the fields appear on screen.
  String? get validationError {
    if (destinations.isEmpty) return 'Select where you are travelling to';
    if (isStudent && tenureMonths == null) return 'Select a tenure';
    if (resolvedEndDate == null) return 'Select an end date';
    if (resolvedEndDate!.isBefore(startDate)) {
      return 'The end date cannot be before the start date';
    }
    if (travellers.any((t) => t.dob == null)) {
      return 'Enter a date of birth for every traveller';
    }
    return null;
  }

  bool get isComplete => validationError == null;

  // ------------------------------------------------------- request build

  /// The relation to send for traveller [i]: the lead is always SELF, and a
  /// FRIENDS policy forces MEMBER for everyone else.
  String relationFor(int i) {
    if (i == 0) return 'SELF';
    if (policyType.isFriends) return 'MEMBER';
    final r = travellers[i].relation;
    return r == 'SELF' ? 'SPOUSE' : r;
  }

  List<AkInsuranceTravellerEntity> get travellerEntities => [
        for (int i = 0; i < travellers.length; i++)
          AkInsuranceTravellerEntity(
            id: i,
            birthdate: InsTokens.iso(travellers[i].dob!),
            relation: relationFor(i),
          ),
      ];

  /// The QuotesListing body. Only valid once [isComplete] is true — the
  /// caller checks [validationError] first.
  AkInsuranceQuotesRequestEntity toQuotesRequest() {
    return AkInsuranceQuotesRequestEntity(
      policyType: policyType.code,
      countryCodes: destinations.map((c) => c.code).toList(),
      countryNames: destinations.map((c) => c.name).toList(),
      startDate: InsTokens.iso(startDate),
      endDate: InsTokens.iso(resolvedEndDate!),
      // The provider rejects a null tenure, so non-student policies send the
      // same default the old form did rather than omitting the field.
      tenureInMonths: tenureMonths ?? 3,
      travellers: travellerEntities,
    );
  }
}

/// Small date helpers used by the query and the calendar screen.
class DateUtilsX {
  const DateUtilsX._();

  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
