import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../Section/data/traveller_api_service.dart';
import '../widgets/account_kit.dart';

/// Full-screen "Add Travellers" form — Figma "Add Travellers". Saves through
/// the same `/api/travellers/` endpoint the old bottom sheet used and pops
/// the saved traveller back to the profile screen.
class AddTravellerScreen extends StatefulWidget {
  const AddTravellerScreen({super.key});

  @override
  State<AddTravellerScreen> createState() => _AddTravellerScreenState();
}

class _AddTravellerScreenState extends State<AddTravellerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _nationality = TextEditingController(text: 'Indian');
  final _passportNumber = TextEditingController();
  final _issuingCountry = TextEditingController(text: 'India');
  final _placeOfIssue = TextEditingController();

  DateTime? _dob;
  DateTime? _passportExpiry;
  String _gender = 'Male';
  bool _saving = false;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _nationality,
      _passportNumber,
      _issuingCountry,
      _placeOfIssue,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDate({
    required DateTime? initial,
    required DateTime first,
    required DateTime last,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initial ?? (last.isBefore(DateTime.now()) ? last : DateTime.now()),
      firstDate: first,
      lastDate: last,
    );
  }

  /// Adult / Child / Infant from the date of birth (12+ / 2–11 / under 2).
  String _paxType(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    if (age >= 12) return 'Adult';
    if (age >= 2) return 'Child';
    return 'Infant';
  }

  String? _apiDate(DateTime? d) =>
      d == null ? null : DateFormat('yyyy-MM-dd').format(d);

  Future<String?> _currentUserEmail() async {
    final prefs = sl<PreferencesManager>();
    final stored = prefs.getString('user_email');
    if (stored != null && stored.isNotEmpty) return stored;
    return prefs.getUserData()?['email'] as String?;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      _snack('Please add the date of birth');
      return;
    }
    setState(() => _saving = true);

    final payload = {
      'paxType': _paxType(_dob!),
      'title': _gender == 'Female' ? 'Ms' : 'Mr',
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'dob': _apiDate(_dob),
      'gender': _gender,
      'nationality': _nationality.text.trim(),
      'visaType': 'Tourist',
      'passportNumber': _passportNumber.text.trim(),
      'placeOfIssue': _placeOfIssue.text.trim(),
      'passportExpiry': _apiDate(_passportExpiry),
      'issuingCountry': _issuingCountry.text.trim(),
      'user_email': await _currentUserEmail(),
    };

    try {
      final response = await sl<TravellerApiService>().addTraveller(payload);
      final data = response.data;
      final traveller = (data is Map && data['traveller'] is Map)
          ? Map<String, dynamic>.from(data['traveller'] as Map)
          : payload;
      if (mounted) Navigator.pop(context, traveller);
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = body is Map
          ? (body['message'] ?? body['error'] ?? 'Failed to save traveller')
          : 'Failed to save traveller';
      _snack(message.toString());
    } catch (_) {
      _snack('Failed to save traveller');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? 'Enter $what' : null;

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.fx(14));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: AccountBottomActions(
          left: AccountSecondaryButton(
            label: 'CANCEL',
            onPressed: _saving ? null : () => Navigator.pop(context),
          ),
          right: AccountPrimaryButton(label: 'SAVE', onPressed: _save, loading: _saving),
        ),
        body: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.fx(16),
                context.fx(8),
                context.fx(16),
                context.fx(24),
              ),
              children: [
                const AccountTopBar(title: 'Add Travellers'),
                SizedBox(height: context.fx(12)),
                AccountSectionCard(
                  title: 'Personal Information',
                  icon: Icons.person_rounded,
                  iconColor: kAccountOrange,
                  child: Column(
                    children: [
                      SizedBox(height: context.fx(4)),
                      _text(_firstName, 'FIRST NAME', required: true,
                          validator: (v) => _required(v, 'first name')),
                      gap,
                      _text(_lastName, 'LAST NAME', required: true,
                          validator: (v) => _required(v, 'last name')),
                      gap,
                      _date(
                        'DATE OF BIRTH',
                        _dob,
                        required: true,
                        onTap: () async {
                          final d = await _pickDate(
                            initial: _dob,
                            first: DateTime(1920),
                            last: DateTime.now(),
                          );
                          if (d != null) setState(() => _dob = d);
                        },
                      ),
                      gap,
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        isExpanded: true,
                        style: accountValueStyle(context),
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
                        decoration: accountInputDecoration(context, label: 'GENDER', required: true),
                        items: [
                          for (final g in _genders) DropdownMenuItem(value: g, child: Text(g)),
                        ],
                        onChanged: (v) => setState(() => _gender = v ?? _gender),
                      ),
                      gap,
                      _text(_nationality, 'NATIONALITY'),
                    ],
                  ),
                ),
                SizedBox(height: context.fx(20)),
                AccountSectionCard(
                  title: 'Passport Details',
                  icon: Icons.menu_book_rounded,
                  iconColor: AppColors.AppBlue,
                  child: Column(
                    children: [
                      SizedBox(height: context.fx(4)),
                      _text(_passportNumber, 'PASSPORT NUMBER',
                          caps: TextCapitalization.characters),
                      gap,
                      _text(_issuingCountry, 'PASSPORT FROM'),
                      gap,
                      _text(_placeOfIssue, 'PLACE OF ISSUE'),
                      gap,
                      _date(
                        'PASSPORT VALID TILL',
                        _passportExpiry,
                        onTap: () async {
                          final d = await _pickDate(
                            initial: _passportExpiry,
                            first: DateTime.now(),
                            last: DateTime(2100),
                          );
                          if (d != null) setState(() => _passportExpiry = d);
                        },
                      ),
                      SizedBox(height: context.fx(6)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Needed for international trips only.',
                          style: TextStyle(fontSize: context.ffs(10), color: kAccountMuted),
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

  Widget _text(
    TextEditingController controller,
    String label, {
    bool required = false,
    String? Function(String?)? validator,
    TextCapitalization caps = TextCapitalization.words,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: caps,
      style: accountValueStyle(context),
      validator: validator,
      decoration: accountInputDecoration(context, label: label, required: required),
    );
  }

  Widget _date(
    String label,
    DateTime? value, {
    required VoidCallback onTap,
    bool required = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: InputDecorator(
        decoration: accountInputDecoration(
          context,
          label: label,
          required: required,
          suffix: Icon(Icons.calendar_month_rounded, size: context.fx(18), color: AppColors.AppBlue),
        ),
        child: Text(
          value == null ? 'Select date' : DateFormat('dd MMM, yyyy').format(value),
          style: value == null
              ? TextStyle(fontSize: context.ffs(12), color: Colors.grey.shade400)
              : accountValueStyle(context),
        ),
      ),
    );
  }
}
