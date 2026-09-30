import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../data/diy_features.dart';
import '../../data/diy_search_query.dart';
import '../../data/diy_traveller.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import 'diy_enquiry_screen.dart';
import 'diy_payment_screen.dart';
import 'diy_traveller_form_screen.dart';

/// Review — the last screen before payment, built to the Figma.
///
/// The DIY API has no booking or payment endpoint: it ends at
/// **API 15 — POST /packages/{share_id}/enquiry/**. So this screen collects
/// everything the Figma asks for, then hands off to [DiyPaymentScreen], which
/// charges through the app's own Razorpay stack and records the booking on the
/// main API. The enquiry is still submitted after a successful payment so the
/// consultant picks the trip up with the same details.
///
/// "Talk to a consultant instead" keeps the original enquiry-only path intact
/// for customers who would rather not pay online.
///
/// Sections with no data behind them on the DIY API — insurance, coupons and
/// the prose policy text — are gated in [DiyFeatures]. Package Inclusions is
/// live, because `counts` is real.
class DiyReviewScreen extends StatefulWidget {
  final String shareId;
  final DiySearchQuery query;
  final bool withFlight;
  final List<String> addOnIds;
  final double quotedTotal;
  final String currency;
  final String packageTitle;
  final String? tripId;
  final DiyCounts? counts;
  final int nights;
  final String destination;

  const DiyReviewScreen({
    super.key,
    required this.shareId,
    required this.query,
    required this.withFlight,
    required this.addOnIds,
    required this.quotedTotal,
    required this.packageTitle,
    this.currency = 'INR',
    this.tripId,
    this.counts,
    this.nights = 0,
    this.destination = '',
  });

  @override
  State<DiyReviewScreen> createState() => _DiyReviewScreenState();
}

class _DiyReviewScreenState extends State<DiyReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  final _travellerDetailsKey = GlobalKey();
  final _inclusionsKey = GlobalKey();
  final _cancellationKey = GlobalKey();
  final _addOnsKey = GlobalKey();

  late List<DiyTraveller> _travellers;
  bool _acceptedTerms = false;
  String _openSection = '';

  @override
  void initState() {
    super.initState();
    // One empty row per head, so the Figma's "Travellers 1 / Travellers 2"
    // rows are present from the start.
    _travellers = [
      for (var i = 0; i < widget.query.adults; i++)
        const DiyTraveller(paxType: 'Adult'),
      for (var i = 0; i < widget.query.children; i++)
        const DiyTraveller(paxType: 'Child'),
    ];
    _prefillFromProfile();
  }

  void _prefillFromProfile() {
    try {
      final user = sl<PreferencesManager>().getUserData();
      if (user == null) return;
      _email.text = (user['email'] ?? '').toString();
      _phone.text = (user['phone'] ?? user['mobile'] ?? '').toString();

      // Seed the lead traveller from the profile name.
      final name = (user['name'] ?? user['full_name'] ?? '').toString().trim();
      if (name.isNotEmpty && _travellers.isNotEmpty) {
        final parts = name.split(RegExp(r'\s+'));
        _travellers[0] = _travellers[0].copyWith(
          firstName: parts.first,
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        );
      }
      setState(() {});
    } catch (_) {
      // Prefill is a convenience only.
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  List<String> get _partyLabels => [
    for (var i = 0; i < widget.query.adults; i++) 'Adult ${i + 1}',
    for (var i = 0; i < widget.query.children; i++) 'Child ${i + 1}',
  ];

  String get _leadName => _travellers.isEmpty ? '' : _travellers.first.fullName;

  Future<void> _editTraveller(int index) async {
    final result = await Navigator.of(context).push<DiyTraveller>(
      MaterialPageRoute(
        builder: (_) => DiyTravellerFormScreen(
          initial: _travellers[index].isComplete ? _travellers[index] : null,
          partyLabels: _partyLabels,
          index: index,
        ),
      ),
    );
    if (result != null) setState(() => _travellers[index] = result);
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.05,
    );
  }

  // ------------------------------------------------------------- continue

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _scrollTo(_travellerDetailsKey);
      return;
    }
    if (!_travellers.first.isComplete) {
      diySnack(context, 'Add the lead traveller\'s details', isError: true);
      _scrollTo(_travellerDetailsKey);
      return;
    }
    if (!_acceptedTerms) {
      diySnack(context, 'Please accept the terms to continue', isError: true);
      return;
    }
    if (widget.query.departureDate == null) {
      diySnack(context, 'Pick a starting date first', isError: true);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyPaymentScreen(
          shareId: widget.shareId,
          tripId: widget.tripId,
          query: widget.query,
          withFlight: widget.withFlight,
          addOnIds: widget.addOnIds,
          amount: widget.quotedTotal,
          currency: widget.currency,
          packageTitle: widget.packageTitle,
          travellers: _travellers,
          contactEmail: _email.text.trim(),
          contactPhone: _phone.text.trim(),
          nights: widget.nights,
          destination: widget.destination,
        ),
      ),
    );
  }

  void _talkToConsultant() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyEnquiryScreen(
          shareId: widget.shareId,
          query: widget.query,
          withFlight: widget.withFlight,
          addOnIds: widget.addOnIds,
          quotedTotal: widget.quotedTotal,
          currency: widget.currency,
          packageTitle: widget.packageTitle,
          tripId: widget.tripId,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      appBar: diyAppBar(context, title: 'Review'),
      body: Form(
        key: _formKey,
        // Deliberately a Column inside a scroll view rather than a ListView:
        // the tab strip scrolls to a section by its GlobalKey, and a lazy
        // ListView has not built the offscreen sections yet, so their keys
        // have no context and the tap would silently do nothing. The content
        // here is a bounded form, not a feed, so building it all is cheap.
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            context.w(14),
            context.h(12),
            context.w(14),
            context.h(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _packageCard(),
              SizedBox(height: context.h(12)),
              _tabStrip(),
              SizedBox(height: context.h(12)),
              Container(key: _travellerDetailsKey),
              _travellerDetailsCard(),
              if (DiyFeatures.insuranceAddon) ...[
                SizedBox(height: context.h(14)),
                Container(key: _addOnsKey),
                _insuranceCard(),
              ],
              SizedBox(height: context.h(12)),
              Container(key: _inclusionsKey),
              _inclusionsAccordion(),
              SizedBox(height: context.h(10)),
              Container(key: _cancellationKey),
              _cancellationAccordion(),
              if (DiyFeatures.coupons) ...[
                SizedBox(height: context.h(10)),
                _couponAccordion(),
              ],
              SizedBox(height: context.h(12)),
              _importantInformation(),
              SizedBox(height: context.h(10)),
              Center(
                child: TextButton(
                  onPressed: _talkToConsultant,
                  child: Text(
                    'Talk to a consultant instead',
                    style: TextStyle(
                      fontSize: context.fs(12.5),
                      fontWeight: FontWeight.w600,
                      color: DiyTokens.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // ------------------------------------------------------------ package card

  Widget _packageCard() {
    final start = widget.query.departureDate;
    final end = start == null || widget.nights == 0
        ? null
        : start.add(Duration(days: widget.nights));

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.packageTitle,
                  style: TextStyle(
                    fontSize: context.fs(15.5),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
              ),
              Icon(
                Icons.verified_rounded,
                size: context.w(18),
                color: DiyTokens.blue,
              ),
            ],
          ),
          SizedBox(height: context.h(7)),
          Row(
            children: [
              _pill('Customizable', DiyTokens.blue),
              SizedBox(width: context.w(6)),
              if (widget.nights > 0)
                _pill(
                  '${widget.nights}N ${widget.destination}'.trim(),
                  DiyTokens.blue,
                ),
            ],
          ),
          SizedBox(height: context.h(12)),
          if (start != null) _dateRow(start, end),
          SizedBox(height: context.h(10)),
          const Divider(height: 1, color: DiyTokens.line),
          SizedBox(height: context.h(9)),
          Row(
            children: [
              Icon(
                Icons.group_rounded,
                size: context.w(15),
                color: DiyTokens.orange,
              ),
              SizedBox(width: context.w(6)),
              Text(
                '${_travellers.length} Traveller'
                '${_travellers.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w700,
                  color: DiyTokens.navy,
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  '${widget.query.adults} Adult'
                  '${widget.query.adults == 1 ? '' : 's'}'
                  '${widget.query.children > 0 ? ' · ${widget.query.children} Child' : ''}'
                  ' / From ${widget.query.origin.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(11.5),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateRow(DateTime start, DateTime? end) {
    // Figma writes the date as "Oct 9, 2026" over "Friday".
    final headline = DateFormat('MMM d, yyyy');

    Widget side(DateTime d, bool alignEnd) {
      return Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            headline.format(d),
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            diyWeekday(d),
            style: TextStyle(
              fontSize: context.fs(10.5),
              color: DiyTokens.subGrey,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        side(start, false),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            child: Column(
              children: [
                Text(
                  widget.nights > 0
                      ? '${widget.nights + 1}D/${widget.nights}N'
                      : '',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.orange,
                  ),
                ),
                SizedBox(height: context.h(3)),
                Container(height: 2, color: DiyTokens.orange),
              ],
            ),
          ),
        ),
        if (end != null) side(end, true),
      ],
    );
  }

  // --------------------------------------------------------------- tab strip

  Widget _tabStrip() {
    final tabs = <String, GlobalKey>{
      'Traveller details': _travellerDetailsKey,
      if (DiyFeatures.insuranceAddon) 'Add-Ons': _addOnsKey,
      'Package Inclusions': _inclusionsKey,
      'Cancellation': _cancellationKey,
    };

    return SizedBox(
      height: context.h(32),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in tabs.entries)
            Padding(
              padding: EdgeInsets.only(right: context.w(8)),
              child: GestureDetector(
                onTap: () => _scrollTo(entry.value),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(6),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: DiyTokens.line),
                    borderRadius: BorderRadius.circular(context.r(7)),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: context.fs(11.5),
                      fontWeight: FontWeight.w600,
                      color: DiyTokens.navy,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- traveller details

  Widget _travellerDetailsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Traveller Details',
                  style: TextStyle(
                    fontSize: context.fs(14.5),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
              ),
              Text(
                'Mandatory',
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE23744),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Text(
            '${_travellers.length} Traveller'
            '${_travellers.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: context.fs(12.5),
              fontWeight: FontWeight.w600,
              color: DiyTokens.navy,
            ),
          ),
          Text(
            '${widget.query.rooms} Room'
            '${widget.query.rooms == 1 ? '' : 's'} · '
            '${widget.query.adults} Adult'
            '${widget.query.adults == 1 ? '' : 's'}'
            '${widget.query.children > 0 ? ' · ${widget.query.children} Child' : ''}',
            style: TextStyle(
              fontSize: context.fs(11),
              color: DiyTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(12)),
          Text(
            'Booking For',
            style: TextStyle(
              fontSize: context.fs(11),
              color: DiyTokens.labelGrey,
            ),
          ),
          SizedBox(height: context.h(5)),
          Row(
            children: [
              Expanded(
                child: Text(
                  _leadName.isEmpty ? 'Add the lead traveller' : _leadName,
                  style: TextStyle(
                    fontSize: context.fs(13.5),
                    fontWeight: FontWeight.w600,
                    color: _leadName.isEmpty
                        ? DiyTokens.labelGrey
                        : DiyTokens.navy,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _editTraveller(0),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.edit_outlined,
                  size: context.w(17),
                  color: DiyTokens.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          const Divider(height: 1, color: DiyTokens.line),
          for (var i = 0; i < _travellers.length; i++) _travellerRow(i),
          SizedBox(height: context.h(14)),
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            'Booking details & communication will be sent to',
            style: TextStyle(
              fontSize: context.fs(10),
              color: DiyTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(10)),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: context.fs(13.5), color: DiyTokens.navy),
            decoration: _inputDecoration('EMAIL ID*'),
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Enter an email address';
              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
              return ok ? null : 'Enter a valid email address';
            },
          ),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Container(
                height: context.h(50),
                padding: EdgeInsets.symmetric(horizontal: context.w(10)),
                decoration: BoxDecoration(
                  border: Border.all(color: DiyTokens.line),
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: Row(
                  children: [
                    Text('🇮🇳', style: TextStyle(fontSize: context.fs(15))),
                    SizedBox(width: context.w(5)),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontSize: context.fs(13),
                        color: DiyTokens.navy,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: TextStyle(
                    fontSize: context.fs(13.5),
                    color: DiyTokens.navy,
                  ),
                  decoration: _inputDecoration('MOBILE NUMBER*'),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Enter a mobile number';
                    return s.length == 10 ? null : 'Enter a 10-digit number';
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _travellerRow(int i) {
    final t = _travellers[i];
    final label = i < _partyLabels.length
        ? _partyLabels[i]
        : 'Traveller ${i + 1}';
    final age = t.age;

    return InkWell(
      onTap: () => _editTraveller(i),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(11)),
        child: Row(
          children: [
            Icon(
              t.isComplete ? Icons.check_circle_rounded : Icons.add,
              size: context.w(17),
              color: t.isComplete ? const Color(0xFF17A46A) : DiyTokens.blue,
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Text(
                t.isComplete
                    ? '${t.fullName}${age == null ? '' : ' · ${age}y'}'
                    : label,
                style: TextStyle(
                  fontSize: context.fs(12.5),
                  fontWeight: FontWeight.w600,
                  color: t.isComplete ? DiyTokens.navy : DiyTokens.blue,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: context.w(18),
              color: DiyTokens.labelGrey,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- sections

  /// Figma: "Travel + Medical Insurance". No product on the DIY API yet.
  Widget _insuranceCard() {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FD),
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.health_and_safety_rounded,
            size: context.w(30),
            color: DiyTokens.blue,
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Text(
              'Travel + Medical Insurance',
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w700,
                color: DiyTokens.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Live: built from the trip's own `counts`.
  Widget _inclusionsAccordion() {
    final c = widget.counts;
    final rows = <MapEntry<IconData, String>>[
      if (c != null && c.flights > 0)
        MapEntry(Icons.flight_rounded, '${c.flights} Flights'),
      if (c != null && c.hotels > 0)
        MapEntry(Icons.hotel_rounded, '${c.hotels} Hotel stays'),
      if (c != null && c.transfers > 0)
        MapEntry(Icons.directions_car_rounded, '${c.transfers} Transfers'),
      if (c != null && c.meals > 0)
        MapEntry(Icons.restaurant_rounded, '${c.meals} Meals'),
      if (c != null && c.activities > 0)
        MapEntry(Icons.local_activity_rounded, '${c.activities} Activities'),
      if (widget.addOnIds.isNotEmpty)
        MapEntry(
          Icons.add_circle_outline_rounded,
          '${widget.addOnIds.length} Add-on${widget.addOnIds.length == 1 ? '' : 's'}',
        ),
    ];

    return _accordion(
      id: 'inclusions',
      title: 'Package Inclusions',
      child: rows.isEmpty
          ? Text(
              'Inclusions will be confirmed by your consultant.',
              style: TextStyle(
                fontSize: context.fs(12),
                color: DiyTokens.subGrey,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in rows)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.h(9)),
                    child: Row(
                      children: [
                        Icon(r.key, size: context.w(15), color: DiyTokens.blue),
                        SizedBox(width: context.w(9)),
                        Text(
                          r.value,
                          style: TextStyle(
                            fontSize: context.fs(12.5),
                            color: DiyTokens.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _cancellationAccordion() {
    return _accordion(
      id: 'cancellation',
      title: 'Cancellation & Date Change',
      child: Text(
        DiyFeatures.policyText
            ? ''
            : 'Cancellation and date-change charges depend on the airline, '
                  'hotel and transfer suppliers on this package. Your '
                  'consultant will confirm the exact terms in writing before '
                  'the booking is issued.',
        style: TextStyle(
          fontSize: context.fs(12),
          height: 1.45,
          color: DiyTokens.subGrey,
        ),
      ),
    );
  }

  Widget _couponAccordion() {
    return _accordion(
      id: 'coupon',
      title: 'Coupon & Offers',
      child: const SizedBox.shrink(),
    );
  }

  Widget _importantInformation() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Important Information',
            style: TextStyle(
              fontSize: context.fs(13.5),
              fontWeight: FontWeight.w700,
              color: DiyTokens.navy,
            ),
          ),
          SizedBox(height: context.h(9)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: context.w(20),
                height: context.w(20),
                child: Checkbox(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: DiyTokens.blue,
                ),
              ),
              SizedBox(width: context.w(9)),
              Expanded(
                child: Text(
                  'I confirm that I have read and I accept the Cancellation '
                  'Policy, User Agreement, Terms of Service and Privacy '
                  'Policy of The Wander Nova.',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    height: 1.45,
                    color: DiyTokens.subGrey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- bottom

  Widget _bottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(10),
          context.w(16),
          context.h(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Grand Total · ${_travellers.length} Traveller'
                    '${_travellers.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: context.fs(9.5),
                      color: DiyTokens.labelGrey,
                    ),
                  ),
                  SizedBox(height: context.h(1)),
                  Text(
                    diyMoney(widget.quotedTotal, currency: widget.currency),
                    style: TextStyle(
                      fontSize: context.fs(19),
                      fontWeight: FontWeight.w800,
                      color: DiyTokens.navy,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: context.h(46),
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiyTokens.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: context.w(34)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
                ),
                child: Text(
                  'CONTINUE',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- pieces

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: child,
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(context.r(5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(10),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _accordion({
    required String id,
    required String title,
    required Widget child,
  }) {
    final open = _openSection == id;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _openSection = open ? '' : id),
            borderRadius: BorderRadius.circular(context.r(12)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(14),
                vertical: context.h(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: context.fs(13.5),
                        fontWeight: FontWeight.w600,
                        color: DiyTokens.navy,
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: context.w(20),
                    color: DiyTokens.subGrey,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(14),
                0,
                context.w(14),
                context.h(14),
              ),
              child: SizedBox(width: double.infinity, child: child),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: context.fs(9.5),
        color: DiyTokens.labelGrey,
        letterSpacing: 0.4,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(13),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(8)),
        borderSide: const BorderSide(color: DiyTokens.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(8)),
        borderSide: const BorderSide(color: DiyTokens.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(8)),
        borderSide: const BorderSide(color: DiyTokens.blue),
      ),
    );
  }
}
