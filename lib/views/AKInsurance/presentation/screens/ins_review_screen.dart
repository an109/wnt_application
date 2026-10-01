import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../bloc/AKInsurance_bloc.dart';
import '../state/ins_booking_details.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';
import '../widgets/ins_fare_sheet.dart';
import '../widgets/ins_form_field.dart';
import '../widgets/ins_plan_card.dart';
import '../widgets/ins_traveller_form_sheet.dart';
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
  final _email = TextEditingController();
  final _addr1 = TextEditingController();
  final _addr2 = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _gst = TextEditingController();
  final _pan = TextEditingController();
  String _nationality = 'India';
  String _state = '';

  // ---- nominee ----
  final _nomineeFirst = TextEditingController();
  final _nomineeLast = TextEditingController();
  String _nomineeRelation = InsNominee.relations.first;

  /// Seeded one row per traveller the quote was priced for, carrying the
  /// dates of birth already entered on the search form so they are never
  /// asked for twice.
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
  void dispose() {
    for (final c in [
      _mobile,
      _email,
      _addr1,
      _addr2,
      _district,
      _city,
      _pincode,
      _gst,
      _pan,
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
    if (_district.text.trim().isEmpty) return 'Enter a district';
    if (_city.text.trim().isEmpty) return 'Enter a city';
    if (_pincode.text.trim().length < 6) return 'Enter a valid pincode';

    for (int i = 0; i < _travellers.length; i++) {
      if (!_travellers[i].isComplete) {
        return 'Add the details for Traveller ${i + 1}';
      }
    }
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
          district: _district.text.trim(),
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
      );

  void _payNow() {
    final error = _validationError;
    if (error != null) {
      insSnack(context, error, isError: true);
      return;
    }

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

  Future<void> _editTraveller(int index) async {
    final updated = await InsTravellerFormSheet.show(
      context,
      traveller: _travellers[index],
      index: index,
      isStudent: widget.query.isStudent,
      lockRelation: index == 0,
    );
    if (updated != null && mounted) {
      setState(() => _travellers[index] = updated);
    }
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
      appBar: insAppBar(context, title: 'Review'),
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

  Widget _planHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(16),
        context.w(14),
        context.h(16),
      ),
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
                        fontSize: context.fs(17),
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
                    _iconLine(
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
          SizedBox(height: context.h(16)),
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
              fontSize: context.fs(13.5),
              height: 1.35,
              color: InsTokens.subGrey,
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
      padding: EdgeInsets.symmetric(vertical: context.h(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: colour.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: context.fs(11.5),
              color: InsTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(13.5),
              fontWeight: FontWeight.w600,
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
      icon: Icons.assignment_ind_rounded,
      iconColour: InsTokens.orange,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Static, not a disabled TextField: a controller built in build()
            // would be recreated on every rebuild and never disposed.
            SizedBox(
              width: context.w(96),
              child: InputDecorator(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.w(10),
                    vertical: context.h(16),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.r(10)),
                    borderSide: const BorderSide(color: InsTokens.line),
                  ),
                ),
                child: Row(
                  children: [
                    Text('🇮🇳', style: TextStyle(fontSize: context.fs(17))),
                    SizedBox(width: context.w(6)),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontSize: context.fs(15),
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
                required: true,
                controller: _mobile,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '9876543210',
              ),
            ),
          ],
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
        InsField(label: 'District', required: true, controller: _district),
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
                    size: context.w(19), color: InsTokens.subGrey),
                SizedBox(width: context.w(8)),
                Text(
                  'ADD ANOTHER TRAVELLER',
                  style: TextStyle(
                    fontSize: context.fs(14),
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
    final t = _travellers[i];
    final dob = t.dob;

    return Padding(
      padding: EdgeInsets.only(bottom: context.h(12)),
      child: Column(
        children: [
          Row(
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
                        fontSize: context.fs(16),
                        fontWeight:
                            t.isComplete ? FontWeight.w500 : FontWeight.w400,
                        color:
                            t.isComplete ? InsTokens.navy : InsTokens.labelGrey,
                      ),
                    ),
                    SizedBox(height: context.h(3)),
                    Text(
                      t.isComplete
                          ? [
                              if (dob != null)
                                'DOB: ${DateFormat('d MMM y').format(dob)}',
                              t.gender,
                              if (t.passport.isNotEmpty)
                                'Passport: ${t.passport}',
                            ].join(' | ')
                          : 'Tap to add name, gender and passport',
                      style: TextStyle(
                        fontSize: context.fs(13.5),
                        color: InsTokens.subGrey,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _editTraveller(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(context.w(4)),
                  child: Icon(Icons.edit_square,
                      size: context.w(21), color: InsTokens.blue),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          const Divider(height: 1, color: InsTokens.line),
        ],
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
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(12),
        context.w(16),
        context.h(12),
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
                      fontSize: context.fs(11),
                      letterSpacing: 0.3,
                      color: InsTokens.subGrey,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Row(
                    children: [
                      Text(
                        InsTokens.rupees(_total),
                        style: TextStyle(
                          fontSize: context.fs(23),
                          fontWeight: FontWeight.w700,
                          color: InsTokens.navy,
                        ),
                      ),
                      SizedBox(width: context.w(6)),
                      GestureDetector(
                        onTap: () => InsFareSheet.show(
                          context,
                          baseFare: _baseFare,
                          taxes: _taxes,
                          travellers: widget.query.travellerCount,
                          planName: widget.plan.planName,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Icon(Icons.info_outline_rounded,
                            size: context.w(17), color: InsTokens.labelGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: context.w(12)),
            SizedBox(
              width: context.w(150),
              child: InsPrimaryButton(label: 'PAY NOW', onPressed: _payNow),
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
