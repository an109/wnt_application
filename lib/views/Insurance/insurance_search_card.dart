import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'insurance_quotesScreen.dart';
import '../../UI_helper/responsive_layout.dart';
import '../../core/resources/app_colours.dart';
import '../../injection_container.dart' as di;
import '../AKInsurance/domain/entity/AKInsurance_entity.dart';
import '../AKInsurance/presentation/bloc/AKInsurance_bloc.dart';
import '../AKInsurance/presentation/bloc/AKInsurance_event.dart';
import '../AKInsurance/presentation/bloc/AKInsurance_state.dart';
import '../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../MainApi/presentation/bloc/general_settings_event.dart';
import '../MainApi/presentation/bloc/general_settings_state.dart';
import '../countries/domain/entities/country_entity.dart';
import '../countries/presentation/bloc/country_bloc.dart';
import '../countries/presentation/bloc/country_event.dart';
import '../countries/presentation/bloc/country_state.dart';

const Color _kLabelGrey = Color(0xFF9AA3B2);
const Color _kSubGrey = Color(0xFF7A8494);
const Color _kPageBg = Color(0xFFF8F9FA);

/// Travel Insurance quote card.
///
/// The **UI** now mirrors the flight [SearchCard]: a full-bleed hero photo
/// (the same `section_heroes.flights` image the flight card uses), a frosted
/// "Insurance" top bar, frosted trip-plan pills and white field cards over
/// the photo, and an orange "Explore Plans" pill.
///
/// The **functionality is unchanged** — every field still maps to the same
/// state and the CTA still builds the identical `AkInsuranceQuotesRequestEntity`
/// / `InsuranceQuoteRequest` and pushes [InsuranceQuotesScreen].
class InsuranceSearchCard extends StatefulWidget {
  const InsuranceSearchCard({super.key});

  @override
  State<InsuranceSearchCard> createState() => _InsuranceSearchCardState();
}

class _InsuranceSearchCardState extends State<InsuranceSearchCard> {
  static const Color _brandBlue = Color(0xFF003B95);

  // ── Quote data (same shape as the web form) ───────────────────────────
  String _insuranceType = 'Individual';
  String _fromCountry = 'India';
  List<String> _travelCountries = <String>[];
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate;
  // STUDENT only — per Benzy's support team, a student policy is priced off
  // Start Date + tenure, not a free-picked date range; _endDate is derived
  // from this rather than user-picked whenever _isStudent is true (see
  // _recomputeStudentEndDate). Null for every other policy type.
  int? _tenureMonths;
  List<DateTime?> _travellerDobs = <DateTime?>[null];
  // Index-aligned with _travellerDobs; index 0 (the lead traveller) is
  // always SELF and has no picker. QuotesListing/PlanDetails' documented
  // relation enum for the rest is SPOUSE/CHILD/PARENT/SIBLING/FRIEND — except
  // a FRIENDS policy, where Benzy's support team says every non-lead
  // traveller's relation must be sent as MEMBER instead (see
  // _relationOptionsFor in _TravellersDialogState).
  List<String> _travellerRelations = <String>['SELF'];

  // Purely cosmetic — the Figma shows a Single Trip / Annual Multi Trip
  // selector but there is no backend field for it yet, so this only drives
  // the pill's selected state and is never sent with the quote request.
  String _tripPlan = 'single';

  // `section_heroes.flights` — the same hero photo the flight SearchCard uses.
  String? _heroImage;

  bool get _isStudent => _insuranceType.toUpperCase() == 'STUDENT';
  // Benzy's support team: for a FRIENDS policy every non-lead traveller's
  // relation must be sent as MEMBER in QuotesListing, not the general
  // SPOUSE/CHILD/PARENT/SIBLING/FRIEND enum used by other policy types.
  bool get _isFriends => _insuranceType.toUpperCase() == 'FRIENDS';

  void _recomputeStudentEndDate() {
    if (!_isStudent || _startDate == null || _tenureMonths == null) return;
    final s = _startDate!;
    // DateTime's month rolls over correctly past December on its own
    // (e.g. month 13 becomes next-year January) — no manual wraparound needed.
    _endDate = DateTime(s.year, s.month + _tenureMonths!, s.day);
  }

  // Fallback options shown while the live ProviderChecklist/cached-countries
  // calls are in flight or if they fail — keeps the form usable either way.
  static const List<String> _fallbackInsuranceTypes = [
    'Individual', 'Family', 'Corporate', 'Student',
  ];
  static const List<String> _fallbackCountries = [
    'India', 'Thailand', 'Singapore', 'Dubai', 'Malaysia', 'Japan',
    'Vietnam', 'USA', 'UK', 'Australia', 'Germany', 'France', 'Indonesia',
  ];

  late final AkInsuranceBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = di.sl<AkInsuranceBloc>();
    _bloc.add(const LoadAkInsuranceProviderChecklistEvent());

    final countryState = context.read<CountryBloc>().state;
    if (countryState is! CountryLoaded) {
      context.read<CountryBloc>().add(const LoadCountriesEvent());
    }

    // Same source the flight SearchCard reads its hero photo from.
    context.read<GeneralSettingsBloc>().add(
      const LoadSectionHeroes(domain: 'thewandernova.com'),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  int? get _noOfDays {
    final s = _startDate, e = _endDate;
    if (s == null || e == null) return null;
    final days = e.difference(s).inDays + 1; // inclusive trip duration
    return days > 0 ? days : null;
  }

  // ── Travellers +/- (mirrors the stepper inside _TravellersDialog) ──────
  void _addTraveller() {
    if (_travellerDobs.length >= 9) return;
    setState(() {
      _travellerDobs = [..._travellerDobs, null];
      _travellerRelations = [
        ..._travellerRelations,
        _isFriends ? 'MEMBER' : 'SPOUSE',
      ];
    });
  }

  void _removeTraveller() {
    if (_travellerDobs.length <= 1) return;
    setState(() {
      _travellerDobs = _travellerDobs.sublist(0, _travellerDobs.length - 1);
      if (_travellerRelations.length > _travellerDobs.length) {
        _travellerRelations =
            _travellerRelations.sublist(0, _travellerDobs.length);
      }
    });
  }

  Future<void> _openTravellersDialog() async {
    final v = await _TravellersDialog.show(
      context,
      _travellerDobs,
      _travellerRelations,
      isFriends: _isFriends,
    );
    if (v != null) {
      setState(() {
        _travellerDobs = v.dobs;
        _travellerRelations = v.relations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeneralSettingsBloc, GeneralSettingsState>(
      listener: (context, state) {
        if (state is SectionHeroesLoaded) {
          setState(() => _heroImage = state.sectionHeroes.flights);
        }
      },
      child: BlocBuilder<CountryBloc, CountryState>(
        builder: (context, countryState) {
          final countries = countryState is CountryLoaded
              ? countryState.countries
              : const <CountryEntity>[];
          final countryNames = countries.isNotEmpty
              ? countries.map((c) => c.name).toList()
              : _fallbackCountries;

          return BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
            bloc: _bloc,
            builder: (context, akState) {
              final policyTypes =
                  akState.checklist?.policyTypes.isNotEmpty == true
                      ? akState.checklist!.policyTypes
                      : _fallbackInsuranceTypes;
              return _buildHeroForm(context, countryNames, policyTypes);
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- BUILD

  Widget _buildHeroForm(
    BuildContext context,
    List<String> countryNames,
    List<String> policyTypes,
  ) {
    return Stack(
      children: [
        // Full-bleed hero image — edge to edge, no radius.
        Positioned.fill(child: _buildHeroBackdrop(context)),

        // ====== BOTTOM MELTING GRADIENT ======
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(100),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.90),
                  Colors.white.withOpacity(0.60),
                  Colors.white.withOpacity(0.35),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: context.h(170),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kPageBg.withOpacity(0.0),
                  _kPageBg.withOpacity(0.45),
                  _kPageBg,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // Foreground content
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: context.statusBarHeight + context.h(10)),
            _buildTopBar(context),
            SizedBox(height: context.h(18)),
            _buildTripPlanSelector(context),
            SizedBox(height: context.h(14)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(14)),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CountryDropdownField(
                          label: 'TRAVELLING TO',
                          options: countryNames,
                          selected: _travelCountries,
                          onChanged: (v) =>
                              setState(() => _travelCountries = v),
                        ),
                      ),
                      SizedBox(width: context.w(10)),
                      Expanded(
                        child: _dropdownField(
                          context,
                          label: 'INSURANCE TRIP',
                          leadingIcon: Icons.health_and_safety_rounded,
                          value: _insuranceType,
                          options: policyTypes,
                          onChanged: (v) => setState(() {
                            _insuranceType = v;
                            if (_isStudent) {
                              _tenureMonths ??= 3;
                              _recomputeStudentEndDate();
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(10)),
                  _dropdownField(
                    context,
                    label: 'FROM COUNTRY',
                    leadingIcon: Icons.flight_takeoff_rounded,
                    value: _fromCountry,
                    options: countryNames,
                    onChanged: (v) => setState(() => _fromCountry = v),
                  ),
                  SizedBox(height: context.h(10)),
                  _buildTravellersCard(context),
                  SizedBox(height: context.h(10)),
                  _isStudent
                      ? _buildStudentDateRow(context)
                      : _buildCombinedDateCard(context),
                ],
              ),
            ),
            SizedBox(height: context.h(24)),
            _buildExploreButton(context),
            SizedBox(height: context.h(26)),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------ HERO IMAGE

  Widget _buildHeroBackdrop(BuildContext context) {
    const fallbackGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4A90E2), Color(0xFF87CEEB)],
    );

    const fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: fallbackGradient),
    );

    final hero = _heroImage;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hero != null && hero.isNotEmpty)
          Image.network(
            hero,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (ctx, child, progress) =>
                progress == null ? child : fallback,
          )
        else
          fallback,

        // Soft white gradient near the bottom for the "cloudy" merge.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(154),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.92),
                  Colors.white.withOpacity(0.72),
                  Colors.white.withOpacity(0.38),
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.20, 0.40, 0.60, 0.80, 1.0],
              ),
            ),
          ),
        ),

        // Top scrim so the white "Insurance" title stays readable.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.22),
                Colors.black.withOpacity(0.0),
              ],
              stops: const [0.0, 0.3],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- TOP BAR

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            behavior: HitTestBehavior.opaque,
            child: Image.asset(
              'assets/NewIcons/arrowBack.png',
              width: context.w(17),
              height: context.w(17),
              color: const Color(0xFFFFFFFF),
            ),
          ),
          SizedBox(width: context.w(14)),
          Text(
            'Insurance',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------- TRIP PLAN PILLS

  Widget _buildTripPlanSelector(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _tripPlanCard(
                context,
                id: 'single',
                title: 'Single Trip',
                subtitle: 'Starting at ₹276',
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: _tripPlanCard(
                context,
                id: 'annual',
                title: 'Annual Multi Trip',
                subtitle: 'Save upto 80%',
                isNew: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripPlanCard(
    BuildContext context, {
    required String id,
    required String title,
    required String subtitle,
    bool isNew = false,
  }) {
    final selected = _tripPlan == id;
    final radius = BorderRadius.circular(context.r(14));

    return GestureDetector(
      onTap: () => setState(() => _tripPlan = id),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(10),
            ),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.white.withOpacity(0.28),
              borderRadius: radius,
            ),
            child: Row(
              children: [
                _radioDot(selected),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.fs(12.5),
                                fontWeight: FontWeight.w700,
                                color: selected ? _brandBlue : Colors.white,
                              ),
                            ),
                          ),
                          if (isNew) ...[
                            SizedBox(width: context.w(4)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(5),
                                vertical: context.h(1),
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
                                ),
                                borderRadius:
                                    BorderRadius.circular(context.r(6)),
                              ),
                              child: Text(
                                'New',
                                style: TextStyle(
                                  fontSize: context.fs(8),
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: context.h(2)),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(10),
                          color: selected
                              ? _kSubGrey
                              : Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _radioDot(bool selected) {
    return Container(
      width: context.w(18),
      height: context.w(18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _brandBlue : Colors.white,
          width: 2,
        ),
      ),
      child: selected
          ? Container(
              width: context.w(9),
              height: context.w(9),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _brandBlue,
              ),
            )
          : null,
    );
  }

  // ------------------------------------------------------ CARD BUILDING BLOCKS

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: context.w(14),
            offset: Offset(0, context.h(4)),
          ),
        ],
      );

  Widget _cardLabel(String text, {bool showChevron = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: context.fs(8),
            fontWeight: FontWeight.bold,
            color: _kLabelGrey,
            letterSpacing: 0.5,
          ),
        ),
        if (showChevron) ...[
          SizedBox(width: context.w(3)),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.w(12),
            color: _kLabelGrey,
          ),
        ],
      ],
    );
  }

  // Inline native dropdown, styled as a white card — tapping opens Flutter's
  // own dropdown menu, populated from live API data (ProviderChecklist /
  // cached-countries).
  Widget _dropdownField(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    IconData? leadingIcon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _cardLabel(label),
          SizedBox(height: context.h(4)),
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: context.w(20), color: _brandBlue),
                SizedBox(width: context.w(6)),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: options.contains(value) ? value : null,
                    isDense: true,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: context.w(16),
                      color: _kLabelGrey,
                    ),
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    items: options
                        .map((o) => DropdownMenuItem(
                            value: o,
                            child: Text(o,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------- NO. OF TRAVELLERS

  Widget _buildTravellersCard(BuildContext context) {
    final n = _travellerDobs.length;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _cardLabel('NO. OF TRAVELLERS', showChevron: false),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: context.w(22), color: _brandBlue),
              SizedBox(width: context.w(8)),
              Expanded(
                child: GestureDetector(
                  onTap: _openTravellersDialog,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$n Traveller${n > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: context.fs(13.5),
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      SizedBox(height: context.h(2)),
                      Text(
                        'Age: 6 month to 70 years',
                        style: TextStyle(
                          fontSize: context.fs(10.5),
                          color: _kSubGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _miniStepper(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStepper(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(3)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F9),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(context, Icons.remove_rounded, _travellerDobs.length > 1,
              _removeTraveller),
          SizedBox(
            width: context.w(24),
            child: Text(
              '${_travellerDobs.length}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          _stepBtn(context, Icons.add_rounded, _travellerDobs.length < 9,
              _addTraveller),
        ],
      ),
    );
  }

  Widget _stepBtn(
    BuildContext context,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.w(28),
        height: context.w(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        child: Icon(
          icon,
          size: context.w(15),
          color: enabled ? _brandBlue : Colors.grey.shade300,
        ),
      ),
    );
  }

  // ------------------------------------------------------------ DATE CARDS

  Widget _buildCombinedDateCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDate(context, true),
              behavior: HitTestBehavior.opaque,
              child: _dateColumn(context, 'START DATE', _startDate),
            ),
          ),
          _dayPill(context),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDate(context, false),
              behavior: HitTestBehavior.opaque,
              child: _dateColumn(context, 'END DATE', _endDate, alignEnd: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentDateRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(context, true),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(14),
                vertical: context.h(12),
              ),
              decoration: _cardDecoration,
              child: _dateColumn(context, 'START DATE', _startDate),
            ),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: _dropdownField(
            context,
            label: 'TENURE (MONTHS)',
            value: (_tenureMonths ?? 3).toString(),
            options: List.generate(24, (i) => '${i + 1}'),
            onChanged: (v) => setState(() {
              _tenureMonths = int.parse(v);
              _recomputeStudentEndDate();
            }),
          ),
        ),
      ],
    );
  }

  Widget _dateColumn(
    BuildContext context,
    String label,
    DateTime? date, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _cardLabel(label, showChevron: false),
        SizedBox(height: context.h(4)),
        Text(
          date != null ? DateFormat('d MMM, yy').format(date) : 'Select Date',
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w700,
            color: date != null ? AppColors.navy : Colors.grey.shade400,
          ),
        ),
        SizedBox(height: context.h(2)),
        Text(
          date != null ? DateFormat('EEEE').format(date) : '-',
          style: TextStyle(fontSize: context.fs(10.5), color: _kSubGrey),
        ),
      ],
    );
  }

  Widget _dayPill(BuildContext context) {
    final n = _noOfDays;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(8)),
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: AppColors.orange.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: context.w(6),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Text(
        n == null ? '—' : '$n Day${n > 1 ? 's' : ''}',
        style: TextStyle(
          fontSize: context.fs(11),
          fontWeight: FontWeight.w700,
          color: AppColors.orange,
        ),
      ),
    );
  }

  // ------------------------------------------------------- EXPLORE BUTTON

  Widget _buildExploreButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: context.w(170),
        height: context.h(44),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: AppColors.orange.withOpacity(0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(30)),
            ),
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
          ),
          onPressed: _onGetQuotes,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Explore Plans',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: context.w(10)),
                Image.asset(
                  'assets/NewIcons/arrowForward.png',
                  width: context.w(9.54),
                  height: context.w(13),
                  color: const Color(0xFFFFFFFF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Pickers ────────────────────────────────────────────────────────────
  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _brandBlue),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_isStudent) {
          _recomputeStudentEndDate();
        } else if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  void _onGetQuotes() {
    if (_travelCountries.isEmpty) {
      _snack('Select a travelling country first');
      return;
    }
    if (_endDate == null) {
      _snack('Select an end date first');
      return;
    }
    if (_travellerDobs.any((d) => d == null)) {
      _snack('Enter date of birth for all travellers');
      return;
    }

    final countryState = context.read<CountryBloc>().state;
    final countries = countryState is CountryLoaded
        ? countryState.countries
        : const <CountryEntity>[];
    final countryCodes = _travelCountries.map((name) {
      final matches = countries.where((c) => c.name == name);
      return matches.isNotEmpty ? matches.first.code : '';
    }).toList();
    final isoFmt = DateFormat('yyyy-MM-dd');

    final effectiveTenure = _isStudent ? (_tenureMonths ?? 3) : 3;

    _bloc.add(LoadAkInsuranceQuotesEvent(
      AkInsuranceQuotesRequestEntity(
        policyType: _insuranceType.toUpperCase(),
        countryCodes: countryCodes,
        countryNames: List<String>.from(_travelCountries),
        startDate: isoFmt.format(_startDate!),
        endDate: isoFmt.format(_endDate!),
        tenureInMonths: effectiveTenure,
        travellers: [
          for (int i = 0; i < _travellerDobs.length; i++)
            AkInsuranceTravellerEntity(
              id: i,
              birthdate: isoFmt.format(_travellerDobs[i]!),
              relation: i == 0
                  ? 'SELF'
                  : (i < _travellerRelations.length
                      ? _travellerRelations[i]
                      : (_isFriends ? 'MEMBER' : 'SPOUSE')),
            ),
        ],
      ),
    ));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<AkInsuranceBloc>.value(
          value: _bloc,
          child: InsuranceQuotesScreen(
            request: InsuranceQuoteRequest(
              insuranceType: _insuranceType,
              fromCountry: _fromCountry,
              travellingCountries: List<String>.from(_travelCountries),
              startDate: _startDate!,
              endDate: _endDate!,
              noOfDays: _noOfDays!,
              travellerDobs: List<DateTime?>.from(_travellerDobs),
              travellerRelations: List<String>.from(_travellerRelations),
              tenureInMonths: _isStudent ? effectiveTenure : null,
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(10))),
      content: Text(msg),
    ));
  }
}

// ── Travelling countries — anchored multi-select dropdown (search + checks),
// opens right under the field instead of a centered dialog. ────────────────
class _CountryDropdownField extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _CountryDropdownField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_CountryDropdownField> createState() => _CountryDropdownFieldState();
}

class _CountryDropdownFieldState extends State<_CountryDropdownField> {
  static const Color _brandBlue = Color(0xFF003B95);

  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  final TextEditingController _search = TextEditingController();

  late Set<String> _draft;

  @override
  void initState() {
    super.initState();
    _draft = Set<String>.from(widget.selected);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open() {
    _draft = Set<String>.from(widget.selected);
    _search.clear();
    _overlayController.show();
  }

  void _apply() {
    widget.onChanged(_draft.toList());
    _overlayController.hide();
  }

  @override
  Widget build(BuildContext context) {
    final display = widget.selected.isEmpty
        ? 'Select Countries'
        : (widget.selected.length == 1
            ? widget.selected[0]
            : '${widget.selected[0]}  +${widget.selected.length - 1} more');

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (overlayCtx) {
          final fieldWidth =
              (_fieldKey.currentContext?.findRenderObject() as RenderBox?)
                      ?.size
                      .width ??
                  context.w(150);

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _overlayController.hide,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: Offset(0, context.h(4)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(context.r(12)),
                    child: StatefulBuilder(
                      builder: (ctx, setOverlayState) {
                        final query = _search.text.trim().toLowerCase();
                        final filtered = query.isEmpty
                            ? widget.options
                            : widget.options
                                .where((c) => c.toLowerCase().contains(query))
                                .toList();
                        return Container(
                          width: fieldWidth,
                          constraints: BoxConstraints(maxHeight: context.h(320)),
                          padding: EdgeInsets.all(context.w(10)),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.r(12)),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _search,
                                onChanged: (_) => setOverlayState(() {}),
                                style: TextStyle(fontSize: context.labelLarge),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Search country',
                                  hintStyle:
                                      TextStyle(fontSize: context.labelLarge),
                                  prefixIcon:
                                      Icon(Icons.search, size: context.iconSmall),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: context.w(10),
                                      vertical: context.h(8)),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(context.r(10)),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.h(6)),
                              Flexible(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: filtered
                                      .map((c) => CheckboxListTile(
                                            dense: true,
                                            visualDensity:
                                                VisualDensity.compact,
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            activeColor: _brandBlue,
                                            value: _draft.contains(c),
                                            title: Text(c,
                                                style: TextStyle(
                                                    fontSize:
                                                        context.labelLarge)),
                                            onChanged: (v) =>
                                                setOverlayState(() {
                                              v == true
                                                  ? _draft.add(c)
                                                  : _draft.remove(c);
                                            }),
                                          ))
                                      .toList(),
                                ),
                              ),
                              SizedBox(height: context.h(6)),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brandBlue,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            context.r(10))),
                                  ),
                                  onPressed: _apply,
                                  child: const Text('DONE',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: GestureDetector(
          key: _fieldKey,
          onTap: _open,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.w(12), vertical: context.h(10)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: context.w(14),
                  offset: Offset(0, context.h(4)),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label,
                        style: TextStyle(
                            fontSize: context.fs(8),
                            fontWeight: FontWeight.bold,
                            color: _kLabelGrey,
                            letterSpacing: 0.5)),
                    SizedBox(width: context.w(3)),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: context.w(12), color: _kLabelGrey),
                  ],
                ),
                SizedBox(height: context.h(6)),
                Row(children: [
                  Icon(Icons.public, size: context.w(20), color: _brandBlue),
                  SizedBox(width: context.w(6)),
                  Expanded(
                    child: Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color: widget.selected.isEmpty
                            ? Colors.grey.shade400
                            : AppColors.navy,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef _TravellersResult = ({List<DateTime?> dobs, List<String> relations});

// ── Travellers popup (stepper + DOB per traveller, like the web popup) ───
class _TravellersDialog extends StatefulWidget {
  final List<DateTime?> initialDobs;
  final List<String> initialRelations;
  // Benzy's support team: every non-lead traveller on a FRIENDS policy must
  // carry relation MEMBER, not the general SPOUSE/CHILD/PARENT/SIBLING/
  // FRIEND enum — see _relationOptions below.
  final bool isFriends;
  const _TravellersDialog({
    required this.initialDobs,
    required this.initialRelations,
    required this.isFriends,
  });

  static Future<_TravellersResult?> show(
      BuildContext context, List<DateTime?> initialDobs, List<String> initialRelations,
      {required bool isFriends}) =>
      showDialog<_TravellersResult>(
        context: context,
        builder: (_) => _TravellersDialog(
          initialDobs: initialDobs,
          initialRelations: initialRelations,
          isFriends: isFriends,
        ),
      );

  @override
  State<_TravellersDialog> createState() => _TravellersDialogState();
}

class _TravellersDialogState extends State<_TravellersDialog> {
  static const _friendsRelationOptions = ['MEMBER'];
  static const _generalRelationOptions = ['SPOUSE', 'CHILD', 'PARENT', 'SIBLING', 'FRIEND'];

  List<String> get _relationOptions =>
      widget.isFriends ? _friendsRelationOptions : _generalRelationOptions;

  late List<DateTime?> _dobs = List<DateTime?>.from(widget.initialDobs);
  // Coerce anything left over from before the policy type became FRIENDS
  // (or vice versa) into a value that's actually still a valid option —
  // DropdownButton throws if its current value isn't in its own items.
  // Index 0 (the lead traveller) is always SELF and is never shown in a
  // dropdown at all, so it's deliberately left untouched here.
  late List<String> _relations = [
    for (int i = 0; i < widget.initialRelations.length; i++)
      i == 0 || _relationOptions.contains(widget.initialRelations[i])
          ? widget.initialRelations[i]
          : _relationOptions.first,
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(16))),
      child: Padding(
        padding: EdgeInsets.all(context.w(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Text('Travellers',
                  style: TextStyle(
                      fontSize: context.titleSmall, fontWeight: FontWeight.w800)),
              const Spacer(),
              _step(Icons.remove_rounded, () {
                if (_dobs.length > 1) {
                  setState(() {
                    _dobs.removeLast();
                    if (_relations.length > _dobs.length) _relations.removeLast();
                  });
                }
              }),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(10)),
                child: Text('${_dobs.length}',
                    style: TextStyle(
                        fontSize: context.titleMedium, fontWeight: FontWeight.w800)),
              ),
              _step(Icons.add_rounded, () {
                if (_dobs.length < 9) {
                  setState(() {
                    _dobs.add(null);
                    _relations.add(_relationOptions.first);
                  });
                }
              }),
            ]),
            SizedBox(height: context.h(12)),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: context.h(280)),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (int i = 0; i < _dobs.length; i++) _dobRow(context, i),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.h(12)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003B95),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(12))),
                ),
                onPressed: () => Navigator.of(context)
                    .pop((dobs: _dobs, relations: _relations)),
                child: const Text('DONE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: CircleBorder(side: BorderSide(color: Colors.grey.shade300)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(context.w(4)),
          child: Icon(icon, size: context.iconXSmall + 2, color: const Color(0xFF003B95)),
        ),
      ),
    );
  }

  String _relationAt(int i) =>
      i < _relations.length ? _relations[i] : _relationOptions.first;

  Widget _dobRow(BuildContext context, int i) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Row(children: [
        SizedBox(
          width: context.w(80),
          child: Text('Traveller ${i + 1}',
              style: TextStyle(
                  fontSize: context.labelLarge,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dobs[i] ?? DateTime(2000, 1, 1),
                firstDate: DateTime(1935, 1, 1),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dobs[i] = picked);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.w(10), vertical: context.h(9)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(10)),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    _dobs[i] == null
                        ? 'dd-mm-yyyy'
                        : DateFormat('dd-MM-yyyy').format(_dobs[i]!),
                    style: TextStyle(
                        fontSize: context.labelLarge,
                        color: _dobs[i] == null
                            ? Colors.grey.shade500
                            : Colors.black87),
                  ),
                ),
                Icon(Icons.calendar_month_outlined,
                    size: context.iconSmall, color: Colors.grey.shade600),
              ]),
            ),
          ),
        ),
        if (i > 0) ...[
          SizedBox(width: context.w(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(10)),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _relationAt(i),
                isDense: true,
                style: TextStyle(fontSize: context.labelLarge, color: Colors.black87),
                items: _relationOptions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    while (_relations.length <= i) {
                      _relations.add(_relationOptions.first);
                    }
                    _relations[i] = v;
                  });
                },
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
