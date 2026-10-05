import 'package:intl/intl.dart';

import '../../../../core/error/data_state.dart';
import '../../../../injection_container.dart' as di;
import '../../../countries/domain/entities/country_entity.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../../domain/usecase/AKInsurance_usecase.dart';
import '../state/ins_booking_details.dart';
import '../state/ins_search_query.dart';

/// What issuing a policy produced.
class InsIssueResult {
  /// The provider's transaction id. Empty when the policy was not issued.
  final String transactionId;

  /// The policy number, when GetItinerary returned one.
  final String policyNumber;

  final String message;

  const InsIssueResult({
    this.transactionId = '',
    this.policyNumber = '',
    this.message = '',
  });

  bool get isIssued => transactionId.isNotEmpty;
}

/// Turns the collected trip, plan and traveller details into a StartPay
/// call, then fetches the issued policy number.
///
/// Lives on its own rather than inside the payment screen because the
/// request has ~50 fields and a handful of provider quirks that must not be
/// lost in a redesign — every one of them is carried over verbatim from the
/// previous payment screen, including the comments explaining why.
class InsPolicyIssuer {
  final InsSearchQuery query;
  final InsBookingDetails details;
  final AkInsurancePlanEntity plan;
  final String tui;
  final List<CountryEntity> countries;

  const InsPolicyIssuer({
    required this.query,
    required this.details,
    required this.plan,
    required this.tui,
    required this.countries,
  });

  static final _dateTimeFmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  /// The provider's example StartDate/EndDate/BirthDate are full ISO
  /// datetimes at midnight. The search form's start date can carry the
  /// actual time of day, so it is stripped here rather than leaking into
  /// the request.
  static String _dateOnly(DateTime d) =>
      _dateTimeFmt.format(DateTime(d.year, d.month, d.day));

  /// Akbar prices an ANNUAL MULTITRIP policy off TenureInMonths rather than
  /// the date range; leaving it null is what made StartPay answer 502
  /// "CompletedWithFailure" for annual trips.
  bool get _isAnnual => query.policyType.code.contains('ANNUAL');

  /// STUDENT is tenure-based on the same contract.
  bool get _isStudent => query.policyType.isStudent;

  /// `Plans[].Type` is a narrower enum than the top-level `PolicyType`:
  /// StartPay rejects anything but Individual / Senior Citizen / Multi Trip
  /// there. PolicyType carries the real category (STUDENT/FAMILY/FRIENDS/…)
  /// while this is a coarser billing class, so Family, Friends, Student and
  /// Individual all bill as "Individual". This app has no policy that maps
  /// to "Senior Citizen", so that value is never produced.
  String get _planType => _isAnnual ? 'Multi Trip' : 'Individual';

  AkInsuranceStartPayRequestEntity buildRequest({
    required String gateway,
    required String paymentReference,
    required int amount,
    String? paymentId,
  }) {
    final lead = details.lead;
    final proposer = details.proposer;

    final countryCodes = query.destinations.map((d) {
      if (d.code.isNotEmpty) return d.code;
      final match = countries.where((c) => c.name == d.name);
      return match.isNotEmpty ? match.first.code : '';
    }).toList();

    // The form collects one contact and one address (the proposer's), not
    // one per traveller, so the same pair is reused on every traveller.
    final contact = AkInsuranceContactInfoEntity(
      number: proposer.contactNumber,
      code: proposer.dialCode,
      emailAddress: proposer.email,
    );
    final address = AkInsuranceAddressEntity(
      line1: proposer.addressLine1.isEmpty ? 'NA' : proposer.addressLine1,
      line2: proposer.addressLine2,
      pinCode: proposer.pincode.isEmpty ? '000000' : proposer.pincode,
      cityName: proposer.city,
      stateName: proposer.state,
    );

    final questionAnswers = details.health.toQuestionAnswers();

    final nominee = AkInsuranceNomineeEntity(
      firstName: details.nominee.firstName,
      lastName: details.nominee.lastName,
      relation: details.nominee.relation,
    );

    return AkInsuranceStartPayRequestEntity(
      paymentReference: paymentReference,
      paymentId: paymentId,
      gateway: gateway,
      panNo: proposer.panNumber,
      countryCodes: countryCodes,
      countryNames: query.destinations.map((d) => d.name).toList(),
      startDate: _dateOnly(query.startDate),
      endDate: _dateOnly(query.resolvedEndDate ?? query.startDate),
      tenureInMonths: _isAnnual
          ? 12
          : (_isStudent ? (query.tenureMonths ?? 3) : null),
      // The real policy category — deliberately not the same value as
      // [_planType]; see its comment for why the two diverge.
      policyType: query.policyType.code,
      // Traveller 1 is the proposer (IsProposer: true below), so the
      // Customer block is that person — nationality, gender and passport
      // included. They were collected on the review form but never reached
      // the request before.
      customer: AkInsuranceCustomerEntity(
        title: lead.title,
        firstName: lead.firstName,
        lastName: lead.lastName,
        birthDate: lead.dob != null ? _dateOnly(lead.dob!) : '',
        nationality: proposer.nationality,
        gender: lead.genderCode,
        passportNumber: lead.passport,
        contactInfo: contact,
        addresses: [address],
        gstin: proposer.gstNumber,
      ),
      plans: [
        AkInsurancePlanBookingEntity(
          id: plan.planId,
          type: _planType,
          travellers: [
            for (int i = 0; i < details.travellers.length; i++)
              AkInsuranceBookingTravellerEntity(
                id: i,
                title: details.travellers[i].title,
                firstName: details.travellers[i].firstName,
                lastName: details.travellers[i].lastName,
                birthDate: details.travellers[i].dob != null
                    ? _dateOnly(details.travellers[i].dob!)
                    : '',
                passportNumber: details.travellers[i].passport,
                gender: details.travellers[i].genderCode,
                relationship:
                    details.travellers[i].relationship.toUpperCase(),
                isProposer: i == 0,
                // A student travelling on a "TOURIST" visa contradicts
                // PolicyType: STUDENT on the same request, which is why
                // StartPay rejected Student bookings with a field-less
                // "Failure".
                visaType: _isStudent ? 'STUDENT' : 'TOURIST',
                // Benzy's schema requires a nominee and a questions list on
                // every traveller; omitting either crashes StartPay with a
                // 500/502 upstream. The answers are the traveller's own, from
                // the questionnaire PlanDetails returned — this used to be a
                // hardcoded "no pre-existing disease" on everyone.
                nominee: nominee,
                questionsAnswers: questionAnswers,
                addresses: [address],
                contactInfo: contact,
                studentDetails: AkInsuranceStudentDetailsEntity(
                  universityDetails:
                      details.travellers[i].university.isEmpty
                          ? null
                          : details.travellers[i].university,
                  sponsor: details.travellers[i].sponsor.isEmpty
                      ? null
                      : details.travellers[i].sponsor,
                  guardian: details.travellers[i].guardian.isEmpty
                      ? null
                      : details.travellers[i].guardian,
                ),
              ),
          ],
        ),
      ],
      amount: amount,
      onlinePayment: false,
      depositPayment: true,
      tui: tui,
    );
  }

  /// Issues the policy, retrying while the provider reports it is still
  /// working, then fetches the policy number.
  ///
  /// The charge has already cleared by the time this runs, so a failure
  /// here means "paid but not yet issued" — never "payment failed".
  Future<InsIssueResult> issue({
    required String gateway,
    required String paymentReference,
    required int amount,
    String? paymentId,
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 4),
  }) async {
    final request = buildRequest(
      gateway: gateway,
      paymentReference: paymentReference,
      amount: amount,
      paymentId: paymentId,
    );

    var attempt = 0;
    while (attempt < maxAttempts) {
      final result = await di.sl<AkInsuranceStartPayUseCase>().call(request);

      if (result is! DataSuccess<AkInsuranceStartPayEntity>) {
        return InsIssueResult(
          message: result.error?.message?.toString() ??
              'The insurer could not be reached.',
        );
      }

      final data = result.data!;
      if (data.isBooked) {
        // Best-effort: the policy is issued either way, so a failure to read
        // the policy number does not flip the outcome.
        var policyNumber = '';
        final itinerary = await di.sl<AkInsuranceGetItineraryUseCase>().call(
              AkInsuranceItineraryRequestEntity(
                tui: tui,
                transactionId: data.transactionId,
              ),
            );
        if (itinerary is DataSuccess<AkInsuranceItineraryEntity>) {
          policyNumber = itinerary.data?.policyNumber ?? '';
        }
        return InsIssueResult(
          transactionId: data.transactionId,
          policyNumber: policyNumber,
          message: data.message,
        );
      }

      if (data.bookingInProgress) {
        attempt++;
        if (attempt < maxAttempts) await Future.delayed(retryDelay);
        continue;
      }
      return InsIssueResult(message: data.message);
    }

    return const InsIssueResult(
      message: 'The insurer is still processing this policy.',
    );
  }
}
