import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class _TravellerControllers {
  final title = TextEditingController(text: 'Mr');
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final dob = TextEditingController();
  final nationality = TextEditingController(text: 'Indian');
  final passport = TextEditingController();
  final passportExpiry = TextEditingController();

  void dispose() {
    title.dispose();
    firstName.dispose();
    lastName.dispose();
    dob.dispose();
    nationality.dispose();
    passport.dispose();
    passportExpiry.dispose();
  }
}

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

class TravellerInformationSection extends StatefulWidget {
  final bool isInternational;

  /// Number of traveller forms to render. One card is shown per traveller
  /// (Adult 1, Adult 2, …); the Contact section stays shared.
  final int travellerCount;

  const TravellerInformationSection({
    super.key,
    this.isInternational = false,
    this.travellerCount = 1,
  });

  @override
  TravellerFormState createState() => TravellerFormState();
}

class TravellerFormState extends State<TravellerInformationSection> {
  final _formKey = GlobalKey<FormState>();

  // Shared contact details for the whole booking.
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );
  String? _emailError;
  String? _phoneError;

  // One controller bundle per traveller.
  late List<_TravellerControllers> _travellers;
  late List<bool> _expanded;

  // ---- MMT-inspired color palette ----
  static const _primary = Color(0xFF1B7BF2);      // blue
  static const _textDark = Color(0xFF1A2B4C);      // Dark navy for text
  static const _textGrey = Color(0xFF5A6879);      // Secondary text
  static const _surface = Color(0xFFFFFFFF);
  static const _fieldFill = Color(0xFFF5F7FA);     // Lighter grey
  static const _border = Color(0xFFE0E5ED);        // Softer border
  static const _shadowColor = Color(0x0D1A2B4C);   // Subtle shadow

  int get _count => widget.travellerCount < 1 ? 1 : widget.travellerCount;

  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final isValid = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
    ).hasMatch(value.trim());
    setState(() {
      _emailError = isValid ? null : 'Enter a valid email';
    });
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

  @override
  void initState() {
    super.initState();
    _initTravellers();
    _detectNationality();
  }

  void _initTravellers() {
    _travellers = List.generate(_count, (_) => _TravellerControllers());
    _expanded = List.generate(_count, (i) => i == 0);
  }

  /// Prefills Nationality from the device's public IP location, so most
  /// users don't have to type it. Defaults to 'Indian' (set synchronously in
  /// [_TravellerControllers]) until this resolves, and silently keeps that
  /// default on any failure — this is a convenience prefill, not a
  /// requirement, and the field stays fully editable either way.
  Future<void> _detectNationality() async {
    String? nationality;
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 4));
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
    if (!mounted || nationality == null) return;
    setState(() {
      for (final t in _travellers) {
        // Only overwrite if still the untouched default — never clobber
        // something the user already typed while this call was in flight.
        if (t.nationality.text == 'Indian') t.nationality.text = nationality!;
      }
    });
  }

  @override
  void didUpdateWidget(covariant TravellerInformationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.travellerCount != widget.travellerCount) {
      for (final t in _travellers) {
        t.dispose();
      }
      _initTravellers();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    for (final t in _travellers) {
      t.dispose();
    }
    super.dispose();
  }

  bool validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid && _expanded.any((e) => !e)) {
      setState(() {
        for (int i = 0; i < _expanded.length; i++) {
          _expanded[i] = true;
        }
      });
    }
    return isValid;
  }

  Map<String, dynamic> _travellerToMap(_TravellerControllers t) {
    return {
      'title': t.title.text.trim(),
      'firstName': t.firstName.text.trim().toUpperCase(),
      'lastName': t.lastName.text.trim().toUpperCase(),
      'dateOfBirth': t.dob.text.trim(),
      'mobileNumber': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'gender': _inferredGender(t.title.text),
      'nationality': t.nationality.text.trim(),
      'isInternational': widget.isInternational,
      // Always include passport keys so payment screen has them available.
      // TBO requires passport even on some domestic fares (e.g. GDS/Air India).
      // The values are empty strings when the user didn't fill them; the
      // BookingPassengerModel will only send them to TBO if non-empty.
      'passportNumber': t.passport.text.trim(),
      'passportExpiry': t.passportExpiry.text.trim(),
    };
  }

  Map<String, dynamic> getTravellerData() {
    return _travellerToMap(_travellers.first);
  }

  List<Map<String, dynamic>> getAllTravellersData() {
    return _travellers.map(_travellerToMap).toList();
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid mobile number (10-15 digits)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Contact Information'),
          SizedBox(height: context.h(8)),
          _buildContactCard(), // separate card for contact
          SizedBox(height: context.h(20)),
          _sectionTitle('Traveller Information'),
          SizedBox(height: context.h(8)),
          for (int i = 0; i < _count; i++) ...[
            if (i > 0) SizedBox(height: context.h(12)),
            _buildTravellerCard(context, i),
          ],
        ],
      ),
    );
  }

  // ---- New contact card with a grey background (no border) ----
  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: _responsiveFields(context, [
        _buildTextField(
          controller: _phoneController,
          label: 'Mobile Number',
          hintText: '+91 98765 43210',
          icon: Icons.phone_android_outlined,
          keyboardType: TextInputType.phone,
          onChanged: _validatePhone,
          errorText: _phoneError,
          validator: _phoneValidator,
        ),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hintText: 'name@example.com',
          icon: Icons.email_outlined,
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          onChanged: _validateEmail,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Email is required';
            final isValid = RegExp(
              r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
            ).hasMatch(text);
            return isValid ? null : 'Enter a valid email';
          },
        ),
      ]),
    );
  }

  Widget _buildTravellerCard(BuildContext context, int index) {
    final traveller = _travellers[index];
    final expanded = _expanded[index];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: context.w(16),
            offset: Offset(0, context.h(6)),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded[index] = !expanded),
            borderRadius: BorderRadius.circular(context.r(12)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(16),
                context.h(14),
                context.w(12),
                context.h(12),
              ),
              child: Row(
                children: [
                  // Avatar icon with circle
                  Container(
                    width: context.w(32),
                    height: context.w(32),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: _primary,
                      size: context.w(18),
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Text(
                      'Adult ${index + 1}',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF8895AA),
                      size: context.w(24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) _buildDivider(),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Offstage(
              offstage: !expanded,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(16),
                  context.h(8),
                  context.w(16),
                  context.h(18),
                ),
                child: Column(
                  children: [
                    // _sectionLabel('IDENTITY'),
                    SizedBox(height: context.h(8)),
                    _responsiveFields(context, [
                      _buildDropdownField(
                        controller: traveller.title,
                        label: 'Title',
                        icon: Icons.badge_outlined,
                        items: const ['Mr', 'Mrs', 'Ms', 'Miss', 'Master'],
                        validator: _required('Title'),
                      ),
                      _buildTextField(
                        controller: traveller.firstName,
                        label: 'First Name',
                        hintText: 'John',
                        icon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        validator: _required('First name'),
                        forceUpperCase: true,
                      ),
                    ]),
                    SizedBox(height: context.h(12)),
                    _responsiveFields(context, [
                      _buildTextField(
                        controller: traveller.lastName,
                        label: 'Last Name',
                        hintText: 'Doe',
                        icon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        validator: _required('Last name'),
                        forceUpperCase: true,
                      ),
                      _buildTextField(
                        controller: traveller.nationality,
                        label: 'Nationality',
                        hintText: 'Indian',
                        icon: Icons.public_outlined,
                        textCapitalization: TextCapitalization.words,
                        validator: _required('Nationality'),
                      ),
                    ]),
                    SizedBox(height: context.h(12)),
                    // _responsiveFields(context, [_buildDobField(traveller)]),
                    // Passport section — international flights only, and
                    // optional even there (airlines/immigration verify the
                    // physical document separately at check-in).
                    if (widget.isInternational) ...[
                      SizedBox(height: context.h(8)),
                      _inlineNote('Passport details are optional here — add them if you have them handy.'),
                      SizedBox(height: context.h(12)),
                      _responsiveFields(context, [
                        _buildTextField(
                          controller: traveller.passport,
                          label: 'Passport Number',
                          hintText: 'A1234567',
                          icon: Icons.credit_card_outlined,
                          textCapitalization: TextCapitalization.characters,
                          labelRequired: false,
                        ),
                        _buildPassportExpiryField(traveller),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Divider line when expanded
  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Divider(
        height: 0,
        thickness: 1,
        color: _border,
      ),
    );
  }

  Widget _responsiveFields(BuildContext context, List<Widget> children) {
    final width = MediaQuery.sizeOf(context).width;
    final useColumns = width >= 390;

    if (!useColumns || children.length == 1) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: context.h(12)),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children[0]),
        SizedBox(width: context.w(12)),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _textDark,
        fontSize: context.fs(17),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Small caps sub-heading used to group related fields within a
  /// traveller card (Identity / Demographics / Travel Document).
  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: _primary,
        fontSize: context.fs(11),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _inlineNote(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: const Color(0xFFFFD59D)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: context.w(18),
            color: const Color(0xFFF79009),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF77520F),
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String label, {bool required = true}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _textGrey,
          fontSize: context.fs(12),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFFF4D4F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool forceUpperCase = false,
    ValueChanged<String>? onChanged,
    String? errorText,
    bool labelRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: labelRequired),
        SizedBox(height: context.h(6)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: TextStyle(
            color: _textDark,
            fontSize: context.fs(14),
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(hintText: hintText, icon: icon, errorText: errorText),
          onChanged: (value) {
            if (forceUpperCase) {
              final upper = value.toUpperCase();
              if (value != upper) {
                controller.value = TextEditingValue(
                  text: upper,
                  selection: TextSelection.collapsed(
                    offset: upper.length,
                  ),
                );
              }
            }
            onChanged?.call(value);
            _formKey.currentState?.validate();
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> items,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        SizedBox(height: context.h(6)),
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.w(22),
            color: _textGrey,
          ),
          validator: validator,
          decoration: _inputDecoration(hintText: 'Select', icon: icon),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: context.fs(14),
                ),
              ),
            ),
          )
              .toList(),
          onChanged: (value) => setState(() => controller.text = value ?? ''),
        ),
      ],
    );
  }

  Widget _buildDobField(_TravellerControllers traveller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Date of Birth'),
        SizedBox(height: context.h(6)),
        TextFormField(
          controller: traveller.dob,
          readOnly: true,
          validator: _required('Date of birth'),
          style: TextStyle(
            color: _textDark,
            fontSize: context.fs(14),
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(
            hintText: 'Select date',
            icon: Icons.cake_outlined,
          ),
          onTap: () async {
            final now = DateTime.now();
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime(now.year - 25, now.month, now.day),
              firstDate: DateTime(now.year - 120),
              lastDate: now,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: _primary,
                      onPrimary: Colors.white,
                      onSurface: _textDark,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              setState(() {
                traveller.dob.text = DateFormat('dd MMM yyyy').format(pickedDate);
              });
              _formKey.currentState?.validate();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPassportExpiryField(_TravellerControllers traveller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Passport Expiry', required: false),
        SizedBox(height: context.h(6)),
        TextFormField(
          controller: traveller.passportExpiry,
          readOnly: true,
          style: TextStyle(
            color: _textDark,
            fontSize: context.fs(14),
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(
            hintText: 'Select date',
            icon: Icons.calendar_today_outlined,
          ),
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: _primary,
                      onPrimary: Colors.white,
                      onSurface: _textDark,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              traveller.passportExpiry.text = DateFormat(
                'dd MMM yyyy',
              ).format(pickedDate);
            }
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: const Color(0xFFA0AEC0),
        fontSize: context.fs(13),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: _textGrey, size: context.w(18)),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(14),
      ),
      border: _outline(_border),
      enabledBorder: _outline(_border),
      focusedBorder: _outline(_primary, width: 2),
      errorBorder: _outline(const Color(0xFFFFA4A4)),
      focusedErrorBorder: _outline(const Color(0xFFFF4D4F), width: 2),
      errorStyle: TextStyle(
        fontSize: context.fs(11),
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFF4D4F),
      ),
      errorText: errorText,
    );
  }

  OutlineInputBorder _outline(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.r(8)),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  String? Function(String?) _required(String label) {
    return (value) {
      if ((value ?? '').trim().isEmpty) return '$label is required';
      return null;
    };
  }
}