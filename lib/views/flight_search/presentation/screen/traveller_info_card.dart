import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TravellerInformationSection extends StatefulWidget {
  final bool isInternational;

  const TravellerInformationSection({super.key, this.isInternational = false});

  @override
  TravellerFormState createState() => TravellerFormState();
}

class TravellerFormState extends State<TravellerInformationSection> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _passportController = TextEditingController();
  final _passportExpiryController = TextEditingController();

  bool _travellerExpanded = true;

  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _surface = Color(0xFFFFFFFF);
  static const _fieldFill = Color(0xFFF8FAFE);
  static const _border = Color(0xFFE2E7F0);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _nationalityController.dispose();
    _passportController.dispose();
    _passportExpiryController.dispose();
    super.dispose();
  }

  bool validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  Map<String, dynamic> getTravellerData() {
    return {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'mobileNumber': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'gender': _genderController.text.trim(),
      'nationality': _nationalityController.text.trim(),
      'isInternational': widget.isInternational,
      if (widget.isInternational)
        'passportNumber': _passportController.text.trim(),
      if (widget.isInternational)
        'passportExpiry': _passportExpiryController.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Contact Information'),
          const SizedBox(height: 12),
          _buildCard(
            child: _responsiveFields(context, [
              _buildTextField(
                controller: _phoneController,
                label: 'Mobile Number',
                hintText: '+91 98765 43210',
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
                validator: _required('Mobile number'),
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'name@example.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
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
          ),
          const SizedBox(height: 22),
          _sectionTitle('Traveller Information'),
          const SizedBox(height: 12),
          _buildTravellerCard(context),
        ],
      ),
    );
  }

  Widget _buildTravellerCard(BuildContext context) {
    return _buildCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _travellerExpanded = !_travellerExpanded),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: _blue,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Adult 1',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _travellerExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: !_travellerExpanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                    child: Column(
                      children: [
                        _responsiveFields(context, [
                          _buildTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            hintText: 'John',
                            icon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: _required('First name'),
                          ),
                          _buildTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            hintText: 'Doe',
                            icon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: _required('Last name'),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        _responsiveFields(context, [
                          _buildDropdownField(
                            controller: _genderController,
                            label: 'Gender',
                            icon: Icons.wc_outlined,
                            items: const ['Male', 'Female', 'Other'],
                            validator: _required('Gender'),
                          ),
                          _buildTextField(
                            controller: _nationalityController,
                            label: 'Nationality',
                            hintText: 'Indian',
                            icon: Icons.public_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: _required('Nationality'),
                          ),
                        ]),
                        if (widget.isInternational) ...[
                          const SizedBox(height: 18),
                          _inlineNote(
                            'Passport details are required for international flights.',
                          ),
                          const SizedBox(height: 12),
                          _responsiveFields(context, [
                            _buildTextField(
                              controller: _passportController,
                              label: 'Passport Number',
                              hintText: 'A1234567',
                              icon: Icons.credit_card_outlined,
                              textCapitalization: TextCapitalization.characters,
                              validator: _required('Passport number'),
                            ),
                            _buildPassportExpiryField(),
                          ]),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
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
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 14),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _buildCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1B3A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF1E2430),
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _inlineNote(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD59D)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFF79009),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF77520F),
                fontSize: 12.5,
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
        style: const TextStyle(
          color: Color(0xFF4B5565),
          fontSize: 13,
          fontWeight: FontWeight.w700,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          decoration: _inputDecoration(hintText: hintText, icon: icon),
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
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          validator: validator,
          decoration: _inputDecoration(hintText: 'Select', icon: icon),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => controller.text = value ?? ''),
        ),
      ],
    );
  }

  Widget _buildPassportExpiryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Passport Expiry'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passportExpiryController,
          readOnly: true,
          validator: _required('Passport expiry'),
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
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
                      primary: _blue,
                      onPrimary: Colors.white,
                      onSurface: _navy,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              _passportExpiryController.text = DateFormat(
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
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFFB8BEC9),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: _navy, size: 19),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: _outline(_border),
      enabledBorder: _outline(_border),
      focusedBorder: _outline(_blue, width: 1.5),
      errorBorder: _outline(const Color(0xFFFFA4A4)),
      focusedErrorBorder: _outline(const Color(0xFFFF4D4F), width: 1.5),
      errorStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }

  OutlineInputBorder _outline(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
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
