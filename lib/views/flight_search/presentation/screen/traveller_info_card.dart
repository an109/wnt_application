import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart' as di;
import 'package:wander_nova/views/AKTravelCheckList/domain/entity/AKTravelCheckList_entity.dart';

// ---------------------------------------------------------------------------
// Figma tokens (Traveller Details card — booking screen nodes 450:2393 /
// 563:1256 / 563:1257 / 563:1619, plus the Add-Traveller sheet)
// ---------------------------------------------------------------------------
const _pri = AppColors.AppBlue; // #00A1E4
const _sec = AppColors.OrangeColor; // #FF6600 (Confirm bar)
const _muted = AppColors.subhead; // #757575
const _stroke = Color(0xFFCCCCCC);
const _slate900 = Color(0xFF0F172A);
const _checkboxIdle = Color(0xFFCBD5E1);
const _danger = Color(0xFFFF383C);

/// Gender isn't collected as its own field — it's inferred from the salutation,
/// same as most airlines' own booking forms do.
String _inferredGender(String title) {
  switch (title.trim()) {
    case 'Mrs':
    case 'Ms':
    case 'Miss':
      return 'Female';
    default:
      return 'Male';
  }
}

/// Demonym for the handful of nationalities most likely to show up for this
/// app's userbase — anything else falls back to the raw country name from
/// the geolocation lookup, which is still a reasonable prefill.
const Map<String, String> _nationalityByCountry = {
  'India': 'Indian',
  'United States': 'American',
  'United Kingdom': 'British',
  'Canada': 'Canadian',
  'Australia': 'Australian',
  'United Arab Emirates': 'Emirati',
  'Singapore': 'Singaporean',
  'Germany': 'German',
  'France': 'French',
  'China': 'Chinese',
  'Japan': 'Japanese',
  'Saudi Arabia': 'Saudi Arabian',
  'Qatar': 'Qatari',
  'Nepal': 'Nepali',
  'Sri Lanka': 'Sri Lankan',
  'Bangladesh': 'Bangladeshi',
  'Pakistan': 'Pakistani',
};

// ---------------------------------------------------------------------------
// Passenger types
// ---------------------------------------------------------------------------

/// One passenger-type block in the card (Adult / Child / Infants). `ptc` is the
/// code CreateItinerary expects.
class _PaxKind {
  final String ptc;
  final String label;
  final String ageHint;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  const _PaxKind(this.ptc, this.label, this.ageHint, this.icon, this.tint, this.iconColor);

  static const adult = _PaxKind(
      'ADT', 'Adult', '(12+ yrs)', Icons.person, Color(0xFFEFF6FF), Color(0xFF2F80ED));
  static const child = _PaxKind(
      'CHD', 'Child', '(2-12 yrs)', Icons.person, Color(0x1FFF8BD4), Color(0xFFF43F8E));
  static const infant = _PaxKind(
      'INF', 'Infants', '(15days-2 yrs)', Icons.person, Color(0x1FFF6600), Color(0xFFFF8A3D));

  /// Figma copy uses "Add New Adult" under every block; keeping the type in the
  /// label makes the three buttons distinguishable for screen readers.
  String get addLabel => 'Add New $label';
}

/// Which fields the airline actually demands for this booking. Built from
/// GetTravelCheckList so the Add-Traveller sheet only ever asks for what the
/// carrier needs (name-only for most domestic fares, +DOB / +passport when the
/// checklist says so).
class _FieldReq {
  final bool dob;
  final bool nationality;
  final bool passportNo;
  final bool passportIssueDate;
  final bool passportExpiry;
  final bool placeOfIssue;
  final bool panNo;
  final bool visaType;
  final bool titleMandatory;

  const _FieldReq({
    this.dob = false,
    this.nationality = false,
    this.passportNo = false,
    this.passportIssueDate = false,
    this.passportExpiry = false,
    this.placeOfIssue = false,
    this.panNo = false,
    this.visaType = false,
    this.titleMandatory = true,
  });

  /// Conservative fallback for when GetTravelCheckList hasn't resolved (or came
  /// back `unavailable`): international needs travel documents, domestic
  /// doesn't. Never assume "nothing is mandatory".
  factory _FieldReq.fallback({required bool isInternational}) => _FieldReq(
        dob: isInternational,
        nationality: isInternational,
        passportNo: isInternational,
        passportExpiry: isInternational,
      );

  factory _FieldReq.fromCheckList(
    AkTravellerCheckListEntity e, {
    required bool titleMandatory,
  }) =>
      _FieldReq(
        dob: e.dob,
        nationality: e.nationality,
        passportNo: e.passportNo,
        passportIssueDate: e.pdoi,
        passportExpiry: e.pdoe,
        placeOfIssue: e.pli,
        panNo: e.panNo,
        visaType: e.visaType,
        titleMandatory: titleMandatory,
      );

  /// Children and infants are always priced off a date of birth, whatever the
  /// checklist says.
  _FieldReq forcedDobFor(String ptc) =>
      (ptc == 'ADT' || dob) ? this : copyWith(dob: true);

  _FieldReq copyWith({bool? dob}) => _FieldReq(
        dob: dob ?? this.dob,
        nationality: nationality,
        passportNo: passportNo,
        passportIssueDate: passportIssueDate,
        passportExpiry: passportExpiry,
        placeOfIssue: placeOfIssue,
        panNo: panNo,
        visaType: visaType,
        titleMandatory: titleMandatory,
      );
}

/// A person the user can put on this booking. Comes either from the signed-in
/// profile's saved travellers or from the Add-Traveller sheet.
class _Traveller {
  final String id;
  String ptc;
  String title;
  String firstName;
  String lastName;
  String dob; // 'dd MMM yyyy'
  String nationality;
  String passportNumber;
  String passportIssueDate;
  String passportExpiry;
  String placeOfIssue;
  String panNumber;
  String visaType;
  String phone;
  String email;
  /// 'Male' | 'Female' — set explicitly by the Add-Traveller screen's toggle;
  /// [title] is kept in sync so the CreateItinerary gender mapping is stable.
  String gender;
  bool wheelchair;
  bool selected;

  _Traveller({
    required this.id,
    required this.ptc,
    this.title = 'Mr',
    this.firstName = '',
    this.lastName = '',
    this.dob = '',
    this.nationality = 'Indian',
    this.passportNumber = '',
    this.passportIssueDate = '',
    this.passportExpiry = '',
    this.placeOfIssue = '',
    this.panNumber = '',
    this.visaType = '',
    this.phone = '',
    this.email = '',
    this.gender = 'Male',
    this.wheelchair = false,
    this.selected = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  /// Maps a saved profile traveller (`Profile_screen` / `AddTravellerModal`
  /// shape) onto this model. Dates there are stored ISO, the UI wants
  /// 'dd MMM yyyy'.
  factory _Traveller.fromSaved(Map<String, dynamic> m, String id) {
    String s(String key) => (m[key] ?? '').toString().trim();
    return _Traveller(
      id: id,
      ptc: s('paxType').toUpperCase().isEmpty ? 'ADT' : s('paxType').toUpperCase(),
      title: s('title').isEmpty ? 'Mr' : s('title'),
      firstName: s('firstName'),
      lastName: s('lastName'),
      dob: _displayDate(s('dob')),
      nationality: s('nationality').isEmpty ? 'Indian' : s('nationality'),
      passportNumber: s('passportNumber'),
      passportExpiry: _displayDate(s('passportExpiry')),
      placeOfIssue: s('placeOfIssue'),
      visaType: s('visaType'),
      phone: s('phone').isEmpty ? s('mobileNumber') : s('phone'),
      email: s('email'),
      gender: s('gender').isEmpty ? _inferredGender(s('title')) : s('gender'),
    );
  }

  _Traveller copy() => _Traveller(
        id: id,
        ptc: ptc,
        title: title,
        firstName: firstName,
        lastName: lastName,
        dob: dob,
        nationality: nationality,
        passportNumber: passportNumber,
        passportIssueDate: passportIssueDate,
        passportExpiry: passportExpiry,
        placeOfIssue: placeOfIssue,
        panNumber: panNumber,
        visaType: visaType,
        phone: phone,
        email: email,
        gender: gender,
        wheelchair: wheelchair,
        selected: selected,
      );
}

String _displayDate(String raw) {
  if (raw.trim().isEmpty) return '';
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(raw.trim()));
  } catch (_) {
    return raw.trim();
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class TravellerInformationSection extends StatefulWidget {
  final bool isInternational;

  /// Total travellers — kept for callers that don't break the count down by
  /// passenger type; used as the adult count when [adultCount] is 0.
  final int travellerCount;

  final int adultCount;
  final int childCount;
  final int infantCount;

  /// GetTravelCheckList's answer for this fare. Drives which fields the
  /// Add-Traveller sheet asks for. Null / `unavailable` falls back to the
  /// route-based heuristic.
  final AkTravelCheckListEntity? checkList;

  const TravellerInformationSection({
    super.key,
    this.isInternational = false,
    this.travellerCount = 1,
    this.adultCount = 0,
    this.childCount = 0,
    this.infantCount = 0,
    this.checkList,
  });

  @override
  TravellerFormState createState() => TravellerFormState();
}

class TravellerFormState extends State<TravellerInformationSection> {
  final _contactFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _emailError;
  String? _phoneError;
  bool _hasGst = false;

  /// Every person offered for selection, saved-profile and freshly-added alike.
  final List<_Traveller> _people = [];
  int _uid = 0;

  /// Per-pax-type validation message shown under a block ("Select 1 adult").
  final Map<String, String> _blockErrors = {};

  String _defaultNationality = 'Indian';

  int get _adults => widget.adultCount > 0
      ? widget.adultCount
      : (widget.childCount == 0 && widget.infantCount == 0
          ? (widget.travellerCount < 1 ? 1 : widget.travellerCount)
          : 0);
  int get _children => widget.childCount;
  int get _infants => widget.infantCount;

  int _requiredFor(String ptc) => switch (ptc) {
        'CHD' => _children,
        'INF' => _infants,
        _ => _adults,
      };

  List<_PaxKind> get _kinds => [
        if (_adults > 0) _PaxKind.adult,
        if (_children > 0) _PaxKind.child,
        if (_infants > 0) _PaxKind.infant,
      ];

  List<_Traveller> _peopleOf(String ptc) => _people.where((p) => p.ptc == ptc).toList();
  List<_Traveller> _selectedOf(String ptc) =>
      _people.where((p) => p.ptc == ptc && p.selected).toList();

  // -------------------------------------------------------------------------
  // Requirements
  // -------------------------------------------------------------------------

  /// The checklist is returned per traveller, in order. Anything past the end
  /// of the list reuses the last entry, which is how the API models "same
  /// requirements for the remaining pax".
  _FieldReq _reqFor(String ptc, int indexInBooking) {
    final data = widget.checkList;
    final titleMandatory = data == null || data.fnuLnuSettings.isEmpty
        ? true
        : data.fnuLnuSettings.first.titleMandatory;

    if (data == null || data.unavailable || data.travellerCheckList.isEmpty) {
      return _FieldReq.fallback(isInternational: widget.isInternational).forcedDobFor(ptc);
    }
    final list = data.travellerCheckList;
    final entry = list[math.min(indexInBooking, list.length - 1)];
    return _FieldReq.fromCheckList(entry, titleMandatory: titleMandatory).forcedDobFor(ptc);
  }

  /// Zero-based position of a traveller across the whole booking, so the
  /// per-traveller checklist entry lines up (adults, then children, then
  /// infants — the order CreateItinerary is given).
  int _bookingIndexOf(String ptc, int indexInKind) => switch (ptc) {
        'CHD' => _adults + indexInKind,
        'INF' => _adults + _children + indexInKind,
        _ => indexInKind,
      };

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadSignedInTravellers();
    _detectNationality();
  }

  /// Seeds the picker with the signed-in user and any travellers they've saved
  /// in their profile, so a returning user can tick themselves rather than
  /// retyping. Silently no-ops when signed out — the block then shows just the
  /// "Add New …" button, which is the correct empty state.
  void _loadSignedInTravellers() {
    try {
      final prefs = di.sl<PreferencesManager>();
      if (!prefs.isLoggedIn()) return;
      final data = prefs.getUserData();
      if (data == null) return;

      final email = (data['email'] ?? '').toString().trim();
      final phone = (data['phone'] ?? data['mobile'] ?? '').toString().trim();
      if (email.isNotEmpty && _emailController.text.isEmpty) _emailController.text = email;
      if (phone.isNotEmpty && _phoneController.text.isEmpty) _phoneController.text = phone;

      final saved = data['travellers'];
      if (saved is List) {
        for (final raw in saved.whereType<Map>()) {
          final person = _Traveller.fromSaved(Map<String, dynamic>.from(raw), 't${_uid++}');
          if (person.fullName.isEmpty) continue;
          if (person.phone.isEmpty && person.ptc == 'ADT') person.phone = phone;
          _people.add(person);
        }
      }

      // No saved list yet — offer the account holder themselves as an adult.
      if (_people.isEmpty) {
        final name = (data['name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          final parts = name.split(RegExp(r'\s+'));
          _people.add(_Traveller(
            id: 't${_uid++}',
            ptc: 'ADT',
            firstName: parts.first,
            lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
            phone: phone,
          ));
        }
      }
    } catch (_) {
      // Prefs unavailable — fall through to the signed-out empty state.
    }
  }

  /// Prefills Nationality from the device's public IP location, so most users
  /// don't have to type it. Defaults to 'Indian' until this resolves, and
  /// silently keeps that default on any failure.
  Future<void> _detectNationality() async {
    String? nationality;
    try {
      final response =
          await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final country = (data['country_name'] as String?)?.trim();
        if (country != null && country.isNotEmpty) {
          nationality = _nationalityByCountry[country] ?? country;
        }
      }
    } catch (_) {
      // Ignore — keep the 'Indian' default.
    }
    final resolved = nationality;
    if (!mounted || resolved == null) return;
    setState(() {
      _defaultNationality = resolved;
      for (final p in _people) {
        if (p.nationality == 'Indian') p.nationality = resolved;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Public API — unchanged contract for FlightBookingScreen
  // -------------------------------------------------------------------------

  bool validateForm() {
    final contactValid = _contactFormKey.currentState?.validate() ?? false;

    final errors = <String, String>{};
    for (final kind in _kinds) {
      final need = _requiredFor(kind.ptc);
      final chosen = _selectedOf(kind.ptc);
      if (chosen.length < need) {
        errors[kind.ptc] =
            'Select ${need - chosen.length} more ${kind.label.toLowerCase()}${need - chosen.length > 1 ? 's' : ''}';
        continue;
      }
      for (int i = 0; i < chosen.length; i++) {
        final missing = _missingFieldFor(chosen[i], kind.ptc, i);
        if (missing != null) {
          errors[kind.ptc] = '${chosen[i].fullName}: $missing';
          break;
        }
      }
    }

    setState(() {
      _blockErrors
        ..clear()
        ..addAll(errors);
    });
    return contactValid && errors.isEmpty;
  }

  /// Re-checks a already-added traveller against the live requirements — the
  /// checklist can arrive after someone was added, so a person saved as
  /// name-only may later need a DOB.
  String? _missingFieldFor(_Traveller t, String ptc, int indexInKind) {
    final req = _reqFor(ptc, _bookingIndexOf(ptc, indexInKind));
    if (t.firstName.trim().isEmpty) return 'first name is required';
    if (t.lastName.trim().isEmpty) return 'last name is required';
    if (req.dob && t.dob.trim().isEmpty) return 'date of birth is required';
    if (req.nationality && t.nationality.trim().isEmpty) return 'nationality is required';
    if (req.passportNo && t.passportNumber.trim().isEmpty) return 'passport number is required';
    if (req.passportExpiry && t.passportExpiry.trim().isEmpty) return 'passport expiry is required';
    if (req.placeOfIssue && t.placeOfIssue.trim().isEmpty) return 'place of issue is required';
    if (req.panNo && t.panNumber.trim().isEmpty) return 'PAN number is required';
    return null;
  }

  Map<String, dynamic> _travellerToMap(_Traveller t) {
    return {
      'paxType': t.ptc,
      'title': t.title.trim(),
      'firstName': t.firstName.trim().toUpperCase(),
      'lastName': t.lastName.trim().toUpperCase(),
      'dateOfBirth': t.dob.trim(),
      // Per-traveller phone/email when the Add-Traveller screen collected
      // one, otherwise the shared booking contact.
      'mobileNumber': t.phone.trim().isNotEmpty
          ? t.phone.trim()
          : _phoneController.text.trim(),
      'email': t.email.trim().isNotEmpty
          ? t.email.trim()
          : _emailController.text.trim(),
      'gender': t.gender.trim().isNotEmpty ? t.gender.trim() : _inferredGender(t.title),
      'wheelchair': t.wheelchair,
      'nationality': t.nationality.trim(),
      'isInternational': widget.isInternational,
      // Always include passport keys so the payment screen has them available.
      // The values are empty strings when the carrier didn't ask for them.
      'passportNumber': t.passportNumber.trim(),
      'passportExpiry': t.passportExpiry.trim(),
      'passportIssueDate': t.passportIssueDate.trim(),
      'placeOfIssue': t.placeOfIssue.trim(),
      'panNumber': t.panNumber.trim(),
      'visaType': t.visaType.trim(),
      'hasGst': _hasGst,
    };
  }

  Map<String, dynamic> getTravellerData() {
    final all = getAllTravellersData();
    return all.isNotEmpty ? all.first : _travellerToMap(_Traveller(id: '_', ptc: 'ADT'));
  }

  /// Selected travellers in the order CreateItinerary expects: adults, then
  /// children, then infants.
  List<Map<String, dynamic>> getAllTravellersData() {
    final out = <Map<String, dynamic>>[];
    for (final ptc in const ['ADT', 'CHD', 'INF']) {
      for (final t in _selectedOf(ptc)) {
        out.add(_travellerToMap(t));
      }
    }
    return out;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mobile number is required';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid mobile number (10-15 digits)';
    }
    return null;
  }

  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final ok = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value.trim());
    setState(() => _emailError = ok ? null : 'Enter a valid email');
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      setState(() => _phoneError = null);
      return;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      if (!RegExp(r'^\d+$').hasMatch(value)) {
        _phoneError = 'Only numbers are allowed';
      } else if (digits.length < 10) {
        _phoneError = 'Minimum 10 digits required';
      } else if (digits.length > 15) {
        _phoneError = 'Maximum 15 digits allowed';
      } else {
        _phoneError = null;
      }
    });
  }

  // -------------------------------------------------------------------------
  // Selection
  // -------------------------------------------------------------------------

  void _toggle(_Traveller t) {
    final need = _requiredFor(t.ptc);
    final chosen = _selectedOf(t.ptc).length;
    setState(() {
      if (t.selected) {
        t.selected = false;
      } else {
        if (chosen >= need) {
          // At capacity — swap the earliest pick out so tapping always does
          // something predictable instead of silently failing.
          final first = _selectedOf(t.ptc).first;
          first.selected = false;
        }
        t.selected = true;
      }
      _blockErrors.remove(t.ptc);
    });
  }

  Future<void> _openSheet({required String ptc, _Traveller? existing}) async {
    final indexInKind = existing != null
        ? math.max(0, _peopleOf(ptc).indexOf(existing))
        : _peopleOf(ptc).length;
    final req = _reqFor(ptc, _bookingIndexOf(ptc, indexInKind));
    final kind = _kinds.firstWhere((k) => k.ptc == ptc, orElse: () => _PaxKind.adult);

    // Only the very first traveller of the booking (the lead adult) enters the
    // booking contact. Every other adult / child / infant fills just gender,
    // name and whatever the airline demands — they inherit this contact via
    // [_travellerToMap]'s fallback to the shared email / phone.
    final isPrimary = _bookingIndexOf(ptc, indexInKind) == 0;

    final result = await Navigator.of(context).push<_Traveller>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddTravellerScreen(
          kind: kind,
          req: req,
          isPrimary: isPrimary,
          defaultNationality: _defaultNationality,
          contactEmail: _emailController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          initial: existing?.copy(),
          newId: 't${_uid++}',
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _blockErrors.remove(ptc);
      final at = _people.indexWhere((p) => p.id == result.id);
      if (at >= 0) {
        _people[at] = result;
      } else {
        // Auto-select a freshly added traveller when there's still room.
        result.selected = _selectedOf(ptc).length < _requiredFor(ptc);
        _people.add(result);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final kinds = _kinds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < kinds.length; i++) ...[
          if (i > 0) SizedBox(height: context.h(24)),
          _paxBlock(context, kinds[i]),
        ],
        SizedBox(height: context.h(24)),
        _contactBlock(context),
      ],
    );
  }

  // ==================== PAX BLOCK (Figma node 563:1256) ====================
  Widget _paxBlock(BuildContext context, _PaxKind kind) {
    final people = _peopleOf(kind.ptc);
    final chosen = _selectedOf(kind.ptc).length;
    final need = _requiredFor(kind.ptc);
    final error = _blockErrors[kind.ptc];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- header ----
        Row(
          children: [
            Container(
              width: context.w(44),
              height: context.w(44),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kind.tint, shape: BoxShape.circle),
              child: Icon(kind.icon, size: context.w(20), color: kind.iconColor),
            ),
            SizedBox(width: context.w(16)),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: '${kind.label} ',
                    style: TextStyle(fontSize: context.fs(16), color: _slate900),
                  ),
                  TextSpan(
                    text: kind.ageHint,
                    style: TextStyle(fontSize: context.fs(12), color: _muted),
                  ),
                ]),
                style: TextStyle(fontWeight: FontWeight.w700, height: 1.5),
              ),
            ),
            SizedBox(width: context.w(8)),
            Text(
              '$chosen/$need Added',
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: _muted,
                height: 1.33,
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(16)),

        // ---- selectable people ----
        for (final person in people) ...[
          _travellerRow(context, person),
          SizedBox(height: context.h(12)),
        ],

        // ---- add ----
        _addButton(context, kind),

        if (error != null) ...[
          SizedBox(height: context.h(8)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, size: context.w(13), color: _danger),
              SizedBox(width: context.w(6)),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(fontSize: context.fs(11), color: _danger),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// One selectable person (Figma node 453:3919) — checkbox, name, optional
  /// phone, edit affordance.
  /// One selectable person (Figma node 453:3919) — checkbox, name, optional
  /// phone, edit affordance.
  Widget _travellerRow(BuildContext context, _Traveller t) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggle(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(8)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(color: t.selected ? _pri : _stroke, width: t.selected ? 1 : 0.5),
        ),
        child: Row(
          children: [
            _checkbox(context, t.selected),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.fullName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.71,
                    ),
                  ),
                  if (t.phone.trim().isNotEmpty)
                    Text(
                      t.phone.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(12), color: _stroke, height: 1.5),
                    )
                  else if (t.dob.trim().isNotEmpty)
                    Text(
                      t.dob.trim(),
                      style: TextStyle(fontSize: context.fs(12), color: _stroke, height: 1.5),
                    ),
                ],
              ),
            ),
            SizedBox(width: context.w(8)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openSheet(ptc: t.ptc, existing: t),
              child: Padding(
                padding: EdgeInsets.all(context.w(2)),
                child: Image.asset(
                  'assets/NewIcons/edit.png',  // Replace with your edit icon path
                  width: context.w(15),
                  height: context.w(15),
                  color: AppColors.AppBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkbox(BuildContext context, bool checked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: context.w(20),
      height: context.w(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? _pri : Colors.white,
        borderRadius: BorderRadius.circular(context.r(4)),
        border: Border.all(color: checked ? _pri : _checkboxIdle, width: 1.5),
      ),
      child: checked
          ? Icon(Icons.check_rounded, size: context.w(14), color: Colors.white)
          : null,
    );
  }

  /// Dashed "Add New …" button (Figma node 450:2404).
  Widget _addButton(BuildContext context, _PaxKind kind) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openSheet(ptc: kind.ptc),
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: _pri.withValues(alpha: 0.3),
          strokeWidth: 2,
          radius: context.r(12),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: context.w(26), vertical: context.h(18)),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: context.w(20), color: _pri),
              SizedBox(width: context.w(8)),
              Text(
                kind.addLabel,
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700,
                  color: _pri,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CONTACT (Figma node 655:11421) ====================
  Widget _contactBlock(BuildContext context) {
    return Form(
      key: _contactFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking details will be sent to',
            style: TextStyle(fontSize: context.fs(14), color: _muted),
          ),
          SizedBox(height: context.h(16)),
          _boxedField(
            context,
            controller: _emailController,
            hint: 'Email address',
            icon: Icons.mail,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: _validateEmail,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Email is required';
              final ok = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(text);
              return ok ? null : 'Enter a valid email';
            },
          ),
          SizedBox(height: context.h(16)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: context.h(44),
                padding: EdgeInsets.symmetric(horizontal: context.w(8)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.r(8)),
                  border: Border.all(color: _stroke, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇮🇳', style: TextStyle(fontSize: context.fs(16))),
                    SizedBox(width: context.w(6)),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: context.w(16), color: Colors.black),
                  ],
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: _boxedField(
                  context,
                  controller: _phoneController,
                  hint: 'Mobile number',
                  keyboardType: TextInputType.phone,
                  errorText: _phoneError,
                  onChanged: _validatePhone,
                  validator: _phoneValidator,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _hasGst = !_hasGst),
            child: Row(
              children: [
                _checkbox(context, _hasGst),
                SizedBox(width: context.w(8)),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'I have a GST number '),
                    TextSpan(text: '(Optional)', style: TextStyle(color: _muted)),
                  ]),
                  style: TextStyle(fontSize: context.fs(10), color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxedField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? iconAsset,
    TextInputType? keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      inputFormatters: formatters,
      style: TextStyle(fontSize: context.fs(12), color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: context.fs(12), color: _stroke),
        errorText: errorText,
        errorStyle: TextStyle(fontSize: context.fs(10), color: _danger),
        prefixIcon: icon == null
            ? null
            : Padding(
                padding: EdgeInsets.only(left: context.w(12), right: context.w(12)),
                child: Icon(icon, size: context.w(16), color: _muted),
              ),
        prefixIconConstraints: BoxConstraints(minWidth: context.w(40), minHeight: context.w(16)),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(14)),
        border: _fieldBorder(context, _stroke),
        enabledBorder: _fieldBorder(context, _stroke),
        focusedBorder: _fieldBorder(context, _pri),
        errorBorder: _fieldBorder(context, _danger),
        focusedErrorBorder: _fieldBorder(context, _danger),
      ),
    );
  }
}

OutlineInputBorder _fieldBorder(BuildContext context, Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.r(8)),
      borderSide: BorderSide(color: color, width: 0.5),
    );

// ---------------------------------------------------------------------------
// Add / Edit traveller sheet
// ---------------------------------------------------------------------------

/// Only renders the fields the carrier actually asks for ([_FieldReq]), so a
/// simple domestic fare shows name-only while an international one adds DOB,
/// nationality and passport details.
/// Full-screen "Add Traveller" form (Figma "Add Traveller"). Pushed as a
/// `fullscreenDialog` route by [TravellerFormState._openSheet]; pops the
/// completed [_Traveller] on Confirm, or null on close.
///
/// Only renders the fields the carrier actually asks for ([_FieldReq]) — a
/// simple domestic fare shows name + gender + contact, an international one
/// adds DOB, nationality and passport details.
class AddTravellerScreen extends StatefulWidget {
  final _PaxKind kind;
  final _FieldReq req;

  /// The lead traveller collects the booking contact (email / mobile); every
  /// other passenger only fills gender, name and the airline-required extras.
  final bool isPrimary;

  final String defaultNationality;
  final String contactEmail;
  final String contactPhone;
  final _Traveller? initial;
  final String newId;

  const AddTravellerScreen({
    super.key,
    required this.kind,
    required this.req,
    this.isPrimary = true,
    required this.defaultNationality,
    this.contactEmail = '',
    this.contactPhone = '',
    required this.initial,
    required this.newId,
  });

  @override
  State<AddTravellerScreen> createState() => _AddTravellerScreenState();
}

class _AddTravellerScreenState extends State<AddTravellerScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _gender; // 'Male' | 'Female'
  bool _wheelchair = false;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _dob;
  late final TextEditingController _nationality;
  late final TextEditingController _passport;
  late final TextEditingController _passportIssue;
  late final TextEditingController _passportExpiry;
  late final TextEditingController _placeOfIssue;
  late final TextEditingController _pan;
  late final TextEditingController _visaType;

  bool get _isEdit => widget.initial != null;

  List<String> get _titles =>
      widget.kind.ptc == 'ADT' ? const ['Mr', 'Mrs', 'Ms'] : const ['Master', 'Miss'];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = _titles.contains(i?.title) ? i!.title : _titles.first;
    _gender = (i?.gender.isNotEmpty ?? false) ? i!.gender : _inferredGender(_title);
    _wheelchair = i?.wheelchair ?? false;
    _firstName = TextEditingController(text: i?.firstName ?? '');
    _lastName = TextEditingController(text: i?.lastName ?? '');
    _email = TextEditingController(
        text: (i?.email.isNotEmpty ?? false) ? i!.email : widget.contactEmail);
    _phone = TextEditingController(
        text: (i?.phone.isNotEmpty ?? false) ? i!.phone : widget.contactPhone);
    _dob = TextEditingController(text: i?.dob ?? '');
    _nationality =
        TextEditingController(text: i?.nationality ?? widget.defaultNationality);
    _passport = TextEditingController(text: i?.passportNumber ?? '');
    _passportIssue = TextEditingController(text: i?.passportIssueDate ?? '');
    _passportExpiry = TextEditingController(text: i?.passportExpiry ?? '');
    _placeOfIssue = TextEditingController(text: i?.placeOfIssue ?? '');
    _pan = TextEditingController(text: i?.panNumber ?? '');
    _visaType = TextEditingController(text: i?.visaType ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _nationality.dispose();
    _passport.dispose();
    _passportIssue.dispose();
    _passportExpiry.dispose();
    _placeOfIssue.dispose();
    _pan.dispose();
    _visaType.dispose();
    super.dispose();
  }

  /// Age windows straight off the labels in the design — an infant can't be
  /// born before two years ago, a child can't be under two, and so on.
  ({DateTime first, DateTime last}) get _dobRange {
    final now = DateTime.now();
    return switch (widget.kind.ptc) {
      'INF' => (
          first: DateTime(now.year - 2, now.month, now.day),
          last: now.subtract(const Duration(days: 15))
        ),
      'CHD' => (
          first: DateTime(now.year - 12, now.month, now.day),
          last: DateTime(now.year - 2, now.month, now.day)
        ),
      _ => (first: DateTime(now.year - 100), last: DateTime(now.year - 12, now.month, now.day)),
    };
  }

  Future<void> _pickDate(TextEditingController target,
      {required DateTime first, required DateTime last, DateTime? initial}) async {
    final seed = initial ?? (last.isAfter(first) ? last : first);
    final picked = await showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _pri),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => target.text = DateFormat('dd MMM yyyy').format(picked));
  }

  /// Keeps [_Traveller.title] consistent with the Male/Female toggle so the
  /// CreateItinerary gender mapping (which reads the salutation) never
  /// disagrees with what the user picked here.
  String get _syncedTitle {
    final female = _gender == 'Female';
    if (widget.kind.ptc == 'ADT') {
      if (_title == 'Mr' && female) return 'Ms';
      if ((_title == 'Mrs' || _title == 'Ms') && !female) return 'Mr';
      return _title;
    }
    return female ? 'Miss' : 'Master';
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final t = (widget.initial ?? _Traveller(id: widget.newId, ptc: widget.kind.ptc))
      ..ptc = widget.kind.ptc
      ..title = _syncedTitle
      ..gender = _gender
      ..wheelchair = _wheelchair
      ..email = _email.text.trim()
      ..phone = _phone.text.trim()
      ..firstName = _firstName.text.trim()
      ..lastName = _lastName.text.trim()
      ..dob = _dob.text.trim()
      ..nationality = _nationality.text.trim()
      ..passportNumber = _passport.text.trim()
      ..passportIssueDate = _passportIssue.text.trim()
      ..passportExpiry = _passportExpiry.text.trim()
      ..placeOfIssue = _placeOfIssue.text.trim()
      ..panNumber = _pan.text.trim()
      ..visaType = _visaType.text.trim();
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.req;
    final range = _dobRange;
    final isAdult = widget.kind.ptc == 'ADT';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---- header ----
            // ---- header ----
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: context.w(16),
                vertical: context.h(12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      size: context.w(24),
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Text(
                    '${_isEdit ? 'Edit' : 'Add'} ${isAdult ? 'Traveller' : widget.kind.label}',
                    style: TextStyle(
                      fontSize: context.fs(20),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A), // Color(0xFF0F172A)
                    ),
                  ),
                  const Spacer(),
                  // Optional: Add "Reset" or "Clear" if needed
                ],
              ),
            ),

            // Padding(
            //   padding: EdgeInsets.fromLTRB(
            //       context.w(16), context.h(12), context.w(16), context.h(14)),
            //   child: Row(
            //     children: [
            //       GestureDetector(
            //         behavior: HitTestBehavior.opaque,
            //         onTap: () => Navigator.pop(context),
            //         child: Icon(Icons.close_rounded, size: context.w(24), color: Colors.black),
            //       ),
            //       SizedBox(width: context.w(14)),
            //       Text(
            //         '${_isEdit ? 'Edit' : 'Add'} ${isAdult ? 'Traveller' : widget.kind.label}',
            //         style: TextStyle(
            //           fontSize: context.fs(22),
            //           fontWeight: FontWeight.w700,
            //           color: Colors.black,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // Divider(height: 1, color: _stroke),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(
                    context.w(16), context.h(20), context.w(16), context.h(24)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- info banner ----
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(context.w(16)),
                        decoration: BoxDecoration(
                          color: _pri.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(context.r(12)),
                          border: Border.all(color: _pri.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Ensure the name matches your official ID, otherwise '
                          'points and booking may not be updated by the airline.',
                          style: TextStyle(
                            fontSize: context.fs(12),
                            color: _pri,
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: context.h(28)),

                      // ---- gender ----
                      Text(
                        'GENDER',
                        style: TextStyle(
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w700,
                          color: _muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: context.h(10)),
                      Row(
                        children: [
                          Expanded(child: _genderChip(context, 'Male')),
                          SizedBox(width: context.w(12)),
                          Expanded(child: _genderChip(context, 'Female')),
                        ],
                      ),
                      SizedBox(height: context.h(24)),

                      // ---- name ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _floatingField(
                              context,
                              label: 'First Name',
                              controller: _firstName,
                              iconAsset: 'assets/NewIcons/TravellerAdult.png',
                              formatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                              ],
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          SizedBox(width: context.w(12)),
                          Expanded(
                            child: _floatingField(
                              context,
                              label: 'Last Name',
                              controller: _lastName,
                              iconAsset: 'assets/NewIcons/TravellerAdult.png',
                              formatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                              ],
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.h(14)),

                      // ---- booking contact — lead traveller only ----
                      if (widget.isPrimary) ...[
                      // ---- email (optional) ----
                      _floatingField(
                        context,
                        label: 'Email ID (optional)',
                        controller: _email,
                        icon: Icons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final text = v?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final ok = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$')
                              .hasMatch(text);
                          return ok ? null : 'Enter a valid email';
                        },
                      ),
                      SizedBox(height: context.h(14)),

                      // ---- phone ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: context.h(52),
                            padding: EdgeInsets.symmetric(horizontal: context.w(12)),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(context.r(10)),
                              border: Border.all(color: _stroke),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🇮🇳', style: TextStyle(fontSize: context.fs(18))),
                                SizedBox(width: context.w(6)),
                                Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: context.fs(14),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    size: context.w(18), color: _muted),
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
                                LengthLimitingTextInputFormatter(15),
                              ],
                              style: TextStyle(fontSize: context.fs(15), color: Colors.black),
                              validator: (v) {
                                final digits =
                                    (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                                if (digits.isEmpty) return null;
                                return digits.length < 10
                                    ? 'Enter a valid mobile number'
                                    : null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Mobile number',
                                hintStyle:
                                    TextStyle(fontSize: context.fs(15), color: _stroke),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: context.w(14), vertical: context.h(16)),
                                errorStyle:
                                    TextStyle(fontSize: context.fs(10), color: _danger),
                                border: _fieldBorder(context, _stroke),
                                enabledBorder: _fieldBorder(context, _stroke),
                                focusedBorder: _fieldBorder(context, _pri),
                                errorBorder: _fieldBorder(context, _danger),
                                focusedErrorBorder: _fieldBorder(context, _danger),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.h(16)),
                      ],

                      // ---- wheelchair ----
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _wheelchair = !_wheelchair),
                        child: Row(
                          children: [
                            _smallCheckbox(context, _wheelchair),
                            SizedBox(width: context.w(10)),
                            Text.rich(
                              TextSpan(children: [
                                const TextSpan(text: 'I require wheelchair '),
                                TextSpan(
                                    text: '(Optional)',
                                    style: TextStyle(color: _muted)),
                              ]),
                              style:
                                  TextStyle(fontSize: context.fs(13), color: Colors.black),
                            ),
                          ],
                        ),
                      ),

                      // ---- carrier-required extras ----
                      if (req.dob ||
                          req.nationality ||
                          req.passportNo ||
                          req.passportIssueDate ||
                          req.passportExpiry ||
                          req.placeOfIssue ||
                          req.panNo ||
                          req.visaType) ...[
                        SizedBox(height: context.h(24)),
                        Text(
                          'REQUIRED BY AIRLINE',
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w700,
                            color: _muted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: context.h(12)),
                        if (req.dob)
                          _sheetField(
                            context,
                            label: 'Date of birth',
                            controller: _dob,
                            hint: 'dd mmm yyyy',
                            readOnly: true,
                            suffix: Icons.calendar_today_rounded,
                            onTap: () => _pickDate(_dob,
                                first: range.first, last: range.last),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Date of birth is required'
                                : null,
                          ),
                        if (req.nationality)
                          _sheetField(
                            context,
                            label: 'Nationality',
                            controller: _nationality,
                            hint: 'e.g. Indian',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nationality is required'
                                : null,
                          ),
                        if (req.passportNo)
                          _sheetField(
                            context,
                            label: 'Passport number',
                            controller: _passport,
                            hint: 'e.g. M1234567',
                            formatters: [UpperCaseTextFormatter()],
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Passport number is required'
                                : null,
                          ),
                        if (req.passportIssueDate)
                          _sheetField(
                            context,
                            label: 'Passport issue date',
                            controller: _passportIssue,
                            hint: 'dd mmm yyyy',
                            readOnly: true,
                            suffix: Icons.calendar_today_rounded,
                            onTap: () => _pickDate(
                              _passportIssue,
                              first: DateTime(DateTime.now().year - 20),
                              last: DateTime.now(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Passport issue date is required'
                                : null,
                          ),
                        if (req.passportExpiry)
                          _sheetField(
                            context,
                            label: 'Passport expiry',
                            controller: _passportExpiry,
                            hint: 'dd mmm yyyy',
                            readOnly: true,
                            suffix: Icons.calendar_today_rounded,
                            onTap: () => _pickDate(
                              _passportExpiry,
                              first: DateTime.now(),
                              last: DateTime(DateTime.now().year + 20),
                              initial: DateTime.now(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Passport expiry is required'
                                : null,
                          ),
                        if (req.placeOfIssue)
                          _sheetField(
                            context,
                            label: 'Place of issue',
                            controller: _placeOfIssue,
                            hint: 'e.g. Delhi',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Place of issue is required'
                                : null,
                          ),
                        if (req.panNo)
                          _sheetField(
                            context,
                            label: 'PAN number',
                            controller: _pan,
                            hint: 'e.g. ABCDE1234F',
                            formatters: [UpperCaseTextFormatter()],
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'PAN number is required'
                                : null,
                          ),
                        if (req.visaType)
                          _sheetField(
                            context,
                            label: 'Visa type',
                            controller: _visaType,
                            hint: 'e.g. Tourist',
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ---- confirm ----
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    context.w(16), context.h(10), context.w(16), context.h(10)),
                child: SizedBox(
                  width: double.infinity,
                  height: context.h(52),
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sec,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(10)),
                      ),
                    ),
                    child: Text(
                      'CONFIRM',
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderChip(BuildContext context, String value) {
    final active = _gender == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: context.h(44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _pri.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(color: active ? _pri : _stroke, width: 1),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w700,
            color: active ? _pri : _muted,
          ),
        ),
      ),
    );
  }

  Widget _smallCheckbox(BuildContext context, bool checked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: context.w(20),
      height: context.w(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? _pri : Colors.white,
        borderRadius: BorderRadius.circular(context.r(4)),
        border: Border.all(color: checked ? _pri : _checkboxIdle, width: 1),
      ),
      child: checked
          ? Icon(Icons.check_rounded, size: context.w(14), color: Colors.white)
          : null,
    );
  }

  /// Outlined field with a floating label and a leading icon, matching the
  /// name / email inputs on the Figma "Add Traveller" screen.
  Widget _floatingField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    IconData? icon,
    String? iconAsset,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      style: TextStyle(fontSize: context.fs(15), color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: context.fs(13), color: _muted),
        floatingLabelStyle: TextStyle(fontSize: context.fs(12), color: _muted),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: context.w(12), right: context.w(8)),
          child: iconAsset != null
              ? Image.asset(
            iconAsset,
            width: context.w(14),
            height: context.h(11),
            color: AppColors.lightsubhead,
          )
              : Icon(icon, size: context.w(16), color: AppColors.lightsubhead),
        ),
        prefixIconConstraints:
            BoxConstraints(minWidth: context.w(38), minHeight: context.w(18)),
        isDense: true,
        contentPadding:
            EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(16)),
        errorStyle: TextStyle(fontSize: context.fs(10), color: _danger),
        border: _fieldBorder(context, _stroke),
        enabledBorder: _fieldBorder(context, _stroke),
        focusedBorder: _fieldBorder(context, _pri),
        errorBorder: _fieldBorder(context, _danger),
        focusedErrorBorder: _fieldBorder(context, _danger),
      ),
    );
  }


  Widget _label(BuildContext context, String text) => Text(
        text,
        style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w500, color: _muted),
      );

  Widget _sheetField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String? hint,
    bool readOnly = false,
    IconData? suffix,
    VoidCallback? onTap,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, label),
          SizedBox(height: context.h(8)),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            inputFormatters: formatters,
            validator: validator,
            style: TextStyle(fontSize: context.fs(13), color: Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: context.fs(13), color: _stroke),
              suffixIcon:
                  suffix == null ? null : Icon(suffix, size: context.w(16), color: _muted),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(14)),
              errorStyle: TextStyle(fontSize: context.fs(10), color: _danger),
              border: _fieldBorder(context, _stroke),
              enabledBorder: _fieldBorder(context, _stroke),
              focusedBorder: _fieldBorder(context, _pri),
              errorBorder: _fieldBorder(context, _danger),
              focusedErrorBorder: _fieldBorder(context, _danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Passport / PAN numbers are always stored upper-case.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
}

/// Dashed rounded-rect outline for the "Add New …" buttons — Flutter has no
/// dashed BorderSide, so the stroke is walked manually.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  const _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth,
            size.height - strokeWidth),
        Radius.circular(radius),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + _dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.radius != radius;
}
