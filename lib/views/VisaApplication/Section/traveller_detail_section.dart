// traveller_details_section.dart
import 'package:flutter/material.dart';

class TravellerDetailsSection extends StatefulWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isActive;
  final Map<String, dynamic>? preFilledData;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onSave;

  const TravellerDetailsSection({
    Key? key,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    this.preFilledData,
    required this.onContinue,
    required this.onBack,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TravellerDetailsSection> createState() => _TravellerDetailsSectionState();
}

class _TravellerDetailsSectionState extends State<TravellerDetailsSection> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passportController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedTitle = 'Mr';
  DateTime? _dateOfBirth;
  String _nationality = 'Indian';
  String _countryCode = '+91';
  bool _isExpanded = true;

  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isActive;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }

    if (widget.preFilledData != null) {
      _emailController.text = widget.preFilledData!['email'] ?? '';
      _phoneController.text = widget.preFilledData!['phone']?.toString().replaceAll(RegExp(r'[^\d]'), '') ?? '';
      _countryCode = widget.preFilledData!['countryCode'] ?? '+91';

      if (widget.preFilledData!['userName'] != null) {
        final nameParts = widget.preFilledData!['userName'].toString().split(' ');
        if (nameParts.isNotEmpty) _firstNameController.text = nameParts.first;
        if (nameParts.length > 1) _lastNameController.text = nameParts.sublist(1).join(' ');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passportController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (widget.isCompleted || widget.isActive) _toggleExpand();
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isActive ? const Color(0xffE3F2FD) : widget.isCompleted ? Colors.green.shade50 : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.isCompleted ? Colors.green : widget.isActive ? const Color(0xff0D47A1) : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Text('${widget.stepNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Traveller Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _heightAnimation,
            axisAlignment: -1.0,
            child: ClipRect(
              child: _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Primary Applicant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 1, child: _buildTitleDropdown()),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildTextField(controller: _firstNameController, label: 'First Name *', hint: 'John')),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(controller: _lastNameController, label: 'Last Name *', hint: 'Doe'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDateField()),
                const SizedBox(width: 8),
                Expanded(child: _buildNationalityField()),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(controller: _passportController, label: 'Passport No *', hint: 'Enter passport number'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 1, child: _buildPhoneField()),
                const SizedBox(width: 8),
                Expanded(flex: 1, child: _buildTextField(controller: _emailController, label: 'Email ID *', hint: 'your@gmail.com', keyboardType: TextInputType.emailAddress)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: widget.onBack, style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xff0D47A1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('BACK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xff0D47A1))))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: _onContinue, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('CONTINUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Color(0xff0D47A1), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: const TextStyle(fontSize: 11),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTitleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Title', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTitle,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 14),
              items: ['Mr', 'Mrs', 'Ms', 'Dr'].map((title) => DropdownMenuItem(value: title, child: Text(title, style: const TextStyle(fontSize: 11)))).toList(),
              onChanged: (value) => setState(() => _selectedTitle = value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date of Birth', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(child: Text(_dateOfBirth != null ? '${_dateOfBirth!.day}-${_dateOfBirth!.month}-${_dateOfBirth!.year}' : 'dd-mm-yyyy', style: TextStyle(fontSize: 11, color: _dateOfBirth != null ? Colors.black87 : Colors.grey.shade500))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNationalityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nationality', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _nationality,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 14),
              items: ['Indian', 'American', 'British', 'Australian'].map((nat) => DropdownMenuItem(value: nat, child: Text(nat, style: const TextStyle(fontSize: 11)))).toList(),
              onChanged: (value) => setState(() => _nationality = value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact Number *', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
                child: DropdownButton<String>(
                  value: _countryCode,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 14),
                  items: ['+91', '+1', '+44', '+971'].map((code) => DropdownMenuItem(value: code, child: Text(code, style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (val) => setState(() => _countryCode = val!),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '8595552345', hintStyle: TextStyle(fontSize: 11, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  style: const TextStyle(fontSize: 11),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 10) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime(1990), firstDate: DateTime(1950), lastDate: DateTime.now());
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'title': _selectedTitle,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'dateOfBirth': _dateOfBirth,
        'nationality': _nationality,
        'passport': _passportController.text,
        'email': _emailController.text,
        'phone': '$_countryCode ${_phoneController.text}',
        'countryCode': _countryCode,
      });
      widget.onContinue();
    }
  }
}