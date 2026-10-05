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
import '../../data/diy_holiday_api.dart';
import 'diy_holiday_payment_screen.dart';
import 'diy_policies_screen.dart';
import 'diy_traveller_form_screen.dart';
import '../widgets/diy_review_sheets.dart';

/// Review — the last screen before payment, built to the Figma.
///
/// The DIY API has no booking or payment endpoint: it ends at
/// **API 15 — POST /packages/{share_id}/enquiry/**. So this screen collects
/// everything the Figma asks for, then hands off to [DiyPaymentScreen], which
/// charges through the app's own Razorpay stack and records the booking on the
/// main API. The enquiry is still submitted after a successful payment so the
/// consultant picks the trip up with the same details.
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

  /// The trip's own before-tax total and tax — the Fare Breakup sheet.
  final double subTotal;
  final double tax;
  final double taxPercent;

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
    this.subTotal = 0,
    this.tax = 0,
    this.taxPercent = 0,
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

  /// The tab-strip chip last tapped — outlined in blue, as in the design.
  String _activeTab = 'Traveller details';

  /// How the party arrives and leaves — the Figma's Arrival / Departure
  /// Information. Pre-set to FLIGHT when the package flies them.

  late final Future<DiyPolicies> _policies = sl<DiyHolidayApi>().getPolicies();
  DiyBooking? _booking;
  bool _bookingInFlight = false;

  /// Set once CONTINUE was pressed with someone missing, so the rows still to
  /// fill turn red rather than only a toast saying so.
  bool _showMissing = false;

  /// Everything a ticket or voucher needs: both names and a gender, and for a
  /// child the date of birth, because children are priced and booked on age.
  bool _ready(DiyTraveller t) =>
      t.isComplete && t.gender.isNotEmpty && (!t.isChild || t.dob.isNotEmpty);

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
          partyNames: [
            for (final t in _travellers)
              t.isComplete
                  ? '${t.fullName}${t.age == null ? '' : '\n${t.age}y'}'
                  : '',
          ],
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

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _scrollTo(_travellerDetailsKey);
      return;
    }
    // Every traveller, not just the lead: the booking goes nowhere until each
    // one has their details in.
    final missing = [
      for (var i = 0; i < _travellers.length; i++)
        if (!_ready(_travellers[i])) i,
    ];
    if (missing.isNotEmpty) {
      setState(() => _showMissing = true);
      _scrollTo(_travellerDetailsKey);
      diySnack(
        context,
        missing.length == 1
            ? 'Add the details of Travellers ${missing.first + 1}'
            : 'Add the details of all ${_travellers.length} travellers '
                  '(${missing.length} still to add)',
        isError: true,
      );
      // Straight into the first one still to fill.
      await _editTraveller(missing.first);
      return;
    }
    if (!_acceptedTerms) {
      diySnack(context, 'Please accept the terms to continue', isError: true);
      return;
    }
    final tripId = widget.tripId;
    if (tripId == null || tripId.isEmpty) {
      diySnack(
        context,
        'This trip can no longer be booked. Search again.',
        isError: true,
      );
      return;
    }

    setState(() => _bookingInFlight = true);
    try {
      final booking = await sl<DiyHolidayApi>().bookTrip(
        tripId: tripId,
        customerName: _leadName,
        customerPhone: _phone.text.trim(),
        customerEmail: _email.text.trim(),
        gstState: '',
        travellers: [
          for (final t in _travellers.where((t) => t.isComplete))
            t.toBookingJson(),
        ],
        termsAccepted: _acceptedTerms,
      );
      if (!mounted) return;
      setState(() => _booking = booking);

      if (booking.previousTotal != null) {
        final go = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('The price has changed'),
            content: Text(
              'This trip was '
              '${diyMoney(booking.previousTotal!, currency: booking.currency)} '
              'and is now ${diyMoney(booking.grandTotal, currency: booking.currency)}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Go back'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (go != true || !mounted) return;
      }
      if (!booking.canPayOnline) {
        diySnack(
          context,
          'Booking ${booking.reference} is raised. A consultant will share a '
          'payment link with you.',
        );
        return;
      }
      await _bookingOptions(booking);
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _bookingInFlight = false);
    }
  }

  /// "Booking Options" — the booking's instalments: a share of the frozen
  /// total now, the rest by the due date. PAY NOW opens Razorpay for it.
  Future<void> _bookingOptions(DiyBooking booking) async {
    final picked = await showModalBottomSheet<DiyInstalment>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BookingOptionsSheet(
        booking: booking,
        travellers: _travellers.length,
      ),
    );
    if (picked == null || !mounted) return;

    // The in-app checkout (UPI, cards, net banking, EMI, wallets), the same
    // seamless Razorpay flow as flights; it falls back to the hosted page by
    // itself on a device the native SDK does not support.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiyHolidayPaymentScreen(
          booking: booking,
          instalment: picked,
          packageTitle: widget.packageTitle,
          origin: widget.query.origin.name,
          destination: widget.destination,
          departureDate: widget.query.departureDate,
          nights: widget.nights,
          travellers: _travellers,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    fontSize: context.fs(17),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                width: context.w(30),
                height: context.w(30),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F1FC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.beach_access_rounded,
                  size: context.w(16),
                  color: DiyTokens.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F1FC),
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: context.w(11),
                      color: DiyTokens.blue,
                    ),
                    SizedBox(width: context.w(4)),
                    Text(
                      'Customizable',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: DiyTokens.blue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(8)),
              if (widget.nights > 0)
                Text(
                  '${widget.nights}N ${widget.destination}'.trim(),
                  style: TextStyle(
                    fontSize: context.fs(10.5),
                    color: DiyTokens.blue,
                  ),
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
                '${_travellers.length == 1 ? '' : 's'}:',
                style: TextStyle(
                  fontSize: context.fs(11.5),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.navy,
                ),
              ),
              SizedBox(width: context.w(5)),
              Expanded(
                child: Text(
                  '${widget.query.adults} Adult'
                  '${widget.query.adults == 1 ? '' : 's'}'
                  '${widget.query.children > 0 ? ', ${widget.query.children} Child' : ''}'
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
                if (widget.nights > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(8),
                      vertical: context.h(1),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD5D8DE)),
                      borderRadius: BorderRadius.circular(context.r(5)),
                    ),
                    child: Text(
                      '${widget.nights + 1}D/${widget.nights}N',
                      style: TextStyle(
                        fontSize: context.fs(9.5),
                        color: DiyTokens.subGrey,
                      ),
                    ),
                  ),
                SizedBox(height: context.h(4)),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 1.5,
                      margin: EdgeInsets.symmetric(horizontal: context.w(6)),
                      color: DiyTokens.orange,
                    ),
                    Container(
                      width: context.w(6),
                      height: context.w(6),
                      decoration: const BoxDecoration(
                        color: DiyTokens.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
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
      height: context.h(26),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in tabs.entries)
            Padding(
              padding: EdgeInsets.only(right: context.w(8)),
              child: GestureDetector(
                onTap: () {
                  setState(() => _activeTab = entry.key);
                  _scrollTo(entry.value);
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: context.w(8)),
                  decoration: BoxDecoration(
                    color: entry.key == _activeTab
                        ? const Color(0xFFEFF7FD)
                        : Colors.white,
                    border: Border.all(
                      color: entry.key == _activeTab
                          ? DiyTokens.blue
                          : const Color(0xFFB9BEC7),
                    ),
                    borderRadius: BorderRadius.circular(context.r(5)),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: context.fs(10.5),
                      color: entry.key == _activeTab
                          ? DiyTokens.blue
                          : const Color(0xFF5B6270),
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
          SizedBox(height: context.h(18)),
          Text(
            '${_travellers.length} Traveller'
            '${_travellers.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: context.fs(11.5),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            '${widget.query.rooms} Room'
            '${widget.query.rooms == 1 ? '' : 's'} : '
            '${widget.query.adults} Adult'
            '${widget.query.adults == 1 ? '' : 's'}'
            '${widget.query.children > 0 ? ', ${widget.query.children} Child' : ''}',
            style: TextStyle(
              fontSize: context.fs(10.5),
              color: DiyTokens.subGrey,
            ),
          ),
          SizedBox(height: context.h(12)),
          const Divider(height: 1, color: DiyTokens.line),
          SizedBox(height: context.h(24)),
          Text(
            'Booking For',
            style: TextStyle(
              fontSize: context.fs(11.5),
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(18)),
          Row(
            children: [
              Expanded(
                child: Text(
                  _leadName.isEmpty ? 'Add the lead traveller' : _leadName,
                  style: TextStyle(
                    fontSize: context.fs(11.5),
                    fontWeight: FontWeight.w400,
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
                  Icons.edit_square,
                  size: context.w(16),
                  color: DiyTokens.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          const Divider(height: 1, color: DiyTokens.line),
          for (var i = 0; i < _travellers.length; i++) ...[
            _travellerRow(i),
            const Divider(height: 1, color: DiyTokens.line),
          ],
          SizedBox(height: context.h(20)),
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
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: context.w(16),
                      color: DiyTokens.labelGrey,
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

  /// "+ Travellers 1" until filled, then the name and age with a tick.
  Widget _travellerRow(int i) {
    final t = _travellers[i];
    final age = t.age;
    final ready = _ready(t);
    final flagged = _showMissing && !ready;
    const red = Color(0xFFE23744);

    return InkWell(
      onTap: () => _editTraveller(i),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(14)),
        child: Row(
          children: [
            Icon(
              ready
                  ? Icons.check_circle_rounded
                  : (flagged ? Icons.error_rounded : Icons.add_rounded),
              size: context.w(17),
              color: ready
                  ? const Color(0xFF17A46A)
                  : (flagged ? red : DiyTokens.blue),
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.isComplete
                        ? '${t.fullName}${age == null ? '' : ' · ${age}y'}'
                        : 'Travellers ${i + 1}',
                    style: TextStyle(
                      fontSize: context.fs(11.5),
                      color: ready
                          ? DiyTokens.navy
                          : (flagged ? red : DiyTokens.blue),
                    ),
                  ),
                  if (flagged)
                    Text(
                      t.isComplete
                          ? 'Add ${t.gender.isEmpty ? 'gender' : 'date of birth'} to continue'
                          : 'Details required to continue',
                      style: TextStyle(fontSize: context.fs(9.5), color: red),
                    ),
                ],
              ),
            ),
            if (t.isComplete)
              Icon(
                Icons.edit_square,
                size: context.w(15),
                color: DiyTokens.blue,
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

  /// The real policy — the same bands the booking freezes and the PDF prints.
  Widget _cancellationAccordion() {
    return _accordion(
      id: 'cancellation',
      title: 'Cancellation & Date Change',
      child: FutureBuilder<DiyPolicies>(
        future: _policies,
        builder: (context, snapshot) {
          final p = snapshot.data;
          if (p == null) {
            return Text(
              snapshot.hasError
                  ? 'Could not load the policy.'
                  : 'Loading the policy…',
              style: TextStyle(
                fontSize: context.fs(12),
                color: DiyTokens.subGrey,
              ),
            );
          }
          Widget band(DiyPolicyBand b) => Padding(
            padding: EdgeInsets.only(bottom: context.h(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.label,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w600,
                    color: DiyTokens.navy,
                  ),
                ),
                Text(
                  b.feePercent == null
                      ? b.note
                      : '${b.feePercent!.round()}% of the package'
                            '${b.note.isEmpty ? '' : ' — ${b.note}'}',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ],
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancellation',
                style: TextStyle(
                  fontSize: context.fs(12.5),
                  fontWeight: FontWeight.w700,
                  color: DiyTokens.navy,
                ),
              ),
              SizedBox(height: context.h(6)),
              for (final b in p.cancellation) band(b),
              if (p.dateChange.isNotEmpty) ...[
                Text(
                  'Date change',
                  style: TextStyle(
                    fontSize: context.fs(12.5),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
                SizedBox(height: context.h(6)),
                for (final b in p.dateChange) band(b),
              ],
              if (p.isProvisional)
                Text(
                  'Charges still to be confirmed are shared in writing before '
                  'you book.',
                  style: TextStyle(
                    fontSize: context.fs(10.5),
                    color: DiyTokens.orange,
                  ),
                ),
            ],
          );
        },
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
                child: Wrap(
                  children: [
                    _infoText('I confirm that I have read and I accept '),
                    _infoLink('Cancellation Policy', DiyPolicyPage.policies),
                    _infoText(', Nova\'s '),
                    _infoLink('User Agreement', DiyPolicyPage.terms),
                    _infoText(', '),
                    _infoLink('Terms of Service', DiyPolicyPage.terms),
                    _infoText(' and '),
                    _infoLink('Privacy Policy', DiyPolicyPage.terms),
                    _infoText(' Of The Wander Nova'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoText(String text) => Text(
    text,
    style: TextStyle(
      fontSize: context.fs(10.5),
      height: 1.5,
      color: DiyTokens.subGrey,
    ),
  );

  Widget _infoLink(String text, DiyPolicyPage page) => GestureDetector(
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DiyPoliciesScreen(page: page))),
    child: Text(
      text,
      style: TextStyle(
        fontSize: context.fs(10.5),
        height: 1.5,
        color: DiyTokens.blue,
      ),
    ),
  );

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
                  Row(
                    children: [
                      Text(
                        diyMoney(
                          _booking?.grandTotal ?? widget.quotedTotal,
                          currency: widget.currency,
                        ),
                        style: TextStyle(
                          fontSize: context.fs(21),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: context.w(6)),
                      GestureDetector(
                        onTap: _fareBreakup,
                        child: Icon(
                          Icons.info_rounded,
                          size: context.w(16),
                          color: const Color(0xFFC4C8CF),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Grand Total - ${_travellers.length} Traveller'
                    '${_travellers.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: context.fs(9),
                      color: DiyTokens.subGrey,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: context.h(46),
              child: ElevatedButton(
                onPressed: _bookingInFlight ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiyTokens.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: context.w(34)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
                ),
                child: _bookingInFlight
                    ? SizedBox(
                        width: context.w(18),
                        height: context.w(18),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
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

  /// "Fare Breakup" — before tax, the tax, the total.
  void _fareBreakup() {
    final b = _booking;
    showDiyFareBreakup(
      context,
      subTotal: b?.subTotal ?? widget.subTotal,
      tax: b?.tax ?? widget.tax,
      taxPercent: b?.taxPercent ?? widget.taxPercent,
      total: b?.grandTotal ?? widget.quotedTotal,
      travellers: _travellers.length,
      adultsOnly: widget.query.children == 0,
      currency: widget.currency,
    );
  }

  // ---------------------------------------------------------------- pieces

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E4EA)),
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: child,
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
        border: Border.all(color: const Color(0xFFE1E4EA)),
        borderRadius: BorderRadius.circular(context.r(10)),
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
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: context.w(20),
                    color: DiyTokens.blue,
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

/// "Booking Options" — each instalment the booking allows, one picked, and
/// PAY NOW.
class _BookingOptionsSheet extends StatefulWidget {
  final DiyBooking booking;
  final int travellers;

  const _BookingOptionsSheet({required this.booking, required this.travellers});

  @override
  State<_BookingOptionsSheet> createState() => _BookingOptionsSheetState();
}

/// Figma `Booking option`: each instalment the booking allows as a radio —
/// a part payment with its two-step timeline (pay now, the rest before the
/// due date), or the whole amount at once — then the amount and PAY NOW.
class _BookingOptionsSheetState extends State<_BookingOptionsSheet> {
  // The smallest share first in the design; the full payment preselected.
  late final List<DiyInstalment> _options = [...widget.booking.instalments]
    ..sort((a, b) => a.percent.compareTo(b.percent));
  late DiyInstalment? _picked = _options.isEmpty ? null : _options.last;

  String _money(double v) => diyMoney(v, currency: widget.booking.currency);

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final radius = Radius.circular(context.r(22));
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: context.w(16),
                bottom: context.h(10),
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: context.w(32),
                  height: context.w(32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: context.w(18),
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: radius,
                    topRight: radius,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: context.h(10)),
                    Center(
                      child: Container(
                        width: context.w(64),
                        height: context.h(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5D8DE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.fromLTRB(
                          context.w(12),
                          context.h(20),
                          context.w(12),
                          context.h(10),
                        ),
                        children: [
                          Text(
                            'Booking Options',
                            style: TextStyle(
                              fontSize: context.fs(13.5),
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: context.h(10)),
                          for (var k = 0; k < _options.length; k++) ...[
                            if (k > 0)
                              const Divider(height: 1, color: DiyTokens.line),
                            _option(_options[k]),
                          ],
                          if (b.policyIsProvisional)
                            Padding(
                              padding: EdgeInsets.only(top: context.h(6)),
                              child: Text(
                                'Cancellation charges are confirmed in writing '
                                'before your trip is issued.',
                                style: TextStyle(
                                  fontSize: context.fs(10),
                                  color: DiyTokens.subGrey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _footer(b),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(DiyBooking b) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(14),
        context.w(14),
        context.h(14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _money(_picked?.payNow ?? b.balance),
                      style: TextStyle(
                        fontSize: context.fs(19),
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: context.w(6)),
                    Icon(
                      Icons.info_rounded,
                      size: context.w(14),
                      color: const Color(0xFFC4C8CF),
                    ),
                  ],
                ),
                Text(
                  'Grand Total - ${widget.travellers} Traveller'
                  '${widget.travellers == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: context.fs(9),
                    color: DiyTokens.subGrey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: context.w(130),
            height: context.h(42),
            child: ElevatedButton(
              onPressed: _picked == null
                  ? null
                  : () => Navigator.of(context).pop(_picked),
              style: ElevatedButton.styleFrom(
                backgroundColor: DiyTokens.orange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: Text(
                'PAY NOW',
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(DiyInstalment i) {
    final selected = _picked?.percent == i.percent;
    final full = i.balance <= 0;
    final due = i.balanceDueOn.isEmpty
        ? ''
        : DateFormat('d MMMM').format(DateTime.parse(i.balanceDueOn));

    final radio = Container(
      width: context.w(16),
      height: context.w(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? DiyTokens.blue : const Color(0xFFB9BEC7),
          width: selected ? 4.5 : 1.2,
        ),
      ),
    );

    return InkWell(
      onTap: () => setState(() => _picked = i),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                radio,
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Text(
                    full ? 'Pay in full' : 'Book Now @${_money(i.payNow)}',
                    style: TextStyle(
                      fontSize: context.fs(13.5),
                      fontWeight: FontWeight.w500,
                      color: DiyTokens.blue,
                    ),
                  ),
                ),
                if (full)
                  Text(
                    _money(i.payNow),
                    style: TextStyle(
                      fontSize: context.fs(12.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
            if (full)
              Padding(
                padding: EdgeInsets.only(
                  left: context.w(26),
                  top: context.h(4),
                ),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: context.fs(10.5),
                      height: 1.4,
                      color: DiyTokens.subGrey,
                    ),
                    children: const [
                      TextSpan(
                        text: 'The entire amount will be deducted in a ',
                      ),
                      TextSpan(
                        text: 'one time payment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(top: context.h(12)),
                child: Column(
                  children: [
                    _step(
                      1,
                      'Pay to Book',
                      'Book Package @ ${_money(i.payNow)} (${i.percent}%)',
                      i.payNow,
                      connect: true,
                    ),
                    _step(
                      2,
                      due.isEmpty ? 'Before departure' : 'Before $due',
                      'Remaining balance',
                      i.balance,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// One step of a part payment: a numbered dot, the dashed rule down to the
  /// next step, what it is, and how much.
  Widget _step(
    int number,
    String title,
    String caption,
    double amount, {
    bool connect = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: context.w(16),
            child: Column(
              children: [
                Container(
                  width: context.w(16),
                  height: context.w(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: number == 1 ? const Color(0xFFE3F1FC) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: number == 1
                          ? const Color(0xFFE3F1FC)
                          : const Color(0xFFB9BEC7),
                    ),
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: context.fs(8.5),
                      color: number == 1 ? DiyTokens.blue : Colors.black87,
                    ),
                  ),
                ),
                if (connect)
                  Expanded(
                    child: CustomPaint(
                      size: const Size(1, double.infinity),
                      painter: _DashedLine(),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: connect ? context.h(26) : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: context.h(2)),
                        Text(
                          caption,
                          style: TextStyle(
                            fontSize: context.fs(9.5),
                            color: DiyTokens.subGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _money(amount),
                    style: TextStyle(
                      fontSize: context.fs(12.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
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
}

class _DashedLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB9BEC7)
      ..strokeWidth = 1;
    var y = 3.0;
    while (y < size.height - 3) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 3),
        paint,
      );
      y += 6;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
