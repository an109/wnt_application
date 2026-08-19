import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'policy_detail_Screen.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../core/error/data_state.dart';
import '../../injection_container.dart' as di;
import '../AKInsurance/domain/entity/AKInsurance_entity.dart';
import '../AKInsurance/domain/usecase/AKInsurance_usecase.dart';
import 'insurance_payment_screen.dart';
import 'insurance_quotesScreen.dart';

/// "Review your policy" booking form — redesigned for mobile
class InsuranceBookingScreen extends StatefulWidget {
  final InsuranceQuoteRequest request;
  final InsurancePolicy policy;

  /// The tui from the QuotesListing response this [policy] came from — echoed
  /// back on ValidateKYC/StartPay/GetItinerary per the provider's contract.
  final String tui;

  const InsuranceBookingScreen({
    super.key,
    required this.request,
    required this.policy,
    required this.tui,
  });

  @override
  State<InsuranceBookingScreen> createState() => _InsuranceBookingScreenState();
}

class _TravellerData {
  String title = 'Mr';
  String gender = 'Male';
  String relationship = 'Self';
  String nationality = 'India';
  DateTime? dob;
  final TextEditingController first = TextEditingController();
  final TextEditingController last = TextEditingController();
  final TextEditingController passport = TextEditingController();
  final TextEditingController dobCtrl = TextEditingController();
  // STUDENT policies only — StartPay's Traveller carries a StudentDetails
  // block (University/Sponsor/Guardian) the app previously always left
  // empty for every policy type, including Student. Optional here since
  // it's unconfirmed whether Benzy actually requires them filled in.
  final TextEditingController university = TextEditingController();
  final TextEditingController sponsor = TextEditingController();
  final TextEditingController guardian = TextEditingController();
  void dispose() {
    first.dispose();
    last.dispose();
    passport.dispose();
    dobCtrl.dispose();
    university.dispose();
    sponsor.dispose();
    guardian.dispose();
  }
}

class _InsuranceBookingScreenState extends State<InsuranceBookingScreen> {
  static const Color _brandBlue = Color(0xFF003B95);
  static const Color _brandTeal = Color(0xFF005B7F);
  static const Color _accentOrange = Color(0xFFE23A1E);

  final _formKey = GlobalKey<FormState>();

  // Proposer
  String _nationality = 'India';
  String _state = '';
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _addr1 = TextEditingController();
  final _addr2 = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _gst = TextEditingController();
  final _pan = TextEditingController();

  // ValidateKYC (step 5/7) accepts exactly one ID document — pick the type,
  // then fill in its number.
  String _kycDocType = 'PAN';
  final _kycNumber = TextEditingController();

  // Travellers + nominee + terms
  final List<_TravellerData> _travellers = [];
  final _nomineeFirst = TextEditingController();
  final _nomineeLast = TextEditingController();
  // Must be exactly one of these per StartPay's Nominee.Relation enum —
  // any other value makes Benzy silently drop the whole booking.
  String _nomineeRelation = 'Spouse';
  bool _termsAccepted = false;

  bool _isProcessing = false;

  static const _states = [
    'Andhra Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Delhi', 'Goa',
    'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Punjab', 'Rajasthan',
    'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  ];
  static const _titles = ['Mr', 'Mrs', 'Ms'];
  static const _genders = ['Male', 'Female'];
  static const _relations = ['Self', 'Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Other'];
  static const _nomineeRelations = [
    'Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister',
  ];
  static const _kycDocTypes = [
    'PAN', 'Aadhaar', 'Passport', 'Voter ID', 'Driving Licence', 'CKYC',
  ];

  int get _baseFare => widget.policy.premiumInr * widget.request.travellers;
  int get _taxes => 0;
  int get _total => _baseFare + _taxes;
  bool get _isStudentPolicy => widget.request.insuranceType.toUpperCase().contains('STUDENT');

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.request.travellers; i++) {
      final t = _TravellerData();
      final dob = i < widget.request.travellerDobs.length
          ? widget.request.travellerDobs[i]
          : null;
      if (dob != null) {
        t.dob = dob;
        t.dobCtrl.text = DateFormat('dd-MM-yyyy').format(dob);
      }
      _travellers.add(t);
    }
  }

  @override
  void dispose() {
    for (final t in _travellers) t.dispose();
    for (final c in [
      _mobile, _email, _addr1, _addr2, _district, _city, _pincode, _gst, _pan,
      _kycNumber, _nomineeFirst, _nomineeLast,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: _brandBlue),
        title: Text(
          'Review Your Policy',
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download_rounded, color: _brandBlue, size: context.iconMedium),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Policy PDF will be available after purchase'))
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
          children: [
            _buildPolicySummaryCard(context),
            SizedBox(height: context.h(16)),
            _buildSectionHeader(context, 'Proposer Details', Icons.person_outline),
            _buildProposerCard(context),
            SizedBox(height: context.h(16)),
            _buildSectionHeader(context, 'Traveller Details', Icons.groups_outlined),
            ..._buildTravellerCards(context),
            SizedBox(height: context.h(16)),
            _buildSectionHeader(context, 'Nominee Details', Icons.people_outline),
            _buildNomineeCard(context),
            SizedBox(height: context.h(16)),
            _buildSectionHeader(context, 'Fare Summary', Icons.receipt_outlined),
            _buildFareCard(context),
            SizedBox(height: context.h(16)),
            _buildTermsAndConditions(context),
            SizedBox(height: context.h(20)),
          ],
        ),
      ),
      bottomNavigationBar: _buildPaymentBar(context),
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.w(6)),
            decoration: BoxDecoration(
              color: _brandBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.r(8)),
            ),
            child: Icon(icon, size: context.iconSmall, color: _brandBlue),
          ),
          SizedBox(width: context.w(8)),
          Text(
            title,
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Policy Summary Card ─────────────────────────────────────────────────
  Widget _buildPolicySummaryCard(BuildContext context) {
    final r = widget.request;
    final df = DateFormat('dd MMM yyyy');
    final numberFormat = NumberFormat('#,##0');

    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, _brandBlue.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _logoBox(context, widget.policy.supplier),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.policy.planName,
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.h(4)),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: context.iconXSmall, color: Colors.grey.shade600),
                        SizedBox(width: context.w(4)),
                        Text(
                          '${df.format(r.startDate)} - ${df.format(r.endDate)}',
                          style: TextStyle(
                            fontSize: context.fs(11),
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(2)),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: context.iconXSmall, color: Colors.grey.shade600),
                        SizedBox(width: context.w(4)),
                        Text(
                          r.destination,
                          style: TextStyle(
                            fontSize: context.fs(11),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: context.w(8)),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: context.w(8)),
                        Text(
                          '${r.noOfDays} days',
                          style: TextStyle(
                            fontSize: context.fs(11),
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: context.h(16), color: Colors.grey.shade200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryStat(context, 'Coverage', 'USD ${numberFormat.format(widget.policy.coverageUsd)}'),
              _summaryStat(context, 'Premium', '₹${numberFormat.format(_total)}'),
              _summaryStat(context, 'Travellers', '${widget.request.travellers}'),
            ],
          ),
          SizedBox(height: context.h(8)),
          GestureDetector(
            onTap: () => PolicyDetailsSheet.show(
              context,
              policy: widget.policy,
              request: widget.request,
              tui: widget.tui,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: context.h(6)),
              decoration: BoxDecoration(
                color: _brandBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(context.r(8)),
                border: Border.all(color: _brandBlue.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: context.iconXSmall, color: _brandBlue),
                  SizedBox(width: context.w(4)),
                  Text(
                    'View Full Policy Details',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w600,
                      color: _brandBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.fs(9),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        SizedBox(height: context.h(2)),
        Text(
          value,
          style: TextStyle(
            fontSize: context.fs(12),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _logoBox(BuildContext context, String supplier) {
    final initials = supplier
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    return Container(
      width: context.w(44),
      height: context.w(44),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4FA0), _brandBlue],
        ),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: context.fs(14),
          ),
        ),
      ),
    );
  }

  // ── Proposer Details ───────────────────────────────────────────────────
  Widget _buildProposerCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _buildFormField(
            context,
            label: 'Mobile Number',
            controller: _mobile,
            hint: 'Enter 10-digit mobile number',
            required: true,
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.length != 10 ? 'Enter 10-digit mobile' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'Email ID',
            controller: _email,
            hint: 'you@example.com',
            required: true,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'Address Line 1',
            controller: _addr1,
            required: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'Address Line 2',
            controller: _addr2,
            hint: 'Optional',
          ),
          SizedBox(height: context.h(12)),
          _buildDropdownField(
            context,
            label: 'State',
            value: _state,
            options: _states,
            onChanged: (v) => setState(() => _state = v),
            required: true,
            hint: 'Select State',
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'City',
            controller: _city,
            required: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'District',
            controller: _district,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'Pincode',
            controller: _pincode,
            required: true,
            keyboardType: TextInputType.number,
            validator: (v) => (v == null || v.length != 6) ? 'Enter 6-digit pincode' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'GST Number',
            controller: _gst,
            hint: 'Optional',
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'PAN Number',
            controller: _pan,
            hint: 'Optional e.g., ABCDE1234F',
          ),
          SizedBox(height: context.h(16)),
          Text('ID Verification',
              style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          SizedBox(height: context.h(2)),
          Text('Only required by some providers before booking — optional otherwise.',
              style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600)),
          SizedBox(height: context.h(10)),
          _buildDropdownField(
            context,
            label: 'Document Type',
            value: _kycDocType,
            options: _kycDocTypes,
            onChanged: (v) => setState(() => _kycDocType = v),
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: '$_kycDocType Number',
            controller: _kycNumber,
            hint: 'Optional',
          ),
        ],
      ),
    );
  }

  // ── Traveller Cards ────────────────────────────────────────────────────
  List<Widget> _buildTravellerCards(BuildContext context) {
    List<Widget> cards = [];
    for (int i = 0; i < _travellers.length; i++) {
      cards.add(_buildTravellerCard(context, i));
      if (i < _travellers.length - 1) {
        cards.add(SizedBox(height: context.h(12)));
      }
    }
    return cards;
  }

  Widget _buildTravellerCard(BuildContext context, int i) {
    final t = _travellers[i];
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: i % 2 == 0 ? Colors.white : const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: i % 2 == 0 ? Colors.grey.shade200 : _brandBlue.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: context.w(4),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(2)),
                decoration: BoxDecoration(
                  color: _brandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
                child: Text(
                  'Traveller ${i + 1}',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w700,
                    color: _brandBlue,
                  ),
                ),
              ),
              const Spacer(),
              if (i > 0)
                IconButton(
                  icon: Icon(Icons.close, size: context.iconSmall, color: Colors.grey.shade400),
                  onPressed: () {
                    setState(() {
                      t.dispose();
                      _travellers.removeAt(i);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: context.h(10)),
          _buildDropdownField(
            context,
            label: 'Title',
            value: t.title,
            options: _titles,
            onChanged: (v) => t.title = v,
            required: true,
          ),
          SizedBox(height: context.h(12)),
          _buildDropdownField(
            context,
            label: 'Gender',
            value: t.gender,
            options: _genders,
            onChanged: (v) => t.gender = v,
            required: true,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'First Name',
            controller: t.first,
            required: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'Last Name',
            controller: t.last,
            required: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildDateField(
            context,
            label: 'Date of Birth',
            controller: t.dobCtrl,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: t.dob ?? DateTime(2000, 1, 1),
                firstDate: DateTime(1935, 1, 1),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  t.dob = picked;
                  t.dobCtrl.text = DateFormat('dd-MM-yyyy').format(picked);
                });
              }
            },
            required: true,
            validator: (v) => t.dob == null ? 'Required' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'Passport Number',
            controller: t.passport,
            required: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildDropdownField(
            context,
            label: 'Relationship',
            value: t.relationship,
            options: _relations,
            onChanged: (v) => t.relationship = v,
            required: true,
          ),
          SizedBox(height: context.h(12)),
          _buildDropdownField(
            context,
            label: 'Nationality',
            value: t.nationality,
            options: ['India'],
            onChanged: (v) => t.nationality = v,
            required: true,
          ),
          if (_isStudentPolicy) ...[
            SizedBox(height: context.h(12)),
            _buildFormField(
              context,
              label: 'University / Institution',
              controller: t.university,
            ),
            SizedBox(height: context.h(12)),
            _buildFormField(
              context,
              label: 'Sponsor Name',
              controller: t.sponsor,
            ),
            SizedBox(height: context.h(12)),
            _buildFormField(
              context,
              label: 'Guardian Name',
              controller: t.guardian,
            ),
          ],
        ],
      ),
    );
  }

  // ── Nominee Card ──────────────────────────────────────────────────────
  Widget _buildNomineeCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _buildFormField(
            context,
            label: 'Nominee First Name',
            controller: _nomineeFirst,
            required: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildFormField(
            context,
            label: 'Nominee Last Name',
            controller: _nomineeLast,
            required: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          SizedBox(height: context.h(12)),
          _buildDropdownField(
            context,
            label: 'Nominee Relationship',
            value: _nomineeRelation,
            options: _nomineeRelations,
            onChanged: (v) => setState(() => _nomineeRelation = v),
            required: true,
          ),
        ],
      ),
    );
  }

  // ── Fare Card ──────────────────────────────────────────────────────────
  Widget _buildFareCard(BuildContext context) {
    final numberFormat = NumberFormat('#,##0');
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _fareRow(context, 'Base Fare', numberFormat.format(_baseFare)),
          Divider(height: context.h(8), color: Colors.grey.shade200),
          _fareRow(context, 'Taxes', numberFormat.format(_taxes)),
          Divider(height: context.h(8), color: Colors.grey.shade300),
          _fareRow(
            context,
            'Total Premium',
            numberFormat.format(_total),
            bold: true,
            accent: true,
          ),
        ],
      ),
    );
  }

  Widget _fareRow(BuildContext context, String label, String value, {bool bold = false, bool accent = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(4)),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: context.fs(bold ? 13 : 12),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            '₹$value',
            style: TextStyle(
              fontSize: context.fs(bold ? 15 : 13),
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: accent ? _accentOrange : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ── Terms & Conditions ──────────────────────────────────────────────────
  Widget _buildTermsAndConditions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: _termsAccepted,
              activeColor: _brandBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(4)),
              ),
              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            ),
          ),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: _brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' and confirm that I have no pre-existing medical conditions.',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment Bar ──────────────────────────────────────────────────────
  Widget _buildPaymentBar(BuildContext context) {
    final numberFormat = NumberFormat('#,##0');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(-4)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Premium',
                    style: TextStyle(
                      fontSize: context.fs(10),
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${numberFormat.format(_total)}',
                    style: TextStyle(
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.w800,
                      color: _accentOrange,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _onProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: context.h(14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(12)),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? SizedBox(
                        width: context.w(20),
                        height: context.w(20),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'PROCEED TO PAY',
                        style: TextStyle(
                          fontSize: context.fs(13),
                          fontWeight: FontWeight.w800,
                          letterSpacing: context.letterSpacingWider,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form Field Helpers ──────────────────────────────────────────────────
  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(12)),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: context.w(6),
          offset: Offset(0, context.h(2)),
        ),
      ],
    );
  }

  Widget _buildFormField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        String? hint,
        bool required = false,
        TextInputType keyboardType = TextInputType.text,
        FormFieldValidator<String>? validator,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: _accentOrange,
                    fontSize: context.fs(12),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: context.h(6)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly || onTap != null,
          onTap: onTap,
          style: TextStyle(
            fontSize: context.fs(14),
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: context.fs(12),
              color: Colors.grey.shade400,
            ),
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(12),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(10)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(10)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(10)),
              borderSide: const BorderSide(color: _brandBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(10)),
              borderSide: BorderSide(color: _accentOrange.withOpacity(0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.r(10)),
              borderSide: const BorderSide(color: _accentOrange),
            ),
            errorStyle: TextStyle(
              fontSize: context.fs(10),
              color: _accentOrange,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      BuildContext context, {
        required String label,
        required String value,
        required List<String> options,
        required ValueChanged<String> onChanged,
        bool required = false,
        String? hint,
        FormFieldValidator<String>? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: _accentOrange,
                    fontSize: context.fs(12),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: context.h(6)),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(context.r(10)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: value.isEmpty ? null : value,
            isDense: true,
            isExpanded: true,
            hint: hint != null
                ? Text(
              hint,
              style: TextStyle(
                fontSize: context.fs(12),
                color: Colors.grey.shade500,
              ),
            )
                : null,
            style: TextStyle(
              fontSize: context.fs(14),
              color: Colors.black87,
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: context.iconMedium,
              color: Colors.grey.shade700,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(10),
              ),
              border: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            items: options.map((o) {
              return DropdownMenuItem(
                value: o,
                child: Text(o),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required VoidCallback onTap,
        bool required = false,
        FormFieldValidator<String>? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: _accentOrange,
                    fontSize: context.fs(12),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: context.h(6)),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              style: TextStyle(
                fontSize: context.fs(14),
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'DD-MM-YYYY',
                hintStyle: TextStyle(
                  fontSize: context.fs(12),
                  color: Colors.grey.shade400,
                ),
                suffixIcon: Icon(
                  Icons.calendar_today,
                  size: context.iconSmall,
                  color: Colors.grey.shade600,
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(12),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.r(10)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.r(10)),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.r(10)),
                  borderSide: const BorderSide(color: _brandBlue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.r(10)),
                  borderSide: BorderSide(color: _accentOrange.withOpacity(0.5)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.r(10)),
                  borderSide: const BorderSide(color: _accentOrange),
                ),
                errorStyle: TextStyle(
                  fontSize: context.fs(10),
                  color: _accentOrange,
                ),
              ),
              validator: validator,
            ),
          ),
        ),
      ],
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  Future<void> _onProceed() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // ValidateKYC/StartPay/GetItinerary all require the app's own user JWT
    // (the "JWT required" endpoints in the API doc) — the shared Dio
    // interceptor attaches it automatically, but only if a token is actually
    // saved. Checked directly rather than via isLoggedIn(), which is stored
    // separately and can be stale-true with no token behind it (observed on
    // a real device: isLoggedIn()==true, getToken()==null, provider 401s
    // with "Authentication credentials were not provided").
    // if (di.sl<PreferencesManager>().getToken() == null) {
    //   _snack('Please log in to purchase travel insurance.');
    //   return;
    // }

    // ValidateKYC (step 5/7) is intentionally NOT called from this screen
    // anymore. The next screen (InsurancePaymentScreen) reads the details
    // gathered below straight into StartPay once a payment clears.
    // if (_kycNumber.text.trim().isNotEmpty) {
    //   final passed = await _runKyc();
    //   if (!passed) return;
    // }

    setState(() => _isProcessing = true);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InsurancePaymentScreen(
          request: widget.request,
          policy: widget.policy,
          tui: widget.tui,
          proposer: InsuranceProposerInfo(
            mobile: _mobile.text.trim(),
            email: _email.text.trim(),
            addr1: _addr1.text.trim(),
            addr2: _addr2.text.trim(),
            state: _state,
            city: _city.text.trim(),
            district: _district.text.trim(),
            pincode: _pincode.text.trim(),
            gst: _gst.text.trim(),
            pan: _pan.text.trim(),
          ),
          travellers: [
            for (final t in _travellers)
              InsuranceTravellerInfo(
                title: t.title,
                gender: t.gender,
                firstName: t.first.text.trim(),
                lastName: t.last.text.trim(),
                dob: t.dob,
                passport: t.passport.text.trim(),
                relationship: t.relationship,
                nationality: t.nationality,
                university: t.university.text.trim(),
                sponsor: t.sponsor.text.trim(),
                guardian: t.guardian.text.trim(),
              ),
          ],
          nomineeFirst: _nomineeFirst.text.trim(),
          nomineeLast: _nomineeLast.text.trim(),
          nomineeRelation: _nomineeRelation,
          totalAmount: _total,
        ),
      ),
    );

    if (mounted) setState(() => _isProcessing = false);
  }

  // Kept for reference, not called — see the comment in _onProceed above.
  Future<bool> _runKyc() async {
    final lead = _travellers.first;
    final gender = lead.gender == 'Female' ? 'F' : 'M';
    final docNumber = _kycNumber.text.trim();
    final result = await di.sl<AkInsuranceValidateKycUseCase>().call(
      AkInsuranceKycRequestEntity(
        pan: _kycDocType == 'PAN' ? docNumber : '',
        aadhaar: _kycDocType == 'Aadhaar' ? docNumber : '',
        passport: _kycDocType == 'Passport' ? docNumber : '',
        voterId: _kycDocType == 'Voter ID' ? docNumber : '',
        drivingLicence: _kycDocType == 'Driving Licence' ? docNumber : '',
        ckyc: _kycDocType == 'CKYC' ? docNumber : '',
        name: '${lead.first.text} ${lead.last.text}'.trim(),
        gender: gender,
        dob: lead.dob != null ? DateFormat('yyyy-MM-dd').format(lead.dob!) : '',
        providerName: widget.policy.supplier,
        tui: widget.tui,
      ),
    );

    final ok = result is DataSuccess<AkInsuranceKycEntity> && result.data!.success;
    if (!ok && mounted) {
      final message = result is DataSuccess<AkInsuranceKycEntity>
          ? result.data!.message
          : result.error?.message;
      _snack(message?.isNotEmpty == true
          ? message!
          : 'Could not verify the $_kycDocType number. Please check the details and try again.');
    }
    return ok;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}