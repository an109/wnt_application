import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../../data/visa_form_data.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import '../widgets/visa_calendar.dart';
import '../widgets/visa_checkout_sheets.dart';
import '../widgets/visa_fields.dart';
import '../widgets/visa_flow_header.dart';
import '../widgets/visa_month_dial.dart';
import '../widgets/visa_passport_step.dart';
import '../widgets/visa_selfie_step.dart';
import '../widgets/visa_sheets.dart';
import 'visa_checkout_screen.dart';

enum _Stage { when, departure, camera, selfie, passportFront, passportBack, detail, travellers, insurance }

/// Step-by-step application of visas that are not visa-free / on arrival
/// (Figma "Start now 1-3", "Before Start …", "Before Start passport …").
class VisaApplyFlowScreen extends StatefulWidget {
  final VisaPopularDestinationEntity destination;
  final VisaTypeEntity visaType;
  final int travellerCount;
  final String employment;
  final DateTime? travelDate;
  /// Starts at the Detail step with already scanned travellers.
  @visibleForTesting
  final List<VisaTravellerForm>? scannedTravellers;

  const VisaApplyFlowScreen({
    super.key,
    required this.destination,
    required this.visaType,
    this.travellerCount = 1,
    this.employment = '',
    this.travelDate,
    this.scannedTravellers,
  });

  @override
  State<VisaApplyFlowScreen> createState() => _VisaApplyFlowScreenState();
}

class _VisaApplyFlowScreenState extends State<VisaApplyFlowScreen> {
  _Stage _stage = _Stage.when;
  late final DateTime _visaOn;
  late final DateTime _cutoff;

  // Dates.
  bool _before = true;
  bool _fixed = true;
  DateTime? _date;
  int _flexIndex = 0;

  // Travellers.
  late final List<VisaTravellerForm> _travellers;
  int _current = 0;
  final VisaTripForm _trip = VisaTripForm();
  final Set<String> _errors = {};
  /// A document is being redone from the Detail step; return there after.
  bool _editing = false;

  VisaPopularDestinationEntity get _d => widget.destination;
  VisaTypeEntity get _type => widget.visaType;
  VisaTravellerForm get _t => _travellers[_current];
  int get _validityDays => visaValidityDays(_type.validity, fallback: 90);

  @override
  void initState() {
    super.initState();
    _visaOn = _type.parsedProcessing?.guaranteedFrom(DateTime.now()) ??
        DateTime.now().add(const Duration(days: 7));
    // Travelling within four weeks of the visa date needs a fixed date so
    // the visa is ready in time; later trips can stay flexible.
    _cutoff = DateUtils.dateOnly(_visaOn).add(const Duration(days: 28));
    _travellers = widget.scannedTravellers ??
        List.generate(widget.travellerCount.clamp(1, 9), (_) => VisaTravellerForm());
    if (widget.scannedTravellers != null) _stage = _Stage.detail;
    _travellers.first.employment = widget.employment;
    final user = di.sl<PreferencesManager>().getUserData() ?? {};
    _trip.email = (user['email'] ?? '').toString();
    _trip.phone = (user['phone'] ?? user['phone_number'] ?? '').toString();
    if (widget.travelDate != null) _date = DateUtils.dateOnly(widget.travelDate!);
  }

  // ---------------------------------------------------------------- dates

  DateTime get _firstDate => _before ? DateUtils.dateOnly(_visaOn) : _cutoff.add(const Duration(days: 1));
  DateTime get _lastDate =>
      _before ? _cutoff : DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 365));

  List<DateTime> get _flexMonths {
    final first = DateTime(_firstDate.year, _firstDate.month);
    final last = DateTime(_lastDate.year, _lastDate.month);
    return [
      for (var m = first; !m.isAfter(last) && m.difference(first).inDays < 366; m = DateTime(m.year, m.month + 1)) m,
    ];
  }

  DateTimeRange get _flexRange {
    final month = _flexMonths[_flexIndex];
    final start = month.isBefore(_firstDate) ? _firstDate : month;
    return DateTimeRange(start: start, end: start.add(const Duration(days: 30)));
  }

  /// The travel date the rest of the application uses.
  DateTime get _travelDate => _fixed ? (_date ?? _firstDate) : _flexRange.start;

  void _chooseWhen(bool before) {
    setState(() {
      _before = before;
      _fixed = before;
      if (_date != null && (_date!.isBefore(_firstDate) || _date!.isAfter(_lastDate))) _date = null;
      _flexIndex = 0;
      _stage = _Stage.departure;
    });
  }

  void _datesDone() {
    if (_fixed && _date == null) {
      _snack('Select your departure date');
      return;
    }
    _trip.arrivalDate = _travelDate;
    if (!_fixed) _trip.departureDate = _flexRange.end;
    setState(() => _stage = _Stage.camera);
  }

  // ---------------------------------------------------------------- scans

  void _onSelfie(String path) => setState(() {
        _t.selfiePath = path;
        _stage = _editing ? _Stage.detail : _Stage.passportFront;
        _editing = false;
      });

  void _onFront(VisaPassportScan scan) {
    final mrz = scan.mrz!;
    setState(() {
      final t = _t;
      t.passportScanPath = scan.path;
      t.mrzLine1 = mrz.line1;
      t.mrzLine2 = mrz.line2;
      t.firstName = _title(mrz.givenNames.isEmpty ? mrz.surname : mrz.givenNames);
      t.lastName = mrz.givenNames.isEmpty ? '' : _title(mrz.surname);
      t.passportNo = mrz.passportNumber;
      t.passportFrom = mrz.nationalityName;
      t.dob = mrz.dob;
      t.passportExpiry = mrz.expiry;
      t.gender = mrz.gender;
      t.passportIssued ??= scan.front?.issueDate;
      if (t.placeOfBirth.isEmpty) t.placeOfBirth = scan.front?.placeOfBirth ?? '';
      // Only Indian passports carry the parents' names on a back page.
      final needsBack = mrz.nationality == 'IND' && (!_editing || t.passportBackPath == null);
      _stage = needsBack ? _Stage.passportBack : _Stage.detail;
      if (!needsBack) _editing = false;
    });
  }

  void _onBack(VisaPassportScan scan) {
    final back = scan.back!;
    setState(() {
      _t.passportBackPath = scan.path;
      if (back.fatherName.isNotEmpty) _t.fatherName = back.fatherName;
      if (back.motherName.isNotEmpty) _t.motherName = back.motherName;
      if (back.oldPassportNumber.isNotEmpty) _t.oldPassportNo = back.oldPassportNumber;
      _stage = _Stage.detail;
      _editing = false;
    });
  }

  String _title(String s) => s
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  // ---------------------------------------------------------------- detail

  static const _messages = {
    'firstName': 'Enter the first name',
    'passportIssued': 'Select the passport issue date',
    'passportExpiry': 'Your passport must be valid for 6 months after you travel',
    'placeOfBirth': 'Enter the place of birth',
    'fatherName': "Enter your father's name",
    'motherName': "Enter your mother's name",
    'email': 'Enter a valid email for visa updates',
    'phone': 'Enter a valid mobile number',
  };

  String? _detailError() => _errorFor(_current);

  /// First problem with traveller [i]'s details, or null when complete.
  String? _errorFor(int i) {
    final t = _travellers[i];
    if (t.firstName.trim().isEmpty) return 'firstName';
    if (t.passportIssued == null ||
        t.passportIssued!.isAfter(DateTime.now()) ||
        (t.dob != null && t.passportIssued!.isBefore(t.dob!))) {
      return 'passportIssued';
    }
    final mustLast = _travelDate.add(const Duration(days: 180));
    if (t.passportExpiry == null || t.passportExpiry!.isBefore(mustLast)) return 'passportExpiry';
    if (t.placeOfBirth.trim().isEmpty) return 'placeOfBirth';
    if (t.fatherName.trim().isEmpty) return 'fatherName';
    if (t.motherName.trim().isEmpty) return 'motherName';
    if (i == 0) {
      if (!RegExp(r'^[\w\-.+]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(_trip.email.trim())) return 'email';
      if (_trip.phone.replaceAll(RegExp(r'\D'), '').length < 8) return 'phone';
    }
    return null;
  }

  void _detailDone() {
    final error = _detailError();
    if (error != null) {
      setState(() => _errors
        ..clear()
        ..add(error));
      _snack(_messages[error]!);
      return;
    }
    setState(() {
      _errors.clear();
      _stage = _Stage.travellers;
    });
  }

  // ---------------------------------------------------------------- travellers

  bool _complete(int i) =>
      _travellers[i].selfiePath != null && _travellers[i].passportScanPath != null && _errorFor(i) == null;

  void _addCoTraveller() {
    if (_travellers.length >= 9) {
      _snack('Up to 9 travellers can apply together');
      return;
    }
    setState(() {
      _travellers.add(VisaTravellerForm());
      _current = _travellers.length - 1;
      _stage = _Stage.selfie;
    });
  }

  void _editTraveller(int i) => setState(() {
        _current = i;
        _stage = _travellers[i].selfiePath == null
            ? _Stage.selfie
            : _travellers[i].passportScanPath == null
                ? _Stage.passportFront
                : _Stage.detail;
      });

  Future<void> _confirmDelete(int i) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx, false),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [VisaColors.primaryLight, VisaColors.primary]),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text('Are you sure you want to\nremove this co-traveller?',
                      textAlign: TextAlign.center, style: visaText(10.5, color: VisaColors.title)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: VisaColors.cta),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text('DELETE', style: visaText(10, weight: FontWeight.w700, color: VisaColors.cta)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VisaColors.cta,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text('KEEP TRAVELLER',
                              style: visaText(10, weight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (delete == true) {
      setState(() {
        _travellers.removeAt(i);
        _current = 0;
      });
    }
  }

  void _travellersDone() {
    for (var i = 1; i < _travellers.length; i++) {
      if (!_complete(i)) {
        _snack('Finish the application for co-traveller $i, or remove them');
        return;
      }
    }
    setState(() {
      _insuranceDays ??= _tripDays;
      _stage = _Stage.insurance;
    });
  }

  // ---------------------------------------------------------------- insurance

  int? _insuranceDays;

  int get _tripDays {
    final a = _trip.arrivalDate, b = _trip.departureDate;
    if (a == null || b == null) return 7;
    return (b.difference(a).inDays + 1).clamp(1, 180);
  }

  void _toCheckout({required bool insurance}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisaCheckoutScreen(
          destination: _d,
          visaType: _type,
          travellers: _travellers,
          trip: _trip,
          insuranceDays: insurance ? _insuranceDays : null,
          header: VisaFlowHeader(
            visaOn: _visaOn,
            step: VisaFlowStep.checkout,
            onBack: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Future<void> _editValidity() async {
    final start = await showVisaSheet<DateTime>(
      context,
      VisaValiditySheet(start: _travelDate, days: _validityDays),
    );
    if (start == null) return;
    setState(() {
      _fixed = true;
      _date = start;
      _trip.arrivalDate = start;
    });
  }

  // ---------------------------------------------------------------- nav

  void _back() {
    final previous = switch (_stage) {
      _Stage.when => null,
      _Stage.departure => _Stage.when,
      _Stage.camera => _Stage.departure,
      _Stage.selfie => _current > 0 ? _Stage.travellers : _Stage.camera,
      _Stage.passportFront => _Stage.selfie,
      _Stage.passportBack => _Stage.passportFront,
      _Stage.detail => _t.passportBackPath != null ? _Stage.passportBack : _Stage.passportFront,
      _Stage.travellers => _Stage.detail,
      _Stage.insurance => _Stage.travellers,
    };
    if (previous == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      if (_editing) {
        _editing = false;
        _stage = _Stage.detail;
        return;
      }
      if (_stage == _Stage.selfie && _current > 0) {
        // Leaving a co-traveller's photo step: drop them if nothing was done.
        if (_t.selfiePath == null && _t.passportScanPath == null) _travellers.removeAt(_current);
        _current = 0;
      }
      if (_stage == _Stage.travellers) _current = 0;
      _stage = previous;
    });
  }

  VisaFlowStep get _step => switch (_stage) {
        _Stage.when || _Stage.departure => VisaFlowStep.dates,
        _Stage.camera || _Stage.selfie => VisaFlowStep.photo,
        _Stage.passportFront || _Stage.passportBack => VisaFlowStep.passport,
        _Stage.detail || _Stage.travellers => VisaFlowStep.detail,
        _Stage.insurance => VisaFlowStep.checkout,
      };

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage == _Stage.when,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              VisaFlowHeader(
                visaOn: _visaOn,
                step: _step,
                onBack: _back,
                subtitle: _current > 0 && _stage.index >= _Stage.selfie.index && _stage.index <= _Stage.detail.index
                    ? 'Co-traveller $_current'
                    : null,
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
        bottomNavigationBar: _bottom(),
      ),
    );
  }

  Widget? _bottom() {
    final (label, action) = switch (_stage) {
      _Stage.departure => ('Continue', _datesDone),
      _Stage.camera => ('Continue', () => setState(() => _stage = _Stage.selfie)),
      _Stage.detail => ('Continue', _detailDone),
      _Stage.travellers => (_travellers.length == 1 ? 'Apply only for myself' : 'Continue', _travellersDone),
      _ => (null, null),
    };
    if (label == null) return null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: VisaPrimaryButton(label: label, onPressed: action),
      ),
    );
  }

  Widget _body() {
    return switch (_stage) {
      _Stage.when => _whenView(),
      _Stage.departure => _departureView(),
      _Stage.camera => _cameraView(),
      _Stage.selfie => VisaSelfieStep(
          key: ValueKey('selfie$_current'),
          initialPath: _t.selfiePath,
          onConfirmed: _onSelfie,
        ),
      _Stage.passportFront => VisaPassportStep(key: ValueKey('front$_current'), back: false, onScanned: _onFront),
      _Stage.passportBack => VisaPassportStep(key: ValueKey('back$_current'), back: true, onScanned: _onBack),
      _Stage.detail => _detailView(),
      _Stage.travellers => _travellersView(),
      _Stage.insurance => _insuranceView(),
    };
  }

  Widget _whenView() {
    final cutoff = DateFormat('MMM d,yyyy').format(_cutoff);
    final title = Text.rich(
      TextSpan(children: [
        TextSpan(text: 'When are you ', style: GoogleFonts.goblinOne(fontSize: 15, color: VisaColors.primary)),
        TextSpan(text: 'travelling ?', style: GoogleFonts.goblinOne(fontSize: 15, color: VisaColors.cta)),
      ]),
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          title,
          // Faded mirror image under the heading, as in the design.
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(1, -0.6, 1),
              child: title,
            ),
          ),
          const SizedBox(height: 16),
          _whenButton('Before $cutoff', () => _chooseWhen(true)),
          const SizedBox(height: 10),
          _whenButton('After $cutoff', () => _chooseWhen(false)),
        ],
      ),
    );
  }

  Widget _whenButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: 220,
      height: 32,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: VisaColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: visaText(10.5, weight: FontWeight.w500, color: VisaColors.primary)),
      ),
    );
  }

  Widget _departureView() {
    return Column(
      children: [
        const SizedBox(height: 22),
        Text('What is your departure date?', style: visaText(13, weight: FontWeight.w600, color: VisaColors.title)),
        const SizedBox(height: 12),
        Container(
          width: 290,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFF1F2F4), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              for (final fixed in [true, false])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _fixed = fixed),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _fixed == fixed ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(fixed ? 'Fixed Date' : 'Flexible Date',
                          textAlign: TextAlign.center,
                          style: visaText(10.5,
                              weight: FontWeight.w500,
                              color: _fixed == fixed ? VisaColors.primary : VisaColors.text)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(child: _fixed ? _fixedCalendar() : _flexibleDial()),
      ],
    );
  }

  Widget _fixedCalendar() {
    final first = _firstDate;
    final months = <DateTime>[];
    for (var m = DateTime(first.year, first.month);
        !m.isAfter(DateTime(_lastDate.year, _lastDate.month));
        m = DateTime(m.year, m.month + 1)) {
      months.add(m);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final h in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                Expanded(child: Center(child: Text(h, style: visaText(10, color: VisaColors.title)))),
            ],
          ),
        ),
        const Divider(height: 16, color: VisaColors.divider),
        Expanded(
          child: Container(
            color: const Color(0xFFF7F8FA),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final m in months) ...[
                  Text.rich(TextSpan(children: [
                    TextSpan(text: DateFormat('MMMM').format(m), style: visaText(13, weight: FontWeight.w700)),
                    TextSpan(text: '  ${m.year}', style: visaText(13, color: VisaColors.text)),
                  ])),
                  const SizedBox(height: 10),
                  VisaMonthGrid(
                    month: m,
                    start: _date,
                    firstDate: first,
                    lastDate: _lastDate,
                    showHeaders: false,
                    onTap: (d) => setState(() => _date = d),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _flexibleDial() {
    final range = _flexRange;
    final f = DateFormat('MMM d, yyyy');
    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: VisaColors.primarySoft, borderRadius: BorderRadius.circular(6)),
          child: Text(text, style: visaText(10, weight: FontWeight.w500, color: VisaColors.title)),
        );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              chip(f.format(range.start)),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: Container(height: 1, color: VisaColors.stroke)),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(color: VisaColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                    Expanded(child: Container(height: 1, color: VisaColors.stroke)),
                  ],
                ),
              ),
              chip(f.format(range.end)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text('Turn the dial to pick your travel month', style: visaText(9.5, color: VisaColors.text)),
        const Spacer(),
        VisaMonthDial(
          months: _flexMonths,
          selected: _flexIndex,
          onChanged: (i) => setState(() => _flexIndex = i),
        ),
      ],
    );
  }

  Widget _cameraView() {
    Widget feature(IconData icon, Color color, String title, String body) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: visaText(11, weight: FontWeight.w600, color: VisaColors.title)),
                    const SizedBox(height: 2),
                    Text(body, style: visaText(9, color: VisaColors.text, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8)],
            ),
            child: const Icon(Icons.add_a_photo_outlined, size: 20, color: VisaColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text('Camera Permission Required',
            style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: VisaColors.title)),
        const SizedBox(height: 4),
        Text(
          'To auto-capture your official selfie and passport, please allow camera access in the system prompt on the next screen.',
          style: visaText(10, color: VisaColors.text, height: 1.4),
        ),
        const SizedBox(height: 20),
        feature(Icons.center_focus_strong, VisaColors.primary, 'Instant Auto-Fill & Alignment',
            'Captures your selfie and passport automatically once they are in frame, and fills your details from the passport.'),
        feature(Icons.published_with_changes, VisaColors.green, 'Instant Error-Checking',
            'Checks that one clear face is visible and that the passport is readable before you continue.'),
        feature(Icons.lock_outline, VisaColors.cta, 'Used only for your visa',
            'Your photos are processed on your phone and sent only with your ${_d.shortName} visa application.'),
      ],
    );
  }

  Widget _detailView() {
    final t = _t;
    final locked = t.passportVerified;
    final f = visaDateFormat;
    final now = DateTime.now();
    final until = _travelDate.add(Duration(days: _validityDays - 1));

    return ListView(
      key: ValueKey('detail$_current'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        VisaDetailCard(
          icon: Icons.calendar_month,
          iconColor: VisaColors.cta,
          title: 'Visa Validity',
          onEdit: _editValidity,
          child: Row(
            children: [
              _dateColumn('FROM', f.format(_travelDate), CrossAxisAlignment.start),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: Container(height: 1, color: const Color(0xFFF5C9A8))),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(color: VisaColors.cta, shape: BoxShape.circle),
                      child: const Icon(Icons.flight, size: 13, color: Colors.white),
                    ),
                    Expanded(child: Container(height: 1, color: const Color(0xFFF5C9A8))),
                  ],
                ),
              ),
              _dateColumn('UNTIL', f.format(until), CrossAxisAlignment.end),
            ],
          ),
        ),
        VisaDetailCard(
          icon: Icons.person,
          title: _travellers.length > 1 ? 'Personal Information · Traveller ${_current + 1}' : 'Personal Information',
          child: Column(
            children: [
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 13, color: VisaColors.green),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('Verified from your passport. Rescan to change these details.',
                            style: visaText(8.5, color: VisaColors.green)),
                      ),
                    ],
                  ),
                ),
              VisaTextInput(
                label: 'First name',
                value: t.firstName,
                locked: locked,
                error: _errors.contains('firstName'),
                onChanged: (v) => t.firstName = v,
              ),
              VisaTextInput(label: 'Last name', value: t.lastName, locked: locked, required: false, onChanged: (v) => t.lastName = v),
              VisaTextInput(
                label: 'Passport number',
                value: t.passportNo,
                locked: locked,
                capitalization: TextCapitalization.characters,
                onChanged: (v) => t.passportNo = v.toUpperCase(),
              ),
              VisaTapInput(label: 'Passport from', value: t.passportFrom, locked: locked, onTap: () {}),
              VisaTapInput(
                label: 'Passport issued on',
                value: t.passportIssued == null ? '' : f.format(t.passportIssued!),
                error: _errors.contains('passportIssued'),
                onTap: () async {
                  final d = await _pickDate(t.passportIssued, DateTime(now.year - 20), now);
                  if (d != null) setState(() => t.passportIssued = d);
                },
              ),
              VisaTapInput(
                label: 'Passport valid till',
                value: t.passportExpiry == null ? '' : f.format(t.passportExpiry!),
                locked: locked,
                error: _errors.contains('passportExpiry'),
                onTap: () {},
              ),
              VisaTapInput(
                label: 'Date of birth',
                value: t.dob == null ? '' : f.format(t.dob!),
                locked: locked,
                onTap: () {},
              ),
              VisaTextInput(
                label: 'Place of birth',
                value: t.placeOfBirth,
                error: _errors.contains('placeOfBirth'),
                onChanged: (v) => t.placeOfBirth = v,
              ),
              VisaTapInput(label: 'Gender', value: t.gender, locked: locked, onTap: () {}),
              VisaTextInput(
                label: 'Father name',
                value: t.fatherName,
                error: _errors.contains('fatherName'),
                onChanged: (v) => t.fatherName = v,
              ),
              VisaTextInput(
                label: 'Mother name',
                value: t.motherName,
                error: _errors.contains('motherName'),
                onChanged: (v) => t.motherName = v,
              ),
              VisaTextInput(
                label: 'Old passport number',
                value: t.oldPassportNo,
                required: false,
                capitalization: TextCapitalization.characters,
                onChanged: (v) => t.oldPassportNo = v.toUpperCase(),
              ),
            ],
          ),
        ),
        if (_current == 0)
          VisaDetailCard(
            icon: Icons.mail_outline,
            title: 'Contact details',
            child: Column(
              children: [
                VisaTextInput(
                  label: 'Email (for visa updates)',
                  value: _trip.email,
                  capitalization: TextCapitalization.none,
                  keyboard: TextInputType.emailAddress,
                  error: _errors.contains('email'),
                  onChanged: (v) => _trip.email = v,
                ),
                VisaTextInput(
                  label: 'Mobile number',
                  value: _trip.phone,
                  capitalization: TextCapitalization.none,
                  keyboard: TextInputType.phone,
                  error: _errors.contains('phone'),
                  onChanged: (v) => _trip.phone = v,
                ),
              ],
            ),
          ),
        VisaDetailCard(
          icon: Icons.description,
          title: 'Document',
          child: SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _docTile('Photo', t.selfiePath, () => _redo(_Stage.selfie)),
                _docTile('Passport Front', t.passportScanPath, () => _redo(_Stage.passportFront)),
                if (t.passportBackPath != null)
                  _docTile('Passport Back', t.passportBackPath, () => _redo(_Stage.passportBack)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(VisaTravellerForm t) => ClipOval(
        child: SizedBox(
          width: 28,
          height: 28,
          child: t.selfiePath != null
              ? Image.file(File(t.selfiePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
              : Container(
                  color: VisaColors.primarySoft,
                  child: const Icon(Icons.person, size: 16, color: VisaColors.primary),
                ),
        ),
      );

  String _fullName(VisaTravellerForm t) => '${t.firstName} ${t.lastName}'.trim().toUpperCase();

  Widget _travellersView() {
    final you = _travellers.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text('Add More Travellers',
            textAlign: TextAlign.center, style: visaText(13, weight: FontWeight.w600, color: VisaColors.title)),
        const SizedBox(height: 4),
        Text('Since you are the primary account holder, you\nwill always be include in the application.',
            textAlign: TextAlign.center, style: visaText(9.5, color: VisaColors.text, height: 1.4)),
        const SizedBox(height: 20),
        _travellerRow(
          leading: _avatar(you),
          title: Text('${_fullName(you)} (You)',
              style: visaText(11, weight: FontWeight.w600, color: VisaColors.title)),
        ),
        for (var i = 1; i < _travellers.length; i++)
          _travellerRow(
            leading: _complete(i) ? _avatar(_travellers[i]) : const Icon(Icons.person, size: 18, color: VisaColors.text),
            title: _complete(i)
                ? Text(_fullName(_travellers[i]), style: visaText(11, weight: FontWeight.w600, color: VisaColors.title))
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFCD34D), borderRadius: BorderRadius.circular(10)),
                      child: Text('Application Pending',
                          style: visaText(8.5, weight: FontWeight.w600, color: VisaColors.title)),
                    ),
                  ),
            actions: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _editTraveller(i),
                icon: const Icon(Icons.edit, size: 16, color: VisaColors.primary),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmDelete(i),
                icon: const Icon(Icons.delete, size: 16, color: VisaColors.red),
              ),
            ],
          ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _seats(),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _addCoTraveller,
                child: CustomPaint(
                  painter: _DashedRectPainter(),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FAFE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle, size: 16, color: VisaColors.primary),
                        const SizedBox(width: 6),
                        Text('Add New Co- Traveller',
                            style: visaText(10, weight: FontWeight.w600, color: VisaColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _travellerRow({required Widget leading, required Widget title, List<Widget> actions = const []}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(10, 8, actions.isEmpty ? 10 : 2, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [leading, const SizedBox(width: 10), Expanded(child: title), ...actions],
      ),
    );
  }

  /// Two rows of three cabin seats; the travellers fill them from the right.
  Widget _seats() {
    final taken = _travellers.length.clamp(1, 6);
    Widget seat(int index) {
      final filled = 5 - index < taken;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Icon(Icons.event_seat, size: 30, color: filled ? VisaColors.primary : const Color(0xFFD6ECF7)),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [for (var i = 0; i < 3; i++) seat(i)]),
        Row(children: [for (var i = 3; i < 6; i++) seat(i)]),
      ],
    );
  }

  Widget _insuranceView() {
    final days = _insuranceDays ?? 7;
    final count = _travellers.length;
    final from = _travelDate;
    final until = from.add(Duration(days: days - 1));
    final price = VisaInsurancePlan.perDayInr * days * count;
    final money = '₹${NumberFormat.decimalPattern('en_IN').format(price.round())}';
    final required = [..._d.requirementsItems, ..._d.requiredDocuments]
        .any((r) => r.toLowerCase().contains('insurance'));
    const benefits = [
      (Icons.medical_services_outlined, 'Emergency Medical Cover', 'Hospitalization & treatment', '\$50,000'),
      (Icons.badge_outlined, 'Loss of Passport', 'Assistance & emergency duplicate', '\$300'),
      (Icons.luggage_outlined, 'Loss of Checked in Baggage', 'Per-bag compensation', '\$300'),
    ];
    final f = DateFormat('d MMM, yyyy');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            children: [
              Text(
                required ? '${_d.name} Requires\nTravel Insurance' : 'Protect Your ${_d.shortName} Trip\nWith Travel Insurance',
                textAlign: TextAlign.center,
                style: visaText(13, weight: FontWeight.w600, color: VisaColors.title, height: 1.3),
              ),
              const SizedBox(height: 4),
              Text(
                required
                    ? 'The ${_d.name} requires visa application to have insurance, and Wander Nova offers the needed coverage'
                    : 'Medical emergencies abroad are expensive. Wander Nova offers cover for your whole trip.',
                textAlign: TextAlign.center,
                style: visaText(9, color: VisaColors.text, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('If you travel', style: visaText(9.5, color: VisaColors.text)),
                        const SizedBox(width: 8),
                        _miniStep(Icons.remove, days > 1 ? () => setState(() => _insuranceDays = days - 1) : null),
                        SizedBox(
                          width: 26,
                          child: Text('$days', textAlign: TextAlign.center, style: visaText(10, weight: FontWeight.w600)),
                        ),
                        _miniStep(Icons.add, days < 180 ? () => setState(() => _insuranceDays = days + 1) : null),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(money, style: visaText(15, weight: FontWeight.w700, color: VisaColors.title)),
                            Text('Total for $count traveller${count == 1 ? '' : 's'}',
                                style: visaText(8.5, color: VisaColors.primary)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 18, color: VisaColors.divider),
                    Text('Travel Dates', style: visaText(8.5, color: VisaColors.text)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(f.format(from), style: visaText(10, weight: FontWeight.w600)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.flight, size: 12, color: VisaColors.primary),
                        ),
                        Text(f.format(until), style: visaText(10, weight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              for (final (icon, title, sub, amount) in benefits)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: VisaColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                        child: Icon(icon, size: 17, color: VisaColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: visaText(10.5, weight: FontWeight.w600, color: VisaColors.title)),
                            Text(sub, style: visaText(8.5, color: VisaColors.text)),
                          ],
                        ),
                      ),
                      Text(amount, style: visaText(11, weight: FontWeight.w700, color: VisaColors.primary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                VisaPrimaryButton(label: 'Add insurance for $money', onPressed: () => _toCheckout(insurance: true)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _toCheckout(insurance: false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: VisaColors.cta),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("I'LL GET IT ON MY OWN",
                        style: visaText(12, weight: FontWeight.w700, color: VisaColors.cta)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStep(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Icon(icon, size: 11, color: onTap == null ? VisaColors.stroke : VisaColors.title),
        ),
      );

  void _redo(_Stage stage) => setState(() {
        _editing = true;
        _stage = stage;
      });

  Future<DateTime?> _pickDate(DateTime? current, DateTime first, DateTime last) => showVisaSheet<DateTime>(
        context,
        VisaDatePickerSheet(initial: current, firstDate: first, lastDate: last),
        showHandle: false,
      );

  Widget _dateColumn(String label, String value, CrossAxisAlignment align) => Column(
        crossAxisAlignment: align,
        children: [
          Text(label, style: visaText(8, weight: FontWeight.w500, color: VisaColors.text)),
          const SizedBox(height: 2),
          Text(value, style: visaText(12, weight: FontWeight.w600, color: VisaColors.title)),
        ],
      );

  Widget _docTile(String label, String? path, VoidCallback onEdit) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: VisaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
            child: Row(
              children: [
                Icon(path == null ? Icons.error_outline : Icons.check_circle,
                    size: 12, color: path == null ? VisaColors.red : VisaColors.green),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: visaText(9.5, weight: FontWeight.w500, color: VisaColors.title)),
                ),
                GestureDetector(onTap: onEdit, child: const Icon(Icons.edit, size: 13, color: VisaColors.primary)),
              ],
            ),
          ),
          Expanded(
            child: path == null
                ? const SizedBox.expand()
                : Image.file(File(path), fit: BoxFit.cover, width: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox()),
          ),
        ],
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VisaColors.primaryLight
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
