import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entity/AKInsurance_entity.dart';
import '../../domain/usecase/resolve_trip_destination_usecase.dart';
import '../bloc/AKInsurance_bloc.dart';
import '../bloc/AKInsurance_event.dart';
import '../bloc/AKInsurance_state.dart';
import 'trip_secure_plan_details_sheet.dart';

/// "Trip Secure" — the optional travel-insurance add-on on the flight booking
/// screen. Self-contained: it owns its own [AkInsuranceBloc], resolves the
/// destination country itself and reports the picked plan back through
/// [onSelectionChanged].
///
/// Loads the provider checklist on mount and shows the enabled providers as a
/// horizontal card carousel (MMT-style). Pricing (QuotesListing) is deferred
/// until the traveller taps "View plans" — it is the heavier, per-traveller
/// call, so it should not fire before there is any intent to buy cover.
///
/// Call [TripSecureSectionState.repriceWithLatestTravellers] after the
/// traveller form is filled in to re-price with the real dates of birth —
/// this only does anything once plans have already been requested once.
class TripSecureSection extends StatefulWidget {
  /// Arrival airport IATA code of the last leg, e.g. "SIN".
  final String destinationAirportCode;

  /// Outbound departure, and the return date when the booking has one.
  final DateTime? departureDate;
  final DateTime? returnDate;

  final int travellerCount;

  /// Reads the traveller dates of birth out of the booking form as
  /// "yyyy-MM-dd". Entries may be empty while the form is still incomplete.
  final List<String> Function() travellerBirthdates;

  /// Fires with the chosen plan, or null when the traveller opts out.
  final ValueChanged<AkInsurancePlanEntity?> onSelectionChanged;

  const TripSecureSection({
    super.key,
    required this.destinationAirportCode,
    required this.departureDate,
    required this.returnDate,
    required this.travellerCount,
    required this.travellerBirthdates,
    required this.onSelectionChanged,
  });

  @override
  State<TripSecureSection> createState() => TripSecureSectionState();
}

class TripSecureSectionState extends State<TripSecureSection> {
  late final AkInsuranceBloc _bloc;

  TripDestination? _destination;
  bool _expanded = true;

  /// True once the traveller has tapped "View plans" at least once — flips
  /// the provider carousel's call-to-action over to the priced plan list.
  bool _plansRequested = false;

  /// The traveller birthdates the current quote was priced on — used to skip
  /// a redundant re-price when nothing about the travellers changed.
  List<String> _pricedBirthdates = const [];

  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _border = Color(0xFFE2E7F0);
  static const _green = Color(0xFF0E9F6E);

  /// The listing sample prices a short trip with this tenure; it only matters
  /// for multi-trip annual policies, which this add-on does not offer.
  static const _tenureInMonths = 3;

  @override
  void initState() {
    super.initState();
    _bloc = di.sl<AkInsuranceBloc>();
    _bloc.add(const LoadAkInsuranceProviderChecklistEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Re-prices against the dates of birth currently in the traveller form.
  /// A no-op until plans have been requested once, and safe to call
  /// repeatedly otherwise — it no-ops when nothing changed either.
  void repriceWithLatestTravellers() {
    if (!_plansRequested) return;
    final birthdates = _birthdates();
    if (_listEquals(birthdates, _pricedBirthdates)) return;
    _loadQuotes();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Fetches QuotesListing for the current trip. Triggered by the "View
  /// plans" tap, and re-run silently by [repriceWithLatestTravellers].
  Future<void> _loadQuotes() async {
    setState(() => _plansRequested = true);

    final destination = _destination ??
        await di.sl<ResolveTripDestinationUseCase>().call(widget.destinationAirportCode);
    if (!mounted) return;
    _destination = destination;

    final start = widget.departureDate ?? DateTime.now();
    // A one-way booking has no return date; the policy still needs an end
    // date, so it covers the travel day itself.
    final end = widget.returnDate ?? start;
    final birthdates = _birthdates();
    _pricedBirthdates = birthdates;

    _bloc.add(LoadAkInsuranceQuotesEvent(
      AkInsuranceQuotesRequestEntity(
        countryCodes: [destination.countryCode],
        countryNames: [destination.countryName],
        startDate: _iso(start),
        endDate: _iso(end.isBefore(start) ? start : end),
        tenureInMonths: _tenureInMonths,
        travellers: [
          for (int i = 0; i < birthdates.length; i++)
            AkInsuranceTravellerEntity(
              id: i,
              birthdate: birthdates[i],
              // Only the lead passenger's relation is known from the flight
              // form; the rest are co-travellers. Unverified against the
              // provider's accepted relation codes.
              relation: i == 0 ? 'SELF' : 'OTHER',
            ),
        ],
      ),
    ));
  }

  /// The form's dates of birth, padded to the traveller count. Blank entries
  /// fall back to a 30-year-old adult so the section can quote a price before
  /// the form is complete — [repriceWithLatestTravellers] corrects it later.
  List<String> _birthdates() {
    final fromForm = widget.travellerBirthdates();
    final count = widget.travellerCount < 1 ? 1 : widget.travellerCount;
    final fallback = _iso(DateTime(DateTime.now().year - 30, 1, 1));

    return List<String>.generate(count, (i) {
      if (i >= fromForm.length) return fallback;
      final value = fromForm[i].trim();
      return value.isEmpty ? fallback : value;
    });
  }

  String _iso(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Premiums come back in the provider's currency (INR) — this shows them in
  /// whatever currency the user picked in Settings, like the rest of the
  /// booking screen.
  String _formatAmount(double amount, String currency) {
    final target = di.sl<PreferencesManager>().getPreferredCurrency() ?? 'INR';
    final from = currency.isEmpty ? 'INR' : currency.toUpperCase();
    final converted = target.toUpperCase() == from
        ? amount
        : CurrencyConverter.convert(
            amount: amount,
            fromCurrency: from,
            toCurrency: target,
          );
    return CurrencyConverter.format(converted, target);
  }

  void _select(AkInsurancePlanEntity? plan) {
    _bloc.add(SelectAkInsurancePlanEvent(plan));
    widget.onSelectionChanged(plan);
  }

  /// The provider requires a validated ID document before a plan can be paid
  /// for (step 5/7 — ValidateKYC), so picking a plan opens that form first
  /// instead of selecting immediately. A KYC already passed for the same
  /// provider on this trip is reused rather than asked for twice.
  Future<void> _selectPlanWithKyc(BuildContext context, AkInsurancePlanEntity plan) async {
    final providerName = plan.provider.isNotEmpty ? plan.provider : plan.planName;
    final existingKyc = _bloc.state.kycRequest;
    if (_bloc.state.kycStatus == AkInsuranceStatus.loaded &&
        existingKyc != null &&
        existingKyc.providerName == providerName) {
      _select(plan);
      return;
    }

    final tui = _bloc.state.quotes?.tui ?? '';
    final birthdates = _birthdates();
    final dob = birthdates.isNotEmpty ? birthdates.first : _iso(DateTime(DateTime.now().year - 30, 1, 1));

    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<AkInsuranceBloc>.value(
        value: _bloc,
        child: _KycForm(providerName: providerName, defaultDob: dob, tui: tui),
      ),
    );

    if (verified == true) {
      _select(plan);
    }
  }

  /// Everything the payment screen needs to actually pay for and issue this
  /// plan: null until a plan is selected AND its KYC has passed.
  TripSecureBookingContext? get bookingContext {
    final plan = _bloc.state.selectedPlan;
    final kyc = _bloc.state.kycRequest;
    final quotesRequest = _bloc.state.quotesRequest;
    final tui = _bloc.state.quotes?.tui;
    if (plan == null || kyc == null || quotesRequest == null || tui == null || tui.isEmpty) {
      return null;
    }
    return TripSecureBookingContext(plan: plan, kyc: kyc, quotesRequest: quotesRequest, tui: tui);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AkInsuranceBloc>.value(
      value: _bloc,
      child: BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
        builder: (context, state) {
          // The checklist says this destination has no provider at all —
          // stay completely out of the way rather than showing an empty card.
          final noProviders = state.checklistStatus == AkInsuranceStatus.loaded &&
              (state.checklist?.providers.isEmpty ?? true);
          if (noProviders) {
            return const SizedBox.shrink();
          }

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(12)),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, state),
                if (_expanded) ...[
                  Divider(height: context.h(1), color: _border),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        context.w(12), context.h(12), context.w(12), context.h(12)),
                    child: _content(context, state),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// True once the traveller form holds dates of birth the current quote was
  /// not priced on — the premium is age-banded, so the shown price is stale.
  bool get _pricingIsStale =>
      _pricedBirthdates.isNotEmpty && !_listEquals(_birthdates(), _pricedBirthdates);

  Widget _header(BuildContext context, AkInsuranceState state) {
    final selected = state.selectedPlan;

    return InkWell(
      onTap: () {
        setState(() => _expanded = !_expanded);
        // Opening the section is the natural moment to pick up dates of birth
        // the traveller has filled in since the last quote.
        if (_expanded) repriceWithLatestTravellers();
      },
      borderRadius: BorderRadius.circular(context.r(12)),
      child: Padding(
        padding: EdgeInsets.all(context.w(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(context.w(7)),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(context.r(9)),
              ),
              child: Icon(Icons.health_and_safety_outlined,
                  color: _blue, size: context.w(19)),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Trip Secure',
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                      SizedBox(width: context.w(6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.w(6), vertical: context.h(2)),
                        decoration: BoxDecoration(
                          color: const Color(0xffEAF7F1),
                          borderRadius: BorderRadius.circular(context.r(4)),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            fontSize: context.fs(8),
                            fontWeight: FontWeight.w900,
                            color: _green,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(3)),
                  Text(
                    selected != null
                        ? '${selected.planName} added • ${_formatAmount(selected.premium, selected.currency)}'
                        : 'Cover trip cancellation, baggage loss and medical emergencies',
                    style: TextStyle(
                      fontSize: context.fs(10.5),
                      height: 1.35,
                      fontWeight: selected != null ? FontWeight.w700 : FontWeight.w500,
                      color: selected != null ? _green : const Color(0xff6B7280),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.w(4)),
            Icon(
              _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xff6B7280),
              size: context.w(22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AkInsuranceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _providerCarousel(context, state),
        SizedBox(height: context.h(12)),
        _viewAllPlansButton(context, state),
        SizedBox(height: context.h(12)),
        _declineTile(context, state.selectedPlan == null),
      ],
    );
  }

  /// Full-width call-to-action — tapping it fires QuotesListing (if it
  /// hasn't run yet) and opens the plan list in a bottom-to-top sheet.
  Widget _viewAllPlansButton(BuildContext context, AkInsuranceState state) {
    final label = state.selectedPlan != null ? 'Change plan' : 'View All Plans';

    return InkWell(
      onTap: () => _openPlansSheet(context),
      borderRadius: BorderRadius.circular(context.r(10)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.h(12)),
        decoration: BoxDecoration(
          color: const Color(0xffF5F5F5),
          borderRadius: BorderRadius.circular(context.r(10)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: _blue,
              fontWeight: FontWeight.bold,
              fontSize: context.fs(12.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Fetches quotes (once) and opens the plan list as a modal bottom sheet
  /// that slides up over the booking screen.
  Future<void> _openPlansSheet(BuildContext context) {
    if (!_plansRequested) {
      _loadQuotes();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<AkInsuranceBloc>.value(
        value: _bloc,
        child: BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
          builder: (sheetContext, state) => _plansSheet(sheetContext, state),
        ),
      ),
    );
  }

  Widget _plansSheet(BuildContext context, AkInsuranceState state) {
    return Container(
      constraints: BoxConstraints(maxHeight: context.screenHeight * 0.85),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: context.h(10)),
          Container(
            width: context.w(40),
            height: context.h(4),
            decoration: BoxDecoration(
              color: const Color(0xffD8DEEA),
              borderRadius: BorderRadius.circular(context.r(4)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(context.w(16), context.h(14), context.w(8), context.h(10)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose a Trip Secure plan',
                    style: TextStyle(
                      fontSize: context.fs(14.5),
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, size: context.w(20), color: const Color(0xff6B7280)),
                ),
              ],
            ),
          ),
          Divider(height: context.h(1), color: _border),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(context.w(16), context.h(12), context.w(16), context.h(16)),
              physics: context.scrollPhysics,
              child: _plansSheetBody(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plansSheetBody(BuildContext context, AkInsuranceState state) {
    if (state.quotesStatus == AkInsuranceStatus.loading ||
        state.quotesStatus == AkInsuranceStatus.initial) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(32)),
        child: Column(
          children: [
            const CircularProgressIndicator(color: _blue),
            SizedBox(height: context.h(10)),
            Text(
              'Finding insurance plans for your trip…',
              style: TextStyle(fontSize: context.fs(11), color: const Color(0xff6B7280)),
            ),
          ],
        ),
      );
    }

    if (state.quotesStatus == AkInsuranceStatus.failed) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(24)),
        child: Column(
          children: [
            Text(
              state.errorMessage.isNotEmpty
                  ? state.errorMessage
                  : 'Could not fetch travel insurance plans. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.fs(12), color: const Color(0xffB45309)),
            ),
            SizedBox(height: context.h(10)),
            TextButton(
              onPressed: _loadQuotes,
              child: Text('Retry', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    if (state.plans.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(24)),
        child: Text(
          state.quotes?.message.isNotEmpty == true
              ? state.quotes!.message
              : 'No cover is available for this trip right now.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: context.fs(12), color: const Color(0xff6B7280)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_destination != null) ...[
          Row(
            children: [
              Icon(Icons.place_outlined, size: context.w(13), color: const Color(0xff9CA3AF)),
              SizedBox(width: context.w(4)),
              Expanded(
                child: Text(
                  'Cover for ${_destination!.countryName} • '
                  '${widget.travellerCount} traveller${widget.travellerCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: const Color(0xff9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
        ],
        if (_pricingIsStale) ...[
          _stalePriceBanner(context),
          SizedBox(height: context.h(10)),
        ],
        for (final plan in state.plans) ...[
          _planCard(context, plan, state.selectedPlan?.planId == plan.planId),
          SizedBox(height: context.h(8)),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Provider checklist — small horizontal cards, MMT-style.
  // ---------------------------------------------------------------------

  Widget _providerCarousel(BuildContext context, AkInsuranceState state) {
    if (state.checklistStatus == AkInsuranceStatus.loading) {
      return SizedBox(
        height: context.h(70),
        child: Row(
          children: [
            SizedBox(
              width: context.w(14),
              height: context.w(14),
              child: const CircularProgressIndicator(strokeWidth: 2, color: _blue),
            ),
            SizedBox(width: context.w(8)),
            Text(
              'Loading providers…',
              style: TextStyle(fontSize: context.fs(10.5), color: const Color(0xff6B7280)),
            ),
          ],
        ),
      );
    }

    final providers = state.checklist?.providers ?? const <AkInsuranceProviderEntity>[];
    if (providers.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: context.h(78),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: context.scrollPhysics,
        itemCount: providers.length,
        separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
        itemBuilder: (context, index) => _providerCard(context, providers[index]),
      ),
    );
  }

  Widget _providerCard(BuildContext context, AkInsuranceProviderEntity provider) {
    // Provider names come back as raw codes (e.g. "ICICI_SAVER") rather than
    // display names — underscores are the only separator worth normalising
    // without guessing at capitalisation for brand mashups like "TATAAIG".
    //
    // insuranceTypes/requiredFields are shared across the whole checklist
    // response (not per provider), so they aren't distinguishing info for an
    // individual card — the card only shows the provider itself.
    final displayName = provider.name.replaceAll('_', ' ').trim();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      width: context.w(90),
      padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(8)),
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F6),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: context.w(30),
            height: context.w(30),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w800, color: _blue),
            ),
          ),
          SizedBox(height: context.h(6)),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: context.fs(9.5), fontWeight: FontWeight.w700, color: _navy),
          ),
        ],
      ),
    );
  }

  /// Premiums are age-banded, so a plan priced before the traveller filled in
  /// their date of birth may not be the real price. This offers the re-price
  /// explicitly instead of silently changing the amount under the user.
  Widget _stalePriceBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(9)),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7E6),
        borderRadius: BorderRadius.circular(context.r(9)),
        border: Border.all(color: const Color(0xffFACC15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xffB45309), size: context.w(14)),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Text(
              'Prices below were quoted before your traveller details.',
              style: TextStyle(
                color: const Color(0xffB45309),
                fontSize: context.fs(10),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: repriceWithLatestTravellers,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: context.w(6)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Update',
              style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(BuildContext context, AkInsurancePlanEntity plan, bool isSelected) {
    return InkWell(
      // Tapping anywhere on the card opens the full PlanDetails response
      // (benefits, deductibles, health questions, T&Cs) in its own
      // bottom-to-top sheet — same action as the explicit "View benefits"
      // button below. Removing an already-added plan is done via the
      // decline tile, not by tapping the card again.
      onTap: () => TripSecurePlanDetailsSheet.show(
        context: context,
        bloc: _bloc,
        plan: plan,
        formatAmount: _formatAmount,
        onAddPlan: () => _selectPlanWithKyc(context, plan),
      ),
      borderRadius: BorderRadius.circular(context.r(10)),
      child: Container(
        padding: EdgeInsets.all(context.w(10)),
        decoration: BoxDecoration(
          color: isSelected ? _blue.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(
            color: isSelected ? _blue : _border,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: context.w(18),
                  color: isSelected ? _blue : const Color(0xffC3CAD9),
                ),
                SizedBox(width: context.w(9)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.planName,
                        style: TextStyle(
                          fontSize: context.fs(12.5),
                          fontWeight: FontWeight.w700,
                          color: _navy,
                          height: 1.25,
                        ),
                      ),
                      if (plan.provider.isNotEmpty || plan.sumInsured > 0) ...[
                        SizedBox(height: context.h(2)),
                        Text(
                          [
                            if (plan.provider.isNotEmpty) plan.provider,
                            if (plan.sumInsured > 0)
                              'Cover ${_formatAmount(plan.sumInsured, plan.currency)}',
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: context.fs(10),
                            color: const Color(0xff6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.w(8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAmount(plan.premium, plan.currency),
                      style: TextStyle(
                        fontSize: context.fs(13.5),
                        fontWeight: FontWeight.w900,
                        color: _navy,
                      ),
                    ),
                    Text(
                      'total',
                      style: TextStyle(
                        fontSize: context.fs(9),
                        color: const Color(0xff9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (plan.highlights.isNotEmpty) ...[
              SizedBox(height: context.h(8)),
              Wrap(
                spacing: context.w(6),
                runSpacing: context.h(6),
                children: [
                  for (final highlight in plan.highlights.take(3))
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.w(7), vertical: context.h(3)),
                      decoration: BoxDecoration(
                        color: const Color(0xffF3F6FC),
                        borderRadius: BorderRadius.circular(context.r(5)),
                      ),
                      child: Text(
                        highlight,
                        style: TextStyle(
                          fontSize: context.fs(9.5),
                          color: const Color(0xff4B5563),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            SizedBox(height: context.h(4)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => TripSecurePlanDetailsSheet.show(
                  context: context,
                  bloc: _bloc,
                  plan: plan,
                  formatAmount: _formatAmount,
                  onAddPlan: () => _selectPlanWithKyc(context, plan),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(6), vertical: context.h(2)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View benefits',
                  style: TextStyle(
                    fontSize: context.fs(10.5),
                    fontWeight: FontWeight.w800,
                    color: _blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _declineTile(BuildContext context, bool isSelected) {
    return InkWell(
      onTap: () => _select(null),
      borderRadius: BorderRadius.circular(context.r(10)),
      child: Container(
        padding: EdgeInsets.all(context.w(10)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(
            color: isSelected ? const Color(0xffC3CAD9) : _border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: context.w(18),
              color: isSelected ? const Color(0xff6B7280) : const Color(0xffC3CAD9),
            ),
            SizedBox(width: context.w(9)),
            Expanded(
              child: Text(
                "No, I'll travel without protection",
                style: TextStyle(
                  fontSize: context.fs(11.5),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 5/7 (ValidateKYC) form — shown right after a plan is tapped, before
/// it is actually selected. Only a PAN is collected (the provider's contract
/// wants exactly one ID document; the rest stay empty strings per its
/// example payload) alongside the name/gender the policy will be issued
/// under. Pops `true` once the bloc reports KYC passed, `false`/`null`
/// (back button, tap outside) if the traveller backs out.
class _KycForm extends StatefulWidget {
  final String providerName;
  final String defaultDob;
  final String tui;

  const _KycForm({
    required this.providerName,
    required this.defaultDob,
    required this.tui,
  });

  @override
  State<_KycForm> createState() => _KycFormState();
}

class _KycFormState extends State<_KycForm> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  final _nameController = TextEditingController();
  String _gender = 'M';

  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _border = Color(0xFFE2E7F0);
  static final _panPattern = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  @override
  void dispose() {
    _panController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit(AkInsuranceBloc bloc) {
    if (!_formKey.currentState!.validate()) return;
    bloc.add(LoadAkInsuranceKycEvent(AkInsuranceKycRequestEntity(
      pan: _panController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      gender: _gender,
      dob: widget.defaultDob,
      providerName: widget.providerName,
      tui: widget.tui,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AkInsuranceBloc>();

    return BlocConsumer<AkInsuranceBloc, AkInsuranceState>(
      listener: (context, state) {
        if (state.kycStatus == AkInsuranceStatus.loaded) {
          Navigator.pop(context, true);
        }
      },
      builder: (context, state) {
        final isSubmitting = state.kycStatus == AkInsuranceStatus.loading;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: context.screenHeight * 0.85),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20))),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(context.w(16), context.h(10), context.w(16), context.h(16)),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: context.w(40),
                        height: context.h(4),
                        margin: EdgeInsets.only(bottom: context.h(14)),
                        decoration: BoxDecoration(
                          color: const Color(0xffD8DEEA),
                          borderRadius: BorderRadius.circular(context.r(4)),
                        ),
                      ),
                    ),
                    Text(
                      'Verify traveller details',
                      style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w800, color: _navy),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      'Required by ${widget.providerName} before this plan can be issued.',
                      style: TextStyle(fontSize: context.fs(11), color: const Color(0xff6B7280)),
                    ),
                    SizedBox(height: context.h(18)),
                    Text(
                      'PAN',
                      style: TextStyle(fontSize: context.fs(11.5), fontWeight: FontWeight.w700, color: _navy),
                    ),
                    SizedBox(height: context.h(6)),
                    TextFormField(
                      controller: _panController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 10,
                      decoration: _fieldDecoration(context, 'ABCDE1234F'),
                      style: TextStyle(fontSize: context.fs(13)),
                      validator: (value) {
                        final v = (value ?? '').trim().toUpperCase();
                        return _panPattern.hasMatch(v) ? null : 'Enter a valid 10-character PAN';
                      },
                    ),
                    SizedBox(height: context.h(10)),
                    Text(
                      'Full name (as on ID)',
                      style: TextStyle(fontSize: context.fs(11.5), fontWeight: FontWeight.w700, color: _navy),
                    ),
                    SizedBox(height: context.h(6)),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(context, 'Full name'),
                      style: TextStyle(fontSize: context.fs(13)),
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? 'Name is required' : null,
                    ),
                    SizedBox(height: context.h(12)),
                    Text(
                      'Gender',
                      style: TextStyle(fontSize: context.fs(11.5), fontWeight: FontWeight.w700, color: _navy),
                    ),
                    SizedBox(height: context.h(6)),
                    Row(
                      children: [
                        _genderChip(context, 'M', 'Male'),
                        SizedBox(width: context.w(8)),
                        _genderChip(context, 'F', 'Female'),
                      ],
                    ),
                    if (state.kycStatus == AkInsuranceStatus.failed) ...[
                      SizedBox(height: context.h(12)),
                      Text(
                        state.errorMessage,
                        style: TextStyle(fontSize: context.fs(11), color: const Color(0xffB45309)),
                      ),
                    ],
                    SizedBox(height: context.h(18)),
                    SizedBox(
                      width: double.infinity,
                      height: context.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () => _submit(bloc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(14))),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: context.w(18),
                                height: context.w(18),
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.fs(13),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: context.fs(12), color: const Color(0xffC3CAD9)),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(12)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(10)),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(10)),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(10)),
        borderSide: const BorderSide(color: _blue, width: 1.4),
      ),
      counterText: '',
    );
  }

  Widget _genderChip(BuildContext context, String value, String label) {
    final selected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      borderRadius: BorderRadius.circular(context.r(10)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(9)),
        decoration: BoxDecoration(
          color: selected ? _blue.withValues(alpha: 0.08) : const Color(0xffF3F4F6),
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: selected ? _blue : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.fs(12),
            fontWeight: FontWeight.w700,
            color: selected ? _blue : const Color(0xff6B7280),
          ),
        ),
      ),
    );
  }
}
