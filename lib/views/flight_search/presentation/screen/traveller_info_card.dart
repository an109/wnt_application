import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class _TravellerControllers {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final gender = TextEditingController();
  final nationality = TextEditingController();
  final passport = TextEditingController();
  final passportExpiry = TextEditingController();

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    gender.dispose();
    nationality.dispose();
    passport.dispose();
    passportExpiry.dispose();
  }
}

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
  static const _primary = Color(0xFF1B7BF2);      // MMT blue
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
  }

  void _initTravellers() {
    _travellers = List.generate(_count, (_) => _TravellerControllers());
    _expanded = List.generate(_count, (i) => i == 0);
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
      'firstName': t.firstName.text.trim().toUpperCase(),
      'lastName': t.lastName.text.trim().toUpperCase(),
      'mobileNumber': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'gender': t.gender.text.trim(),
      'nationality': t.nationality.text.trim(),
      'isInternational': widget.isInternational,
      if (widget.isInternational) 'passportNumber': t.passport.text.trim(),
      if (widget.isInternational)
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
                    _responsiveFields(context, [
                      _buildTextField(
                        controller: traveller.firstName,
                        label: 'First Name',
                        hintText: 'John',
                        icon: Icons.badge_outlined,
                        textCapitalization: TextCapitalization.words,
                        validator: _required('First name'),
                        forceUpperCase: true,
                      ),
                      _buildTextField(
                        controller: traveller.lastName,
                        label: 'Last Name',
                        hintText: 'Doe',
                        icon: Icons.badge_outlined,
                        textCapitalization: TextCapitalization.words,
                        validator: _required('Last name'),
                        forceUpperCase: true,
                      ),
                    ]),
                    SizedBox(height: context.h(12)),
                    _responsiveFields(context, [
                      _buildDropdownField(
                        controller: traveller.gender,
                        label: 'Gender',
                        icon: Icons.wc_outlined,
                        items: const ['Male', 'Female', 'Other'],
                        validator: _required('Gender'),
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
                    if (widget.isInternational) ...[
                      SizedBox(height: context.h(16)),
                      _inlineNote(
                        'Passport details are required for international flights.',
                      ),
                      SizedBox(height: context.h(12)),
                      _responsiveFields(context, [
                        _buildTextField(
                          controller: traveller.passport,
                          label: 'Passport Number',
                          hintText: 'A1234567',
                          icon: Icons.credit_card_outlined,
                          textCapitalization: TextCapitalization.characters,
                          validator: _required('Passport number'),
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

  Widget _label(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _textGrey,
          fontSize: context.fs(12),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Color(0xFFFF4D4F),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool forceUpperCase = false,
    ValueChanged<String>? onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
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

  Widget _buildPassportExpiryField(_TravellerControllers traveller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Passport Expiry'),
        SizedBox(height: context.h(6)),
        TextFormField(
          controller: traveller.passportExpiry,
          readOnly: true,
          validator: _required('Passport expiry'),
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