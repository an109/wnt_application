import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/error/data_state.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entity/AKInsurance_entity.dart';
import '../../domain/usecase/AKInsurance_usecase.dart';
import '../bloc/AKInsurance_bloc.dart';
import '../bloc/AKInsurance_event.dart';
import '../bloc/AKInsurance_state.dart';
import '../state/ins_booking_details.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';
import '../widgets/ins_fare_sheet.dart';
import '../widgets/ins_form_field.dart';
import '../widgets/ins_plan_card.dart';
import '../widgets/ins_traveller_form.dart';
import 'ins_payment_screen.dart';

/// "Review" — Figma `insurance Individual review`.
///
/// Collects the proposer, the insured travellers and the nominee, then
/// hands the lot to [InsPaymentScreen]. Nothing is sent to the provider
/// here: StartPay only runs once a payment has actually cleared, which is
/// the same order the previous booking screen used.
class InsReviewScreen extends StatefulWidget {
  final AkInsurancePlanEntity plan;
  final InsSearchQuery query;
  final String tui;

  const InsReviewScreen({
    super.key,
    required this.plan,
    required this.query,
    required this.tui,
  });

  @override
  State<InsReviewScreen> createState() => _InsReviewScreenState();
}

class _InsReviewScreenState extends State<InsReviewScreen> {
  // ---- proposer ----
  final _mobile = TextEditingController();

  /// The country-code card is not focusable, so it borrows the number
  /// field's focus to keep the pair's two borders the same colour.
  final _mobileFocus = FocusNode();
  final _email = TextEditingController();
  final _addr1 = TextEditingController();
  final _addr2 = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _gst = TextEditingController();
  final _pan = TextEditingController();
  String _nationality = 'India';
  String _state = '';

  // ---- nominee ----
  /// The PED questionnaire and the traveller's answers to it. The question
  /// list arrives with PlanDetails, which this screen loads on open.
  InsHealthDeclaration _health = const InsHealthDeclaration();

  /// True while ValidateKYC is in flight, so PAY NOW cannot be
  /// double-tapped into two verifications.
  bool _verifying = false;
  final Map<String, TextEditingController> _pedText_ = {};
  final _pedDesc = TextEditingController();
  final _pedSince = TextEditingController();

  final _nomineeFirst = TextEditingController();
  final _nomineeLast = TextEditingController();
  String _nomineeRelation = InsNominee.relations.first;

  /// Seeded one row per traveller the quote was priced for, carrying the
  /// dates of birth already entered on the search form so they are never
  /// asked for twice.
  /// The traveller whose form is dropped open, or null when every row is
  /// collapsed to its summary line. Only one opens at a time, so a long
  /// party never turns the card into a wall of fields.
  int? _openTraveller;

  late List<InsBookingTraveller> _travellers = [
    for (int i = 0; i < widget.query.travellers.length; i++)
      InsBookingTraveller(
        dob: widget.query.travellers[i].dob,
        relationship: i == 0
            ? 'Self'
            : _titleCase(widget.query.relationFor(i)),
        nationality: widget.query.fromCountry.name,
      ),
  ];

  @override
  void initState() {
    super.initState();
    _mobileFocus.addListener(() => setState(() {}));
    // The questionnaire this plan asks lives on PlanDetails, and the
    // traveller can reach Review without ever opening the details screen,
    // so it is fetched here rather than assumed to be in state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<AkInsuranceBloc>()
            .add(LoadAkInsurancePlanDetailsEvent(widget.plan.planId));
      }
    });
  }

  /// Keeps the declaration in step with whatever questionnaire the plan
  /// returned, without discarding answers already given.
  void _syncQuestions(List<AkInsurancePedQuestionEntity> questions) {
    if (listEquals(questions, _health.questions)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _health = _health.copyWith(questions: questions));
      }
    });
  }

  @override
  void dispose() {
    _mobileFocus.dispose();
    for (final c in _pedText_.values) {
      c.dispose();
    }
    for (final c in [
      _mobile,
      _email,
      _addr1,
      _addr2,
      _city,
      _pincode,
      _gst,
      _pan,
      _pedDesc,
      _pedSince,
      _nomineeFirst,
      _nomineeLast,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  // ------------------------------------------------------------- pricing

  /// The amount charged for the whole party.
  ///
  /// Taken from the quote's own per-traveller breakdown
  /// (`premium.premiumDistributions`) rather than multiplying the headline
  /// premium by the party size, which is what the previous booking screen
  /// did. The breakdown is correct either way the headline figure is read,
  /// so this cannot over- or under-charge; when a provider sends no
  /// breakdown it falls back to the headline premium.
  double get _baseFare => widget.plan.partyPremium;

  /// No separate tax line is quoted — the provider's premium is already
  /// GST-inclusive, which is what the policy-details note says.
  double get _taxes => 0;

  double get _total => _baseFare + _taxes;

  // ---------------------------------------------------------- validation

  String? get _validationError {
    if (_mobile.text.trim().length < 10) return 'Enter a valid mobile number';
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address';
    }
    if (_addr1.text.trim().isEmpty) return 'Enter address line 1';
    if (_state.isEmpty) return 'Select a state';
    if (_city.text.trim().isEmpty) return 'Enter a city';
    if (_pincode.text.trim().length < 6) return 'Enter a valid pincode';

    for (int i = 0; i < _travellers.length; i++) {
      if (!_travellers[i].isComplete) {
        return 'Add the details for Traveller ${i + 1}';
      }
    }
    final health = _health.validationError;
    if (health != null) return health;

    if (!InsNominee(
      firstName: _nomineeFirst.text,
      lastName: _nomineeLast.text,
    ).isComplete) {
      return "Enter the nominee's name";
    }
    return null;
  }

  InsBookingDetails get _details => InsBookingDetails(
        proposer: InsProposer(
          mobile: _mobile.text.trim(),
          email: _email.text.trim(),
          addressLine1: _addr1.text.trim(),
          addressLine2: _addr2.text.trim(),
          nationality: _nationality,
          state: _state,
          city: _city.text.trim(),
          pincode: _pincode.text.trim(),
          gstNumber: _gst.text.trim(),
          panNumber: _pan.text.trim(),
        ),
        travellers: _travellers,
        nominee: InsNominee(
          firstName: _nomineeFirst.text.trim(),
          lastName: _nomineeLast.text.trim(),
          relation: _nomineeRelation,
        ),
        health: _health.copyWith(
          description: _pedDesc.text.trim(),
          sufferingSince: _pedSince.text.trim(),
        ),
      );

  /// Verifies the ID document before any money moves.
  ///
  /// StartPay runs *after* the charge has cleared, so a provider that rejects
  /// the KYC there leaves the traveller paid-but-uninsured. Running it here
  /// turns that into an ordinary form error. Only attempted when a PAN was
  /// given — the checklist carries no flag saying which providers require
  /// KYC, so this cannot be made unconditional without asking every customer
  /// for a PAN they may not need.
  Future<bool> _validateKyc() async {
    final pan = _pan.text.trim();
    final lead = _travellers.first;
    if (pan.isEmpty || lead.dob == null) return true;

    setState(() => _verifying = true);
    final result = await di.sl<AkInsuranceValidateKycUseCase>().call(
          AkInsuranceKycRequestEntity(
            pan: pan,
            name: lead.fullName,
            gender: lead.genderCode,
            dob: InsTokens.iso(lead.dob!),
            providerName: widget.plan.provider,
            tui: widget.tui,
          ),
        );
    if (!mounted) return false;
    setState(() => _verifying = false);

    if (result is DataSuccess<AkInsuranceKycEntity> && result.data!.success) {
      return true;
    }
    final message = result is DataSuccess<AkInsuranceKycEntity>
        ? result.data!.message
        : result.error?.message;
    insSnack(
      context,
      message?.isNotEmpty == true
          ? message!
          : 'We could not verify that PAN. Check it and try again.',
      isError: true,
    );
    return false;
  }

  Future<void> _payNow() async {
    final error = _validationError;
    if (error != null) {
      insSnack(context, error, isError: true);
      return;
    }
    if (_verifying) return;
    if (!await _validateKyc() || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<AkInsuranceBloc>.value(
          value: context.read<AkInsuranceBloc>(),
          child: InsPaymentScreen(
            plan: widget.plan,
            query: widget.query,
            tui: widget.tui,
            details: _details,
            amount: _total,
          ),
        ),
      ),
    );
  }

  void _toggleTraveller(int index) {
    setState(() => _openTraveller = _openTraveller == index ? null : index);
  }

  void _saveTraveller(int index, InsBookingTraveller updated) {
    setState(() {
      _travellers[index] = updated;
      _openTraveller = null;
    });
  }

  void _addTraveller() {
    if (_travellers.length >= widget.query.policyType.maxTravellers) {
      insSnack(
        context,
        'A ${widget.query.policyType.label} policy covers at most '
        '${widget.query.policyType.maxTravellers}. Edit your search to '
        'change the party size.',
        isError: true,
      );
      return;
    }
    // Party size feeds the premium, so a traveller added here would be
    // uninsured at the quoted price — send them back to the search instead.
    insSnack(
      context,
      'Change the number of travellers in your search so the plan is '
      'repriced for them.',
    );
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsTokens.pageBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: context.r(10),
                offset: Offset(0, context.h(4)), // cast DOWN onto the body
              ),
            ],
          ),
          child: insAppBar(context, title: 'Review'),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: context.h(20)),
        children: [
          _planHeader(context),
          SizedBox(height: context.h(18)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(14)),
            child: Column(
              children: [
                _proposerCard(context),
                _travellersCard(context),
                _healthCard(context),
                _nomineeCard(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _footer(context),
    );
  }

  // -------------------------------------------------------- plan header

  /// The blue banner, with its bottom edge melting into the page and the
  /// stat chips riding on top of that fade — Figma `insurance Individual
  /// review`.
  ///
  /// A Stack rather than a padded Container so the paint order can be
  /// spelled out: wash, fade, then content. The content is the only
  /// unpositioned child, so it still sizes the banner.
  Widget _planHeader(BuildContext context) {
    return Stack(
      children: [
        // The banner's own wash, behind everything.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  InsTokens.blue.withOpacity(0.18),
                  InsTokens.blue.withOpacity(0.04),
                ],
              ),
            ),
          ),
        ),

        // ====== LAYER GRADIENT EFFECT (NO BLUR) ======
        // Layer 1: Soft white gradient that creates the "cloudy" look
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(40),
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
                  Colors.white.withOpacity(0.05),
                ],
                stops: const [0.0, 0.20, 0.40, 0.60, 0.80, 1.0],
              ),
            ),
          ),
        ),

        // Layer 2: Additional subtle gradient overlay for depth
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(80),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Last, so the stat chips sit over the fade instead of under it.
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(14),
            context.h(16),
            context.w(14),
            context.h(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plan.planName,
                          style: TextStyle(
                            fontSize: context.fs(16),
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: InsTokens.navy,
                          ),
                        ),
                        SizedBox(height: context.h(10)),
                        _iconLine(
                          context,
                          Icons.location_on_rounded,
                          widget.query.destinationLabel,
                        ),
                        SizedBox(height: context.h(6)),
                        _icLine(
                          context,
                          Icons.calendar_month_rounded,
                          widget.query.tripSummary,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  InsProviderLogo(
                    provider: widget.plan.provider,
                    logoUrl: widget.plan.logoUrl,
                    width: 96,
                    height: 70,
                  ),
                ],
              ),
              SizedBox(height: context.h(24)),
              Row(
                children: [
                  Expanded(
                    child: _statChip(
                      context,
                      'Plan Type',
                      widget.query.policyType.label,
                      InsTokens.green,
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: _statChip(
                      context,
                      'Coverage',
                      widget.plan.sumInsured > 0
                          ? InsTokens.coverage(widget.plan.sumInsured)
                          : '—',
                      InsTokens.orange,
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: _statChip(
                      context,
                      'Premium',
                      InsTokens.rupees(widget.plan.premium),
                      InsTokens.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconLine(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: context.w(17), color: InsTokens.blue),
        SizedBox(width: context.w(7)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _icLine(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: context.w(17), color: AppColors.subhead),
        SizedBox(width: context.w(7)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: AppColors.subhead,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(
      BuildContext context,
      String label,
      String value,
      Color colour,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.h(6),
        horizontal: context.w(4),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(4)),
        // Shadow so each chip lifts off the gradient wash behind it.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: context.r(6),
            offset: Offset(0, context.h(3)), // cast slightly DOWN
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: context.fs(9),
              fontWeight: FontWeight.w500,
              color: InsTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(10),
              fontWeight: FontWeight.w700,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ proposer

  Widget _proposerCard(BuildContext context) {
    return InsSectionCard(
      title: 'Proposer Details',
      iconAsset: 'assets/NewIcons/personEyemark.png',
      icon: Icons.assignment_ind_rounded,
      iconColour: InsTokens.orange,
      children: [
        // The label is notched into the country-code card, which makes that
        // box the taller of the two; IntrinsicHeight + stretch pulls the
        // number field up to the same height so the pair reads as one
        // control, and the card borrows its focus colour below.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Static, not a disabled TextField: a controller built in
              // build() would be recreated on every rebuild and never
              // disposed.
              SizedBox(
                width: context.w(96),
                child: InputDecorator(
                  isFocused: _mobileFocus.hasFocus,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    // MOBILE NUMBER* floats here rather than over the number
                    // field, so the pair reads as one labelled control.
                    label: const InsFieldLabel(
                      label: 'Mobile Number',
                      required: true,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(13),
                    ),
                    border: _mobileBorder(context, InsTokens.line),
                    enabledBorder: _mobileBorder(context, InsTokens.line),
                    focusedBorder: _mobileBorder(context, InsTokens.blue),
                  ),
                  child: Row(
                    children: [
                      Text('🇮🇳', style: TextStyle(fontSize: context.fs(12.5))),
                      SizedBox(width: context.w(6)),
                      Text(
                        '+91',
                        style: TextStyle(
                          fontSize: context.fs(12),
                          color: InsTokens.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: InsField(
                  label: 'Mobile Number',
                  showLabel: false,
                  required: true,
                  controller: _mobile,
                  focusNode: _mobileFocus,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  hint: '9876543210',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(14)),
        InsField(
          label: 'Email ID',
          required: true,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          hint: 'name@example.com',
        ),
        SizedBox(height: context.h(14)),
        InsField(
          label: 'Address Line 1',
          required: true,
          controller: _addr1,
        ),
        SizedBox(height: context.h(14)),
        InsField(label: 'Address Line 2', controller: _addr2),
        SizedBox(height: context.h(14)),
        Row(
          children: [
            Expanded(
              child: InsDropdown(
                label: 'Nationality',
                required: true,
                value: _nationality,
                options: {
                  _nationality,
                  widget.query.fromCountry.name,
                  'India',
                }.toList(),
                onChanged: (v) => setState(() => _nationality = v),
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: InsDropdown(
                label: 'State',
                required: true,
                value: _state,
                options: InsOptions.states,
                onChanged: (v) => setState(() => _state = v),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(14)),
        InsField(label: 'City', required: true, controller: _city),
        SizedBox(height: context.h(14)),
        InsField(
          label: 'Pincode',
          required: true,
          controller: _pincode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: context.h(14)),
        Row(
          children: [
            Expanded(
              child: InsField(
                label: 'GST Number (optional)',
                controller: _gst,
                formatters: [UpperCaseTextFormatter()],
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: InsField(
                label: 'PAN Number (optional)',
                controller: _pan,
                maxLength: 10,
                formatters: [UpperCaseTextFormatter()],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Both halves of the mobile pair draw their outline from here, so the
  /// radius and the focus colour can never drift apart.
  OutlineInputBorder _mobileBorder(BuildContext context, Color colour) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.r(10)),
      borderSide: BorderSide(color: colour),
    );
  }

  // ---------------------------------------------------------- travellers

  Widget _travellersCard(BuildContext context) {
    final added = _travellers.where((t) => t.isComplete).length;

    return InsSectionCard(
      title: 'Travellers',
      icon: Icons.groups_rounded,
      iconColour: InsTokens.blue,
      trailing: Text(
        '$added/${_travellers.length} Added',
        style: TextStyle(
          fontSize: context.fs(15),
          fontWeight: FontWeight.w500,
          color: InsTokens.blue,
        ),
      ),
      children: [
        for (int i = 0; i < _travellers.length; i++) _travellerRow(context, i),
        GestureDetector(
          onTap: _addTraveller,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(top: context.h(6)),
            child: Row(
              children: [
                Icon(Icons.add_rounded,
                    size: context.w(18), color: InsTokens.subGrey),
                SizedBox(width: context.w(8)),
                Text(
                  'ADD ANOTHER TRAVELLER',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    letterSpacing: 0.2,
                    color: InsTokens.subGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _travellerRow(BuildContext context, int i) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(12)),
      child: Column(
        children: [
          // The form takes the summary line's place while it is open, so the
          // row never shows the same traveller twice over.
          if (_openTraveller == i)
            InsTravellerForm(
              // Keyed by index so switching rows rebuilds the controllers
              // against the traveller that is actually open.
              key: ValueKey('ins-traveller-form-$i'),
              traveller: _travellers[i],
              index: i,
              isStudent: widget.query.isStudent,
              lockRelation: i == 0,
              onSaved: (t) => _saveTraveller(i, t),
            )
          else
            _travellerSummary(context, i),
          SizedBox(height: context.h(12)),
          const Divider(height: 1, color: InsTokens.line),
        ],
      ),
    );
  }

  Widget _travellerSummary(BuildContext context, int i) {
    final t = _travellers[i];
    final dob = t.dob;

    return GestureDetector(
      onTap: () => _toggleTraveller(i),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.isComplete
                      ? '${t.title} ${t.fullName}'
                      : 'Traveller ${i + 1}',
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight:
                        t.isComplete ? FontWeight.w500 : FontWeight.w400,
                    color: t.isComplete ? InsTokens.navy : InsTokens.labelGrey,
                  ),
                ),
                SizedBox(height: context.h(3)),
                Text(
                  t.isComplete
                      ? [
                          if (dob != null)
                            'DOB: ${DateFormat('d MMM y').format(dob)}',
                          t.gender,
                          if (t.passport.isNotEmpty) 'Passport: ${t.passport}',
                        ].join(' | ')
                      : 'Tap to add name, gender and passport',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: InsTokens.subGrey,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.w(4)),
            child: Image.asset(
              'assets/NewIcons/edit.png',
              width: context.w(16),
              height: context.w(16),
              color: AppColors.AppBlue,
            ),
          ),
        ],
      ),
    );
  }


  // -------------------------------------------------- health declaration

  /// The PED questionnaire exactly as this plan asks it.
  ///
  /// Rendered from `PlanDetails.coverageDetails.questions` rather than a
  /// fixed list, so a plan that asks nothing shows nothing and a plan that
  /// asks ten questions gets ten answers. Nothing here is invented by the
  /// app — the answers go to StartPay as given.
  Widget _healthCard(BuildContext context) {
    return BlocBuilder<AkInsuranceBloc, AkInsuranceState>(
      buildWhen: (a, b) =>
          a.planDetails != b.planDetails ||
          a.planDetailsStatus != b.planDetailsStatus,
      builder: (context, state) {
        final questions = state.planDetails?.healthQuestions ?? const [];
        _syncQuestions(questions);

        // Nothing to declare for this plan — and nothing to show while the
        // questionnaire is still being fetched.
        if (questions.isEmpty) return const SizedBox.shrink();

        final gate = _health.gate;

        return InsSectionCard(
          title: 'Health Declaration',
          icon: Icons.favorite_rounded,
          iconColour: InsTokens.errorFg,
          children: [
            Text(
              gate?.title ??
                  'Does any person to be insured have any pre-existing '
                      'diseases?',
              style: TextStyle(
                fontSize: context.fs(13),
                height: 1.35,
                color: InsTokens.navy,
              ),
            ),
            SizedBox(height: context.h(12)),
            Row(
              children: [
                _pedChoice(context, label: 'No', value: false),
                SizedBox(width: context.w(24)),
                _pedChoice(context, label: 'Yes', value: true),
              ],
            ),
            if (_health.hasPed == true) ...[
              SizedBox(height: context.h(18)),
              Text(
                'Which of these apply?',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: InsTokens.subGrey,
                ),
              ),
              SizedBox(height: context.h(6)),
              for (final q in _health.gatedQuestions)
                q.isCheckbox
                    ? _pedCondition(context, q)
                    : _pedText(context, q),
              SizedBox(height: context.h(12)),
              InsField(
                label: 'Details of the condition',
                controller: _pedDesc,
              ),
              SizedBox(height: context.h(14)),
              InsField(
                label: 'Suffering since',
                controller: _pedSince,
                hint: 'e.g. March 2021',
              ),
            ],
            // Asked of everyone — previous claims and recent hospitalisation
            // are not conditional on the pre-existing-disease answer.
            for (final q in _health.independentQuestions) ...[
              SizedBox(height: context.h(16)),
              _pedText(context, q),
            ],
          ],
        );
      },
    );
  }

  /// A free-text row, for the questions the provider marks `TextBox`.
  Widget _pedText(
    BuildContext context,
    AkInsurancePedQuestionEntity question,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.title,
          style: TextStyle(
            fontSize: context.fs(13.5),
            height: 1.3,
            color: InsTokens.navy,
          ),
        ),
        SizedBox(height: context.h(8)),
        InsField(
          label: 'Your answer',
          controller: _pedController(question.questionCode),
        ),
      ],
    );
  }

  /// One controller per text question, created on first use and disposed with
  /// the screen.
  TextEditingController _pedController(String code) {
    return _pedText_.putIfAbsent(code, () {
      final c = TextEditingController(text: _health.textAnswers[code] ?? '');
      c.addListener(() {
        final next = Map<String, String>.from(_health.textAnswers)
          ..[code] = c.text;
        _health = _health.copyWith(textAnswers: next);
      });
      return c;
    });
  }

  Widget _pedChoice(
    BuildContext context, {
    required String label,
    required bool value,
  }) {
    final selected = _health.hasPed == value;
    return GestureDetector(
      onTap: () => setState(() => _health = InsHealthDeclaration(
            questions: _health.questions,
            hasPed: value,
            // Switching back to "no" drops anything ticked, so a stale
            // condition can never ride along on the request.
            conditions: value ? _health.conditions : const {},
            description: value ? _health.description : '',
            sufferingSince: value ? _health.sufferingSince : '',
          )),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InsRadio(
            selected: selected,
            onTap: () => setState(() => _health = InsHealthDeclaration(
                  questions: _health.questions,
                  hasPed: value,
                  conditions: value ? _health.conditions : const {},
                  description: value ? _health.description : '',
                  sufferingSince: value ? _health.sufferingSince : '',
                )),
          ),
          SizedBox(width: context.w(8)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.fs(14),
              color: selected ? InsTokens.navy : InsTokens.labelGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pedCondition(
    BuildContext context,
    AkInsurancePedQuestionEntity question,
  ) {
    final ticked = _health.conditions.contains(question.questionCode);
    return GestureDetector(
      onTap: () {
        final next = Set<String>.from(_health.conditions);
        ticked
            ? next.remove(question.questionCode)
            : next.add(question.questionCode);
        setState(() => _health = _health.copyWith(conditions: next));
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(7)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InsCheckbox(
              value: ticked,
              onChanged: (_) {
                final next = Set<String>.from(_health.conditions);
                ticked
                    ? next.remove(question.questionCode)
                    : next.add(question.questionCode);
                setState(() => _health = _health.copyWith(conditions: next));
              },
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Text(
                question.title,
                style: TextStyle(
                  fontSize: context.fs(13.5),
                  height: 1.3,
                  color: InsTokens.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- nominee

  Widget _nomineeCard(BuildContext context) {
    return InsSectionCard(
      title: 'Nominee Details',
      icon: Icons.group_add_rounded,
      iconColour: InsTokens.green,
      children: [
        Row(
          children: [
            Expanded(
              child: InsField(
                label: 'Nominee First Name',
                required: true,
                controller: _nomineeFirst,
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: InsField(
                label: 'Nominee Last Name',
                required: true,
                controller: _nomineeLast,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(14)),
        InsDropdown(
          label: 'Nominee Relationship',
          required: true,
          value: _nomineeRelation,
          options: InsNominee.relations,
          onChanged: (v) => setState(() => _nomineeRelation = v),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- footer

  Widget _footer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // Shadow cast UP onto the list above.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: context.r(10),
            offset: Offset(0, -context.h(4)), // negative = cast upward
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(12),
        context.w(16),
        context.h(0),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL PREMIUM',
                    style: TextStyle(
                      fontSize: context.fs(8.5),
                      letterSpacing: 0,
                      color: InsTokens.subGrey,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Row(
                    children: [
                      Text(
                        InsTokens.rupees(_total),
                        style: TextStyle(
                          fontSize: context.fs(24),
                          fontWeight: FontWeight.w700,
                          color: InsTokens.navy,
                        ),
                      ),
                      SizedBox(width: context.w(8)),
                      GestureDetector(
                        onTap: () => InsFareSheet.show(
                          context,
                          baseFare: _baseFare,
                          taxes: _taxes,
                          travellers: widget.query.travellerCount,
                          planName: widget.plan.planName,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Icon(Icons.info,
                            size: context.w(17), color: AppColors.lightsubhead),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: context.w(12)),
            SizedBox(
              width: context.w(147),
              child: InsPrimaryButton(
                label: 'PAY NOW',
                busy: _verifying,
                onPressed: _payNow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps GST/PAN uppercase as they are typed — both are uppercase by format.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
